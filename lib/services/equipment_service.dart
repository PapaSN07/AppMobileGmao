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

  // Utiliser PATCH au lieu de PUT pour la modification
  Future<dynamic> updateEquipment(String id, Map<String, dynamic> data) async {
    // Filtrer les valeurs nulles pour ne pas les envoyer
    final filteredData = Map<String, dynamic>.from(data);
    filteredData.removeWhere((key, value) => value == null || value == '');

    return await _apiService.patch('/equipments/$id', filteredData);
  }

  Future<void> deleteEquipment(String id) async {
    return await _apiService.delete('/equipments/$id');
  }
}
