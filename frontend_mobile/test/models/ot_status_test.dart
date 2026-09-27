import 'package:appmobilegmao/models/ot_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OTStatus (référentiel Coswin chargé)', () {
    setUp(() => OTStatus.register({
          'CR': 0, 'L1': 0,
          'EC': 1, 'SU': 1, 'AP': 1,
          'TE': 2, 'CL': 2, 'RT': 2,
          'AY': 3,
          'AZ': 4,
        }));

    test('normalize maps synonyms to Coswin codes', () {
      expect(OTStatus.normalize(' fait '), 'TE');
      expect(OTStatus.normalize('En cours'), 'EC');
      expect(OTStatus.normalize('OUV'), 'CR'); // OUV n'existe pas dans Coswin
      expect(OTStatus.normalize('ap'), 'AP');
      expect(OTStatus.normalize('SUSP'), isNull);
      expect(OTStatus.normalize(null), isNull);
    });

    test('closed / editable follow the Coswin system status', () {
      expect(OTStatus.isClosed('cl'), isTrue);
      expect(OTStatus.isClosed('RT'), isTrue);
      expect(OTStatus.isClosed('AZ'), isTrue);
      expect(OTStatus.isClosed('AP'), isFalse);
      expect(OTStatus.isEditable('AP'), isTrue);
      expect(OTStatus.isEditable('AY'), isFalse);
      expect(OTStatus.isEditable('INCONNU'), isFalse);
    });

    test('completionRate', () {
      expect(OTStatus.completionRate('TERMINE'), 100.0);
      expect(OTStatus.completionRate('SU'), 50.0);
      expect(OTStatus.completionRate('CR'), 0.0);
      expect(OTStatus.completionRate('XX'), isNull);
    });
  });
}
