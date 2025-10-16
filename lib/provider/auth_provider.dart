import 'package:appmobilegmao/models/user.dart';
import 'package:appmobilegmao/services/auth_service.dart';
import 'package:appmobilegmao/services/hive_service.dart';
import 'package:flutter/foundation.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
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
    final result = await _authService.login(username, password);

    if (result['success']) {
      // Créer un objet User
      final user = result['data'];

      // Sauvegarder l'utilisateur dans Hive
      await HiveService.cacheCurrentUser(user);

      // Mettre à jour l'état local
      _currentUser = user;
      notifyListeners();

      return true;
    } else {
      return false;
    }
  }

  /// Déconnexion utilisateur
  Future<void> logout() async {
    try {
      _currentUser = null;
      await HiveService.clearCurrentUser();
      notifyListeners();

      if (kDebugMode) {
        print('✅ AuthProvider.logout()');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ AuthProvider.logout() error: $e');
      }
    }
  }

  /// Vérifier si un utilisateur est connecté
  bool isLoggedIn() {
    return _currentUser != null;
  }
}
