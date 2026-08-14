import 'package:flutter/material.dart';
import 'package:appmobilegmao/models/work_request.dart';

/// =====================================================================
/// CREATION DI (Demandes d'Intervention) - SAUVEGARDE DU CODE D'ORIGINE
/// Pour réactiver l'écran de création d'origine, supprimez les commentaires /* ... */
/// =====================================================================

class DICreateScreen extends StatefulWidget {
  final WorkRequest? requestToEdit;

  const DICreateScreen({super.key, this.requestToEdit});

  @override
  State<DICreateScreen> createState() => _DICreateScreenState();
}

class _DICreateScreenState extends State<DICreateScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.requestToEdit != null ? 'Modifier la DI' : 'Créer une DI'),
        backgroundColor: const Color(0xFF0F1B80),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.edit_note_outlined, size: 64, color: Color(0xFF0F1B80)),
              SizedBox(height: 16),
              Text(
                "Écran de création / modification DI",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                "Code d'origine sauvegardé en commentaire pour le développeur du module.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* =====================================================================
CODE D'ORIGINE COMPLET DE DI_CREATE_SCREEN (CONSERVÉ EN BACKUP) :
======================================================================== */
/*
import 'dart:math';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';
import 'package:appmobilegmao/widgets/custom_app_bar.dart';

  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  bool get _isEditMode => widget.requestToEdit != null;

  // General tab controller/values
  String _selectedEquipment = 'LM0308FAFROTRF1';
  String _equipmentDescription = 'POSTE FANN FROBENIUS - TRANSFORMATEUR';
  String _priority = 'URGENT';
  String _destinataire = 'UMP-DV';
  String _zone = 'DAKAR';
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _supervisorController = TextEditingController();

  // Probleme tab values
  final TextEditingController _descriptionController = TextEditingController();
  String? _attachedFileName;

  // Plus tab values
  String _costCentre = 'DD303';
  String _actionEntity = 'SDDV';
  final TextEditingController _mailsController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  // Diagnostic tab values
  String _symptom = 'DECHARGE PARTIELLE SUR CELLULE';
  String _defect = 'ECHAUFFEMENT';
  String _cause = 'EFFET CORONA';
  String _remedy = 'REMPLACEMENT DES COMPOSANTS';

  // Remarques tab values
  final TextEditingController _remarksController = TextEditingController();

  final Map<String, String> _equipments = {
    'LM0308FAFROTRF1': 'POSTE FANN FROBENIUS - TRANSFORMATEUR',
    'LM0905PACONSU1': 'POSTE CONSULAT ITALIE - ARMOIRE BT',
    'LM0902ALALBTR1': 'CABLE LIAISON BT HTA - DEPART SALY',
    'LM1201PACL12TR2': 'POSTE ALASSANE DJIGO CELLULE PROTEC',
    'LM0312PAFANN1': 'POSTE FANN RESIDENCE - DISJONCTEUR',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    if (_isEditMode) {
      final req = widget.requestToEdit!;
      _selectedEquipment = req.dinqEquipment;
      _equipmentDescription = req.dinqEquipmentDescription;
      _priority = req.dinqPriority ?? 'URGENT';
      _destinataire = req.dinqActionEntity ?? 'UMP-DV';
      _zone = req.dinqZone ?? 'DAKAR';
      _codeController.text = req.dinqCode;
      _supervisorController.text = req.dinqSupervisor ?? 'ERIC DASYLVA CARDOZO';
      _descriptionController.text = req.dinqDescription;
      _costCentre = req.dinqCostcentre ?? 'DD303';
      _actionEntity = req.dinqActionEntity ?? 'SDDV';
      _mailsController.text = req.mailsToNotify ?? '';
      _attachedFileName = 'RAPPORT_ULTRASON_VISITE.pdf';
      
      if (req.dateDebut != null) {
        _startDate = DateTime.tryParse(req.dateDebut!);
      }
      if (req.dateFin != null) {
        _endDate = DateTime.tryParse(req.dateFin!);
      }
    } else {
      _supervisorController.text = 'ERIC DASYLVA CARDOZO';
      _startDate = DateTime.now();
      _endDate = DateTime.now().add(const Duration(hours: 4));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    _supervisorController.dispose();
    _descriptionController.dispose();
    _mailsController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final randomId = _isEditMode ? widget.requestToEdit!.pkWorkRequest : (Random().nextInt(900) + 100);
      
      final updatedRequest = WorkRequest(
        pkWorkRequest: randomId,
        dinqCode: _isEditMode ? widget.requestToEdit!.dinqCode : 'DI00062$randomId',
        dinqUserStatus: _isEditMode ? widget.requestToEdit!.dinqUserStatus : '0. Créée',
        dinqEquipment: _selectedEquipment,
        dinqEquipmentDescription: _equipmentDescription,
        dinqDescription: _descriptionController.text,
        dinqPriority: _priority,
        dinqAskDate: _isEditMode ? widget.requestToEdit!.dinqAskDate : DateTime.now().toIso8601String(),
        dinqSupervisor: _supervisorController.text,
        dinqZone: _zone,
        dinqActionEntity: _actionEntity,
        dinqRequestEntity: _destinataire,
        dinqCostcentre: _costCentre,
        mailsToNotify: _mailsController.text.isNotEmpty ? _mailsController.text : null,
        dateDebut: _startDate?.toIso8601String(),
        dateFin: _endDate?.toIso8601String(),
      );

      Navigator.pop(context, updatedRequest);
    } else {
      // Navigate to Problem tab if description is empty
      if (_descriptionController.text.trim().isEmpty) {
        _tabController.animateTo(1);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez saisir la description de la panne dans l\'onglet Problème.')),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        backgroundColor: Colors.white,
        iconColor: const Color(0xFF2B1D4C),
        title: _isEditMode ? 'Modifier la DI ${_codeController.text}' : 'Créer une DI',
        bottom: CustomTabBar(
          tabController: _tabController,
          tabLabels: const [
            'Général',
            'Problème',
            'Plus',
            'Diagnostic',
            'Remarques',
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            // 🗂️ TAB 1: GENERAL
            _buildGeneralTab(spacing, responsive),
            // 🗂️ TAB 2: PROBLEME
            _buildProblemeTab(spacing, responsive),
            // 🗂️ TAB 3: PLUS
            _buildPlusTab(spacing, responsive),
            // 🗂️ TAB 4: DIAGNOSTIC
            _buildDiagnosticTab(spacing, responsive),
            // 🗂️ TAB 5: REMARQUES
            _buildRemarquesTab(spacing, responsive),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: spacing.custom(all: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
        ),
        child: ElevatedButton(
          onPressed: _submitForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.secondaryColor,
            padding: spacing.custom(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            _isEditMode ? 'Enregistrer les modifications' : 'Créer la Demande d\'Intervention',
            style: TextStyle(
              fontFamily: AppTheme.fontMontserrat,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: responsive.sp(14),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralTab(ResponsiveSpacing spacing, Responsive responsive) {
    return ListView(
      padding: spacing.custom(all: 16),
      children: [
        _buildSectionCard(context, 'Équipement', [
          DropdownButtonFormField<String>(
            initialValue: _selectedEquipment,
            decoration: InputDecoration(
              labelText: 'Sélectionner l\'équipement',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: _equipments.keys.map((code) {
              return DropdownMenuItem<String>(
                value: code,
                child: Text('$code (${code.substring(0, min(8, code.length))}...)'),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedEquipment = val!;
                _equipmentDescription = _equipments[val]!;
              });
            },
          ),
          SizedBox(height: spacing.medium),
          Text(
            'Description : $_equipmentDescription',
            style: TextStyle(
              fontFamily: AppTheme.fontRoboto,
              fontSize: responsive.sp(13),
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ]),
        SizedBox(height: spacing.medium),
        _buildSectionCard(context, 'Paramètres initiaux', [
          DropdownButtonFormField<String>(
            initialValue: _priority,
            decoration: InputDecoration(
              labelText: 'Priorité',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: const [
              DropdownMenuItem(value: 'URGENT', child: Text('Urgent')),
              DropdownMenuItem(value: 'NORMAL', child: Text('Normal')),
              DropdownMenuItem(value: 'DEPL_SUPPORT', child: Text('Déplacement Support')),
            ],
            onChanged: (val) {
              setState(() {
                _priority = val!;
              });
            },
          ),
          SizedBox(height: spacing.medium),
          DropdownButtonFormField<String>(
            initialValue: _destinataire,
            decoration: InputDecoration(
              labelText: 'Destinataire / Unité',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: const [
              DropdownMenuItem(value: 'UMP-DV', child: Text('UMP-DV')),
              DropdownMenuItem(value: 'SEM', child: Text('SEM')),
              DropdownMenuItem(value: 'UED/N-DV', child: Text('UED/N-DV')),
            ],
            onChanged: (val) {
              setState(() {
                _destinataire = val!;
              });
            },
          ),
          SizedBox(height: spacing.medium),
          TextFormField(
            controller: _supervisorController,
            decoration: InputDecoration(
              labelText: 'Demandeur / Superviseur',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _buildProblemeTab(ResponsiveSpacing spacing, Responsive responsive) {
    return ListView(
      padding: spacing.custom(all: 16),
      children: [
        _buildSectionCard(context, 'Détail de l\'anomalie', [
          TextFormField(
            controller: _descriptionController,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: 'Description de la panne (Obligatoire)',
              hintText: 'Décrivez précisément l\'anomalie constatée...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'La description de la panne est obligatoire.';
              }
              return null;
            },
          ),
        ]),
        SizedBox(height: spacing.medium),
        _buildSectionCard(context, 'Document & Rapport joint', [
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _attachedFileName = 'RAPPORT_ULTRASON_PHOTO.jpg';
                  });
                },
                icon: const Icon(Icons.attach_file, color: Colors.white),
                label: const Text('Joindre un fichier'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
              SizedBox(width: spacing.medium),
              Expanded(
                child: Text(
                  _attachedFileName ?? 'Aucun fichier joint',
                  style: TextStyle(
                    fontStyle: _attachedFileName == null ? FontStyle.italic : FontStyle.normal,
                    color: _attachedFileName == null ? Colors.grey : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_attachedFileName != null)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _attachedFileName = null;
                    });
                  },
                ),
            ],
          ),
        ]),
      ],
    );
  }

  Widget _buildPlusTab(ResponsiveSpacing spacing, Responsive responsive) {
    return ListView(
      padding: spacing.custom(all: 16),
      children: [
        _buildSectionCard(context, 'Planification', [
          ListTile(
            title: const Text('Date début prévue', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(_startDate != null ? _startDate!.toIso8601String().substring(0, 10) : 'Choisir une date'),
            trailing: const Icon(Icons.calendar_month, color: AppTheme.secondaryColor),
            onTap: () => _selectDate(context, true),
          ),
          const Divider(),
          ListTile(
            title: const Text('Date fin prévue', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(_endDate != null ? _endDate!.toIso8601String().substring(0, 10) : 'Choisir une date'),
            trailing: const Icon(Icons.calendar_month, color: AppTheme.secondaryColor),
            onTap: () => _selectDate(context, false),
          ),
        ]),
        SizedBox(height: spacing.medium),
        _buildSectionCard(context, 'Localisation & Répartition', [
          DropdownButtonFormField<String>(
            initialValue: _zone,
            decoration: InputDecoration(
              labelText: 'Zone',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: const [
              DropdownMenuItem(value: 'DAKAR', child: Text('Dakar')),
              DropdownMenuItem(value: 'THIES', child: Text('Thiès')),
              DropdownMenuItem(value: 'KAOLACK', child: Text('Kaolack')),
            ],
            onChanged: (val) {
              setState(() {
                _zone = val!;
              });
            },
          ),
          SizedBox(height: spacing.medium),
          DropdownButtonFormField<String>(
            initialValue: _costCentre,
            decoration: InputDecoration(
              labelText: 'Centre de charges',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: const [
              DropdownMenuItem(value: 'DD303', child: Text('DD303 - G. Équipement')),
              DropdownMenuItem(value: 'DD304', child: Text('DD304 - Réseau')),
            ],
            onChanged: (val) {
              setState(() {
                _costCentre = val!;
              });
            },
          ),
          SizedBox(height: spacing.medium),
          DropdownButtonFormField<String>(
            initialValue: _actionEntity,
            decoration: InputDecoration(
              labelText: 'Entité de réalisation',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: const [
              DropdownMenuItem(value: 'SDDV', child: Text('SDDV - SERVICE DAKAR VILLE')),
              DropdownMenuItem(value: 'SEM', child: Text('SEM - SERVICE ELEC METRO')),
            ],
            onChanged: (val) {
              setState(() {
                _actionEntity = val!;
              });
            },
          ),
        ]),
        SizedBox(height: spacing.medium),
        _buildSectionCard(context, 'Mails à notifier', [
          TextFormField(
            controller: _mailsController,
            decoration: InputDecoration(
              labelText: 'Adresses courriel',
              hintText: 'adresse1@senelec.sn;adresse2@senelec.sn',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _buildDiagnosticTab(ResponsiveSpacing spacing, Responsive responsive) {
    return ListView(
      padding: spacing.custom(all: 16),
      children: [
        _buildSectionCard(context, 'Arbre Diagnostic', [
          DropdownButtonFormField<String>(
            initialValue: _symptom,
            decoration: InputDecoration(
              labelText: 'Symptôme',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: const [
              DropdownMenuItem(value: 'DECHARGE PARTIELLE SUR CELLULE', child: Text('Décharge partielle sur cellule')),
              DropdownMenuItem(value: 'BRUIT ANORMAL', child: Text('Bruit anormal')),
              DropdownMenuItem(value: 'FUITE D\'HUILE', child: Text('Fuite d\'huile')),
            ],
            onChanged: (val) {
              setState(() {
                _symptom = val!;
              });
            },
          ),
          SizedBox(height: spacing.medium),
          DropdownButtonFormField<String>(
            initialValue: _defect,
            decoration: InputDecoration(
              labelText: 'Défaut',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: const [
              DropdownMenuItem(value: 'ECHAUFFEMENT', child: Text('Échauffement')),
              DropdownMenuItem(value: 'COURT-CIRCUIT', child: Text('Court-circuit')),
              DropdownMenuItem(value: 'ISOLEMENT DEGRADE', child: Text('Isolement dégradé')),
            ],
            onChanged: (val) {
              setState(() {
                _defect = val!;
              });
            },
          ),
          SizedBox(height: spacing.medium),
          DropdownButtonFormField<String>(
            initialValue: _cause,
            decoration: InputDecoration(
              labelText: 'Cause',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: const [
              DropdownMenuItem(value: 'EFFET CORONA', child: Text('Effet corona')),
              DropdownMenuItem(value: 'USURE NATURELLE', child: Text('Usure naturelle')),
              DropdownMenuItem(value: 'SURTENSION', child: Text('Surtension')),
            ],
            onChanged: (val) {
              setState(() {
                _cause = val!;
              });
            },
          ),
          SizedBox(height: spacing.medium),
          DropdownButtonFormField<String>(
            initialValue: _remedy,
            decoration: InputDecoration(
              labelText: 'Remède',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: const [
              DropdownMenuItem(value: 'REMPLACEMENT DES COMPOSANTS', child: Text('Remplacement des composants')),
              DropdownMenuItem(value: 'NETTOYAGE ET SERRAGE', child: Text('Nettoyage et resserrage')),
              DropdownMenuItem(value: 'APPOINT D\'HUILE', child: Text('Appoint d\'huile')),
            ],
            onChanged: (val) {
              setState(() {
                _remedy = val!;
              });
            },
          ),
        ]),
      ],
    );
  }

  Widget _buildRemarquesTab(ResponsiveSpacing spacing, Responsive responsive) {
    return ListView(
      padding: spacing.custom(all: 16),
      children: [
        _buildSectionCard(context, 'Remarques complémentaires', [
          TextFormField(
            controller: _remarksController,
            maxLines: 8,
            decoration: InputDecoration(
              labelText: 'Remarque de l\'exécutant / demandeur',
              hintText: 'Saisissez vos remarques ou notes complémentaires ici...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _buildSectionCard(BuildContext context, String title, List<Widget> children) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    return Container(
      padding: spacing.custom(all: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: AppTheme.fontMontserrat,
              fontWeight: FontWeight.bold,
              color: AppTheme.secondaryColor,
              fontSize: responsive.sp(14),
            ),
          ),
          const Divider(height: 24),
          ...children,
        ],
    );
  }
}
*/

