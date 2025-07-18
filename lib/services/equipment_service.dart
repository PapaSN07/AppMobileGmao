import 'package:appmobilegmao/services/api_service.dart';

class EquipmentService {
  final ApiService _apiService;

  EquipmentService(this._apiService);

  Future<List<dynamic>> getAllEquipments() async {
    return await _apiService.get('/equipments');
  }

  Future<dynamic> getEquipmentById(String id) async {
    return await _apiService.get('/equipments/$id');
  }

  Future<dynamic> createEquipment(Map<String, dynamic> data) async {
    return await _apiService.post('/equipments', data);
  }

  Future<dynamic> updateEquipment(String id, Map<String, dynamic> data) async {
    return await _apiService.put('/equipments/$id', data);
  }
}