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

  // ✅ CORRIGÉ: Méthode compatible avec add_equipment_screen.dart avec attributs automatiques
  Future<void> addEquipment(Map<String, dynamic> equipmentData) async {
    try {
      await _checkConnectivity();

      if (!_isOffline) {
        if (kDebugMode) {
          print('🔄 EquipmentProvider - Début ajout équipement');
          print(
            '📊 EquipmentProvider - Données reçues: ${equipmentData.keys.join(', ')}',
          );
        }

        // ✅ NOUVEAU: Traitement spécial des codes (extraire codes depuis descriptions)
        final processedData = <String, dynamic>{};

        // ✅ Traitement des sélecteurs: extraire les CODES des descriptions
        processedData['code'] = equipmentData['code'] ?? '';
        processedData['description'] = equipmentData['description'] ?? '';

        // ✅ Pour les sélecteurs, utiliser les codes extraits
        processedData['famille'] =
            _extractCodeFromSelector(
              equipmentData['famille'],
              familles: true,
            ) ??
            '';
        processedData['zone'] =
            _extractCodeFromSelector(equipmentData['zone'], zones: true) ?? '';
        processedData['entity'] =
            _extractCodeFromSelector(equipmentData['entity'], entities: true) ??
            '';
        processedData['unite'] =
            _extractCodeFromSelector(equipmentData['unite'], unites: true) ??
            '';
        processedData['centre_charge'] =
            _extractCodeFromSelector(
              equipmentData['centreCharge'],
              centreCharges: true,
            ) ??
            '';
        processedData['code_parent'] = equipmentData['codeParent'] ?? '';
        processedData['feeder'] =
            _extractCodeFromSelector(equipmentData['feeder'], feeders: true) ??
            '';
        processedData['feeder_description'] = equipmentData['infoFeeder'] ?? '';
        processedData['longitude'] = equipmentData['longitude'] ?? '';
        processedData['latitude'] = equipmentData['latitude'] ?? '';

        // ✅ CRITICAL: Traitement des attributs
        List<EquipmentAttribute> finalAttributes = [];

        if (equipmentData['attributs'] != null) {
          finalAttributes = _extractAttributeValue(equipmentData['attributs']);
        }

        if (kDebugMode) {
          print('📊 EquipmentProvider - Données traitées pour l\'API:');
          print('   - Famille (CODE): ${processedData['famille']}');
          print('   - Zone (CODE): ${processedData['zone']}');
          print('   - Entity (CODE): ${processedData['entity']}');
          print('   - Unite (CODE): ${processedData['unite']}');
          print('   - Centre Charge (CODE): ${processedData['centre_charge']}');
          print('   - Attributs: ${finalAttributes.length} éléments');
          for (final attr in finalAttributes) {
            print('     • ${attr.name}: "${attr.value}" (${attr.type})');
          }
        }

        // ✅ Créer l'équipement avec les données traitées
        final equipment = Equipment(
          code: processedData['code'],
          description: processedData['description'],
          famille: processedData['famille'],
          zone: processedData['zone'],
          entity: processedData['entity'],
          unite: processedData['unite'],
          centreCharge: processedData['centre_charge'],
          codeParent: processedData['code_parent'],
          feeder: processedData['feeder'],
          feederDescription: processedData['feeder_description'],
          longitude: processedData['longitude'],
          latitude: processedData['latitude'],
          attributes: finalAttributes, // ✅ Inclure tous les attributs
          cachedAt: DateTime.now(),
        );

        // ✅ Envoyer à l'API
        final addedEquipment = await _apiService.addEquipment(equipment);

        // ✅ Ajouter à la liste locale avec l'ID retourné par l'API
        final newEquipmentMap = _convertEquipmentToMap(addedEquipment);
        _allEquipments.insert(0, newEquipmentMap);
        _equipments.insert(0, newEquipmentMap);

        // ✅ Mettre en cache avec les données complètes
        await HiveService.cacheEquipments([addedEquipment]);

        if (kDebugMode) {
          print('✅ EquipmentProvider - Équipement ajouté avec succès via API');
        }
      } else {
        throw Exception(
          'Impossible d\'ajouter un équipement en mode hors ligne',
        );
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ EquipmentProvider - Erreur ajout équipement: $e');
      }
      rethrow;
    }
  }

  List<EquipmentAttribute> _extractAttributeValue(
    List<Map<String, String>> attributsData,
  ) {
    List<EquipmentAttribute> attributes = [];
    for (final attrData in attributsData) {
      final attribute = EquipmentAttribute(
        id: attrData['id'],
        specification: attrData['specification'],
        index: attrData['index'],
        name: attrData['name'],
        value: attrData['value'] ?? '', // ✅ Même si vide, inclure l'attribut
        type: attrData['type'] ?? 'string',
      );
      attributes.add(attribute);
    }
    return attributes;
  }

  // ✅ CORRIGÉ: Extraire le code depuis une description de sélecteur avec gestion des erreurs
  String? _extractCodeFromSelector(
    String? displayValue, {
    bool familles = false,
    bool zones = false,
    bool entities = false,
    bool unites = false,
    bool centreCharges = false,
    bool feeders = false,
  }) {
    if (displayValue == null || displayValue.isEmpty) return null;

    // ✅ Chercher dans la liste appropriée selon le type
    List<Map<String, dynamic>> searchList = [];
    String selectorType = '';

    if (familles && _cachedSelectors != null) {
      searchList =
          _cachedSelectors!['familles'] as List<Map<String, dynamic>>? ?? [];
      selectorType = 'familles';
    } else if (zones && _cachedSelectors != null) {
      searchList =
          _cachedSelectors!['zones'] as List<Map<String, dynamic>>? ?? [];
      selectorType = 'zones';
    } else if (entities && _cachedSelectors != null) {
      searchList =
          _cachedSelectors!['entities'] as List<Map<String, dynamic>>? ?? [];
      selectorType = 'entities';
    } else if (unites && _cachedSelectors != null) {
      searchList =
          _cachedSelectors!['unites'] as List<Map<String, dynamic>>? ?? [];
      selectorType = 'unites';
    } else if (centreCharges && _cachedSelectors != null) {
      searchList =
          _cachedSelectors!['centreCharges'] as List<Map<String, dynamic>>? ??
          [];
      selectorType = 'centreCharges';
    } else if (feeders && _cachedSelectors != null) {
      searchList =
          _cachedSelectors!['feeders'] as List<Map<String, dynamic>>? ?? [];
      selectorType = 'feeders';
    }

    if (kDebugMode) {
      print(
        '🔍 Recherche code pour "$displayValue" dans $selectorType (${searchList.length} éléments)',
      );
    }

    // ✅ Chercher la correspondance description -> code
    for (final item in searchList) {
      final description = item['description']?.toString() ?? '';
      final code = item['code']?.toString() ?? '';

      if (description == displayValue) {
        if (kDebugMode) {
          print('   ✓ Trouvé: "$displayValue" -> CODE: "$code"');
        }
        return code;
      }
    }

    // Recherche alternative par similarité si pas de correspondance exacte
    for (final item in searchList) {
      final description = item['description']?.toString() ?? '';
      final code = item['code']?.toString() ?? '';

      // Recherche si la description contient la valeur cherchée ou vice versa
      if (description.toLowerCase().contains(displayValue.toLowerCase()) ||
          displayValue.toLowerCase().contains(description.toLowerCase())) {
        if (kDebugMode) {
          print(
            '   ✓ Trouvé par similarité: "$displayValue" ≈ "$description" -> CODE: "$code"',
          );
        }
        return code;
      }
    }

    // ✅ CRITICAL: Stratégies de fallback pour éviter les valeurs trop longues
    if (entities) {
      // ✅ SPÉCIAL ENTITY: Essayer de créer un code court depuis la description
      final shortCode = _generateShortEntityCode(displayValue);
      if (kDebugMode) {
        print('   ⚠️ Aucun code entity trouvé pour: "$displayValue"');
        print(
          '   🔧 Code généré: "$shortCode" (longueur: ${shortCode.length})',
        );
      }
      return shortCode;
    }

    // ✅ Fallback général: Tronquer la valeur si trop longue
    String fallbackValue = displayValue;

    // Limites par type de champ (selon les contraintes Oracle)
    int maxLength = 50; // Par défaut
    if (entities) {
      maxLength = 20; // EREQ_ENTITY max 20 caractères
    } else if (zones) {
      maxLength = 20; // EREQ_ZONE généralement limité
    } else if (familles) {
      maxLength = 30; // EREQ_FAMILLE
    }

    if (fallbackValue.length > maxLength) {
      fallbackValue = fallbackValue.substring(0, maxLength);
      if (kDebugMode) {
        print(
          '   ⚠️ Valeur tronquée: "$displayValue" -> "$fallbackValue" (max $maxLength chars)',
        );
      }
    }

    if (kDebugMode) {
      print(
        '   ⚠️ Code non trouvé pour: "$displayValue", utilisation: "$fallbackValue"',
      );
    }
    return fallbackValue;
  }

  // ✅ NOUVEAU: Générer un code court pour les entities
  String _generateShortEntityCode(String entityDescription) {
    if (entityDescription.isEmpty) return '';

    // ✅ Stratégies pour créer un code court depuis la description
    String code = entityDescription;

    // 1. Essayer d'extraire les acronymes
    final words = entityDescription.split(' ');
    if (words.length > 1) {
      // Prendre les premières lettres de chaque mot
      final acronym = words
          .where((word) => word.isNotEmpty)
          .map((word) => word[0].toUpperCase())
          .join('');

      if (acronym.length <= 20 && acronym.length >= 3) {
        if (kDebugMode) {
          print('   🎯 Acronyme généré: "$entityDescription" -> "$acronym"');
        }
        return acronym;
      }
    }

    // 2. Essayer de prendre les mots-clés importants
    final keywords = <String>[];
    for (final word in words) {
      final cleanWord = word.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
      if (cleanWord.length >= 2 &&
          !['DE', 'DU', 'LE', 'LA', 'LES', 'ET', 'OU'].contains(cleanWord)) {
        keywords.add(cleanWord);
        if (keywords.join('').length >= 15) break; // Limiter la longueur
      }
    }

    if (keywords.isNotEmpty) {
      final keywordCode = keywords
          .join('')
          .substring(
            0,
            keywords.join('').length > 20 ? 20 : keywords.join('').length,
          );
      if (keywordCode.length >= 3) {
        if (kDebugMode) {
          print('   🎯 Code mots-clés: "$entityDescription" -> "$keywordCode"');
        }
        return keywordCode;
      }
    }

    // 3. Fallback: Prendre les premiers caractères en nettoyant
    code = entityDescription
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '') // Supprimer caractères spéciaux
        .substring(
          0,
          entityDescription.length > 20 ? 20 : entityDescription.length,
        );

    if (kDebugMode) {
      print('   🎯 Code nettoyé: "$entityDescription" -> "$code"');
    }

    return code;
  }

  // ✅ CORRIGÉ: Méthode de mise à jour avec cache Hive correct
  Future<void> updateEquipment(
    String equipmentId,
    Map<String, dynamic> updatedFields,
  ) async {
    try {
      // ✅ Validation des paramètres d'entrée
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

        // Sauvegarder le code équipement AVANT l'appel API
        final equipmentCode = updatedFields['code'] as String? ?? '';

        // Trouver l'équipement à modifier AVANT l'appel API
        final index = _allEquipments.indexWhere(
          (eq) => eq['id'] == equipmentId || eq['ID'] == equipmentId,
        );

        if (index == -1) {
          throw Exception('Équipement $equipmentId non trouvé dans les données locales');
        }

        // Préparer les données locales AVANT l'appel API
        final localUpdatedEquipment = Map<String, dynamic>.from(_allEquipments[index]);
        
        // Appliquer les modifications localement
        updatedFields.forEach((key, value) {
          if (value != null) {
            localUpdatedEquipment[key] = value;
          }
        });

        // ✅ Appeler l'API pour la synchronisation (mais ne pas s'arrêter si ça échoue)
        try {
          await _apiService.updateEquipment(equipmentId, updatedFields);
          
          if (kDebugMode) {
            print('✅ EquipmentProvider - Synchronisation API réussie');
          }
        } catch (apiError) {
          if (kDebugMode) {
            print('⚠️ EquipmentProvider - Erreur API mais mise à jour locale maintenue: $apiError');
          }
          // Ne pas faire échouer la mise à jour si l'API échoue
        }

        // ✅ IMPORTANT: Mettre à jour les données locales
        _allEquipments[index] = localUpdatedEquipment;
        final equipmentIndex = _equipments.indexWhere(
          (eq) => eq['id'] == equipmentId || eq['ID'] == equipmentId,
        );
        if (equipmentIndex != -1) {
          _equipments[equipmentIndex] = localUpdatedEquipment;
        }

        // ✅ CRITICAL: Mettre à jour le cache Hive avec les nouvelles données
        try {
          // Convertir les données locales en Equipment pour le cache
          final updatedEquipment = Equipment(
            id: localUpdatedEquipment['id']?.toString(),
            codeParent: localUpdatedEquipment['code_parent']?.toString(),
            feeder: localUpdatedEquipment['feeder']?.toString(),
            feederDescription: localUpdatedEquipment['feeder_description']?.toString(),
            code: localUpdatedEquipment['code']?.toString() ?? '',
            famille: localUpdatedEquipment['famille']?.toString() ?? '',
            zone: localUpdatedEquipment['zone']?.toString() ?? '',
            entity: localUpdatedEquipment['entity']?.toString() ?? '',
            unite: localUpdatedEquipment['unite']?.toString() ?? '',
            centreCharge: localUpdatedEquipment['centre_charge']?.toString() ?? '',
            description: localUpdatedEquipment['description']?.toString() ?? '',
            longitude: localUpdatedEquipment['longitude']?.toString() ?? '',
            latitude: localUpdatedEquipment['latitude']?.toString() ?? '',
            attributes: [], // Les attributs seront gérés séparément
            cachedAt: DateTime.now(),
          );

          // ✅ IMPORTANT: Mettre à jour le cache Hive
          await HiveService.updateEquipmentInCache(updatedEquipment);

          if (kDebugMode) {
            print('✅ EquipmentProvider - Cache Hive mis à jour avec les nouvelles données');
          }
        } catch (cacheError) {
          if (kDebugMode) {
            print('⚠️ EquipmentProvider - Erreur mise à jour cache Hive: $cacheError');
          }
        }

        // ✅ CRITICAL: Mettre à jour les attributs si nécessaire
        if (updatedFields.containsKey('attributs')) {
          final finalEquipmentCode = equipmentCode.isNotEmpty 
            ? equipmentCode 
            : localUpdatedEquipment['code']?.toString() ?? '';

          if (finalEquipmentCode.isNotEmpty) {
            try {
              // ✅ NOUVEAU: Traitement correct des attributs
              final attributsData = updatedFields['attributs'] as List<Map<String, String>>? ?? [];
              final newAttributes = attributsData.map((attrData) => 
                EquipmentAttribute(
                  name: attrData['name'],
                  value: attrData['value'] ?? '',
                  type: attrData['type'] ?? 'string',
                )
              ).toList();

              // ✅ IMPORTANT: Nettoyer d'abord le cache des attributs
              await HiveService.clearAttributeValues(finalEquipmentCode);
              
              // ✅ IMPORTANT: Sauvegarder les nouveaux attributs
              if (newAttributes.isNotEmpty) {
                await HiveService.cacheAttributeValues(finalEquipmentCode, newAttributes);
              }

              // ✅ Mettre à jour en mémoire aussi
              _equipmentAttributes[finalEquipmentCode] = newAttributes;

              if (kDebugMode) {
                print('✅ EquipmentProvider - ${newAttributes.length} attributs mis à jour en cache pour: $finalEquipmentCode');
                for (final attr in newAttributes) {
                  print('   - ${attr.name}: "${attr.value}"');
                }
              }
            } catch (attrError) {
              if (kDebugMode) {
                print('⚠️ EquipmentProvider - Erreur mise à jour attributs: $attrError');
              }
            }
          }
        }

        if (kDebugMode) {
          print('✅ EquipmentProvider - Données locales et cache mis à jour');
        }
      } else {
        throw Exception('Impossible de modifier un équipement en mode hors ligne');
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ EquipmentProvider: Erreur modification équipement: $e');
      }
      rethrow;
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
