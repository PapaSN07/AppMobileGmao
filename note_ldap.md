# Pour implémenter l'authentification LDAP avant la connexion à l'app, voici comment procéder

## 🔧 **1. Ajouter les dépendances LDAP**

Ajoutez dans votre pubspec.yaml :

````yaml
dependencies:
  # ... vos dépendances existantes
  ldap: ^0.3.0
  # ou
  dart_ldap: ^0.0.6
  # Authentification
  shared_preferences: ^2.2.2
````

## 🛠️ **2. Créer le service LDAP**

Créez `lib/services/ldap_service.dart` :

````dart
import 'package:flutter/foundation.dart';
import 'package:ldap/ldap.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LdapService {
  // Configuration LDAP (à adapter selon votre infrastructure)
  static const String ldapHost = 'ldap.senelec.sn'; // Remplacez par votre serveur LDAP
  static const int ldapPort = 389; // ou 636 pour LDAPS
  static const String baseDn = 'dc=senelec,dc=sn'; // Base DN à adapter
  static const String userDnTemplate = 'uid=%s,ou=users,dc=senelec,dc=sn'; // Template DN utilisateur

  late LdapConnection _connection;
  
  /// Initialiser la connexion LDAP
  Future<bool> initConnection() async {
    try {
      _connection = LdapConnection(host: ldapHost, port: ldapPort);
      await _connection.open();
      
      if (kDebugMode) {
        print('✅ LDAP: Connexion établie avec $ldapHost:$ldapPort');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ LDAP: Erreur connexion: $e');
      }
      return false;
    }
  }

  /// Authentifier un utilisateur via LDAP
  Future<LdapAuthResult> authenticateUser(String username, String password) async {
    try {
      // Initialiser la connexion si nécessaire
      if (!await initConnection()) {
        return LdapAuthResult(
          isAuthenticated: false,
          message: 'Impossible de se connecter au serveur LDAP',
        );
      }

      // Construire le DN de l'utilisateur
      final userDn = userDnTemplate.replaceAll('%s', username);
      
      if (kDebugMode) {
        print('🔍 LDAP: Tentative d\'authentification pour: $userDn');
      }

      // Tentative de bind (authentification)
      final bindResult = await _connection.bind(userDn, password);
      
      if (bindResult.resultCode == 0) {
        // Authentification réussie - récupérer les informations utilisateur
        final userInfo = await _getUserInfo(username);
        
        // Sauvegarder les informations de session
        await _saveUserSession(username, userInfo);
        
        if (kDebugMode) {
          print('✅ LDAP: Authentification réussie pour $username');
        }
        
        return LdapAuthResult(
          isAuthenticated: true,
          message: 'Authentification réussie',
          userInfo: userInfo,
        );
      } else {
        if (kDebugMode) {
          print('❌ LDAP: Échec authentification - Code: ${bindResult.resultCode}');
        }
        
        return LdapAuthResult(
          isAuthenticated: false,
          message: 'Nom d\'utilisateur ou mot de passe incorrect',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ LDAP: Erreur authentification: $e');
      }
      
      return LdapAuthResult(
        isAuthenticated: false,
        message: 'Erreur lors de l\'authentification: ${e.toString()}',
      );
    } finally {
      await _closeConnection();
    }
  }

  /// Récupérer les informations détaillées de l'utilisateur
  Future<LdapUserInfo?> _getUserInfo(String username) async {
    try {
      final filter = Filter.equals('uid', username);
      final searchResult = await _connection.search(
        baseDn,
        filter,
        ['cn', 'mail', 'departmentNumber', 'title', 'telephoneNumber'],
      );

      if (searchResult.isNotEmpty) {
        final entry = searchResult.first;
        return LdapUserInfo(
          username: username,
          fullName: entry.attributes['cn']?.first?.toString() ?? '',
          email: entry.attributes['mail']?.first?.toString() ?? '',
          department: entry.attributes['departmentNumber']?.first?.toString() ?? '',
          title: entry.attributes['title']?.first?.toString() ?? '',
          phone: entry.attributes['telephoneNumber']?.first?.toString() ?? '',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ LDAP: Erreur récupération info utilisateur: $e');
      }
    }
    
    return null;
  }

  /// Sauvegarder la session utilisateur
  Future<void> _saveUserSession(String username, LdapUserInfo? userInfo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user', username);
    await prefs.setBool('is_authenticated', true);
    await prefs.setInt('auth_timestamp', DateTime.now().millisecondsSinceEpoch);
    
    if (userInfo != null) {
      await prefs.setString('user_full_name', userInfo.fullName);
      await prefs.setString('user_email', userInfo.email);
      await prefs.setString('user_department', userInfo.department);
      await prefs.setString('user_title', userInfo.title);
      await prefs.setString('user_phone', userInfo.phone);
    }
  }

  /// Vérifier si l'utilisateur est toujours authentifié
  Future<bool> isUserAuthenticated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isAuth = prefs.getBool('is_authenticated') ?? false;
      final timestamp = prefs.getInt('auth_timestamp') ?? 0;
      
      // Vérifier si la session n'est pas expirée (ex: 8 heures)
      final sessionDuration = DateTime.now().millisecondsSinceEpoch - timestamp;
      final maxSessionDuration = 8 * 60 * 60 * 1000; // 8 heures en ms
      
      if (isAuth && sessionDuration < maxSessionDuration) {
        return true;
      } else {
        // Session expirée, nettoyer
        await logout();
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ LDAP: Erreur vérification session: $e');
      }
      return false;
    }
  }

  /// Récupérer les informations de l'utilisateur connecté
  Future<LdapUserInfo?> getCurrentUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('current_user');
      
      if (username != null) {
        return LdapUserInfo(
          username: username,
          fullName: prefs.getString('user_full_name') ?? '',
          email: prefs.getString('user_email') ?? '',
          department: prefs.getString('user_department') ?? '',
          title: prefs.getString('user_title') ?? '',
          phone: prefs.getString('user_phone') ?? '',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ LDAP: Erreur récupération info utilisateur: $e');
      }
    }
    
    return null;
  }

  /// Déconnexion
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      if (kDebugMode) {
        print('✅ LDAP: Déconnexion effectuée');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ LDAP: Erreur déconnexion: $e');
      }
    }
  }

  /// Fermer la connexion LDAP
  Future<void> _closeConnection() async {
    try {
      await _connection.close();
    } catch (e) {
      if (kDebugMode) {
        print('❌ LDAP: Erreur fermeture connexion: $e');
      }
    }
  }
}

