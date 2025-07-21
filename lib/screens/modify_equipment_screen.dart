import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ModifyEquipmentScreen extends StatefulWidget {
  final Map<String, String>?
  equipmentData; // Données de l'équipement à modifier

  const ModifyEquipmentScreen({super.key, this.equipmentData});

  @override
  State<ModifyEquipmentScreen> createState() => _ModifyEquipmentScreenState();
}

class _ModifyEquipmentScreenState extends State<ModifyEquipmentScreen> {
  String? selectedCodeParent;
  String? selectedFeeder;
  String? selectedFamille;
  String? selectedZone;
  String? selectedEntity;
  String? selectedUnite;
  String? selectedCentreCharge;

  final _formKey = GlobalKey<FormState>();
  final FocusNode _descriptionFocusNode = FocusNode();
  final TextEditingController _descriptionController = TextEditingController();

  // Listes des valeurs disponibles pour chaque dropdown
  final List<String> codeParentItems = ['#12345', '#67890', '#54321'];
  final List<String> feederItems = [
    '1250977676AF11TG',
    '8129731276AF11TG',
    '1287377676AF11TG',
  ];
  final List<String> familleItems = ['1676AF11TG', '7676AF11TG', '12996AF11TG', 'Famille A', 'Famille B', 'Famille C'];
  final List<String> zoneItems = ['Dakar', 'Thiès', 'Saint-Louis'];
  final List<String> entityItems = ['1676AF11TG', '7676AF11TG', '2816AF11TG', 'Entité 1', 'Entité 2', 'Entité 3'];
  final List<String> uniteItems = ['Dakar', 'Thiès', 'Saint-Louis', 'Unité 1', 'Unité 2', 'Unité 3'];
  final List<String> centreChargeItems = [
    '1676AF11TG',
    '7676AF11TG',
    '7676AF11TG',
    'Centre 1',
    'Centre 2',
    'Centre 3'
  ];

