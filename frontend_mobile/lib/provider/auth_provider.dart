import 'package:appmobilegmao/models/user.dart';
import 'package:appmobilegmao/services/auth_service.dart';
import 'package:appmobilegmao/services/hive_service.dart';
import 'package:appmobilegmao/services/websocket_service.dart';
import 'package:flutter/foundation.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  final WebSocketService _wsService = WebSocketService();
  User? _currentUser;
  String? _activeEntity;

  AuthProvider({AuthService? authService})
    : _authService = authService ?? AuthService();

  User? get currentUser => _currentUser;

  /// Matricule / Code agent de l'utilisateur connecté (pour Coswin)
  String? get currentMatricule {
    final mat = _currentUser?.matricule;
    if (mat != null && mat.isNotEmpty) return mat;
    return null;
  }

  // ✅ Entité active réactive synchronisée sur toute l'app (Accueil + OT + Équipements)
  String get activeEntity {
    if (_activeEntity != null && _activeEntity!.isNotEmpty) {
      return _activeEntity!;
    }
    return _currentUser?.entity.trim() ?? '';
  }

  void updateActiveEntity(String entity) {
    final cleanEntity = entity.trim().toUpperCase();
    if (cleanEntity.isNotEmpty && cleanEntity != _activeEntity) {
      _activeEntity = cleanEntity;
      if (kDebugMode) {
        print('🔄 AuthProvider: Entité active mise à jour => $cleanEntity');
      }
      notifyListeners();
    }
  }

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

  /// Rester connecté : une session existe sur ce téléphone (profil + jeton de rafraîchissement).
  Future<bool> hasSavedSession() async {
    return HiveService.getCurrentUser() != null && (await HiveService.getRefreshToken()) != null;
  }

  /// Reprend la session enregistrée sans repasser par l'écran de connexion.
  Future<void> resumeSession() async {
    _currentUser = HiveService.getCurrentUser();
    _isOfflineSession = false;
    notifyListeners();
    try {
      await _wsService.connect();
    } catch (_) {
      // Pas de réseau : l'application reste utilisable, les notifications reprendront plus tard
    }
  }

  /// Session ouverte sans réseau (mot de passe vérifié sur le téléphone).
  bool _isOfflineSession = false;
  bool get isOfflineSession => _isOfflineSession;

  /// Message de la dernière tentative de connexion échouée (réseau, identifiants…).
  String? _lastLoginError;
  String? get lastLoginError => _lastLoginError;

  /// Connexion utilisateur
  Future<bool> login(String username, String password) async {
    try {
      final result = await _authService.login(username, password);

      if (result['success'] == true) {
        final userData = result['data'];
        _currentUser = userData;
        _isOfflineSession = result['offline'] == true;
        _lastLoginError = null;

        await HiveService.cacheCurrentUser(_currentUser!);

        // Notifications temps réel seulement si le serveur est joignable
        if (!_isOfflineSession) await _wsService.connect();

        notifyListeners();
        return true;
      }

      _lastLoginError = result['message']?.toString();
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ AuthProvider: Erreur login: $e');
      }
      _lastLoginError = 'Erreur lors de la connexion. Veuillez réessayer.';
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
      _isOfflineSession = false;
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
