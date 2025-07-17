import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AddEquipmentScreen extends StatefulWidget {
  const AddEquipmentScreen({super.key});

  @override
  State<AddEquipmentScreen> createState() => _AddEquipmentScreenState();
}

class _AddEquipmentScreenState extends State<AddEquipmentScreen> {
  String? selectedCodeParent; // Variable pour stocker la valeur sélectionnée
  String? selectedFeeder;
  String? selectedFamille;
  String? selectedZone;
  String? selectedEntity;
  String? selectedUnite;
  String? selectedCentreCharge;

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
                    // spacing: 20,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () {
                          Navigator.pop(context); // Retour à l'écran précédent
                        },
                      ),
                      const Spacer(), // Ajoute un espace flexible avant le texte
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
                      const Spacer(), // Ajoute un espace flexible avant le texte
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Contenu du body
          Positioned(
            top: 156, // Commence après l'AppBar
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.only(
                top: 10, // Espace pour la carte qui déborde
                left: 0,
                right: 0,
              ),
              child: SingleChildScrollView(
                // Permet de rendre le contenu scrollable
                child: Padding(
                  padding: const EdgeInsets.only(top: 0, right: 16, left: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      _fieldsets('Informations parents'),
                      _buildDropdownField(
                        label: 'Code Parent',
                        msgError: 'Veuillez sélectionner un code parent',
                        items: [
                          '#12345',
                          '#67890',
                          '#54321',
                        ], // Liste des options
                        selectedValue: selectedCodeParent,
                        onChanged: (value) {
                          setState(() {
                            selectedCodeParent =
                                value; // Met à jour la valeur sélectionnée
                          });
                        },
                      ),
                      SizedBox(height: 20),
                      _rowOne(),
                      SizedBox(height: 40),
                      _fieldsets('Informations'),
                      SizedBox(height: 10),
                      _rowTwo(),
                      SizedBox(height: 20),
                      _rowThree(),
                      SizedBox(height: 20),
                      _rowFour(),
                      SizedBox(height: 20),
                      _rowFive(),
                      SizedBox(height: 40),
                      _fieldsets('Informations de positionnement'),
                      SizedBox(height: 10),
                      _rowSix(),
                      SizedBox(height: 20),
                      _rowSeven(),
                      SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({required String label, required String msgError}) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: AppTheme.secondaryColor,
          fontFamily: AppTheme.fontMontserrat,
          fontWeight: FontWeight.w600,
        ),
        border: UnderlineInputBorder(),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.thirdColor),
        ),
        focusedBorder: UnderlineInputBorder(
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
    if (value.isEmpty) {
      // Si la valeur est vide, créer un champ de texte classique
      return TextFormField(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: AppTheme.secondaryColor,
            fontFamily: AppTheme.fontMontserrat,
            fontWeight: FontWeight.w600,
          ),
          border: const UnderlineInputBorder(),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppTheme.thirdColor),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppTheme.secondaryColor, width: 2.0),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Veuillez entrer une valeur pour $label';
          }
          return null;
        },
      );
    } else {
      // Si la valeur n'est pas vide, afficher un champ avec la valeur existante
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontMontserrat,
              fontWeight: FontWeight.w600,
              color: AppTheme.secondaryColor,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppTheme.fontMontserrat,
              fontWeight: FontWeight.normal,
              color: AppTheme.thirdColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(height: 1, color: AppTheme.thirdColor),
        ],
      );
    }
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
        Container(height: 1, color: AppTheme.thirdColor),
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
        SizedBox(width: 10), // Espace entre les champs
        Expanded(
          child: _buildDropdownField(
            label: 'Famille',
            msgError: 'Veuillez sélectionner une famille',
            items: [
              '1676AF11TG',
              '7676AF11TG',
              '12996AF11TG',
            ], // Liste des options
            selectedValue: selectedFamille,
            onChanged: (value) {
              setState(() {
                selectedFamille = value; // Met à jour la valeur sélectionnée
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
            items: ['Dakar', 'Thiès', 'Saint-Louis'], // Liste des options
            selectedValue: selectedZone,
            onChanged: (value) {
              setState(() {
                selectedZone = value; // Met à jour la valeur sélectionnée
              });
            },
          ),
        ),
        SizedBox(width: 10), // Espace entre les champs
        Expanded(
          child: _buildDropdownField(
            label: 'Entité',
            msgError: 'Veuillez sélectionner une entité',
            items: [
              '1676AF11TG',
              '7676AF11TG',
              '2816AF11TG',
            ], // Liste des options
            selectedValue: selectedEntity,
            onChanged: (value) {
              setState(() {
                selectedEntity = value; // Met à jour la valeur sélectionnée
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
            items: ['Dakar', 'Thiès', 'Saint-Louis'], // Liste des options
            selectedValue: selectedUnite,
            onChanged: (value) {
              setState(() {
                selectedUnite = value; // Met à jour la valeur sélectionnée
              });
            },
          ),
        ),
        SizedBox(width: 10), // Espace entre les champs
        Expanded(
          child: _buildDropdownField(
            label: 'Centre de Charge',
            msgError: 'Veuillez sélectionner un centre de charge',
            items: [
              '1676AF11TG',
              '7676AF11TG',
              '7676AF11TG',
            ], // Liste des options
            selectedValue: selectedCentreCharge,
            onChanged: (value) {
              setState(() {
                selectedCentreCharge =
                    value; // Met à jour la valeur sélectionnée
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
}