  List<String> selectedAttributeValues = List.filled(10, '1922309AHDNAJ');

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    if (widget.equipmentData != null) {
      final data = widget.equipmentData!;

      // Fonction helper pour mapper les valeurs reçues avec les valeurs disponibles
      String? mapValueToDropdown(
        String? receivedValue,
        List<String> availableItems,
      ) {
        if (receivedValue == null || receivedValue.isEmpty) return null;

        // Chercher une correspondance exacte
        if (availableItems.contains(receivedValue)) {
          return receivedValue;
        }

        // Chercher une correspondance partielle (optionnel)
        for (String item in availableItems) {
          if (item.toLowerCase().contains(receivedValue.toLowerCase()) ||
              receivedValue.toLowerCase().contains(item.toLowerCase())) {
            return item;
          }
        }

        // Si aucune correspondance, retourner null
        return null;
      }

      // Initialiser les dropdowns avec les valeurs mappées
      selectedFamille = mapValueToDropdown(data['Famille'], familleItems);
      selectedZone = mapValueToDropdown(data['Zone'], zoneItems);
      selectedEntity = mapValueToDropdown(data['Entité'], entityItems);
      selectedUnite = mapValueToDropdown(data['Unité'], uniteItems);
      selectedCentreCharge = mapValueToDropdown(
        data['Centre'],
        centreChargeItems,
      );

      // Initialiser le champ description
      _descriptionController.text = data['Description'] ?? '';

      if (kDebugMode) {
        print('🔄 Données reçues: $data');
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Stack(
        children: [
          // AppBar personnalisée
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(color: AppTheme.secondaryColor),
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
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      const Spacer(),
                      const Text(
                        'Modifier l\'équipement', // Titre modifié
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
          ),

          // Contenu du body avec les champs pré-remplis
          Positioned(
            top: 156,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.only(top: 10, left: 0, right: 0),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(top: 0, right: 16, left: 16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        _fieldsets('Informations parents'),
                        _buildDropdownField(
                          label: 'Code Parent',
                          msgError: 'Veuillez sélectionner un code parent',
                          items: ['#12345', '#67890', '#54321'],
                          selectedValue: selectedCodeParent,
                          onChanged: (value) {
                            setState(() {
                              selectedCodeParent = value;
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                        _rowOne(),
                        const SizedBox(height: 40),
                        _fieldsets('Informations'),
                        const SizedBox(height: 10),
                        _rowTwo(),
                        const SizedBox(height: 20),
                        _rowThree(),
                        const SizedBox(height: 20),
                        _rowFour(),
                        const SizedBox(height: 20),
                        _rowFive(),
                        const SizedBox(height: 40),
                        _fieldsets('Informations de positionnement'),
                        const SizedBox(height: 10),
                        _rowSix(),
                        const SizedBox(height: 20),
                        _rowSeven(),
                        const SizedBox(height: 20),
                        _rowEight(),
                        const SizedBox(height: 20),
                        _buildActionButtons(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
          style: TextStyle(
            color: AppTheme.secondaryColor,
            fontFamily: AppTheme.fontMontserrat,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value.isNotEmpty
              ? value
              : '------', // Affiche '-' si la valeur est vide
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
          // margin: const EdgeInsets.only(top: 4),
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
    items = items.toSet().toList(); // Supprimer les doublons
    items.sort(); // Trier les éléments
    if (items.isEmpty) {
      items.add('Aucun élément disponible'); // Ajouter un élément par défaut
    }

    return DropdownButtonFormField<String>(
      value: selectedValue,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: AppTheme.secondaryColor,
          fontFamily: AppTheme.fontMontserrat,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        border: const UnderlineInputBorder(),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.thirdColor),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.secondaryColor, width: 2.0),
        ),
      ),
      items:
          items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: TextStyle(
                  color: AppTheme.secondaryColor,
                  fontFamily: AppTheme.fontMontserrat,
                  fontWeight: FontWeight.normal,
                ),
              ),
            );
          }).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return msgError;
        }
        return null;
      },
    );
  }

  Widget _fieldsets(String title) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(
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
            margin: EdgeInsets.only(top: 10),
          ),
        ),
      ],
    );
  }

  Widget _rowOne() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _buildDropdownField(
            label: 'Feeder',
            msgError: 'Veuillez sélectionner un feeder',
            items: [
              '1250977676AF11TG',
              '8129731276AF11TG',
              '1287377676AF11TG',
            ], // Liste des options
            selectedValue: selectedFeeder,
            onChanged: (value) {
              setState(() {
                selectedFeeder = value; // Met à jour la valeur sélectionnée
              });
            },
          ),
        ),
        SizedBox(width: 10), // Espace entre les champs
        Expanded(
          child: _buildText(label: 'Info Feeder', value: selectedFeeder ?? ''),
        ),
      ],
    );
  }

  Widget _rowTwo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: _buildText(label: 'Code', value: '#12345')),
        const SizedBox(width: 10),
        Expanded(
          child: _buildDropdownField(
            label: 'Famille',
            msgError: 'Veuillez sélectionner une famille',
            items: familleItems, // Utiliser la liste définie
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

  Widget _rowThree() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _buildDropdownField(
            label: 'Zone',
            msgError: 'Veuillez sélectionner une zone',
            items: zoneItems, // Utiliser la liste définie
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
            items: entityItems, // Utiliser la liste définie
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

  Widget _rowFour() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _buildDropdownField(
            label: 'Unité',
            msgError: 'Veuillez sélectionner une unité',
            items: uniteItems, // Utiliser la liste définie
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
            items: centreChargeItems, // Utiliser la liste définie
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

  Widget _rowFive() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _buildTextField(
            label: 'Description',
            msgError: 'Veuillez entrer la description',
            focusNode: _descriptionFocusNode,
            controller: _descriptionController,
          ),
        ),
      ],
    );
  }

  Widget _rowSix() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: _buildText(label: 'Longitude', value: '12311231')),
        SizedBox(width: 10), // Espace entre les champs
        Expanded(child: _buildText(label: 'Latitude', value: '12311231')),
      ],
    );
  }

  Widget _rowSeven() {
    return // Carte simulée
    Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: const DecorationImage(
          image: AssetImage('assets/images/map.png'),
          fit: BoxFit.cover,
        ),
        color: Colors.grey[300], // Couleur de fallback
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
          // Background simulé (en attendant l'API)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primaryColor75, AppTheme.primaryColor75],
              ),
            ),
          ),

          // Contenu de la carte
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
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
                    // Action pour modifier la position
                    if (kDebugMode) {
                      print('Toucher pour modifier la position');
                    }
                  },
                  child: Text(
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

  Widget _rowEight() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              // Afficher le modal en bas de l'écran
              showModalBottomSheet(
                context: context,
                isScrollControlled: true, // Permet de contrôler la hauteur
                backgroundColor: Colors.transparent,
                builder: (BuildContext context) {
                  return Container(
                    height:
                        MediaQuery.of(context).size.height *
                        0.7, // 70% de l'écran
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Handle bar pour indiquer que c'est draggable
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          height: 4,
                          width: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.thirdColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),

                        // En-tête avec bouton retour et titre
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                },
                                child: SizedBox(
                                  width: 64, // Largeur fixe
                                  height: 34, // Hauteur fixe
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.secondaryColor,
                                      padding:
                                          EdgeInsets
                                              .zero, // Supprime les marges internes
                                    ),
                                    child: Icon(
                                      Icons.arrow_back,
                                      size: 20, // Taille de l'icône
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Text(
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

                        // En-tête avec colonnes Attribut et Valeur
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
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
                                  margin: EdgeInsets.only(top: 10),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
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

                        // const SizedBox(height: 20),

                        // Liste des attributs scrollable
                        Expanded(
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 26,
                                vertical: 20,
                              ),
                              child: Column(
                                children: List.generate(
                                  8, // Nombre d'attributs comme dans l'image
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
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.add, color: AppTheme.secondaryColor),
                  const SizedBox(width: 8),
                  Text(
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

  // Méthode pour construire chaque ligne d'attribut
  Widget _buildAttributeRow(int index) {
    List<String> values = [
      '1922309AHDNAJ',
      '2033410BIEKBK',
      '3144521CJFLCL',
      '4255632DKGMDM',
      '5366743ELHNEE',
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Attribut (côté gauche)
        Expanded(
          flex: 2,
          child: Text(
            'Test',
            style: TextStyle(
              fontFamily: AppTheme.fontMontserrat,
              fontWeight: FontWeight.w600,
              color: AppTheme.secondaryColor,
              fontSize: 16,
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Valeur avec dropdown (côté droit)
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
    );
  }

  Widget _buildButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.secondaryColor,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTheme.fontMontserrat,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [_buildCancelButton(), _buildSaveButton()],
    );
  }

  Widget _buildCancelButton() {
    return _buildButton('Annuler', () {
      Navigator.of(context).pop();
    });
  }

  Widget _buildSaveButton() {
    return _buildButton('Modifier', () {
      if (_formKey.currentState!.validate()) {
        // Logique pour sauvegarder les modifications
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Équipement modifié avec succès !'),
            backgroundColor: Colors.green,
          ),
        );

        // Retourner à l'écran précédent
        Navigator.of(context).pop();
      }
    });
  }
}
