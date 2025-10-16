import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appmobilegmao/widgets/empty_state.dart';

void main() {
  group('EmptyState Tests', () {
    testWidgets('renders correctly with default values', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: EmptyState())));

      // Vérifier que le titre par défaut est affiché
      expect(find.text('Aucun résultat trouvé'), findsOneWidget);

      // Vérifier que le message par défaut est affiché
      expect(
        find.text('Aucun équipement ne correspond à votre recherche.'),
        findsOneWidget,
      );

      // Vérifier que l'icône par défaut est affichée
      expect(find.byIcon(Icons.search_off), findsOneWidget);

      // Vérifier que le bouton n'est pas affiché par défaut
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('renders correctly with custom values', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              title: 'Erreur de chargement',
              message: 'Impossible de récupérer les données.',
              icon: Icons.error,
            ),
          ),
        ),
      );

      // Vérifier que le titre personnalisé est affiché
      expect(find.text('Erreur de chargement'), findsOneWidget);

      // Vérifier que le message personnalisé est affiché
      expect(find.text('Impossible de récupérer les données.'), findsOneWidget);

      // Vérifier que l'icône personnalisée est affichée
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('renders retry button when onRetry is provided', (
      WidgetTester tester,
    ) async {
      bool wasRetried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              onRetry: () {
                wasRetried = true;
              },
              retryButtonText: 'Réessayer maintenant',
            ),
          ),
        ),
      );

      // Vérifier que le bouton est affiché avec le texte personnalisé
      expect(find.text('Réessayer maintenant'), findsOneWidget);

      // Appuyer sur le bouton
      await tester.tap(find.text('Réessayer maintenant'));
      await tester.pumpAndSettle();

      // Vérifier que la fonction onRetry a été appelée
      expect(wasRetried, true);
    });

    testWidgets('renders animation correctly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: EmptyState())));

      // Vérifier que l'animation est présente
      expect(find.byType(TweenAnimationBuilder<double>), findsOneWidget);
    });
  });
}
