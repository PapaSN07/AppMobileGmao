import 'package:appmobilegmao/provider/auth_provider.dart';
import 'package:appmobilegmao/provider/equipment_provider.dart';
import 'package:appmobilegmao/services/hive_service.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/widgets/custom_buttons.dart';
import 'package:appmobilegmao/widgets/notification_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddEquipmentScreen extends StatefulWidget {
  const AddEquipmentScreen({super.key});

  @override
  State<AddEquipmentScreen> createState() => _AddEquipmentScreenState();
}

class _AddEquipmentScreenState extends State<AddEquipmentScreen> {
  // Valeurs sélectionnées
  String? selectedCodeParent;
  String? selectedFeeder;
  String? selectedFamille;
  String? selectedZone;
  String? selectedEntity;
  String? selectedUnite;
  String? selectedCentreCharge;

  // Contrôleurs et form
  final _formKey = GlobalKey<FormState>();
  final FocusNode _descriptionFocusNode = FocusNode();
  final TextEditingController _descriptionController = TextEditingController();

  // Attributs
  List<String> selectedAttributeValues = List.filled(10, '1922309AHDNAJ');

  // Listes des sélecteurs (optimisées)
  List<Map<String, dynamic>> feeders = [];
  List<Map<String, dynamic>> familles = [];
  List<Map<String, dynamic>> zones = [];
  List<Map<String, dynamic>> entities = [];
  List<Map<String, dynamic>> unites = [];
  List<Map<String, dynamic>> centreCharges = [];

