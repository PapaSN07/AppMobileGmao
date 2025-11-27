import 'package:flutter/material.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/utils/responsive.dart';

/// Widget réutilisable pour l'AppBar personnalisée
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage de l'AppBar
/// Principe DRY: Un seul widget pour toutes les AppBar de l'application
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showBackButton;   
  final VoidCallback? onBackPressed;
  final Color backgroundColor;
  final Color iconColor;
  final Color? titleColor;
  final PreferredSizeWidget? bottom;
  final List<Widget>? actions;
  final double? customHeight;

  const CustomAppBar({
    Key? key,
    this.title,
    this.showBackButton = true,
    this.onBackPressed,
    this.backgroundColor = const Color(0xFF015CC0),
    this.iconColor = Colors.white,
    this.titleColor,
    this.bottom,
    this.actions,
    this.customHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    
    return AppBar(
      leading: showBackButton
          ? IconButton(
              icon: Icon(Icons.arrow_back, color: iconColor),
              onPressed: onBackPressed ?? () => Navigator.pop(context),
            )
          : null,
      title: title != null
          ? Text(
              title!,
              style: TextStyle(
                color: titleColor ?? iconColor,
                fontSize: responsive.sp(20),
                fontWeight: FontWeight.w600,
                fontFamily: AppTheme.fontMontserrat,
              ),
            )
          : null,
      backgroundColor: backgroundColor,
      elevation: 0,
      bottom: bottom,
      actions: actions,
      toolbarHeight: customHeight ?? responsive.hp(8), // Hauteur augmentée de l'AppBar
    );
  }

  @override
  Size get preferredSize {
    final baseHeight = customHeight ?? 70.0; // Hauteur de base augmentée
    final bottomHeight = bottom?.preferredSize.height ?? 0.0;
    return Size.fromHeight(baseHeight + bottomHeight);
  }
}

/// Widget réutilisable pour la barre d'onglets avec TabBar
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage de la TabBar
/// Principe DRY: Réutilisable dans tous les écrans avec onglets
class CustomTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController tabController;
  final List<String> tabLabels;
  final Color indicatorColor;
  final Color selectedLabelColor;
  final Color unselectedLabelColor;

  const CustomTabBar({
    Key? key,
    required this.tabController,
    required this.tabLabels,
    this.indicatorColor = const Color(0xFF015CC0),
    this.selectedLabelColor = const Color(0xFF015CC0),
    this.unselectedLabelColor = Colors.grey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Container(
      color: Colors.white,
      child: TabBar(
        controller: tabController,
        isScrollable: true,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: indicatorColor, width: 3),
        ),
        labelColor: selectedLabelColor,
        unselectedLabelColor: unselectedLabelColor,
        labelStyle: TextStyle(
          fontFamily: AppTheme.fontMontserrat,
          fontWeight: FontWeight.w600,
          fontSize: responsive.sp(14),
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: AppTheme.fontMontserrat,
          fontWeight: FontWeight.normal,
          fontSize: responsive.sp(14),
        ),
        tabs: tabLabels.map((label) => Tab(text: label)).toList(),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(48.0);
}
