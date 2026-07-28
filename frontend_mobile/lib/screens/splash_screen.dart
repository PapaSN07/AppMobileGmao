import 'package:flutter/material.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/services/auth_service.dart';
import 'package:appmobilegmao/screens/auth/login_screen.dart';
import 'package:appmobilegmao/screens/main_screen.dart';
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';

class SplashScreen extends StatefulWidget {
  // 🔧 Mode test pour sauter l'authentification
  final bool testMode;

  const SplashScreen({super.key, this.testMode = false});

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
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    // Démarrer l'animation et la logique de navigation
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    _animationController.forward();
    await Future.delayed(const Duration(seconds: 5));
    await _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    try {
      if (widget.testMode) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => MainScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 600),
            ),
          );
        }
        return;
      }

      final authService = AuthService();
      final isLoggedIn = authService.isLoggedIn();

      if (mounted) {
        if (isLoggedIn) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => MainScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 600),
            ),
          );
        } else {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 600),
            ),
          );
        }
      }
    } catch (e) {
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
      backgroundColor: AppTheme.senelecIndigo,
      body: Stack(
        children: [
          // 💜 Fond Violet Foncé Senelec avec subtil dégradé
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.senelecIndigo,
                  Color(0xFF160A30), // Indigo encore plus profond pour le bas
                ],
              ),
            ),
          ),

          // 💡 Halo Lumineux subtil d'Arrière-Plan
          Positioned(
            top: -responsive.spacing(50),
            right: -responsive.spacing(50),
            child: Container(
              width: responsive.spacing(280),
              height: responsive.spacing(280),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF0F1B80).withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -responsive.spacing(60),
            left: -responsive.spacing(60),
            child: Container(
              width: responsive.spacing(300),
              height: responsive.spacing(300),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFB800).withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 📱 Contenu Principal Centré
          Center(
            child: Padding(
              padding: spacing.custom(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),

                  // 🛡️ Logo Senelec Animé
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            width: responsive.spacing(180),
                            height: responsive.spacing(180),
                            padding: EdgeInsets.all(responsive.spacing(12)),
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: spacing.medium),

                  // ✨ Titre Institutionnel SENELEC GMAO
                  AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'SENELEC ',
                                  style: TextStyle(
                                    fontSize: responsive.sp(28),
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 2.0,
                                    fontFamily: AppTheme.fontMontserrat,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFFB800), Color(0xFFFF8A00)],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFFB800).withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    'GMAO',
                                    style: TextStyle(
                                      fontSize: responsive.sp(18),
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF2B1D4C),
                                      letterSpacing: 1.5,
                                      fontFamily: AppTheme.fontMontserrat,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: spacing.small),
                            Text(
                              'Gestion de la Maintenance Assistée par Ordinateur',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: responsive.sp(13),
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const Spacer(flex: 2),

                  // ⚡ Barre de Chargement Moderne
                  AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            SizedBox(
                              width: responsive.spacing(150),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  minHeight: 4,
                                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    AppTheme.senelecOrange,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: spacing.small),
                            Text(
                              'Initialisation des modules...',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: responsive.sp(12),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const Spacer(flex: 1),

                  // 🏢 Footer Corporate Senelec
                  AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: spacing.medium),
                          child: Text(
                            '© Senelec • Version 1.0.0',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: responsive.sp(11),
                              letterSpacing: 1.0,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
