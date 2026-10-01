import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:appmobilegmao/services/api_service.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  
  bool _isLocalHost() {
    final base = ApiService().baseUrl;
    return base.contains('127.0.0.1') || base.contains('10.0.2.2') || base.contains('localhost') || base.contains('192.168.');
  }

  Future<bool> isConnected() async {
    final result = await _connectivity.checkConnectivity();
    if (result != ConnectivityResult.none) return true;
    return _isLocalHost();
  }
  
  /// Appelle [onBack] chaque fois que le téléphone retrouve le réseau
  /// (après un court délai, le temps que la connexion soit vraiment utilisable).
  StreamSubscription<bool> onReconnected(void Function() onBack) {
    var wasOnline = true;
    isConnected().then((online) => wasOnline = online);
    return connectivityStream.listen((online) {
      if (online && !wasOnline) {
        Future.delayed(const Duration(seconds: 2), onBack);
      }
      wasOnline = online;
    });
  }

  Stream<bool> get connectivityStream {
    return _connectivity.onConnectivityChanged.map(
      (result) => result != ConnectivityResult.none || _isLocalHost(),
    );
  }
}