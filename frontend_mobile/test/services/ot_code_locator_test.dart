import 'package:appmobilegmao/services/ot_code_locator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Faux Coswin : OT de codes [first, last], 50 par appel, ordre croissant.
class _FakeCoswin {
  _FakeCoswin(this.first, this.last);
  final int first;
  int last;
  int calls = 0;

  Future<CodeProbe> probe(int from, int to) async {
    calls++;
    final lo = from < first ? first : from;
    final hi = to > last ? last : to;
    if (lo > hi) return const CodeProbe([], false);
    final end = (lo + 49) < hi ? lo + 49 : hi;
    return CodeProbe([for (var c = lo; c <= end; c++) c], end < hi);
  }
}

void main() {
  final year = DateTime.now().year;
  final first = year * 1000000 + 253021;

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('finds the first and latest codes of the year', () async {
    final coswin = _FakeCoswin(first, first + 18034);
    final locator = OTCodeLocator(coswin.probe);

    expect(await locator.firstCode(year), first);
    expect(await locator.latestCode(year), first + 18034);
  });

  test('reuses the remembered latest code: one probe when few new OT', () async {
    final coswin = _FakeCoswin(first, first + 18034);
    await OTCodeLocator(coswin.probe).latestCode(year);

    coswin.last += 20; // 20 nouveaux OT depuis le dernier passage
    coswin.calls = 0;
    final latest = await OTCodeLocator(coswin.probe).latestCode(year);

    expect(latest, first + 18054);
    expect(coswin.calls, 1);
  });

  test('handles many new OT since the last visit', () async {
    final coswin = _FakeCoswin(first, first + 100);
    await OTCodeLocator(coswin.probe).latestCode(year);

    coswin.last += 5000;
    expect(await OTCodeLocator(coswin.probe).latestCode(year), first + 5100);
  });

  test('returns null for a year without OT', () async {
    final coswin = _FakeCoswin(first, first + 10);
    expect(await OTCodeLocator(coswin.probe).latestCode(year - 1), isNull);
  });
}
