import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/equipment_provider.dart';

class EquipmentFormDialog extends StatefulWidget {
  final Map<String, dynamic>? equipmentToEdit;

  const EquipmentFormDialog({super.key, this.equipmentToEdit});

  @override
  State<EquipmentFormDialog> createState() => _EquipmentFormDialogState();
}

class _EquipmentFormDialogState extends State<EquipmentFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _codeController;
  late TextEditingController _descriptionController;
  late TextEditingController _familleController;
  late TextEditingController _zoneController;
  late TextEditingController _entityController;
  late TextEditingController _costcentreController;
  late TextEditingController _uniteController;
  late TextEditingController _feederController;
  late TextEditingController _codeParentController;

  bool _isSaving = false;
  bool get _isEditMode => widget.equipmentToEdit != null;

  @override
  void initState() {
    super.initState();
    final eq = widget.equipmentToEdit ?? {};
    _codeController = TextEditingController(text: eq['code']?.toString() ?? '');
    _descriptionController = TextEditingController(text: eq['description']?.toString() ?? '');
    _familleController = TextEditingController(text: eq['famille']?.toString() ?? 'TRANSFORMATEUR');
    _zoneController = TextEditingController(text: eq['zone']?.toString() ?? 'ZONE-A');
    _entityController = TextEditingController(text: eq['entity']?.toString() ?? 'SDDRCO2');
    _costcentreController = TextEditingController(text: eq['centreCharge']?.toString() ?? eq['centre_charge']?.toString() ?? 'CC_MAIN');
    _uniteController = TextEditingController(text: eq['unite']?.toString() ?? 'DISTRIBUTION');
    _feederController = TextEditingController(text: eq['feeder']?.toString() ?? 'FEEDER_01');
    _codeParentController = TextEditingController(text: eq['codeParent']?.toString() ?? '');
  }

  @override
  void dispose() {
    _codeController.dispose();
    _descriptionController.dispose();
    _familleController.dispose();
    _zoneController.dispose();
    _entityController.dispose();
    _costcentreController.dispose();
    _uniteController.dispose();
    _feederController.dispose();
    _codeParentController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final provider = Provider.of<EquipmentProvider>(context, listen: false);

      final Map<String, dynamic> equipmentData = {
        'code': _codeController.text.trim(),
        'description': _descriptionController.text.trim(),
        'famille': _familleController.text.trim(),
        'zone': _zoneController.text.trim(),
        'entity': _entityController.text.trim(),
        'centre_charge': _costcentreController.text.trim(),
        'unite': _uniteController.text.trim(),
        'feeder': _feederController.text.trim(),
        'code_parent': _codeParentController.text.trim(),
      };

      if (_isEditMode) {
        final id = widget.equipmentToEdit!['id']?.toString() ?? widget.equipmentToEdit!['code']?.toString() ?? '';
        await provider.updateEquipment(id, equipmentData);
      } else {
        await provider.createEquipment(equipmentData);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur d\'enregistrement: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isEditMode ? 'Modifier l\'équipement' : 'Ajouter un équipement',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF015CC0),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 10),
                _buildTextField(
                  label: 'Code Équipement *',
                  controller: _codeController,
                  readOnly: _isEditMode,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Obligatoire' : null,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  label: 'Description / Nom *',
                  controller: _descriptionController,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Obligatoire' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        label: 'Famille *',
                        controller: _familleController,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Obligatoire' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        label: 'Zone *',
                        controller: _zoneController,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Obligatoire' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        label: 'Entité *',
                        controller: _entityController,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Obligatoire' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        label: 'Centre de charge *',
                        controller: _costcentreController,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Obligatoire' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        label: 'Unité / Fonction',
                        controller: _uniteController,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        label: 'Feeder',
                        controller: _feederController,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _submitForm,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save, size: 18),
                      label: Text(_isEditMode ? 'Enregistrer' : 'Créer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF015CC0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF015CC0)),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          validator: validator,
          readOnly: readOnly,
          style: TextStyle(fontSize: 14, color: readOnly ? Colors.grey[600] : Colors.black87),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
      ],
    );
  }
}