  // État de chargement
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // ✅ Utiliser WidgetsBinding pour différer l'exécution après la construction
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadValuesEquipmentsWithUserInfo();
    });
  }

  @override
  void dispose() {
    _descriptionFocusNode.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  void deactivate() {
    FocusScope.of(context).unfocus();
    super.deactivate();
  }

  void _loadValuesEquipmentsWithUserInfo() async {
    if (!mounted) return;

    // ✅ Sécuriser setState avec mounted check
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    try {
      // Vérifier le cache d'abord
      final selectorsBox = HiveService.getCachedSelectors();

      if (selectorsBox != null && selectorsBox.isNotEmpty) {
        _populateSelectorsFromCache(selectorsBox);
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // Si pas de cache, charger depuis l'API
      await _loadSelectorsFromAPI();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur chargement sélecteurs: $e');
      }
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  void _populateSelectorsFromCache(Map<String, dynamic> selectorsBox) {
    try {
      // ✅ Ne pas appeler setState ici - juste mettre à jour les variables
      entities = _extractSelectorData(selectorsBox['entities']);
      unites = _extractSelectorData(selectorsBox['unites']);
      centreCharges = _extractSelectorData(selectorsBox['centreCharges']);
      zones = _extractSelectorData(selectorsBox['zones']);
      familles = _extractSelectorData(selectorsBox['familles']);
      feeders = _extractSelectorData(selectorsBox['feeders']);

      if (kDebugMode) {
        print('✅ Sélecteurs chargés depuis le cache');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur extraction cache: $e');
      }
      // ✅ Différer l'appel API avec Future.microtask
      Future.microtask(() => _loadSelectorsFromAPI());
    }
  }

  List<Map<String, dynamic>> _extractSelectorData(dynamic data) {
    if (data == null) return [];

    if (data is List) {
      return data
          .map((item) {
            if (item is Map<String, dynamic>) {
              return item;
            } else {
              // Si c'est un objet avec toJson()
              try {
                return (item as dynamic).toJson() as Map<String, dynamic>;
              } catch (e) {
                if (kDebugMode) {
                  print('❌ Erreur conversion objet: $e');
                }
                return <String, dynamic>{};
              }
            }
          })
          .where((item) => item.isNotEmpty)
          .toList();
    }

    return [];
  }

  Future<void> _loadSelectorsFromAPI() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final equipmentProvider = Provider.of<EquipmentProvider>(
        context,
        listen: false,
      );
      final user = authProvider.currentUser;

      if (user != null) {
        // Charger les équipements et sélecteurs
        await equipmentProvider.fetchEquipments(entity: user.entity);

        final selectors = await equipmentProvider.loadSelectors(
          entity: user.entity,
        );

        if (selectors.isNotEmpty && mounted) {
          _populateSelectorsFromAPI(selectors);
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        // Utilisateur non connecté
        await context.read<EquipmentProvider>().fetchEquipments();
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur chargement API: $e');
      }
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  void _populateSelectorsFromAPI(Map<String, dynamic> selectors) {
    // ✅ Ne pas appeler setState ici non plus
    entities = _extractSelectorData(selectors['entities']);
    unites = _extractSelectorData(selectors['unites']);
    centreCharges = _extractSelectorData(selectors['centreCharges']);
    zones = _extractSelectorData(selectors['zones']);
    familles = _extractSelectorData(selectors['familles']);
    feeders = _extractSelectorData(selectors['feeders']);
  }

  // Helpers pour extraire les données des sélecteurs
  List<String> _getSelectorsOptions(
    List<Map<String, dynamic>> data, {
    String codeKey = 'code',
    String descKey = 'description',
  }) {
    return data
        .map((item) {
          final code = item[codeKey]?.toString() ?? '';
          final desc = item[descKey]?.toString() ?? '';
          return desc.isNotEmpty ? '$code - $desc' : code;
        })
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  String? _getSelectedCode(String? displayValue) {
    if (displayValue == null || displayValue.isEmpty) return null;
    return displayValue.split(' - ').first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Consumer<EquipmentProvider>(
        builder: (context, equipmentProvider, child) {
          return _buildBody(equipmentProvider);
        },
      ),
    );
  }

  Widget _buildBody(EquipmentProvider equipmentProvider) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_hasError) {
      return _buildErrorState();
    }

    return Stack(
      children: [
        // AppBar personnalisée
        _buildCustomAppBar(),

        // Contenu principal
        _buildMainContent(),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.secondaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            'Chargement des données...',
            style: TextStyle(
              fontFamily: AppTheme.fontMontserrat,
              color: AppTheme.secondaryColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppTheme.secondaryColor),
          const SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: TextStyle(
              fontFamily: AppTheme.fontMontserrat,
              fontWeight: FontWeight.bold,
              color: AppTheme.secondaryColor,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Impossible de charger les données',
            style: TextStyle(
              fontFamily: AppTheme.fontMontserrat,
              color: AppTheme.secondaryColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            text: 'Réessayer',
            icon: Icons.refresh,
            onPressed: _loadValuesEquipmentsWithUserInfo,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: const BoxDecoration(color: AppTheme.secondaryColor),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 0, left: 16, right: 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                const Text(
                  'Ajouter un équipement',
                  style: TextStyle(
                    fontFamily: AppTheme.fontMontserrat,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 20,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Positioned(
      top: 156,
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.only(top: 10),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(top: 0, right: 16, left: 16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildInformationsSection(),
                  const SizedBox(height: 40),
                  _buildParentInfoSection(),
                  const SizedBox(height: 40),
                  _buildPositioningSection(),
                  const SizedBox(height: 20),
                  _buildActionButtons(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInformationsSection() {
    return Column(
      children: [
        _buildFieldset('Informations'),
        const SizedBox(height: 10),
        _buildCodeAndFamilleRow(),
        const SizedBox(height: 20),
        _buildZoneAndEntityRow(),
        const SizedBox(height: 20),
        _buildUniteAndChargeRow(),
        const SizedBox(height: 20),
        _buildDescriptionRow(),
      ],
    );
  }

  Widget _buildParentInfoSection() {
    return Column(
      children: [
        _buildFieldset('Informations parents'),
        _buildDropdownField(
          label: 'Code Parent',
          msgError: 'Veuillez sélectionner un code parent',
          items:
              feeders
                  .map((item) {
                    final code = item['code']?.toString() ?? '';
                    return code;
                  })
                  .where((item) => item.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort(),
          selectedValue: selectedCodeParent,
          onChanged: (value) {
            setState(() {
              selectedCodeParent = value;
            });
          },
        ),
        const SizedBox(height: 20),
        _buildFeederRow(),
      ],
    );
  }

  Widget _buildPositioningSection() {
    return Column(
      children: [
        _buildFieldset('Informations de positionnement'),
        const SizedBox(height: 10),
        _buildCoordinatesRow(),
        const SizedBox(height: 20),
        _buildMapSection(),
        const SizedBox(height: 20),
        _buildAttributesSection(),
      ],
    );
  }

  Widget _buildCodeAndFamilleRow() {
    return Row(
      children: [
        Expanded(
          child: _buildText(
            label: 'Code',
            value: selectedCodeParent ?? '#12345',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildDropdownField(
            label: 'Famille',
            msgError: 'Veuillez sélectionner une famille',
            items: _getSelectorsOptions(familles),
            selectedValue: selectedFamille,
            onChanged: (value) {
              setState(() {
                selectedFamille = value;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildZoneAndEntityRow() {
    return Row(
      children: [
        Expanded(
          child: _buildDropdownField(
            label: 'Zone',
            msgError: 'Veuillez sélectionner une zone',
            items: _getSelectorsOptions(zones),
            selectedValue: selectedZone,
            onChanged: (value) {
              setState(() {
                selectedZone = value;
              });
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildDropdownField(
            label: 'Entité',
            msgError: 'Veuillez sélectionner une entité',
            items: _getSelectorsOptions(entities),
            selectedValue: selectedEntity,
            onChanged: (value) {
              setState(() {
                selectedEntity = value;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUniteAndChargeRow() {
    return Row(
      children: [
        Expanded(
          child: _buildDropdownField(
            label: 'Unité',
            msgError: 'Veuillez sélectionner une unité',
            items: _getSelectorsOptions(unites),
            selectedValue: selectedUnite,
            onChanged: (value) {
              setState(() {
                selectedUnite = value;
              });
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildDropdownField(
            label: 'Centre de Charge',
            msgError: 'Veuillez sélectionner un centre de charge',
            items: _getSelectorsOptions(centreCharges),
            selectedValue: selectedCentreCharge,
            onChanged: (value) {
              setState(() {
                selectedCentreCharge = value;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionRow() {
    return _buildTextField(
      label: 'Description',
      msgError: 'Veuillez entrer la description',
      focusNode: _descriptionFocusNode,
      controller: _descriptionController,
    );
  }

  Widget _buildFeederRow() {
    return Row(
      children: [
        Expanded(
          child: _buildDropdownField(
            label: 'Feeder',
            msgError: 'Veuillez sélectionner un feeder',
            items: feeders
                  .map((item) {
                    final code = item['description']?.toString() ?? '';
                    return code;
                  })
                  .where((item) => item.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort(),
            selectedValue: selectedFeeder,
            onChanged: (value) {
              setState(() {
                selectedFeeder = value;
              });
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildText(label: 'Info Feeder', value: selectedFeeder ?? ''),
        ),
      ],
    );
  }

  Widget _buildCoordinatesRow() {
    return Row(
      children: [
        Expanded(child: _buildText(label: 'Longitude', value: '12311231')),
        const SizedBox(width: 10),
        Expanded(child: _buildText(label: 'Latitude', value: '12311231')),
      ],
    );
  }

  Widget _buildMapSection() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: const DecorationImage(
          image: AssetImage('assets/images/map.png'),
          fit: BoxFit.cover,
        ),
        color: Colors.grey[300],
        boxShadow: [
          BoxShadow(
            color: AppTheme.boxShadowColor,
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primaryColor75, AppTheme.primaryColor75],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Position actuelle',
                  style: TextStyle(
                    fontFamily: AppTheme.fontMontserrat,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryColor,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    if (kDebugMode) {
                      print('Toucher pour modifier la position');
                    }
                  },
                  child: const Text(
                    'Toucher pour modifier',
                    style: TextStyle(
                      fontFamily: AppTheme.fontMontserrat,
                      fontWeight: FontWeight.normal,
                      color: AppTheme.secondaryColor,
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttributesSection() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _showAttributesModal,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.add, color: AppTheme.secondaryColor),
                  const SizedBox(width: 8),
                  const Text(
                    'Ajouter les attributs',
                    style: TextStyle(
                      fontFamily: AppTheme.fontMontserrat,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryColor,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Container(
                      height: 1,
                      width: double.infinity,
                      color: AppTheme.thirdColor,
                      margin: const EdgeInsets.only(top: 10),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Widgets utilitaires optimisés
  Widget _buildTextField({
    required String label,
    required String msgError,
    FocusNode? focusNode,
    TextEditingController? controller,
  }) {
    return TextFormField(
      focusNode: focusNode,
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: AppTheme.secondaryColor,
          fontFamily: AppTheme.fontMontserrat,
          fontWeight: FontWeight.w600,
        ),
        border: const UnderlineInputBorder(),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.thirdColor),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.secondaryColor, width: 2.0),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return msgError;
        }
        return null;
      },
    );
  }

  Widget _buildText({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.secondaryColor,
            fontFamily: AppTheme.fontMontserrat,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value.isNotEmpty ? value : '------',
          style: TextStyle(
            color:
                value.isNotEmpty
                    ? AppTheme.secondaryColor
                    : AppTheme.thirdColor,
            fontFamily: AppTheme.fontMontserrat,
            fontWeight: FontWeight.normal,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 1,
          width: double.infinity,
          color: AppTheme.thirdColor,
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String msgError,
    required List<String> items,
    required String? selectedValue,
    required Function(String?) onChanged,
  }) {
    // Nettoyage et optimisation des items
    final cleanItems = items.toSet().toList()..sort();
    if (cleanItems.isEmpty) {
      cleanItems.add('Aucun élément disponible');
    }

    return DropdownButtonFormField<String>(
      value: selectedValue,
      isExpanded: true, // ✅ Important pour éviter l'overflow
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: AppTheme.secondaryColor,
          fontFamily: AppTheme.fontMontserrat,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        border: const UnderlineInputBorder(),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.thirdColor),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.secondaryColor, width: 2.0),
        ),
      ),
      items:
          cleanItems.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: SizedBox(
                width: double.infinity, // ✅ Prendre toute la largeur disponible
                child: Text(
                  _truncateText(item, 25), // ✅ Tronquer le texte
                  style: const TextStyle(
                    color: AppTheme.secondaryColor,
                    fontFamily: AppTheme.fontMontserrat,
                    fontWeight: FontWeight.normal,
                    fontSize: 14, // ✅ Réduire la taille de police
                  ),
                  overflow: TextOverflow.ellipsis, // ✅ Points de suspension
                  maxLines: 1, // ✅ Une seule ligne
                ),
              ),
            );
          }).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null ||
            value.isEmpty ||
            value == 'Aucun élément disponible') {
          return msgError;
        }
        return null;
      },
      // ✅ Personnaliser l'icône dropdown
      icon: const Icon(Icons.arrow_drop_down, color: AppTheme.secondaryColor),
      // ✅ Style pour la zone sélectionnée
      selectedItemBuilder: (BuildContext context) {
        return cleanItems.map<Widget>((String item) {
          return Container(
            width: double.infinity,
            alignment: Alignment.centerLeft,
            child: Text(
              _truncateText(
                item,
                20,
              ), // ✅ Texte encore plus court pour la sélection
              style: const TextStyle(
                color: AppTheme.secondaryColor,
                fontFamily: AppTheme.fontMontserrat,
                fontWeight: FontWeight.normal,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          );
        }).toList();
      },
    );
  }

  // ✅ Méthode helper pour tronquer le texte
  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  Widget _buildFieldset(String title) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: AppTheme.fontMontserrat,
            fontWeight: FontWeight.bold,
            color: AppTheme.secondaryColor,
            fontSize: 18,
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Container(
            height: 1,
            width: double.infinity,
            color: AppTheme.thirdColor,
            margin: const EdgeInsets.only(top: 10),
          ),
        ),
      ],
    );
  }

  void _showAttributesModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: AppTheme.thirdColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // En-tête
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 64,
                      height: 34,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondaryColor,
                          padding: EdgeInsets.zero,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          size: 20,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    const Text(
                      'Ajout Attribut',
                      style: TextStyle(
                        fontFamily: AppTheme.fontMontserrat,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondaryColor,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // En-tête colonnes
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Attribut',
                      style: TextStyle(
                        fontFamily: AppTheme.fontMontserrat,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondaryColor,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        height: 1,
                        width: double.infinity,
                        color: AppTheme.thirdColor,
                        margin: const EdgeInsets.only(top: 10),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Valeur',
                      style: TextStyle(
                        fontFamily: AppTheme.fontMontserrat,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondaryColor,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              // Liste des attributs
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 26,
                      vertical: 20,
                    ),
                    child: Column(
                      children: List.generate(
                        8,
                        (index) => _buildAttributeRow(index),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttributeRow(int index) {
    const values = [
      '1922309AHDNAJ',
      '2033410BIEKBK',
      '3144521CJFLCL',
      '4255632DKGMDM',
      '5366743ELHNEE',
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'Test ${index + 1}',
              style: const TextStyle(
                fontFamily: AppTheme.fontMontserrat,
                fontWeight: FontWeight.w600,
                color: AppTheme.secondaryColor,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: _buildDropdownField(
              label: '',
              msgError: 'Veuillez sélectionner une valeur',
              items: values,
              selectedValue: selectedAttributeValues[index],
              onChanged: (value) {
                setState(() {
                  selectedAttributeValues[index] = value!;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: SecondaryButton(
            text: 'Annuler',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: PrimaryButton(
            text: 'Enregistrer',
            icon: Icons.save,
            onPressed: _handleSave,
          ),
        ),
      ],
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      if (mounted) {
        NotificationService.showWarning(
          context,
          title: '⚠️ Formulaire incomplet',
          message: 'Veuillez remplir tous les champs obligatoires',
          duration: const Duration(seconds: 3),
          showProgressBar: false,
        );
      }
      return;
    }

    try {
      final equipmentData = {
        'codeParent': selectedCodeParent,
        'code': _getSelectedCode(selectedCodeParent),
        'feeder': _getSelectedCode(selectedFeeder),
        'infoFeeder': selectedFeeder,
        'famille': _getSelectedCode(selectedFamille),
        'zone': _getSelectedCode(selectedZone),
        'entity': _getSelectedCode(selectedEntity),
        'unite': _getSelectedCode(selectedUnite),
        'centreCharge': _getSelectedCode(selectedCentreCharge),
        'description': _descriptionController.text.trim(),
        'longitude': '12311231',
        'latitude': '12311231',
        'attributes': selectedAttributeValues,
      };

      await context.read<EquipmentProvider>().addEquipment(equipmentData);

      if (mounted && Navigator.canPop(context)) {
        NotificationService.showSuccess(
          context,
          title: '🎉 Succès',
          message: 'Équipement ajouté avec succès !',
          showAction: false,
          duration: const Duration(seconds: 2),
        );

        await Future.delayed(const Duration(milliseconds: 800));

        if (mounted && Navigator.canPop(context)) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de l\'ajout: $e');
      }

      if (mounted) {
        NotificationService.showError(
          context,
          title: '❌ Erreur',
          message: 'Impossible d\'ajouter l\'équipement: $e',
          showAction: true,
          actionText: 'Réessayer',
          onActionPressed: _handleSave,
          duration: const Duration(seconds: 4),
        );
      }
    }
  }
}
