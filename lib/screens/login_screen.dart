import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _screenLogin(context));
  }

  Padding _screenLogin(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 80),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 200,
              height: 200,
              fit: BoxFit.cover,
            ),
            SizedBox(height: 40),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Nom d’utilisateur',
                labelStyle: TextStyle(color: AppTheme.secondaryColor),
                border: UnderlineInputBorder(),
                // Bordure par défaut (quand le champ n'est pas sélectionné)
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color:
                        AppTheme.thirdColor, // Couleur de la bordure inactive
                  ),
                ),
                // Bordure lorsqu'on clique (focus)
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color:
                        AppTheme.secondaryColor, // Couleur de la bordure active
                    width: 2.0, // Épaisseur de la bordure
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer votre nom d’utilisateur';
                }
                return null;
              },
            ),
            SizedBox(height: 20),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                labelStyle: TextStyle(color: AppTheme.secondaryColor),
                border: UnderlineInputBorder(),
                // Bordure par défaut (quand le champ n'est pas sélectionné)
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color:
                        AppTheme.thirdColor, // Couleur de la bordure inactive
                  ),
                ),
                // Bordure lorsqu'on clique (focus)
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color:
                        AppTheme.secondaryColor, // Couleur de la bordure active
                    width: 2.0, // Épaisseur de la bordure
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un mot de passe';
                }
                return null;
              },
            ),
            SizedBox(height: 60),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // Logique de connexion ici
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Connexion réussie')));
                }
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: AppTheme.secondaryColor,
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text('Se connecter'),
            ),
          ],
        ),
      ),
    );
  }
}
