// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';

Future<Map<String, double>?> getCurrentGpsPosition() async {
  final completer = Completer<Map<String, double>?>();
  try {
    html.window.navigator.geolocation.getCurrentPosition(
      enableHighAccuracy: true,
      timeout: const Duration(seconds: 10),
    ).then((pos) {
      final lat = pos.coords?.latitude?.toDouble();
      final lng = pos.coords?.longitude?.toDouble();
      if (lat != null && lng != null) {
        completer.complete({'latitude': lat, 'longitude': lng});
      } else {
        completer.complete(null);
      }
    }).catchError((e) {
      completer.complete(null);
    });
  } catch (_) {
    completer.complete(null);
  }
  return completer.future;
}
