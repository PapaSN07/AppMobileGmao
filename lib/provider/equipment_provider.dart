import 'package:appmobilegmao/models/equipment_attribute.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:appmobilegmao/services/equipment_service.dart';
import 'package:appmobilegmao/services/hive_service.dart';
import 'package:appmobilegmao/models/equipment.dart';

class EquipmentProvider extends ChangeNotifier {
  final EquipmentService _apiService = EquipmentService();
  final Connectivity _connectivity = Connectivity();

  // État de la liste d'équipements
  List<Map<String, dynamic>> _equipments = [];
  List<Map<String, dynamic>> _allEquipments = [];
  Map<String, String> _filters = {};
  bool _isLoading = false;
  bool _isOffline = false;
  String? _error;

  // État pour les sélecteurs
  Map<String, dynamic>? _cachedSelectors;
  bool _selectorsLoaded = false;

  // État pour les valeurs d'attributs
  // État pour les attributs d'équipements (EquipmentAttribute au lieu d'AttributeValue)
  final Map<String, List<EquipmentAttribute>> _equipmentAttributes = {};
  final Map<String, List<EquipmentAttribute>> _attributeSpecifications = {};
  bool _attributesLoading = false;

  // Getters
  List<Map<String, dynamic>> get equipments => _equipments;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, String> get filters => _filters;
  bool get isOffline => _isOffline;
  Map<String, dynamic>? get cachedSelectors => _cachedSelectors;
  bool get selectorsLoaded => _selectorsLoaded;

  // Getters pour les valeurs d'attributs
  // Getters pour les attributs
  Map<String, List<EquipmentAttribute>> get equipmentAttributes =>
      _equipmentAttributes;
  Map<String, List<EquipmentAttribute>> get attributeSpecifications =>
      _attributeSpecifications;
  bool get attributesLoading => _attributesLoading;

  // Initialisation
  Future<void> initialize() async {
    await _checkConnectivity();
    await fetchEquipments();
  }

