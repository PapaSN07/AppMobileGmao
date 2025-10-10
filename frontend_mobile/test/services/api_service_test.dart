import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:appmobilegmao/services/api_service.dart';

class MockHttpClient extends Mock {}

void main() {
  group('ApiService Tests', () {
    late ApiService apiService;

    setUp(() {
      apiService = ApiService();
    });

    test('Base URL should be configured correctly', () {
      expect(apiService.baseUrl, isNotNull);
    });

    test('GET request should return data', () async {
      final response = await apiService.get('/test-endpoint');
      expect(response, isNotNull);
      expect(response, isA<Map<String, dynamic>>());
    });
  });
}
