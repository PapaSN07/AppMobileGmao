import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appmobilegmao/screens/auth/login_screen.dart';
import 'package:appmobilegmao/widgets/custom_buttons.dart';
import 'package:appmobilegmao/theme/app_theme.dart';

void main() {
  group('LoginScreen Widget Tests', () {
    Widget createTestApp() {
      return MaterialApp(
        home: const LoginScreen(),
        theme: ThemeData(fontFamily: AppTheme.fontMontserrat),
      );
    }

    testWidgets('renders all essential UI components', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Vérifier la présence des composants essentiels
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(Form), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.byType(PrimaryButton), findsOneWidget);

      // Vérifier les textes visibles
      expect(find.text('Nom d\'utilisateur'), findsOneWidget);
      expect(find.text('Mot de passe'), findsOneWidget);
      expect(find.text('Se connecter'), findsOneWidget);
    });

    testWidgets('logo displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Vérifier la présence du logo
      expect(find.byType(Image), findsOneWidget);
      expect(
        find.image(const AssetImage('assets/images/logo.png')),
        findsOneWidget,
      );
    });

    testWidgets('password field shows visibility toggle icon', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Vérifier la présence de l'icône de visibilité
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('password visibility can be toggled', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // État initial
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      expect(find.byIcon(Icons.visibility), findsNothing);

      // Premier toggle
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.visibility), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsNothing);

      // Second toggle
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      expect(find.byIcon(Icons.visibility), findsNothing);
    });

    testWidgets('form validation works for empty fields', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Essayer de soumettre sans remplir
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      // Vérifier les messages d'erreur
      expect(
        find.text('Veuillez entrer votre nom d\'utilisateur'),
        findsOneWidget,
      );
      expect(find.text('Veuillez entrer un mot de passe'), findsOneWidget);
    });

    testWidgets('partial form validation works', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Remplir seulement le username
      await tester.enterText(find.byType(TextFormField).first, 'testuser');
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      // Seulement l'erreur de password devrait être visible
      expect(
        find.text('Veuillez entrer votre nom d\'utilisateur'),
        findsNothing,
      );
      expect(find.text('Veuillez entrer un mot de passe'), findsOneWidget);
    });

    testWidgets('successful form submission triggers loading', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Remplir les deux champs
      await tester.enterText(find.byType(TextFormField).first, 'testuser');
      await tester.enterText(find.byType(TextFormField).last, 'password123');

      // Soumettre
      await tester.tap(find.byType(PrimaryButton));
      await tester.pump();

      // Vérifier que le bouton est en état de chargement
      final buttonWidget = tester.widget<PrimaryButton>(
        find.byType(PrimaryButton),
      );
      expect(buttonWidget.isLoading, isTrue);

      // Pas de messages d'erreur
      expect(
        find.text('Veuillez entrer votre nom d\'utilisateur'),
        findsNothing,
      );
      expect(find.text('Veuillez entrer un mot de passe'), findsNothing);

      // Attendre la fin du processus
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Vérifier que le chargement est terminé
      final updatedButtonWidget = tester.widget<PrimaryButton>(
        find.byType(PrimaryButton),
      );
      expect(updatedButtonWidget.isLoading, isFalse);
    });

    testWidgets('text input works in both fields', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      const username = 'mon_utilisateur';
      const password = 'mon_password';

      // Saisir dans les champs
      await tester.enterText(find.byType(TextFormField).first, username);
      await tester.enterText(find.byType(TextFormField).last, password);

      // Vérifier que le texte est visible
      expect(find.text(username), findsOneWidget);
      expect(find.text(password), findsOneWidget);
    });

    testWidgets('button properties are correct', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final buttonWidget = tester.widget<PrimaryButton>(
        find.byType(PrimaryButton),
      );

      expect(buttonWidget.text, equals('Se connecter'));
      expect(buttonWidget.width, equals(double.infinity));
      expect(buttonWidget.height, equals(54));
      expect(buttonWidget.fontSize, equals(16));
      expect(buttonWidget.isLoading, isFalse);
      expect(buttonWidget.onPressed, isNotNull);
    });

    testWidgets('form state persists during password toggle', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      const username = 'testuser';
      const password = 'testpass';

      // Remplir les champs
      await tester.enterText(find.byType(TextFormField).first, username);
      await tester.enterText(find.byType(TextFormField).last, password);

      // Toggle password visibility
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pumpAndSettle();

      // Vérifier que les valeurs sont préservées
      expect(find.text(username), findsOneWidget);
      expect(find.text(password), findsOneWidget);

      // Toggle back
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pumpAndSettle();

      // Vérifier encore
      expect(find.text(username), findsOneWidget);
      expect(find.text(password), findsOneWidget);
    });

    testWidgets('validation messages disappear with valid input', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Déclencher les erreurs
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();
      expect(
        find.text('Veuillez entrer votre nom d\'utilisateur'),
        findsOneWidget,
      );
      expect(find.text('Veuillez entrer un mot de passe'), findsOneWidget);

      // Corriger en remplissant les champs
      await tester.enterText(find.byType(TextFormField).first, 'user');
      await tester.enterText(find.byType(TextFormField).last, 'pass');
      await tester.tap(find.byType(PrimaryButton));
      await tester.pump();

      // Les erreurs devraient disparaître
      expect(
        find.text('Veuillez entrer votre nom d\'utilisateur'),
        findsNothing,
      );
      expect(find.text('Veuillez entrer un mot de passe'), findsNothing);

      // Attendre la fin de tous les processus async
      await tester.pumpAndSettle(const Duration(seconds: 3));
    });

    testWidgets('complete workflow integration', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // 1. État initial
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);

      // 2. Validation des champs vides
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();
      expect(
        find.text('Veuillez entrer votre nom d\'utilisateur'),
        findsOneWidget,
      );
      expect(find.text('Veuillez entrer un mot de passe'), findsOneWidget);

      // 3. Remplissage progressif
      await tester.enterText(find.byType(TextFormField).first, 'admin');
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();
      expect(
        find.text('Veuillez entrer votre nom d\'utilisateur'),
        findsNothing,
      );
      expect(find.text('Veuillez entrer un mot de passe'), findsOneWidget);

      // 4. Complétion et toggle password
      await tester.enterText(find.byType(TextFormField).last, 'admin123');
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.visibility), findsOneWidget);

      // 5. Soumission finale
      await tester.tap(find.byType(PrimaryButton));
      await tester.pump();

      final buttonWidget = tester.widget<PrimaryButton>(
        find.byType(PrimaryButton),
      );
      expect(buttonWidget.isLoading, isTrue);
      expect(
        find.text('Veuillez entrer votre nom d\'utilisateur'),
        findsNothing,
      );
      expect(find.text('Veuillez entrer un mot de passe'), findsNothing);

      // Attendre la fin de tous les processus
      await tester.pumpAndSettle(const Duration(seconds: 3));
    });

    testWidgets('handles special characters and long text', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      const specialUsername = 'user@domain.com';
      const specialPassword = 'P@ssw0rd!';
      final longText = 'a' * 50;

      // Test caractères spéciaux
      await tester.enterText(find.byType(TextFormField).first, specialUsername);
      await tester.enterText(find.byType(TextFormField).last, specialPassword);
      await tester.tap(find.byType(PrimaryButton));
      await tester.pump();

      var buttonWidget = tester.widget<PrimaryButton>(
        find.byType(PrimaryButton),
      );
      expect(buttonWidget.isLoading, isTrue);

      // Attendre la fin du premier processus
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Test texte long
      await tester.enterText(find.byType(TextFormField).first, longText);
      await tester.enterText(find.byType(TextFormField).last, longText);
      await tester.tap(find.byType(PrimaryButton));
      await tester.pump();

      buttonWidget = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
      expect(buttonWidget.isLoading, isTrue);

      // Attendre la fin du second processus
      await tester.pumpAndSettle(const Duration(seconds: 3));
    });
  });

  group('LoginScreen Edge Cases', () {
    Widget createTestApp() {
      return MaterialApp(home: const LoginScreen());
    }

    testWidgets('handles screen size constraints', (WidgetTester tester) async {
      // Tester avec une taille d'écran plus petite
      await tester.binding.setSurfaceSize(const Size(350, 600));

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Vérifier que tous les composants sont toujours présents
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.byType(PrimaryButton), findsOneWidget);

      // Tester la fonctionnalité avec cette taille d'écran
      await tester.enterText(find.byType(TextFormField).first, 'test');
      await tester.enterText(find.byType(TextFormField).last, 'pass');

      // Le bouton devrait fonctionner même avec l'écran plus petit
      await tester.tap(find.byType(PrimaryButton));
      await tester.pump();

      final buttonWidget = tester.widget<PrimaryButton>(
        find.byType(PrimaryButton),
      );
      expect(buttonWidget.isLoading, isTrue);

      // Attendre la fin du processus
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Remettre la taille normale
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('handles very small screen size gracefully', (
      WidgetTester tester,
    ) async {
      // Tester avec une taille d'écran vraiment petite
      await tester.binding.setSurfaceSize(const Size(280, 480));

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Vérifier que les composants essentiels sont présents
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.byType(PrimaryButton), findsOneWidget);

      // Remettre la taille normale
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('handles landscape orientation', (WidgetTester tester) async {
      // Utiliser une taille paysage plus haute pour que le bouton soit visible
      await tester.binding.setSurfaceSize(const Size(600, 500));

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Vérifier que tous les composants sont présents en paysage
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.byType(PrimaryButton), findsOneWidget);

      // Tester la fonctionnalité en paysage
      await tester.enterText(find.byType(TextFormField).first, 'test');
      await tester.enterText(find.byType(TextFormField).last, 'pass');

      // Utiliser scrolling pour s'assurer que le bouton est visible
      await tester.ensureVisible(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PrimaryButton));
      await tester.pump();

      final buttonWidget = tester.widget<PrimaryButton>(
        find.byType(PrimaryButton),
      );
      expect(buttonWidget.isLoading, isTrue);

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Remettre la taille normale
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('handles multiple rapid button taps', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Remplir les champs
      await tester.enterText(find.byType(TextFormField).first, 'user');
      await tester.enterText(find.byType(TextFormField).last, 'pass');

      // S'assurer que le bouton est visible
      await tester.ensureVisible(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      // Tapper rapidement plusieurs fois
      await tester.tap(find.byType(PrimaryButton));
      await tester.pump();

      // Le bouton devrait être en loading
      var buttonWidget = tester.widget<PrimaryButton>(
        find.byType(PrimaryButton),
      );
      expect(buttonWidget.isLoading, isTrue);

      // Essayer de tapper à nouveau (devrait être ignoré car disabled)
      await tester.tap(find.byType(PrimaryButton), warnIfMissed: false);
      await tester.pump();

      // Devrait toujours être en loading (pas de double soumission)
      buttonWidget = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
      expect(buttonWidget.isLoading, isTrue);

      // Attendre la fin
      await tester.pumpAndSettle(const Duration(seconds: 3));
    });

    testWidgets('button text truncates properly on small screens', (
      WidgetTester tester,
    ) async {
      // Tester avec une taille très petite pour forcer la troncature
      await tester.binding.setSurfaceSize(const Size(200, 400));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 150, // Largeur très petite
                child: const PrimaryButton(
                  text: 'Texte très long qui devrait être tronqué',
                  height: 40,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Le bouton devrait être présent sans erreur de débordement
      expect(find.byType(PrimaryButton), findsOneWidget);

      // Remettre la taille normale
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('button with icon handles small screens', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(300, 500));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                child: const PrimaryButton(
                  text: 'Modifier',
                  icon: Icons.edit,
                  height: 40,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Le bouton avec icône devrait être présent sans erreur
      expect(find.byType(PrimaryButton), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);

      // Remettre la taille normale
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('responsive layout works correctly', (
      WidgetTester tester,
    ) async {
      // Test avec différentes tailles d'écran
      final testSizes = [
        const Size(320, 568), // iPhone SE
        const Size(375, 667), // iPhone 8
        const Size(414, 896), // iPhone 11 Pro Max
        const Size(768, 1024), // iPad
      ];

      for (final size in testSizes) {
        await tester.binding.setSurfaceSize(size);

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Vérifier que tous les composants sont présents
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.byType(TextFormField), findsNWidgets(2));
        expect(find.byType(PrimaryButton), findsOneWidget);

        // Tester une interaction basique
        await tester.enterText(find.byType(TextFormField).first, 'test');
        expect(find.text('test'), findsOneWidget);
      }

      // Remettre la taille normale
      await tester.binding.setSurfaceSize(null);
    });
  });
}
