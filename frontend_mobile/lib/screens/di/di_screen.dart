import 'package:flutter/material.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';
import 'package:appmobilegmao/screens/di/di_detail_screen.dart';

class DiScreen extends StatefulWidget {
  const DiScreen({super.key});

  @override
  State<DiScreen> createState() => _DiScreenState();
}

class _DiScreenState extends State<DiScreen> {
  // Dummy data matching the mockup
  final List<Map<String, dynamic>> diList = [
    {
      "id": "DI00062653",
      "status1": "Actif",
      "status2": "Urgent",
      "title": "DECHARGE PARTIELLE",
      "subtitle": "POSTE FANN FROBENIUS -",
    },
    {
      "id": "DI00062540",
      "status1": "Actif",
      "status2": "Urgent",
      "title": "FUITE JOINT MECANIQUE",
      "subtitle": "POMPE CENTRIFUGE P-204 - STATION",
    },
    {
      "id": "DI00062480",
      "status1": "Actif",
      "status2": "Urgent",
      "title": "DERIVE CAPTEUR PRESSION",
      "subtitle": "CAPTEUR PRESSION PT-302 - LIGNE",
    },
    {
      "id": "DI00062350",
      "status1": "Actif",
      "status2": null,
      "title": "REVISION GENERALE 500H",
      "subtitle": "CONVOYEUR CV-08 - ATELIER",
    },
    {
      "id": "DI00061900",
      "status1": "Suspendu",
      "status2": null,
      "title": "FISSURES TOITURE ATELIER",
      "subtitle": "BÂTIMENT ATELIER - SAINT-LOUIS",
    },
    {
      "id": "DI00062600",
      "status1": "Actif",
      "status2": "Urgent",
      "title": "FUITE VAPEUR BRIDE DN100",
      "subtitle": "CHAUDIÈRE CHD-01 - SALLE DES",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Light grey background
      body: Column(
        children: [
          // Header Card
          Padding(
            padding: spacing.custom(all: 16),
            child: Container(
              padding: spacing.custom(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor, // Dark blue from theme
                borderRadius: BorderRadius.circular(responsive.spacing(16)),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.boxShadowColor.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: spacing.custom(all: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(responsive.spacing(12)),
                    ),
                    child: Icon(
                      Icons.assignment, // Or similar icon
                      color: Colors.white,
                      size: responsive.iconSize(24),
                    ),
                  ),
                  SizedBox(width: spacing.medium),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${diList.length} Domaines',
                        style: TextStyle(
                          fontFamily: AppTheme.fontMontserrat,
                          color: Colors.white,
                          fontSize: responsive.sp(20),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Domaines d\'Intervention',
                        style: TextStyle(
                          fontFamily: AppTheme.fontRoboto,
                          color: Colors.white.withOpacity(0.8),
                          fontSize: responsive.sp(14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // List of DI
          Expanded(
            child: ListView.builder(
              padding: spacing.custom(horizontal: 16, bottom: 16),
              itemCount: diList.length,
              itemBuilder: (context, index) {
                final di = diList[index];
                return _buildDiCard(context, di, responsive, spacing);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiCard(BuildContext context, Map<String, dynamic> di, Responsive responsive, ResponsiveSpacing spacing) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DiDetailScreen(diData: di),
          ),
        );
      },
      child: Container(
        margin: spacing.custom(bottom: 12),
        padding: spacing.custom(all: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(responsive.spacing(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Box
            Container(
              padding: spacing.custom(all: 12),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withOpacity(0.1), // Light blue
                borderRadius: BorderRadius.circular(responsive.spacing(12)),
              ),
              child: Icon(
                Icons.assignment_outlined,
                color: AppTheme.secondaryColor,
                size: responsive.iconSize(24),
              ),
            ),
            SizedBox(width: spacing.medium),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ID and Tags
                  Row(
                    children: [
                      Text(
                        di['id'],
                        style: TextStyle(
                          fontFamily: AppTheme.fontMontserrat,
                          fontWeight: FontWeight.bold,
                          fontSize: responsive.sp(15),
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(width: spacing.small),
                      _buildTag(di['status1'], responsive, spacing),
                      if (di['status2'] != null) ...[
                        SizedBox(width: spacing.small),
                        _buildTag(di['status2'], responsive, spacing, isUrgent: true),
                      ],
                    ],
                  ),
                  SizedBox(height: spacing.small),
                  
                  // Title
                  Text(
                    di['title'],
                    style: TextStyle(
                      fontFamily: AppTheme.fontRoboto,
                      fontWeight: FontWeight.bold,
                      fontSize: responsive.sp(14),
                      color: AppTheme.secondaryColor.withOpacity(0.9),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: responsive.spacing(4)),
                  
                  // Subtitle
                  Text(
                    di['subtitle'],
                    style: TextStyle(
                      fontFamily: AppTheme.fontRoboto,
                      fontSize: responsive.sp(12),
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Right Arrow
            Padding(
              padding: EdgeInsets.only(top: responsive.spacing(8)),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: Colors.grey[400],
                size: responsive.iconSize(24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, Responsive responsive, ResponsiveSpacing spacing, {bool isUrgent = false}) {
    Color textColor;
    Color bgColor;
    
    if (text == 'Actif') {
      textColor = AppTheme.successColor;
      bgColor = AppTheme.successColor.withOpacity(0.15);
    } else if (text == 'Suspendu') {
      textColor = AppTheme.warningColor;
      bgColor = AppTheme.warningColor.withOpacity(0.15);
    } else if (isUrgent) {
      textColor = AppTheme.errorColor;
      bgColor = AppTheme.errorColor.withOpacity(0.15);
    } else {
      textColor = Colors.grey;
      bgColor = Colors.grey.withOpacity(0.15);
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.spacing(8),
        vertical: responsive.spacing(2),
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(responsive.spacing(12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isUrgent) ...[
            Icon(Icons.warning_amber_rounded, color: textColor, size: responsive.iconSize(12)),
            SizedBox(width: responsive.spacing(4)),
          ],
          Text(
            text,
            style: TextStyle(
              fontFamily: AppTheme.fontRoboto,
              fontWeight: FontWeight.w600,
              fontSize: responsive.sp(11),
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}