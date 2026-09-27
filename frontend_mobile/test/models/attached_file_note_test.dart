import 'package:appmobilegmao/models/attached_file_note.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AttachedFileNote', () {
    test('compose then parse gives back the file information', () {
      final text = AttachedFileNote.compose('Poste inspecté', {
        'nom': 'photo.jpg',
        'type': 'JPG',
        'url': 'http://serveur/doc',
        'isImprimable': true,
      });

      expect(text, startsWith('Poste inspecté\n[PJ: '));
      expect(AttachedFileNote.stripFrom(text), 'Poste inspecté');
      expect(AttachedFileNote.parse(text), {
        'nom': 'photo.jpg',
        'type': 'JPG',
        'url': 'http://serveur/doc',
        'isImprimable': true,
      });
    });

    test('comment without attachment is left untouched', () {
      expect(AttachedFileNote.compose(' Simple ', null), 'Simple');
      expect(AttachedFileNote.parse('Simple'), isNull);
      expect(AttachedFileNote.stripFrom('Simple'), 'Simple');
    });

    test('reads the older attachment format', () {
      const legacy = 'Texte 📎 [Fichier joint: Nom: plan.pdf|Type: PDF]';
      expect(AttachedFileNote.parse(legacy), {'nom': 'plan.pdf', 'type': 'PDF'});
      expect(AttachedFileNote.stripFrom(legacy), 'Texte');
    });
  });
}
