import 'package:appmobilegmao/models/coswin_comment_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CoswinCommentLog.parse', () {
    test('reads several entries, most recent first (format <b>, OT 2026268977)', () {
      const html = '<b>#[moustapha.fall2] - 31-03-2026 07:30:55</b><br>LES HEURES D UTILISATION SONT VIDES&nbsp;<br><br>'
          '<b>#[mouhamed.niasse] - 30-03-2026 12:21:04</b><br>LE CABLE EST UNE RECUPERATION<div>&nbsp;POSTE DE LINGUERE.</div><br><br>';
      final entries = CoswinCommentLog.parse(html);

      expect(entries, hasLength(2));
      expect(entries[0].author, 'moustapha.fall2');
      expect(entries[0].date, '31-03-2026 07:30:55');
      expect(entries[0].dateTime, DateTime(2026, 3, 31, 7, 30, 55));
      expect(entries[0].text, 'LES HEURES D UTILISATION SONT VIDES');
      expect(entries[1].author, 'mouhamed.niasse');
      expect(entries[1].text, 'LE CABLE EST UNE RECUPERATION\n POSTE DE LINGUERE.');
    });

    test('reads the <span> header with matricule (OT 2026265000)', () {
      const html = '<span style="font-weight: bold;">#[amadou.mbodji] - 05-03-2026 15:52:59, 7390 - 05-03-2026 15:52:30</span>'
          '<br/><br/>TRAVAUX REALISES PAR BABALY SIDIBE';
      final entries = CoswinCommentLog.parse(html);

      expect(entries.single.author, 'amadou.mbodji');
      expect(entries.single.date, '05-03-2026 15:52:59');
      expect(entries.single.text, 'TRAVAUX REALISES PAR BABALY SIDIBE');
    });

    test('plain text without header gives one entry without author (OT 2026262000)', () {
      final entries = CoswinCommentLog.parse('REGLAGE PARTIE MECANIQUE DHP KEUR SALOUM&nbsp; NDIANE');
      expect(entries.single.author, isEmpty);
      expect(entries.single.text, 'REGLAGE PARTIE MECANIQUE DHP KEUR SALOUM  NDIANE');
    });

    test('empty field gives no entry', () {
      expect(CoswinCommentLog.parse(null), isEmpty);
      expect(CoswinCommentLog.parse('  '), isEmpty);
    });
  });

  group('CoswinCommentLog.prepend', () {
    test('adds the new entry first, in Coswin format, and reads back', () {
      const existing = '<b>#[ancien] - 01-01-2026 08:00:00</b><br>Ancien texte<br><br>';
      final html = CoswinCommentLog.prepend(
        existing,
        author: 'agent.test',
        text: 'Ligne 1\nTension <230V> & isolement OK',
        now: DateTime(2026, 9, 28, 9, 5, 7),
      );

      expect(html, startsWith('<b>#[agent.test] - 28-09-2026 09:05:07</b><br>'));
      final entries = CoswinCommentLog.parse(html);
      expect(entries.map((e) => e.author), ['agent.test', 'ancien']);
      expect(entries.first.text, 'Ligne 1\nTension <230V> & isolement OK');
    });
  });
}
