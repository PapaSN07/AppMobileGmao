import 'package:appmobilegmao/models/ot_referentials.dart';
import 'package:appmobilegmao/models/ot_status.dart';
import 'package:appmobilegmao/services/ot_payload_rules.dart';
import 'package:flutter_test/flutter_test.dart';

const _refs = OTReferentials(
  jobTypes: [RefItem('CORR', 'CORRECTIF'), RefItem('PREV', 'PREVENTIVE')],
  jobClasses: [RefItem('POSTE', 'POSTE'), RefItem('TELCOM', 'TELECOM')],
  priorities: [RefItem('URGENT', 'URGENT'), RefItem('NORMALE', 'NORMALE')],
  supervisors: [RefItem('5144', 'Paul'), RefItem('M07306', 'Agent')],
);

void main() {
  group('OTPayloadRules.forCreate', () {
    test('keeps real Coswin job classes longer than 4 characters', () {
      final p = OTPayloadRules.forCreate({
        'wowoJob': 'Remplacement transformateur HTA',
        'wowoJobClass': 'telcom',
      }, _refs);
      expect(p['wowoJob'], 'Remplacement tr');
      expect(p['mdjbDescription'], p['wowoJob']);
      expect(p['wowoJobClass'], 'TELCOM');
      expect(p['wowoScheduleDate'], isNotNull);
    });

    test('falls back to the default class when the class is unknown', () {
      final p = OTPayloadRules.forCreate({'wowoJobClass': 'POST'}, _refs);
      expect(p['wowoJobClass'], OTPayloadRules.defaultJobClass);
      expect(OTPayloadRules.forCreate({}, _refs)['wowoJob'], OTPayloadRules.defaultJob);
    });
  });

  group('OTPayloadRules.forUpdate', () {
    test('validates against Coswin referentials', () {
      final p = OTPayloadRules.forUpdate({
        'wowoPriority': 'urgent',
        'wowoJobType': 'corr',
        'wowoJobClass': 'poste',
        'wowoSupervisor': 'M07306',
        'wowoCompletionRate': 40,
      }, _refs);
      expect(p['wowoPriority'], 'URGENT');
      expect(p['wowoJobType'], 'CORR');
      expect(p['wowoJobClass'], 'POSTE');
      expect(p['wowoSupervisor'], 'M07306');
      expect(p.containsKey('wowoCompletionRate'), isFalse);
    });

    test('drops values unknown to Coswin', () {
      final p = OTPayloadRules.forUpdate({
        'wowoPriority': 'XYZ',
        'wowoJobType': 'EXPT',
        'wowoJobClass': 'CEL-',
        'wowoSupervisor': 'Jean',
      }, _refs);
      expect(p, isEmpty); // superviseur inconnu retiré, pas remplacé
    });

    test('maps priority aliases to NORMALE', () {
      expect(OTPayloadRules.forUpdate({'wowoPriority': 'normal'}, _refs)['wowoPriority'], 'NORMALE');
    });

    test('sends values as-is while referentials are not loaded', () {
      final p = OTPayloadRules.forUpdate({'wowoJobClass': 'GCIVIL', 'wowoJobType': 'VIS'});
      expect(p, {'wowoJobClass': 'GCIVIL', 'wowoJobType': 'VIS'});
    });

    test('does not add fields that were absent', () {
      expect(OTPayloadRules.forUpdate({'wowoZone': 'DAKAR'}, _refs), {'wowoZone': 'DAKAR'});
    });
  });

  group('OTPayloadRules.withoutRejectedFields', () {
    test('removes fields named in the Coswin error', () {
      final payload = {'wowoPriority': 'NORMALE', 'wowoJobType': 'CORR', 'wowoZone': 'DAKAR'};
      final fallback = OTPayloadRules.withoutRejectedFields(
        payload,
        Exception('Invalid Job Type and priority'),
      );
      expect(fallback, {'wowoZone': 'DAKAR'});
      expect(OTPayloadRules.withoutRejectedFields(payload, Exception('timeout')), isNull);
    });
  });

  group('Coswin request bodies', () {
    setUp(() => OTStatus.register({'CR': 0, 'EC': 1, 'TE': 2}));

    test('update0 keeps only updatable fields and sends the status apart', () {
      final body = OTPayloadRules.update0Body({
        'wowoJobType': 'CORR',
        'wowoJobClass': 'POSTE',
        'wowoJob': 'MOUV_TRF',
        'wowoZone': 'DAKAR',
        'wowoUserStatus': 'EC',
      }, newStatus: 'EC');

      expect(body['workorder0View'], {'wowoJobType': 'CORR', 'wowoJobClass': 'POSTE'});
      final statuses = body['woUserStatusUpdate0List']['woUserStatusUpdate0'] as List;
      expect(statuses.single['wowoUserStatus'], 'EC');
      expect(statuses.single['wowoStatusComments'], isNotEmpty);
    });

    test('update0 sends an empty status list when the status is unchanged', () {
      final body = OTPayloadRules.update0Body({'wowoJobType': 'CORR'});
      expect(body['woUserStatusUpdate0List'], {'woUserStatusUpdate0': []});
    });

    test('createSimple0 nests header fields and requires equipment and job type', () {
      final body = OTPayloadRules.createSimple0Body({
        'wowoEquipment': 'LM0109CIMZ2TRF1',
        'wowoJobType': 'CORR',
        'wowoJob': 'Remplacement',
        'wowoRequestEntity': 'SDDV',
        'wowoScheduleDate': '2026-09-25T00:00:00.000Z',
        'wowoUserStatus': 'CR',
      });
      final main = body['workordercreatesimple0'] as Map;
      expect(main['wowoScheduleDate'], '2026-09-25T00:00:00.000Z');
      expect(main['workOrderExtraViewworkordercreatesimple0'], {
        'wowoEquipment': 'LM0109CIMZ2TRF1',
        'wowoJob': 'Remplacement',
        'wowoJobType': 'CORR',
        'wowoActionEntity': 'SDDV',
        'wowoJobDescription': 'Remplacement',
      });
      expect((body['woUserStatusCreatesimple0List']['woUserStatusCreatesimple0'] as List).single['wowoUserStatus'], 'CR');

      expect(() => OTPayloadRules.createSimple0Body({'wowoJobType': 'CORR'}), throwsArgumentError);
    });
  });
}
