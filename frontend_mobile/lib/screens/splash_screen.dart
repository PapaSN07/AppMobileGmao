import 'package:flutter/material.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/services/auth_service.dart';
import 'package:appmobilegmao/screens/auth/login_screen.dart';
import 'package:appmobilegmao/screens/main_screen.dart';
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Configuration des animations
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    // Démarrer l'animation et la logique de navigation
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Démarrer l'animation
    _animationController.forward();

    // Attendre un minimum de 3 secondes pour l'expérience utilisateur
    await Future.delayed(const Duration(seconds: 3));

    // Vérifier l'authentification
    await _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    try {
      final authService = AuthService();
      final isLoggedIn = authService.isLoggedIn();

      if (mounted) {
        if (isLoggedIn) {
          // Naviguer vers l'écran principal
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder:
                  (context, animation, secondaryAnimation) =>
                      const MainScreen(),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        } else {
          // Naviguer vers l'écran de connexion
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder:
                  (context, animation, secondaryAnimation) =>
                      const LoginScreen(),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        }
      }
    } catch (e) {
      // En cas d'erreur, aller vers la page de connexion
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo animé
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: responsive.spacing(150), // ✅ Largeur responsive
                        height: responsive.spacing(150), // ✅ Hauteur responsive
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            responsive.spacing(25),
                          ), // ✅ Border radius responsive
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromRGBO(0, 0, 0, 0.2),
                              blurRadius: responsive.spacing(
                                20,
                              ), // ✅ Blur radius responsive
                              offset: Offset(
                                0,
                                responsive.spacing(10),
                              ), // ✅ Offset responsive
                            ),
                          ],
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              SizedBox(height: spacing.xlarge), // ✅ Espacement responsive
              // Sous-titre
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      'GMAO Mobile',
                      style: TextStyle(
                        fontSize: responsive.sp(20), // ✅ Texte responsive
                        color: const Color.fromRGBO(255, 255, 255, 0.9),
                        fontFamily: AppTheme.fontRoboto,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  );
                },
              ),

              SizedBox(height: spacing.xxlarge), // ✅ Espacement responsive
              // Indicateur de chargement animé
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SizedBox(
                      width: responsive.spacing(40), // ✅ Largeur responsive
                      height: responsive.spacing(40), // ✅ Hauteur responsive
                      child: CircularProgressIndicator(
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                        strokeWidth: responsive.spacing(
                          3,
                        ), // ✅ Épaisseur responsive
                        backgroundColor: const Color.fromRGBO(
                          255,
                          255,
                          255,
                          0.3,
                        ),
                      ),
                    ),
                  );
                },
              ),

              SizedBox(height: spacing.medium), // ✅ Espacement responsive
              // Texte de chargement
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      'Chargement...',
                      style: TextStyle(
                        color: const Color.fromRGBO(255, 255, 255, 0.8),
                        fontSize: responsive.sp(16), // ✅ Texte responsive
                        fontFamily: AppTheme.fontRoboto,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
