import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appmobilegmao/widgets/notification_bar.dart';

void main() {
  group('NotificationBar Tests', () {
    testWidgets('renders correctly with default values', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationBar(
              title: 'Notification Title',
              message: 'This is a notification message.',
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      // Vérifier que le titre et le message sont affichés
      expect(find.text('Notification Title'), findsOneWidget);
      expect(find.text('This is a notification message.'), findsOneWidget);

      // Vérifier que l'icône par défaut (info) est affichée
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('renders success notification correctly', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationBar.success(
              title: 'Success',
              message: 'Operation completed successfully.',
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Success'), findsOneWidget);
      expect(find.text('Operation completed successfully.'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('renders error notification correctly', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationBar.error(
              title: 'Error',
              message: 'An error occurred.',
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Error'), findsOneWidget);
      expect(find.text('An error occurred.'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('renders warning notification correctly', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationBar.warning(
              title: 'Warning',
              message: 'This is a warning.',
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Warning'), findsOneWidget);
      expect(find.text('This is a warning.'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
    });

    testWidgets('renders info notification correctly', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationBar.info(
              title: 'Info',
              message: 'This is an informational message.',
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Info'), findsOneWidget);
      expect(find.text('This is an informational message.'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      bool wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationBar(
              title: 'Notification Title',
              message: 'This is a notification message.',
              onTap: () {
                wasTapped = true;
              },
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      // Chercher le GestureDetector et taper dessus
      final gestureDetector = find.byType(GestureDetector);
      expect(gestureDetector, findsWidgets);

      await tester.tap(gestureDetector.first, warnIfMissed: false);
      await tester.pump();

      // Vérifier que la fonction onTap a été appelée
      expect(wasTapped, true);
    });

    testWidgets('calls onClose when close button is tapped', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      bool wasClosed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationBar(
              title: 'Notification Title',
              message: 'This is a notification message.',
              onClose: () {
                wasClosed = true;
              },
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      // Appuyer sur le bouton de fermeture
      await tester.tap(find.byIcon(Icons.close), warnIfMissed: false);
      await tester.pump();

      // Vérifier que la fonction onClose a été appelée
      expect(wasClosed, true);
    });

    testWidgets('renders action button and calls onActionPressed', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      bool actionPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationBar(
              title: 'Notification Title',
              message: 'This is a notification message.',
              showAction: true,
              actionText: 'Retry',
              onActionPressed: () {
                actionPressed = true;
              },
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      // Vérifier que le bouton d'action est affiché
      expect(find.text('Retry'), findsOneWidget);

      // Appuyer sur le bouton d'action
      await tester.tap(find.text('Retry'), warnIfMissed: false);
      await tester.pump();

      // Vérifier que la fonction onActionPressed a été appelée
      expect(actionPressed, true);
    });

    testWidgets('renders progress bar when showProgressBar is true', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationBar(
              title: 'Notification Title',
              message: 'This is a notification message.',
              showProgressBar: true,
            ),
          ),
        ),
      );

      // Utiliser pump() au lieu de pumpAndSettle() pour éviter le timeout
      await tester.pump(const Duration(milliseconds: 500));

      // Vérifier que la barre de progression est affichée
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // Vérifier les propriétés du LinearProgressIndicator
      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );

      // Vérifier que c'est bien un indicateur indéterminé (value == null)
      expect(progressIndicator.value, isNull);
      expect(progressIndicator.backgroundColor, isNotNull);
    });
  });
}