/// Résultat de l'authentification LDAP
class LdapAuthResult {
  final bool isAuthenticated;
  final String message;
  final LdapUserInfo? userInfo;

  LdapAuthResult({
    required this.isAuthenticated,
    required this.message,
    this.userInfo,
  });
}

/// Informations utilisateur LDAP
class LdapUserInfo {
  final String username;
  final String fullName;
  final String email;
  final String department;
  final String title;
  final String phone;

  LdapUserInfo({
    required this.username,
    required this.fullName,
    required this.email,
    required this.department,
    required this.title,
    required this.phone,
  });

  Map<String, dynamic> toJson() => {
    'username': username,
    'fullName': fullName,
    'email': email,
    'department': department,
    'title': title,
    'phone': phone,
  };

  factory LdapUserInfo.fromJson(Map<String, dynamic> json) => LdapUserInfo(
    username: json['username'] ?? '',
    fullName: json['fullName'] ?? '',
    email: json['email'] ?? '',
    department: json['department'] ?? '',
    title: json['title'] ?? '',
    phone: json['phone'] ?? '',
  );
}
````

## 🎯 **3. Créer l'écran de connexion**

Créez login_screen.dart :

````dart
import 'package:flutter/material.dart';
import 'package:appmobilegmao/services/ldap_service.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/screens/equipments/equipment_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ldapService = LdapService();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _ldapService.authenticateUser(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      if (result.isAuthenticated) {
        // Authentification réussie - naviguer vers l'écran principal
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const EquipmentScreen()),
          );
        }
      } else {
        // Échec de l'authentification
        setState(() {
          _errorMessage = result.message;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de connexion: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                
                // Logo ou titre
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.boxShadowColor,
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.business,
                        size: 60,
                        color: AppTheme.secondaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'SENELEC',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondaryColor,
                          fontFamily: AppTheme.fontMontserrat,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'GMAO Mobile',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.thirdColor,
                          fontFamily: AppTheme.fontRoboto,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Formulaire de connexion
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.boxShadowColor,
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Connexion',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondaryColor,
                          fontFamily: AppTheme.fontMontserrat,
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Champ nom d'utilisateur
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Nom d\'utilisateur',
                          prefixIcon: Icon(Icons.person, color: AppTheme.secondaryColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.secondaryColor, width: 2),
                          ),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Veuillez entrer votre nom d\'utilisateur';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Champ mot de passe
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Mot de passe',
                          prefixIcon: Icon(Icons.lock, color: AppTheme.secondaryColor),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                              color: AppTheme.secondaryColor,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.secondaryColor, width: 2),
                          ),
                        ),
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleLogin(),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Veuillez entrer votre mot de passe';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Message d'erreur
                      if (_errorMessage != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(color: Colors.red.shade700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Bouton de connexion
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.secondaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Se connecter',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Informations de contact support
                Text(
                  'En cas de problème, contactez le support IT',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontFamily: AppTheme.fontRoboto,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
````

## 🔐 **4. Créer un middleware d'authentification**

Créez `lib/services/auth_middleware.dart` :

````dart
import 'package:flutter/material.dart';
import 'package:appmobilegmao/services/ldap_service.dart';
import 'package:appmobilegmao/screens/auth/login_screen.dart';

class AuthMiddleware extends StatelessWidget {
  final Widget child;
  
  const AuthMiddleware({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: LdapService().isUserAuthenticated(),
      builder: (context, snapshot) {
        // En cours de vérification
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // Utilisateur authentifié
        if (snapshot.data == true) {
          return child;
        }
        
        // Utilisateur non authentifié
        return const LoginScreen();
      },
    );
  }
}
````

## 🚀 **5. Modifier le `main.dart`**

````dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:appmobilegmao/provider/equipment_provider.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/services/hive_service.dart';
import 'package:appmobilegmao/models/equipment_hive.dart';
import 'package:appmobilegmao/services/auth_middleware.dart';
import 'package:appmobilegmao/screens/equipments/equipment_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Hive
  await Hive.initFlutter();

  // Enregistrer les adaptateurs Hive
  Hive.registerAdapter(EquipmentHiveAdapter());
  Hive.registerAdapter(AttributeValueHiveAdapter());
  Hive.registerAdapter(ReferenceDataHiveAdapter());

  // Initialiser le service Hive
  await HiveService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => EquipmentProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SENELEC GMAO',
      theme: AppTheme.lightTheme,
      home: const AuthMiddleware(
        child: EquipmentScreen(), // ✅ L'écran principal après authentification
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
````

## 🎯 **6. Configuration LDAP**

Adaptez les constantes dans `LdapService` selon votre infrastructure SENELEC :

````dart
// Configuration à adapter selon votre LDAP SENELEC
static const String ldapHost = 'ldap.senelec.sn'; // Votre serveur LDAP
static const int ldapPort = 389; // 636 pour LDAPS
static const String baseDn = 'dc=senelec,dc=sn'; // Base DN
static const String userDnTemplate = 'uid=%s,ou=employees,dc=senelec,dc=sn';
````

## 🔒 **Fonctionnalités implémentées**

✅ **Authentification LDAP** contre l'Active Directory SENELEC  
✅ **Session persistante** avec expiration automatique  
✅ **Gestion des erreurs** d'authentification  
✅ **Interface utilisateur** moderne et responsive  
✅ **Sécurité** - mots de passe non stockés localement  
✅ **Auto-logout** après expiration de session  
✅ **Récupération infos utilisateur** depuis LDAP  

L'app vérifiera maintenant l'authentification LDAP à chaque démarrage et redirigera vers l'écran de connexion si nécessaire ! 🚀

Code similaire trouvé avec 1 type de licence
