import 'package:flutter/material.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';

class NewDiagnosticScreen extends StatefulWidget {
  const NewDiagnosticScreen({super.key});

  @override
  State<NewDiagnosticScreen> createState() => _NewDiagnosticScreenState();
}

class _NewDiagnosticScreenState extends State<NewDiagnosticScreen> {
  int _selectedRadio = 0; // 0 for 'Fichier base', 1 for 'Famille'

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(responsive.spacing(60)),
        child: AppBar(
          backgroundColor: AppTheme.secondaryColor,
          elevation: 0,
          leading: Padding(
            padding: EdgeInsets.all(responsive.spacing(8)),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(responsive.spacing(8)),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.close, color: Colors.white, size: responsive.iconSize(20)),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          title: Text(
            'Nouveau diagnostic',
            style: TextStyle(
              fontFamily: AppTheme.fontMontserrat,
              color: Colors.white,
              fontSize: responsive.sp(16),
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            Padding(
              padding: EdgeInsets.only(right: responsive.spacing(12), top: responsive.spacing(12), bottom: responsive.spacing(12)),
              child: ElevatedButton.icon(
                onPressed: () {
                  // Save action
                  Navigator.pop(context);
                },
                icon: Icon(Icons.check, color: AppTheme.secondaryColor, size: responsive.iconSize(16)),
                label: Text(
                  'Enregistrer',
                  style: TextStyle(
                    color: AppTheme.secondaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: responsive.sp(13),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(responsive.spacing(8)),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: responsive.spacing(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: spacing.custom(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Section
            Container(
              padding: spacing.custom(all: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(responsive.spacing(12)),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Date du rapport',
                          style: TextStyle(color: Colors.grey[600], fontSize: responsive.sp(13)),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: responsive.spacing(12), vertical: responsive.spacing(10)),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(responsive.spacing(6)),
                            border: Border.all(color: const Color(0xFFFCD34D)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '10/08/2026 00:09',
                                style: TextStyle(
                                  color: const Color(0xFFB45309),
                                  fontWeight: FontWeight.bold,
                                  fontSize: responsive.sp(13),
                                ),
                              ),
                              Icon(Icons.calendar_today_outlined, color: const Color(0xFFD97706), size: responsive.iconSize(16)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.medium),
                  Row(
                    children: [
                      _buildRadioOption('0. Fichier base', 0, responsive),
                      SizedBox(width: spacing.medium),
                      _buildRadioOption('1. Famille', 1, responsive),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: spacing.medium),

            // Middle Section (Symptom, Defect, etc.)
            Container(
              padding: spacing.custom(all: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(responsive.spacing(12)),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  _buildFormGroup('Symptôme', 'Description du symptôme...', responsive, spacing),
                  SizedBox(height: spacing.medium),
                  _buildFormGroup('Défaut', 'Description du défaut...', responsive, spacing),
                  SizedBox(height: spacing.medium),
                  _buildFormGroup('Cause', 'Description de la cause...', responsive, spacing),
                  SizedBox(height: spacing.medium),
                  _buildFormGroup('Remède', 'Description du remède...', responsive, spacing),
                ],
              ),
            ),
            SizedBox(height: spacing.medium),

            // Bottom Section (Duration, OT)
            Container(
              padding: spacing.custom(all: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(responsive.spacing(12)),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Text('Durée', style: TextStyle(color: Colors.grey[600], fontSize: responsive.sp(13))),
                      ),
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: responsive.spacing(12), vertical: responsive.spacing(10)),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(responsive.spacing(6)),
                                  border: Border.all(color: const Color(0xFFFCD34D)),
                                ),
                                child: Text(
                                  '0,00',
                                  style: TextStyle(
                                    color: const Color(0xFFB45309),
                                    fontWeight: FontWeight.bold,
                                    fontSize: responsive.sp(13),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: spacing.small),
                            Expanded(
                              flex: 1,
                              child: Text('Val. compte', style: TextStyle(color: Colors.grey[600], fontSize: responsive.sp(11)), maxLines: 1, overflow: TextOverflow.ellipsis,),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.medium),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Text('N° d\'OT', style: TextStyle(color: Colors.grey[600], fontSize: responsive.sp(13))),
                      ),
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: responsive.spacing(12), vertical: responsive.spacing(10)),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(responsive.spacing(6)),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Icon(Icons.north_east, color: Colors.grey[400], size: responsive.iconSize(14)),
                                    SizedBox(width: responsive.spacing(4)),
                                    Icon(Icons.keyboard_arrow_down, color: Colors.grey[400], size: responsive.iconSize(16)),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: spacing.small),
                            Expanded(
                              flex: 1,
                              child: Text('Coût', style: TextStyle(color: Colors.grey[600], fontSize: responsive.sp(12))),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: spacing.medium),

            // Remarks Section
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(responsive.spacing(12)),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: spacing.custom(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(responsive.spacing(12))),
                    ),
                    child: Text(
                      'REMARQUES',
                      style: TextStyle(
                        color: AppTheme.secondaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: responsive.sp(13),
                      ),
                    ),
                  ),
                  Container(
                    height: responsive.spacing(120),
                    padding: spacing.custom(all: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Saisir des remarques...',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: responsive.sp(13),
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.attach_file, color: Colors.grey[400], size: responsive.iconSize(20)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: spacing.large),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioOption(String text, int value, Responsive responsive) {
    bool isSelected = _selectedRadio == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRadio = value;
        });
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            color: isSelected ? AppTheme.secondaryColor : Colors.grey[400],
            size: responsive.iconSize(20),
          ),
          SizedBox(width: responsive.spacing(8)),
          Text(
            text,
            style: TextStyle(
              color: isSelected ? AppTheme.secondaryColor : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: responsive.sp(13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormGroup(String label, String hintText, Responsive responsive, ResponsiveSpacing spacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 1,
              child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: responsive.sp(13))),
            ),
            Expanded(
              flex: 3,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: responsive.spacing(12), vertical: responsive.spacing(8)),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(responsive.spacing(6)),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.keyboard_arrow_down, color: Colors.grey[400], size: responsive.iconSize(16)),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: responsive.spacing(4)),
        Row(
          children: [
            Expanded(flex: 1, child: const SizedBox()),
            Expanded(
              flex: 3,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: responsive.spacing(12), vertical: responsive.spacing(10)),
                decoration: BoxDecoration(
                  color: Colors.grey[50], // Very light grey
                  borderRadius: BorderRadius.circular(responsive.spacing(6)),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Text(
                  hintText,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: responsive.sp(13),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
