import 'package:appmobilegmao/services/hive_service.dart';
import 'package:flutter/foundation.dart';
import 'package:appmobilegmao/models/user.dart';
import 'package:appmobilegmao/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  User? _currentUser;

  AuthProvider({AuthService? authService})
    : _authService = authService ?? AuthService();

  User? get currentUser => _currentUser;

  /// Initialiser le provider et charger l'utilisateur depuis Hive
  Future<void> initialize() async {
    _currentUser = HiveService.getCurrentUser();
    notifyListeners();
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
    final user = _currentUser?.username ?? '';

    await _authService.logout(user);

    // Supprimer l'utilisateur de Hive
    await HiveService.clearAllCache();

    // Réinitialiser l'état local
    _currentUser = null;
    notifyListeners();
  }

  /// Vérifier si un utilisateur est connecté
  bool isLoggedIn() {
    return _currentUser != null;
  }
}
