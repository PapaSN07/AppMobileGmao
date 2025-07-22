import 'package:appmobilegmao/services/equipment_service.dart';
import 'package:flutter/foundation.dart';
import 'package:appmobilegmao/services/api_service.dart';

class EquipmentProvider extends ChangeNotifier {
  final EquipmentService _equipmentService = EquipmentService(ApiService());

  bool _isLoading = false;
  List<dynamic> _equipments = [];
  List<dynamic> _filteredEquipments = [];
  String _errorMessage = '';
  String _currentSearchQuery = '';

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get currentSearchQuery => _currentSearchQuery;

  // Corriger le getter pour gérer correctement les données
  List<dynamic> get equipments =>
      _currentSearchQuery.isEmpty ? _equipments : _filteredEquipments;

  Future<void> fetchEquipments() async {
    _isLoading = true;
    _currentSearchQuery = '';
    _filteredEquipments = [];
    notifyListeners();

    try {
      final response = await _equipmentService.getAllEquipments();
      _equipments = response;

      if (kDebugMode) {
        print('✅ ${_equipments.length} équipements chargés');
      }
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des équipements : $e';
      if (kDebugMode) {
        print('❌ $_errorMessage');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void filterEquipments(String query) {
    _currentSearchQuery = query;

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

      if (kDebugMode) {
        print('🔍 Recherche "$query": ${_filteredEquipments.length} résultats');
      }
    }
    notifyListeners();
  }

  Future<void> addEquipment(Map<String, dynamic> equipment) async {
    try {
      final response = await _equipmentService.createEquipment(equipment);
      _equipments.add(response);

      // Réappliquer le filtre si une recherche est active
      if (_currentSearchQuery.isNotEmpty) {
        filterEquipments(_currentSearchQuery);
      } else {
        notifyListeners();
      }

      if (kDebugMode) {
        print('✅ Équipement ajouté avec succès');
      }
    } catch (e) {
      _errorMessage = 'Erreur lors de l\'ajout de l\'équipement : $e';
      if (kDebugMode) {
        print('❌ $_errorMessage');
      }
    }
  }

  Future<void> updateEquipment(
    String id,
    Map<String, dynamic> equipment,
  ) async {
    if (id.isEmpty) {
      _errorMessage = 'ID de l\'équipement manquant';
      if (kDebugMode) {
        print('❌ $_errorMessage');
      }
      return;
    }

    try {
      if (kDebugMode) {
        print('🔧 Mise à jour équipement ID: $id');
        print('🔧 Données: $equipment');
      }

      final response = await _equipmentService.updateEquipment(id, equipment);

      // Chercher l'équipement avec plusieurs critères possibles
      final index = _equipments.indexWhere(
        (item) =>
            item['id']?.toString() == id ||
            item['ID']?.toString() == id ||
            item['Code']?.toString() == id ||
            item['code']?.toString() == id,
      );

      if (index != -1) {
        // Mettre à jour l'équipement dans la liste principale
        if (response != null) {
          _equipments[index] = response;
        } else {
          // Si pas de réponse du serveur, fusionner les données
          _equipments[index] = {..._equipments[index], ...equipment};
        }

        // Réappliquer le filtre si une recherche est active
        if (_currentSearchQuery.isNotEmpty) {
          filterEquipments(_currentSearchQuery);
        } else {
          notifyListeners();
        }

        if (kDebugMode) {
          print('✅ Équipement mis à jour localement à l\'index: $index');
        }
      } else {
        // Si l'équipement n'est pas trouvé, recharger toute la liste
        if (kDebugMode) {
          print(
            '⚠️ Équipement non trouvé dans la liste locale pour l\'ID: $id',
          );
          print('🔄 Rechargement complet de la liste...');
        }
        await fetchEquipments();
      }
    } catch (e) {
      _errorMessage = 'Erreur lors de la mise à jour de l\'équipement : $e';
      if (kDebugMode) {
        print('❌ $_errorMessage');
      }
    }
  }

  Future<void> deleteEquipment(String id) async {
    try {
      await _equipmentService.deleteEquipment(id);

      // Supprimer de la liste principale
      _equipments.removeWhere(
        (item) =>
            item['id']?.toString() == id ||
            item['ID']?.toString() == id ||
            item['Code']?.toString() == id ||
            item['code']?.toString() == id,
      );

      // Réappliquer le filtre si une recherche est active
      if (_currentSearchQuery.isNotEmpty) {
        filterEquipments(_currentSearchQuery);
      } else {
        notifyListeners();
      }

      if (kDebugMode) {
        print('✅ Équipement supprimé avec succès');
      }
    } catch (e) {
      _errorMessage = 'Erreur lors de la suppression de l\'équipement : $e';
      if (kDebugMode) {
        print('❌ $_errorMessage');
      }
    }
  }
}
