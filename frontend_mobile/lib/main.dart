import 'package:appmobilegmao/services/equipment_service.dart';
import 'package:appmobilegmao/services/connectivity_service.dart';
import 'package:appmobilegmao/services/ot_sync_service.dart';
import 'package:appmobilegmao/services/pending_ot_queue.dart';
import 'package:appmobilegmao/services/offline_snapshots.dart';
import 'package:appmobilegmao/screens/auth/login_screen.dart';
import 'package:appmobilegmao/services/pending_equipment_changes.dart';
import 'package:appmobilegmao/provider/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:provider/provider.dart';
import 'package:appmobilegmao/screens/splash_screen.dart';
import 'package:appmobilegmao/provider/auth_provider.dart';
import 'package:appmobilegmao/provider/equipment_provider.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/services/hive_service.dart';
import 'package:appmobilegmao/services/cache_service.dart';
import 'package:appmobilegmao/services/api_service.dart';
import 'package:appmobilegmao/services/ot_service.dart';

// Auth normale: laisser false pour afficher l'écran de connexion quand nécessaire.
// MODIFICATION: Desactivation du mode test pour afficher l'ecran de connexion.
const bool testMode = false; // Mettre à true pour sauter l'authentification (mode test)

// ---------------- MAIN PRINCIPAL ----------------
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser le service Hive (qui gère l'init et les adaptateurs)
  await HiveService.init();
  // Équipements modifiés depuis ce téléphone, encore en attente de validation
  await PendingEquipmentChanges.load();
  await OfflineSnapshots.load();
  await PendingOtQueue.load();

  // Nettoyer les anciens caches de données au démarrage pour forcer 100% de données fraîches en direct
  await HiveService.clearDataCache();
  await CacheService().clearCache();

  _returnToLoginOnSessionExpiry();

  runApp(
    // CORRIGÉ: Injection correcte avec ProxyProvider
    MultiProvider(
      providers: [
        // 1️⃣ AuthProvider en premier (indépendant)
        ChangeNotifierProvider(
          create: (context) => AuthProvider()..initialize(),
        ),

        // 2️⃣ EquipmentProvider qui dépend d'AuthProvider
        ChangeNotifierProxyProvider<AuthProvider, EquipmentProvider>(
          create:
              (context) => EquipmentProvider(
                Provider.of<AuthProvider>(context, listen: false),
              ),
          update: (context, authProvider, previousEquipmentProvider) {
            // ✅ FIX #2 : Mettre à jour si l'utilisateur ou l'entité active change
            if (previousEquipmentProvider == null) {
              return EquipmentProvider(authProvider);
            }
            // Notifier le provider existant du changement d'authProvider
            previousEquipmentProvider.onAuthProviderUpdated(authProvider);
            return previousEquipmentProvider;
          },
        ),

        // 3️⃣ Service OT partagé (injecté dans les écrans, remplaçable dans les tests)
        Provider<OTService>(create: (_) => OTService(ApiService())),

        // Envoi des écritures d'OT faites sans réseau
        Provider<OtSyncService>(
          create: (context) => OtSyncService(
            send: (action) async {
              if (action.kind != PendingOtKind.createEquipment) return context.read<OTService>().replay(action);
              await EquipmentService().postNewEquipment(action.data);
              await PendingEquipmentChanges.markPending(action.otCode);
            },
            currentUsername: () => HiveService.getCurrentUser()?.username,
            hasNetwork: ConnectivityService().isConnected,
          ),
        ),

        // 4️⃣ Provider pour les notifications
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

/// Navigation globale : permet de revenir à la connexion quand la session expire.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void _returnToLoginOnSessionExpiry() {
  ApiService.onSessionExpired = () {
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) return;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
    ScaffoldMessenger.maybeOf(navigator.context)?.showSnackBar(
      const SnackBar(content: Text('Session expirée : veuillez vous reconnecter.')),
    );
  };
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return OverlaySupport.global(
      child: MaterialApp(
        navigatorKey: appNavigatorKey,
        title: 'GMAO - Senelec',
        theme: ThemeData(
          primaryColor: AppTheme.secondaryColor,
          fontFamily: AppTheme.fontRoboto,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppTheme.secondaryColor,
            primary: AppTheme.secondaryColor,
            secondary: AppTheme.thirdColor,
          ),
          useMaterial3: true,
          textTheme: const TextTheme(
            headlineLarge: AppTheme.headline1,
            bodyLarge: AppTheme.bodyText1,
            bodyMedium: AppTheme.bodyText2,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryColor,
              foregroundColor: AppTheme.primaryColor,
              textStyle: const TextStyle(
                fontFamily: AppTheme.fontMontserrat,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        // Commencer par le Splash Screen
        home: SplashScreen(testMode: testMode),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
