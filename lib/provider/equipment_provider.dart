import 'package:appmobilegmao/services/equipment_service.dart';
import 'package:flutter/foundation.dart';
import 'package:appmobilegmao/services/api_service.dart';

class EquipmentProvider extends ChangeNotifier {
  final EquipmentService _equipmentService = EquipmentService(ApiService());

  bool _isLoading = false;
  List<dynamic> _equipments = [];
  List<dynamic> _filteredEquipments = []; // Liste des équipements filtrés
  String _errorMessage = '';

  bool get isLoading => _isLoading;
  List<dynamic> get equipments =>
      _filteredEquipments.isEmpty ? _equipments : _filteredEquipments;
  String get errorMessage => _errorMessage;

  Future<void> fetchEquipments() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _equipmentService.getAllEquipments();
      
      _equipments = response;
      _filteredEquipments = []; // Réinitialiser les filtres
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors du chargement des équipements : $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void filterEquipments(String query) {
    if (query.isEmpty) {
      _filteredEquipments = [];
    } else {
      _filteredEquipments =
          _equipments.where((equipment) {
            return (equipment['code']?.toString().toLowerCase() ?? '').contains(
              query.toLowerCase(),
            ) ||
            (equipment['famille']?.toString().toLowerCase() ?? '').contains(
              query.toLowerCase(),
            ) ||
            (equipment['entity']?.toString().toLowerCase() ?? '').contains(
              query.toLowerCase(),
            ) ||
            (equipment['zone']?.toString().toLowerCase() ?? '').contains(
              query.toLowerCase(),
            ) ||
            (equipment['unite']?.toString().toLowerCase() ?? '').contains(
              query.toLowerCase(),
            );
          }).toList();
    }
    notifyListeners();
  }

  Future<void> addEquipment(Map<String, dynamic> equipment) async {
    try {
      final response = await _equipmentService.createEquipment(equipment);
      _equipments.add(response);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors de l\'ajout de l\'équipement : $e';
      if (kDebugMode) {
        print(_errorMessage);
      }
    }
  }

  Future<void> updateEquipment(
    String id,
    Map<String, dynamic> equipment,
  ) async {
    try {
      final response = await _equipmentService.updateEquipment(id, equipment);
      final index = _equipments.indexWhere((item) => item['id'] == id);
      if (index != -1) {
        _equipments[index] = response;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Erreur lors de la mise à jour de l\'équipement : $e';
      if (kDebugMode) {
        print(_errorMessage);
      }
    }
  }
}
