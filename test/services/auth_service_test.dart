import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:appmobilegmao/services/auth_service.dart';
import 'package:appmobilegmao/services/api_service.dart';

// Générer les mocks automatiquement
@GenerateMocks([ApiService])
import 'auth_service_test.mocks.dart';

void main() {
  group('AuthService Tests', () {
    late AuthService authService;
    late MockApiService mockApiService;

    setUp(() {
      mockApiService = MockApiService();
      authService = AuthService(apiClient: mockApiService); // Injecter le mock
    });

    test('login should succeed with valid credentials', () async {
      // Simuler une réponse réussie
      when(
        mockApiService.post('/auth/login', {
          'username': 'testuser',
          'password': 'password123',
        }),
      ).thenAnswer((_) async => {'token': 'mockToken'});

      await authService.login('testuser', 'password123');

      // Vérifier que la méthode post a été appelée avec les bons paramètres
      verify(
        mockApiService.post('/auth/login', {
          'username': 'testuser',
          'password': 'password123',
        }),
      ).called(1);
    });

    test('login should fail with invalid credentials', () async {
      // Simuler une réponse échouée
      when(
        mockApiService.post('/auth/login', {
          'username': 'wronguser',
          'password': 'wrongpassword',
        }),
      ).thenAnswer((_) async => {});

      await authService.login('wronguser', 'wrongpassword');

      // Vérifier que la méthode post a été appelée avec les mauvais paramètres
      verify(
        mockApiService.post('/auth/login', {
          'username': 'wronguser',
          'password': 'wrongpassword',
        }),
      ).called(1);
    });

    test('logout should succeed', () async {
      // Simuler une réponse réussie
      when(
        mockApiService.post('/auth/logout', {}),
      ).thenAnswer((_) async => {'success': true});

      await authService.logout();

      // Vérifier que la méthode post a été appelée
      verify(mockApiService.post('/auth/logout', {})).called(1);
    });

    test('logout should fail', () async {
      // Simuler une réponse échouée
      when(
        mockApiService.post('/auth/logout', {}),
      ).thenAnswer((_) async => {'success': false});

      await authService.logout();

      // Vérifier que la méthode post a été appelée
      verify(mockApiService.post('/auth/logout', {})).called(1);
    });

    test('updateProfile should succeed', () async {
      // Simuler une réponse réussie
      final profileData = {
        'nom': 'Mamadou Diallo',
        'email': 'mamadou.diallo@senelec.sn',
        'telephone': '+221 77 123 45 67',
      };

      when(
        mockApiService.patch('/auth/profile', profileData),
      ).thenAnswer((_) async => {'success': true});

      await authService.updateProfile(profileData);

      // Vérifier que la méthode patch a été appelée avec les bons paramètres
      verify(mockApiService.patch('/auth/profile', profileData)).called(1);
    });

    test('updateProfile should fail', () async {
      // Simuler une réponse échouée
      final profileData = {
        'nom': 'Mamadou Diallo',
        'email': 'mamadou.diallo@senelec.sn',
        'telephone': '+221 77 123 45 67',
      };

      when(
        mockApiService.patch('/auth/profile', profileData),
      ).thenAnswer((_) async => {'success': false});

      await authService.updateProfile(profileData);

      // Vérifier que la méthode patch a été appelée avec les bons paramètres
      verify(mockApiService.patch('/auth/profile', profileData)).called(1);
    });
  });
}
