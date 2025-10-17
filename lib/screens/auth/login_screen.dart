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
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: spacing.custom(all: 24), // ✅ Padding responsive
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: spacing.xxlarge), // ✅ Espacement responsive
                // Logo et titre
                Container(
                  padding: spacing.custom(all: 10), // ✅ Padding responsive
                  child: Column(
                    children: [
                      SizedBox(
                        width: responsive.spacing(200), // ✅ Largeur responsive
                        height: responsive.spacing(200), // ✅ Hauteur responsive
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(
                        height: spacing.large,
                      ), // ✅ Espacement responsive
                      Text(
                        'GMAO Mobile',
                        style: TextStyle(
                          fontSize: responsive.sp(18), // ✅ Texte responsive
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondaryColor,
                          fontFamily: AppTheme.fontMontserrat,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: spacing.xlarge), // ✅ Espacement responsive
                // Formulaire de connexion
                Container(
                  padding: spacing.custom(
                    left: 16,
                    right: 16,
                    top: 10,
                    bottom: 10,
                  ), // ✅ Padding responsive
                  child: Column(
                    children: [
                      // Message d'erreur
                      if (_errorMessage != null)
                        Container(
                          width: double.infinity,
                          padding: spacing.custom(
                            all: 16,
                          ), // ✅ Padding responsive
                          margin: spacing.custom(
                            bottom: 20,
                          ), // ✅ Margin responsive
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(
                              responsive.spacing(12),
                            ), // ✅ Border radius responsive
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red.shade700,
                              ),
                              SizedBox(
                                width: spacing.medium,
                              ), // ✅ Espacement responsive
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Champ nom d'utilisateur
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Nom d\'utilisateur',
                          prefixIcon: Icon(
                            Icons.person,
                            color: AppTheme.secondaryColor,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              responsive.spacing(12),
                            ), // ✅ Border radius responsive
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              responsive.spacing(12),
                            ), // ✅ Border radius responsive
                            borderSide: BorderSide(
                              color: AppTheme.secondaryColor,
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              responsive.spacing(12),
                            ), // ✅ Border radius responsive
                            borderSide: BorderSide(
                              color: AppTheme.thirdColor,
                              width: 1,
                            ),
                          ),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Veuillez entrer votre nom d\'utilisateur';
                          }
                          if (value!.length < 3) {
                            return 'Le nom d\'utilisateur doit contenir au moins 3 caractères';
                          }
                          return null;
                        },
                      ),

                      SizedBox(
                        height: spacing.medium,
                      ), // ✅ Espacement responsive
                      // Champ mot de passe
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Mot de passe',
                          prefixIcon: Icon(
                            Icons.lock,
                            color: AppTheme.secondaryColor,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: AppTheme.secondaryColor,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              responsive.spacing(12),
                            ), // ✅ Border radius responsive
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              responsive.spacing(12),
                            ), // ✅ Border radius responsive
                            borderSide: BorderSide(
                              color: AppTheme.secondaryColor,
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              responsive.spacing(12),
                            ), // ✅ Border radius responsive
                            borderSide: BorderSide(
                              color: AppTheme.thirdColor,
                              width: 1,
                            ),
                          ),
                        ),
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleLogin(),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Veuillez entrer votre mot de passe';
                          }
                          if (value!.length < 4) {
                            return 'Le mot de passe doit contenir au moins 4 caractères';
                          }
                          return null;
                        },
                      ),

                      SizedBox(
                        height: spacing.xlarge,
                      ), // ✅ Espacement responsive
                      // Bouton de connexion
                      PrimaryButton(
                        text: 'Se connecter',
                        width: double.infinity,
                        height: responsive.spacing(56), // ✅ Hauteur responsive
                        isLoading: _isLoading,
                        onPressed: _handleLogin,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: spacing.xlarge), // ✅ Espacement responsive
                // Informations de support
                Text(
                  'En cas de problème, contactez le support IT SENELEC',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: responsive.sp(14), // ✅ Texte responsive
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
