import 'package:appmobilegmao/models/ot_status.dart';
import 'package:appmobilegmao/models/work_order.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => OTStatus.register({'CR': 0, 'EC': 1, 'TE': 2, 'CL': 2}));

  group('Taux de réalisation', () {
    test('Coswin value (wowoLongString2) wins over the status', () {
      final ot = WorkOrder.fromJson({'wowoCode': 1, 'wowoUserStatus': 'EC', 'wowoLongString2': '75%'});
      expect(ot.wowoCompletionRate, 75);
    });

    test('free text after the percentage is ignored', () {
      expect(WorkOrder.parseCompletionRate('100% suite vandalisme'), 100);
      expect(WorkOrder.parseCompletionRate('00%'), 0);
      expect(WorkOrder.parseCompletionRate('Pas de taux'), isNull);
      expect(WorkOrder.parseCompletionRate(null), isNull);
    });

    test('falls back to the status when Coswin has no value', () {
      final ot = WorkOrder.fromJson({'wowoCode': 1, 'wowoUserStatus': 'EC'});
      expect(ot.wowoCompletionRate, 50);
    });
  });
}