  Future<void> _checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _isOffline = result == ConnectivityResult.none;
  }

  // Charger les équipements
  Future<void> fetchEquipments({
    String? entity,
    bool forceRefresh = false,
  }) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;

    notifyListeners();

    try {
      await _checkConnectivity();

      List<Equipment> equipments;

      // Charger depuis le cache si disponible
      if (!forceRefresh && (!_isOffline || await _isCacheValid())) {
        equipments = await HiveService.getCachedEquipments(filters: _filters);
        if (equipments.isNotEmpty) {
          if (kDebugMode) {
            print('📋 GMAO: Chargement depuis cache');
          }
          _allEquipments = _convertToMapList(equipments);
          _equipments = List.from(_allEquipments);
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      // Charger depuis l'API si connecté
      if (!_isOffline) {
        if (kDebugMode) {
          print('🌐 GMAO: Chargement depuis API');
        }

        final response = await _apiService.getEquipments(
          entity: entity ?? _filters['entity'] ?? '',
          zone: _filters['zone'],
          famille: _filters['famille'],
          search: _filters['search'],
          description: _filters['description'],
        );

        equipments = response.items;

        // Mettre en cache si pas de filtres
        if (_filters.isEmpty) {
          await HiveService.cacheEquipments(equipments);
        }
      } else {
        // Mode hors ligne
        equipments = await HiveService.getCachedEquipments(filters: _filters);
        if (equipments.isEmpty) {
          throw Exception('Aucune donnée disponible hors ligne');
        }
      }

      _allEquipments = _convertToMapList(equipments);
      _equipments = List.from(_allEquipments);

      if (kDebugMode) {
        print('📊 GMAO: ${equipments.length} équipements chargés');
      }
    } catch (e) {
      _handleError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Charger les sélecteurs avec priorité cache
  Future<Map<String, dynamic>> loadSelectors({required String entity}) async {
    try {
      if (kDebugMode) {
        print(
          '🔧 EquipmentProvider - Chargement des sélecteurs pour l\'entité $entity',
        );
      }

      // 1. Vérifier le cache d'abord
      final cachedSelectors = HiveService.getCachedSelectors();
      if (cachedSelectors != null && cachedSelectors.isNotEmpty) {
        final convertedSelectors = _convertSelectorsToMap(cachedSelectors);
        if (kDebugMode) {
          print(
            '📋 EquipmentProvider - Sélecteurs chargés depuis Hive (${convertedSelectors.keys.join(', ')})',
          );
        }
        _cachedSelectors = convertedSelectors;
        _selectorsLoaded = true;
        return convertedSelectors;
      }

      // 2. Si pas de cache, charger depuis l'API
      if (kDebugMode) {
        print('🌐 EquipmentProvider - Chargement des sélecteurs depuis l\'API');
      }

      final apiSelectors = await _apiService.getEquipmentSelectors(
        entity: entity,
      );

      // 3. Convertir pour l'utilisation dans l'app
      final convertedSelectors = _convertSelectorsToMap(apiSelectors);

      // 4. ✅ Mettre en cache les données converties (pas les objets typés)
      await HiveService.cacheSelectors(convertedSelectors);

      _cachedSelectors = convertedSelectors;
      _selectorsLoaded = true;

      if (kDebugMode) {
        print(
          '✅ EquipmentProvider - Sélecteurs chargés et mis en cache (${convertedSelectors.keys.join(', ')})',
        );
      }

      return convertedSelectors;
    } catch (e) {
      if (kDebugMode) {
        print('❌ EquipmentProvider - Erreur chargement des sélecteurs: $e');
      }
      rethrow;
    }
  }

  // Convertir les sélecteurs de l'API en Map<String, dynamic>
  Map<String, dynamic> _convertSelectorsToMap(
    Map<String, dynamic> apiSelectors,
  ) {
    final Map<String, dynamic> result = {};

    apiSelectors.forEach((key, value) {
      if (value is List) {
        result[key] =
            value.map((item) {
              // ✅ Vérifie si l'élément est déjà une Map<String, dynamic>
              if (item is Map<String, dynamic>) {
                return item;
              }

              // ✅ Si c'est une Map<dynamic, dynamic>, force la conversion
              if (item is Map) {
                return item.map(
                  (key, value) => MapEntry(key.toString(), value),
                );
              }

              // ✅ Si c'est un objet typé, tente d'appeler toJson()
              try {
                final jsonMap = (item as dynamic).toJson();
                if (jsonMap is Map) {
                  return jsonMap.map(
                    (key, value) => MapEntry(key.toString(), value),
                  );
                }
              } catch (_) {}

              // Retourne une Map vide si tout échoue
              return <String, dynamic>{};
            }).toList();
      } else {
        result[key] = value;
      }
    });

    return result;
  }

  // Forcer le rechargement des sélecteurs
  Future<Map<String, dynamic>> forceReloadSelectors({
    required String entity,
  }) async {
    _cachedSelectors = null;
    _selectorsLoaded = false;
    await HiveService.clearCache('selectors');
    return await loadSelectors(entity: entity);
  }

  // Appliquer les filtres
  Future<void> applyFilters(Map<String, String> filters) async {
    _filters = Map.from(filters);
    await fetchEquipments(forceRefresh: true);
  }

  // Effacer les filtres
  Future<void> clearFilters() async {
    await applyFilters({});
  }

  // Méthode helper pour gérer les erreurs
  void _handleError(dynamic e) {
    if (kDebugMode) {
      print('❌ GMAO: Erreur chargement équipements: $e');
    }
    _error = e.toString();

    // Fallback sur cache en cas d'erreur
    _tryLoadFromCache();
  }

  Future<void> _tryLoadFromCache() async {
    try {
      final cached = await HiveService.getCachedEquipments(filters: _filters);
      if (cached.isNotEmpty) {
        _allEquipments = _convertToMapList(cached);
        _equipments = List.from(_allEquipments);
        _error = 'Données en mode hors ligne';
      }
    } catch (cacheError) {
      if (kDebugMode) {
        print('❌ GMAO: Erreur fallback cache: $cacheError');
      }
    }
  }

  // ✅ Méthode compatible avec add_equipment_screen.dart
  Future<void> addEquipment(Map<String, dynamic> equipmentData) async {
    try {
      await _checkConnectivity();

      if (!_isOffline) {
        // Envoyer à l'API
        final equipment = Equipment.fromJson(equipmentData);

        // Simuler l'ajout API (à remplacer par votre vraie API)
        await _apiService.addEquipment(equipment);
        final newEquipmentMap = _convertEquipmentToMap(equipment);
        newEquipmentMap['id'] =
            DateTime.now().millisecondsSinceEpoch.toString();

        // Ajouter à la liste locale
        _allEquipments.insert(0, newEquipmentMap);
        _equipments.insert(0, newEquipmentMap);

        // Mettre en cache
        await HiveService.cacheEquipments([equipment]);

        if (kDebugMode) {
          print('✅ GMAO: Équipement ajouté avec succès');
        }
      } else {
        throw Exception(
          'Impossible d\'ajouter un équipement en mode hors ligne',
        );
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ GMAO: Erreur ajout équipement: $e');
      }
      rethrow;
    }
  }

  // ✅ Méthode compatible avec modify_equipment_screen.dart + attributs
  Future<void> updateEquipment(
    String equipmentId,
    Map<String, dynamic> updatedFields,
  ) async {
    try {
      // ✅ AJOUTÉ: Validation des paramètres d'entrée
      if (equipmentId.isEmpty) {
        throw Exception('ID équipement requis');
      }

      if (updatedFields.isEmpty) {
        throw Exception('Aucune donnée à mettre à jour');
      }

      await _checkConnectivity();

      if (!_isOffline) {
        if (kDebugMode) {
          print('🔄 EquipmentProvider - Début mise à jour équipement: $equipmentId');
          print('📊 EquipmentProvider - Données: ${updatedFields.keys.join(', ')}');
        }

        // ✅ Appeler l'API pour la mise à jour réelle
        final equipment = await _apiService.updateEquipment(
          equipmentId,
          updatedFields,
        );

        if (kDebugMode) {
          print('✅ EquipmentProvider - Réponse API reçue pour: ${equipment.code}');
        }

        // Trouver l'équipement à modifier dans les listes locales
        final index = _allEquipments.indexWhere(
          (eq) => eq['id'] == equipmentId || eq['code'] == equipmentId,
        );
        
        if (index != -1) {
          // Mettre à jour les champs modifiés localement
          final updatedEquipment = Map<String, dynamic>.from(
            _allEquipments[index],
          );
          
          // ✅ Mettre à jour tous les champs du formulaire
          updatedFields.forEach((key, value) {
            // Mapper les clés du formulaire vers les clés de stockage
            switch (key) {
              case 'code_parent':
                updatedEquipment['codeParent'] = value;
                updatedEquipment['Code Parent'] = value;
                break;
              case 'feeder':
                updatedEquipment['feeder'] = value;
                updatedEquipment['Feeder'] = value;
                break;
              case 'feeder_description':
                updatedEquipment['feederDescription'] = value;
                updatedEquipment['Info Feeder'] = value;
                break;
              case 'famille':
                updatedEquipment['famille'] = value;
                updatedEquipment['Famille'] = value;
                break;
              case 'zone':
                updatedEquipment['zone'] = value;
                updatedEquipment['Zone'] = value;
                break;
              case 'entity':
                updatedEquipment['entity'] = value;
                updatedEquipment['Entité'] = value;
                break;
              case 'unite':
                updatedEquipment['unite'] = value;
                updatedEquipment['Unité'] = value;
                break;
              case 'centre_charge':
                updatedEquipment['centreCharge'] = value;
                updatedEquipment['Centre'] = value;
                break;
              case 'description':
                updatedEquipment['description'] = value;
                updatedEquipment['Description'] = value;
                break;
              case 'longitude':
                updatedEquipment['longitude'] = value;
                updatedEquipment['Longitude'] = value;
                break;
              case 'latitude':
                updatedEquipment['latitude'] = value;
                updatedEquipment['Latitude'] = value;
                break;
              case 'attributs':
                // ✅ Mettre à jour les attributs si fournis
                updatedEquipment['attributes'] = value;
                break;
              // ✅ AJOUTÉ: Gestion du champ code (lecture seule mais peut être dans les données)
              case 'code':
                // Le code ne change pas normalement, mais on le met à jour si fourni
                updatedEquipment['code'] = value;
                updatedEquipment['Code'] = value;
                break;
              default:
                updatedEquipment[key] = value;
            }
          });

          // Mettre à jour dans les listes
          _allEquipments[index] = updatedEquipment;
          final equipmentIndex = _equipments.indexWhere(
            (eq) => eq['id'] == equipmentId || eq['code'] == equipmentId,
          );
          if (equipmentIndex != -1) {
            _equipments[equipmentIndex] = updatedEquipment;
          }

          // ✅ Mettre à jour le cache des attributs si modifiés
          if (updatedFields.containsKey('attributs')) {
            final equipmentCode =  updatedEquipment['code'] ?? 
                                  updatedEquipment['Code'] ?? 
                                  equipmentId;
            await _updateEquipmentAttributesCache(equipmentCode, updatedFields['attributs']);
          }

          if (kDebugMode) {
            print('✅ EquipmentProvider - Données locales mises à jour');
          }
        } else {
          if (kDebugMode) {
            print('⚠️ EquipmentProvider - Équipement $equipmentId non trouvé dans les données locales');
          }
        }

        if (kDebugMode) {
          print('✅ GMAO: Équipement modifié avec succès via API');
        }
      } else {
        throw Exception(
          'Impossible de modifier un équipement en mode hors ligne',
        );
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ GMAO: Erreur modification équipement: $e');
      }
      rethrow;
    }
  }

  /// ✅ Mettre à jour le cache des attributs après modification
  Future<void> _updateEquipmentAttributesCache(
    String equipmentCode, 
    List<dynamic> attributs,
  ) async {
    try {
      // Convertir les attributs du format API vers EquipmentAttribute
      final attributes = attributs.map((attr) {
        if (attr is Map<String, dynamic>) {
          return EquipmentAttribute(
            id: attr['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
            name: attr['name']?.toString() ?? '',
            value: attr['value']?.toString() ?? '',
            specification: attr['type']?.toString() ?? '1', // Utiliser type comme specification
            index: '1', // ✅ Ajouter un index par défaut
          );
        }
        return null;
      }).where((attr) => attr != null).cast<EquipmentAttribute>().toList();

      // ✅ AJOUTÉ: Filtrer les doublons avant la mise en cache
      final uniqueAttributes = _filterDuplicateAttributes(attributes);

      // Mettre à jour le cache
      await HiveService.cacheAttributeValues(equipmentCode, uniqueAttributes);
      
      // Mettre à jour en mémoire
      _equipmentAttributes[equipmentCode] = uniqueAttributes;

      if (kDebugMode) {
        print('✅ EquipmentProvider - Cache des attributs mis à jour pour $equipmentCode (${uniqueAttributes.length} attributs)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ EquipmentProvider - Erreur mise à jour cache attributs: $e');
      }
    }
  }

  // Vérifier si le cache est valide
  Future<bool> _isCacheValid() async {
    return !await HiveService.isCacheExpired('equipments');
  }

  // Conversion helper
  List<Map<String, dynamic>> _convertToMapList(List<Equipment> equipments) {
    return equipments
        .map((equipment) => _convertEquipmentToMap(equipment))
        .toList();
  }

  // ✅ MODIFIÉ: Conversion helper pour inclure les attributs
  Map<String, dynamic> _convertEquipmentToMap(Equipment equipment) {
    return {
      'id': equipment.id,
      'codeParent': equipment.codeParent,
      'feeder': equipment.feeder,
      'feederDescription': equipment.feederDescription,
      'code': equipment.code,
      'famille': equipment.famille,
      'zone': equipment.zone,
      'entity': equipment.entity,
      'unite': equipment.unite,
      'centreCharge': equipment.centreCharge,
      'description': equipment.description,
      'longitude': equipment.longitude,
      'latitude': equipment.latitude,
      'attributes':
          equipment.attributes?.map((attr) => attr.toJson()).toList() ??
          [], // ✅ Inclure les attributs
    };
  }

  // ========================================
  // GESTION DES VALEURS D'ATTRIBUTS
  // ========================================

  /// ✅ NOUVEAU: Charger les attributs d'un équipement spécifique depuis ses données
  /// Cette méthode simule le chargement des attributs de l'équipement en utilisant ses spécifications
  Future<List<EquipmentAttribute>> loadEquipmentAttributes(
    String equipmentCode,
  ) async {
    if (_attributesLoading) return _equipmentAttributes[equipmentCode] ?? [];

    _attributesLoading = true;
    notifyListeners();

    try {
      if (kDebugMode) {
        print(
          '🔧 EquipmentProvider - Chargement des attributs pour équipement: $equipmentCode',
        );
      }

      // 1. Vérifier le cache d'abord
      final cachedAttributes = await HiveService.getCachedAttributeValues(
        equipmentCode,
      );

      if (cachedAttributes != null && cachedAttributes.isNotEmpty) {
        // ✅ Filtrer les doublons même dans le cache
        final uniqueAttributes = _filterDuplicateAttributes(cachedAttributes);
        _equipmentAttributes[equipmentCode] = uniqueAttributes;
        if (kDebugMode) {
          print(
            '📋 EquipmentProvider - ${uniqueAttributes.length} attributs équipement uniques depuis le cache (${cachedAttributes.length} au total)',
          );
        }
        return uniqueAttributes;
      }

      // 2. Si pas de cache, récupérer l'équipement et ses attributs réels
      await _checkConnectivity();
      if (_isOffline) {
        throw Exception(
          'Impossible de charger les attributs en mode hors ligne',
        );
      }

      if (kDebugMode) {
        print(
          '🌐 EquipmentProvider - Chargement des attributs équipement depuis l\'API',
        );
      }

      // ✅ Chercher l'équipement dans la liste avec ses attributs réels
      final equipment = _allEquipments.firstWhere(
        (eq) => eq['code'] == equipmentCode,
        orElse: () => <String, dynamic>{},
      );

      if (equipment.isEmpty) {
        throw Exception('Équipement $equipmentCode non trouvé');
      }

      // ✅ Utiliser UNIQUEMENT les vrais attributs de l'équipement
      List<EquipmentAttribute> attributeValues = [];

      if (equipment['attributes'] != null && equipment['attributes'] is List) {
        attributeValues =
            (equipment['attributes'] as List).map((attr) {
              if (attr is Map<String, dynamic>) {
                return EquipmentAttribute(
                  id: attr['id']?.toString(),
                  specification: attr['specification']?.toString(),
                  index: attr['index']?.toString(),
                  name: attr['name']?.toString(),
                  value: attr['value']?.toString() ?? '',
                );
              } else {
                return attr as EquipmentAttribute;
              }
            }).toList();
      }

      // ✅ NOUVEAU: Filtrer les doublons de spécification AVANT de mettre en cache
      final uniqueAttributes = _filterDuplicateAttributes(attributeValues);

      // ✅ Si aucun attribut, retourner une liste vide
      if (uniqueAttributes.isEmpty) {
        if (kDebugMode) {
          print(
            '📋 EquipmentProvider - Aucun attribut trouvé pour l\'équipement $equipmentCode',
          );
        }
        return [];
      }

      // 3. Mettre en cache les attributs uniques (pas tous les doublons)
      await HiveService.cacheAttributeValues(equipmentCode, uniqueAttributes);

      // 4. Stocker en mémoire
      _equipmentAttributes[equipmentCode] = uniqueAttributes;

      if (kDebugMode) {
        print(
          '✅ EquipmentProvider - ${uniqueAttributes.length} attributs équipement uniques chargés (${attributeValues.length} au total)',
        );
      }

      return uniqueAttributes;
    } catch (e) {
      if (kDebugMode) {
        print(
          '❌ EquipmentProvider - Erreur chargement attributs équipement: $e',
        );
      }
      rethrow;
    } finally {
      _attributesLoading = false;
      notifyListeners();
    }
  }

  /// ✅ NOUVEAU: Filtrer les attributs dupliqués par spécification
  List<EquipmentAttribute> _filterDuplicateAttributes(
    List<EquipmentAttribute> attributes,
  ) {
    final Map<String, EquipmentAttribute> uniqueAttributesMap = {};

    for (final attr in attributes) {
      if (attr.specification != null &&
          attr.index != null &&
          attr.name != null) {
        final specKey = '${attr.specification}_${attr.index}';

        // ✅ Garder seulement le premier attribut de chaque spécification/index
        if (!uniqueAttributesMap.containsKey(specKey)) {
          uniqueAttributesMap[specKey] = attr;
        } else {
          // Si on a déjà cet attribut, garder celui qui a une valeur non vide
          final existing = uniqueAttributesMap[specKey]!;
          if ((existing.value == null || existing.value!.isEmpty) &&
              (attr.value != null && attr.value!.isNotEmpty)) {
            uniqueAttributesMap[specKey] = attr;
          }
        }
      } else {
        // Pour les attributs sans spécification valide, utiliser l'ID comme clé unique
        final key =
            attr.id ??
            'no_id_${attr.name ?? 'unknown'}_${DateTime.now().millisecondsSinceEpoch}';
        if (!uniqueAttributesMap.containsKey(key)) {
          uniqueAttributesMap[key] = attr;
        }
      }
    }

    // Trier les résultats par nom pour un affichage cohérent
    final uniqueList = uniqueAttributesMap.values.toList();
    uniqueList.sort((a, b) {
      final nameA = a.name ?? '';
      final nameB = b.name ?? '';
      return nameA.compareTo(nameB);
    });

    if (kDebugMode) {
      print(
        '🔍 Filtrage attributs: ${attributes.length} -> ${uniqueList.length} uniques',
      );

      // Afficher les attributs filtrés pour debug
      for (final attr in uniqueList) {
        print(
          '  ✓ ${attr.name} (spec: ${attr.specification}, index: ${attr.index}, valeur: "${attr.value}")',
        );
      }
    }

    return uniqueList;
  }

  /// ✅ NOUVEAU: Charger les valeurs possibles pour un attribut spécifique UNIQUEMENT
  Future<List<EquipmentAttribute>> loadPossibleValuesForAttribute(
    String specification,
    String attributeIndex,
  ) async {
    final specKey = '${specification}_$attributeIndex';

    // Vérifier si déjà chargé en mémoire
    if (_attributeSpecifications.containsKey(specKey)) {
      return _attributeSpecifications[specKey]!;
    }

    if (_attributesLoading) {
      return _attributeSpecifications[specKey] ?? [];
    }

    _attributesLoading = true;
    notifyListeners();

    try {
      if (kDebugMode) {
        print(
          '🔧 EquipmentProvider - Chargement des valeurs possibles pour: $specKey',
        );
      }

      // 1. Vérifier le cache d'abord
      final cachedAttributes =
          await HiveService.getCachedAttributeSpecifications(
            specification,
            attributeIndex,
          );

      if (cachedAttributes != null && cachedAttributes.isNotEmpty) {
        _attributeSpecifications[specKey] = cachedAttributes;
        if (kDebugMode) {
          print(
            '📋 EquipmentProvider - ${cachedAttributes.length} valeurs possibles depuis le cache',
          );
        }
        return cachedAttributes;
      }

      // 2. Si pas de cache, charger depuis l'API
      await _checkConnectivity();
      if (_isOffline) {
        throw Exception('Impossible de charger les valeurs en mode hors ligne');
      }

      if (kDebugMode) {
        print('🌐 EquipmentProvider - Chargement des valeurs depuis l\'API');
      }

      final apiResponse = await _apiService.getAttributeValuesEquipment(
        specification: specification,
        attributeIndex: attributeIndex,
      );

      // ✅ CORRIGÉ: Gestion du cas où aucun attribut n'est trouvé
      final attributeValues =
          apiResponse['attributes'] as List<EquipmentAttribute>? ?? [];
      final hasError = apiResponse['error'] == true;

      if (hasError) {
        if (kDebugMode) {
          print('⚠️ EquipmentProvider - Erreur API: ${apiResponse['message']}');
        }
      }

      // 3. Mettre en cache même si la liste est vide (pour éviter les appels répétés)
      await HiveService.cacheAttributeSpecifications(
        specification,
        attributeIndex,
        attributeValues,
      );

      // 4. Stocker en mémoire
      _attributeSpecifications[specKey] = attributeValues;

      if (kDebugMode) {
        print(
          '✅ EquipmentProvider - ${attributeValues.length} valeurs possibles chargées',
        );
      }

      return attributeValues;
    } catch (e) {
      if (kDebugMode) {
        print('❌ EquipmentProvider - Erreur chargement valeurs possibles: $e');
      }

      // ✅ Retourner une liste vide au lieu de relancer l'erreur
      _attributeSpecifications[specKey] = [];
      return [];
    } finally {
      _attributesLoading = false;
      notifyListeners();
    }
  }

  /// Mettre à jour une valeur d'attribut
  Future<void> updateAttributeValue(
    String equipmentCode,
    String attributeId,
    String newValue,
  ) async {
    try {
      // 1. Mettre à jour en mémoire
      if (_equipmentAttributes.containsKey(equipmentCode)) {
        final attributes = _equipmentAttributes[equipmentCode]!;
        final attributeIndex = attributes.indexWhere(
          (attr) => attr.id == attributeId,
        );

        if (attributeIndex != -1) {
          attributes[attributeIndex].value = newValue;
          _equipmentAttributes[equipmentCode] = attributes;
        }
      }

      // 2. Mettre à jour dans le cache
      await HiveService.updateAttributeValue(
        equipmentCode,
        attributeId,
        newValue,
      );

      // 3. Envoyer à l'API (si en ligne)
      if (!_isOffline) {
        if (kDebugMode) {
          print(
            '🌐 EquipmentProvider - Mise à jour attribut via API (à implémenter)',
          );
        }
        // TODO: Implémenter l'appel API pour mettre à jour la valeur
      } else {
        // Ajouter à la queue des actions en attente
        await HiveService.addPendingAction({
          'type': 'update_attribute_value',
          'equipmentCode': equipmentCode,
          'attributeId': attributeId,
          'newValue': newValue,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }

      notifyListeners();

      if (kDebugMode) {
        print('✅ EquipmentProvider - Valeur d\'attribut mise à jour');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ EquipmentProvider - Erreur mise à jour attribut: $e');
      }
      rethrow;
    }
  }

  /// ✅ NOUVEAU: Filtrer les équipements par un champ spécifique
  void filterEquipmentsByField(String searchTerm, String field) {
    if (searchTerm.isEmpty) {
      _equipments = List.from(_allEquipments);
    } else {
      _equipments =
          _allEquipments.where((equipment) {
            String? fieldValue;

            // Récupérer la valeur selon le champ demandé
            switch (field.toLowerCase()) {
              case 'code':
                fieldValue =
                    equipment['code']?.toString() ??
                    equipment['Code']?.toString();
                break;
              case 'description':
                fieldValue =
                    equipment['description']?.toString() ??
                    equipment['Description']?.toString();
                break;
              case 'zone':
                fieldValue =
                    equipment['zone']?.toString() ??
                    equipment['Zone']?.toString();
                break;
              case 'famille':
                fieldValue =
                    equipment['famille']?.toString() ??
                    equipment['Famille']?.toString();
                break;
              case 'entity':
              case 'entité':
                fieldValue =
                    equipment['entity']?.toString() ??
                    equipment['Entité']?.toString() ??
                    equipment['Entity']?.toString();
                break;
              case 'unite':
              case 'unité':
                fieldValue =
                    equipment['unite']?.toString() ??
                    equipment['Unité']?.toString() ??
                    equipment['Unite']?.toString();
                break;
              case 'feeder':
                fieldValue =
                    equipment['feeder']?.toString() ??
                    equipment['Feeder']?.toString();
                break;
              default:
                // Si le champ n'est pas reconnu, chercher dans tous les champs
                fieldValue = [
                  equipment['code']?.toString(),
                  equipment['Code']?.toString(),
                  equipment['description']?.toString(),
                  equipment['Description']?.toString(),
                ].where((v) => v != null && v.isNotEmpty).join(' ');
            }

            if (fieldValue == null || fieldValue.isEmpty) {
              return false;
            }

            final searchLower = searchTerm.toLowerCase();
            final fieldLower = fieldValue.toLowerCase();

            return fieldLower.contains(searchLower);
          }).toList();
    }

    notifyListeners();

    if (kDebugMode) {
      print(
        '🔍 EquipmentProvider - Filtrage par $field: "$searchTerm" -> ${_equipments.length} résultats',
      );
    }
  }

  /// ✅ MODIFIÉ: Amélioration du filtrage général existant
  void filterEquipments(String searchTerm) {
    if (searchTerm.isEmpty) {
      _equipments = List.from(_allEquipments);
    } else {
      _equipments =
          _allEquipments.where((equipment) {
            final searchableText =
                [
                      equipment['code']?.toString(),
                      equipment['Code']?.toString(),
                      equipment['description']?.toString(),
                      equipment['Description']?.toString(),
                      equipment['zone']?.toString(),
                      equipment['Zone']?.toString(),
                      equipment['famille']?.toString(),
                      equipment['Famille']?.toString(),
                      equipment['entity']?.toString(),
                      equipment['Entité']?.toString(),
                      equipment['Entity']?.toString(),
                      equipment['unite']?.toString(),
                      equipment['Unité']?.toString(),
                      equipment['Unite']?.toString(),
                      equipment['feeder']?.toString(),
                      equipment['Feeder']?.toString(),
                    ]
                    .where((value) => value != null && value.isNotEmpty)
                    .join(' ')
                    .toLowerCase();

            return searchableText.contains(searchTerm.toLowerCase());
          }).toList();
    }

    notifyListeners();

    if (kDebugMode) {
      print(
        '🔍 EquipmentProvider - Recherche générale: "$searchTerm" -> ${_equipments.length} résultats',
      );
    }
  }

}
