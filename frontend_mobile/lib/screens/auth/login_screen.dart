import 'dart:io';

import 'package:appmobilegmao/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/widgets/custom_buttons.dart';
import 'package:appmobilegmao/screens/main_screen.dart';
import 'package:provider/provider.dart';
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

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
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await authProvider.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      if (result) {
        if (mounted) {
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
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 300),
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Nom d\'utilisateur ou mot de passe incorrect';
        });
      }
    } on SocketException catch (_) {
      setState(() {
        _errorMessage =
            'Connexion impossible au serveur. Vérifiez votre connexion internet ou que le serveur est démarré.';
      });
    } on Exception catch (e) {
      setState(() {
        _errorMessage = 'Erreur inattendue : ${e.toString()}';
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
    final responsive = context.responsive;
    final spacing = context.spacing;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: spacing.custom(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: spacing.xxlarge),
                // 🏷️ Logo et Titre Corporate
                Container(
                  padding: spacing.custom(all: 10),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: SizedBox(
                          width: responsive.spacing(120),
                          height: responsive.spacing(120),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      SizedBox(height: spacing.large),
                      Text(
                        'GMAO Mobile',
                        style: TextStyle(
                          fontSize: responsive.sp(22),
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF2B1D4C),
                          fontFamily: AppTheme.fontMontserrat,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Senelec • Portail de Maintenance',
                        style: TextStyle(
                          fontSize: responsive.sp(13),
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                          fontFamily: AppTheme.fontRoboto,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: spacing.xlarge),

                // 📝 Formulaire de Connexion sur Carte Blanche Élevée
                Container(
                  padding: spacing.custom(horizontal: 20, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(responsive.spacing(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      // Message d'erreur
                      if (_errorMessage != null)
                        Container(
                          width: double.infinity,
                          padding: spacing.custom(all: 14),
                          margin: spacing.custom(bottom: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(responsive.spacing(12)),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Color(0xFFDC2626)),
                              SizedBox(width: spacing.medium),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Color(0xFFDC2626),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Champ nom d'utilisateur
                      TextFormField(
                        controller: _usernameController,
                        style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          labelText: 'Nom d\'utilisateur',
                          labelStyle: const TextStyle(color: Color(0xFF64748B)),
                          prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF0F1B80)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(responsive.spacing(14)),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(responsive.spacing(14)),
                            borderSide: const BorderSide(color: Color(0xFF0F1B80), width: 2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(responsive.spacing(14)),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Veuillez entrer votre nom d\'utilisateur';
                          }
                          if (value!.length < 3) {
                            return 'Au moins 3 caractères requis';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: spacing.medium),

                      // Champ mot de passe
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          labelText: 'Mot de passe',
                          labelStyle: const TextStyle(color: Color(0xFF64748B)),
                          prefixIcon: const Icon(Icons.lock_outlined, color: Color(0xFF0F1B80)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: const Color(0xFF64748B),
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(responsive.spacing(14)),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(responsive.spacing(14)),
                            borderSide: const BorderSide(color: Color(0xFF0F1B80), width: 2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(responsive.spacing(14)),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleLogin(),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Veuillez entrer votre mot de passe';
                          }
                          if (value!.length < 4) {
                            return 'Au moins 4 caractères requis';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: spacing.xlarge),

                      // Bouton de connexion
                      PrimaryButton(
                        text: 'Se connecter',
                        width: double.infinity,
                        height: responsive.spacing(52),
                        isLoading: _isLoading,
                        onPressed: _handleLogin,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: spacing.xlarge),
                
                // 📞 Support IT
                Text(
                  'En cas de problème, contactez le support IT SENELEC',
                  style: TextStyle(
                    color: const Color(0xFF64748B),
                    fontSize: responsive.sp(12),
                    fontWeight: FontWeight.w500,
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
