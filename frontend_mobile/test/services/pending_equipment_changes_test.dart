import 'dart:io';

import 'package:appmobilegmao/services/pending_equipment_changes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  setUpAll(() => Hive.init(Directory.systemTemp.createTempSync('pending_eq').path));

  test('a sent modification is marked pending, whatever the code case', () async {
    await PendingEquipmentChanges.markPending(' eq-001 ');

    final since = PendingEquipmentChanges.pendingSince('EQ-001');
    expect(since, isNotNull);
    expect(DateTime.now().difference(since!).inMinutes, lessThan(1));
    expect(PendingEquipmentChanges.pendingSince('EQ-002'), isNull);
  });

  test('pending modifications survive a restart (reloaded from storage)', () async {
    await PendingEquipmentChanges.markPending('EQ-RELOAD');
    await PendingEquipmentChanges.load();
    expect(PendingEquipmentChanges.pendingSince('eq-reload'), isNotNull);
  });
}
