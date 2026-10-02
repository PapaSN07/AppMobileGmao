import 'dart:io';

import 'package:appmobilegmao/services/api_service.dart';
import 'package:appmobilegmao/services/ot_conflict.dart';
import 'package:appmobilegmao/services/ot_sync_service.dart';
import 'package:appmobilegmao/services/pending_ot_queue.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  setUpAll(() async {
    Hive.init(Directory.systemTemp.createTempSync('pending_ot').path);
    await PendingOtQueue.load();
  });

  setUp(() async {
    for (final a in PendingOtQueue.all()) {
      await PendingOtQueue.remove(a.id);
    }
  });

  group('file des saisies hors ligne', () {
    test('keeps the entry order and survives a restart', () async {
      await PendingOtQueue.enqueue(PendingOtKind.updateOT, '2026271071', data: {'wowoJob': 'A'}, username: 'agent');
      await PendingOtQueue.enqueue(PendingOtKind.addComment, '2026271071', data: {'text': 'B'}, username: 'agent');
      await PendingOtQueue.load();

      final kinds = PendingOtQueue.all().map((a) => a.kind).toList();
      expect(kinds, [PendingOtKind.updateOT, PendingOtKind.addComment]);
      expect(PendingOtQueue.actions.value, hasLength(2));
      expect(PendingOtQueue.hasPendingFor('2026271071'), isTrue);
    });

    test('an OT created offline gets its real code for the following entries', () async {
      final temp = '${PendingOtQueue.newTemporaryCode()}';
      expect(PendingOtQueue.isTemporaryCode(temp), isTrue);
      await PendingOtQueue.enqueue(PendingOtKind.createOT, temp, data: {'wowoJob': 'X'}, username: 'agent');
      await PendingOtQueue.enqueue(PendingOtKind.createPart, temp, data: {'wospItem': 'P1'}, username: 'agent');

      await PendingOtQueue.replaceCode(temp, '2026300001');

      expect(PendingOtQueue.all().map((a) => a.otCode), everyElement('2026300001'));
    });

    test('only the entries of the given user are listed', () async {
      await PendingOtQueue.enqueue(PendingOtKind.addComment, '1', username: 'agent.a');
      await PendingOtQueue.enqueue(PendingOtKind.addComment, '2', username: 'agent.b');
      expect(PendingOtQueue.forUser('agent.a').map((a) => a.otCode), ['1']);
    });
  });

  group('conflits', () {
    const baseline = {'wowoJobType': 'CORRECTIF', 'wowoPriority': '2'};

    test('a field nobody else changed is not a conflict', () {
      expect(
        OtConflict.detect(
          baseline: baseline,
          wanted: {'wowoJobType': 'PREVENTIF', 'wowoPriority': '2'},
          current: {'wowoJobType': 'CORRECTIF', 'wowoPriority': '2'},
        ),
        isEmpty,
      );
    });

    test('someone else already set the same value: no conflict', () {
      expect(
        OtConflict.detect(
          baseline: baseline,
          wanted: {'wowoJobType': 'PREVENTIF'},
          current: {'wowoJobType': 'PREVENTIF', 'wowoPriority': '2'},
        ),
        isEmpty,
      );
    });

    test('a value changed in Coswin since the entry is a conflict', () {
      final conflicts = OtConflict.detect(
        baseline: baseline,
        wanted: {'wowoJobType': 'PREVENTIF', 'wowoPriority': '2'},
        current: {'wowoJobType': 'AMELIORATIF', 'wowoPriority': '2'},
      );
      expect(conflicts.single.field, 'wowoJobType');
      expect(conflicts.single.coswin, 'AMELIORATIF');
      expect(conflicts.single.mine, 'PREVENTIF');
    });

    test('the baseline only keeps the fields being changed', () {
      expect(
        OtConflict.baselineFor({'wowoJobType': 'X'}, {'wowoJobType': 'CORRECTIF', 'wowoZone': 'DAKAR'}),
        {'wowoJobType': 'CORRECTIF'},
      );
    });
  });

  group('envoi', () {
    OtSyncService service(Future<void> Function(PendingOtAction) send, {bool network = true}) => OtSyncService(
          send: send,
          currentUsername: () => 'agent',
          hasNetwork: () async => network,
        );

    test('sends in entry order and empties the queue', () async {
      await PendingOtQueue.enqueue(PendingOtKind.updateOT, '10', username: 'agent');
      await PendingOtQueue.enqueue(PendingOtKind.addComment, '11', username: 'agent');
      final sent = <String>[];

      final report = await service((a) async => sent.add(a.otCode)).syncNow();

      expect(sent, ['10', '11']);
      expect(report.sent, 2);
      expect(PendingOtQueue.all(), isEmpty);
    });

    test('a network failure stops the sending, the rest stays queued', () async {
      await PendingOtQueue.enqueue(PendingOtKind.addComment, '10', username: 'agent');
      await PendingOtQueue.enqueue(PendingOtKind.addComment, '11', username: 'agent');

      final report = await service((a) async => throw ApiException('injoignable', statusCode: 0)).syncNow();

      expect(report.stoppedByNetwork, isTrue);
      expect(PendingOtQueue.all(), hasLength(2));
      expect(PendingOtQueue.all().every((a) => a.status == PendingStatus.pending), isTrue);
    });

    test('a refusal blocks only its OT; the other OT is sent', () async {
      await PendingOtQueue.enqueue(PendingOtKind.updateOT, '10', username: 'agent');
      await PendingOtQueue.enqueue(PendingOtKind.addComment, '10', username: 'agent');
      await PendingOtQueue.enqueue(PendingOtKind.addComment, '20', username: 'agent');
      final sent = <String>[];

      await service((a) async {
        if (a.kind == PendingOtKind.updateOT) throw ApiException('Champ invalide', statusCode: 400);
        sent.add(a.otCode);
      }).syncNow();

      expect(sent, ['20']);
      final left = PendingOtQueue.all();
      expect(left.map((a) => a.otCode), ['10', '10']);
      expect(left.first.status, PendingStatus.failed);
      expect(left.first.lastError, 'Champ invalide');
    });

    test('a conflict is kept for the agent; "send my version" forces it', () async {
      await PendingOtQueue.enqueue(PendingOtKind.updateOT, '10', username: 'agent');
      final sync = service((a) async {
        if (!a.force) {
          throw const OtConflictException([FieldConflict('wowoPriority', coswin: '1', mine: '3')]);
        }
      });

      await sync.syncNow();
      final conflict = PendingOtQueue.all().single;
      expect(conflict.status, PendingStatus.conflict);
      expect(conflict.conflicts.single.field, 'wowoPriority');

      final report = await sync.retry(conflict, force: true);
      expect(report.sent, 1);
      expect(PendingOtQueue.all(), isEmpty);
    });

    test('a comment on an OT created offline follows the new code', () async {
      final temp = '${PendingOtQueue.newTemporaryCode()}';
      await PendingOtQueue.enqueue(PendingOtKind.createOT, temp, username: 'agent');
      await PendingOtQueue.enqueue(PendingOtKind.addComment, temp, username: 'agent');
      final sent = <String>[];

      await service((a) async {
        sent.add(a.otCode);
        if (a.kind == PendingOtKind.createOT) await PendingOtQueue.replaceCode(a.otCode, '2026300002');
      }).syncNow();

      expect(sent, [temp, '2026300002']);
    });

    test('another user\'s entries are not sent', () async {
      await PendingOtQueue.enqueue(PendingOtKind.addComment, '10', username: 'autre');
      final report = await service((a) async {}).syncNow();
      expect(report.sent, 0);
      expect(PendingOtQueue.all(), hasLength(1));
    });
  });
}
