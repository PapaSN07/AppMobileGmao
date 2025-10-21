import 'package:appmobilegmao/models/user.dart';
import 'package:appmobilegmao/services/auth_service.dart';
import 'package:appmobilegmao/services/hive_service.dart';
import 'package:appmobilegmao/services/websocket_service.dart';
import 'package:flutter/foundation.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  final WebSocketService _wsService = WebSocketService();
  User? _currentUser;

  AuthProvider({AuthService? authService})
    : _authService = authService ?? AuthService();

  User? get currentUser => _currentUser;

  // ✅ NOUVEAU: Getter pour le rôle
  String? get role => _currentUser?.role ?? _currentUser?.group;

  // ✅ Vérifier si utilisateur est PRESTATAIRE
  bool get isPrestataire => role?.toUpperCase() == 'PRESTATAIRE';

  /// Initialiser le provider et charger l'utilisateur depuis Hive
  Future<void> initialize() async {
    try {
      // Charger depuis cache Hive
      _currentUser = HiveService.getCurrentUser();

      if (kDebugMode) {
        print('✅ AuthProvider.initialize() - User: ${_currentUser?.username}');
        print('   Role: $role | isPrestataire: $isPrestataire');
      }

      notifyListeners(); // ✅ Notifier après chargement
    } catch (e) {
      if (kDebugMode) {
        print('❌ AuthProvider.initialize() error: $e');
      }
      notifyListeners();
    }
  }

  /// Connexion utilisateur
  Future<bool> login(String username, String password) async {
    try {
      final result = await _authService.login(username, password);

      if (result['success'] == true) {
        final userData = result['data'];
        _currentUser = userData;

        await HiveService.cacheCurrentUser(_currentUser!);

        // ✅ NOUVEAU: Se connecter au WebSocket après login réussi
        await _wsService.connect();

        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ AuthProvider: Erreur login: $e');
      }
      return false;
    }
  }

  /// Déconnexion utilisateur
  Future<void> logout() async {
    try {
      if (_currentUser != null) {
        await _authService.logout(_currentUser!.username);
      }

      // ✅ NOUVEAU: Se déconnecter du WebSocket
      await _wsService.disconnect();

      await HiveService.clearAllCache();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ AuthProvider: Erreur logout: $e');
      }
    }
  }

  /// Vérifier si un utilisateur est connecté
  bool isLoggedIn() {
    return _currentUser != null;
  }
}
