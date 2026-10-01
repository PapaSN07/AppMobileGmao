import 'dart:async';
import 'dart:io';

import 'package:appmobilegmao/models/work_order.dart';
import 'package:appmobilegmao/services/api_service.dart';
import 'package:appmobilegmao/services/offline_snapshots.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  setUpAll(() async {
    Hive.init(Directory.systemTemp.createTempSync('offline_snap').path);
    await OfflineSnapshots.load();
  });

  test('a saved list comes back with its date, also after a restart', () async {
    await OfflineSnapshots.saveList('equipments|SDDV', [
      {'code': 'EQ-1', 'famille': 'TRANSFO', 'attributes': []},
    ]);
    await OfflineSnapshots.load();

    final saved = OfflineSnapshots.readList('equipments|SDDV');
    expect(saved, isNotNull);
    expect(saved!.data.single['code'], 'EQ-1');
    expect(DateTime.now().difference(saved.savedAt).inMinutes, lessThan(1));
    expect(OfflineSnapshots.readList('equipments|AUTRE'), isNull);
  });

  test('a saved work order still reads the same once restored', () async {
    final order = WorkOrder.fromJson({
      'wowoCode': 2026271071,
      'wowoUserStatus': 'EN_COURS',
      'wowoEquipment': 'EQ-1',
      'wowoLongString2': '75%',
      'wowoRequestEntity': 'SDDV',
    });
    await OfflineSnapshots.saveList('ot_list|SDDV|false', [order.toJson()]);

    final restored = WorkOrder.fromJson(OfflineSnapshots.readList('ot_list|SDDV|false')!.data.single);
    expect(restored.wowoCode, 2026271071);
    expect(restored.wowoEquipment, 'EQ-1');
    expect(restored.wowoCompletionRate, order.wowoCompletionRate);
  });

  test('only network failures fall back to the saved copy', () {
    expect(isNetworkFailure(ApiException('injoignable', statusCode: 0)), isTrue);
    expect(isNetworkFailure(const SocketException('no route')), isTrue);
    expect(isNetworkFailure(TimeoutException('lent')), isTrue);
    expect(isNetworkFailure(ApiException('refusé', statusCode: 403)), isFalse);
    expect(isNetworkFailure(ApiException('erreur', statusCode: 500)), isFalse);
  });
}
