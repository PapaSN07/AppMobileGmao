import 'package:flutter/material.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final double width;
  final double height;
  final double fontSize;
  final bool isLoading;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.width = double.infinity,
    this.height = 54,
    this.fontSize = 16,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    return SizedBox(
      width: width,
      height: responsive.spacing(height), // ✅ Hauteur responsive
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.secondaryColor,
          foregroundColor: AppTheme.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              responsive.spacing(8),
            ), // ✅ Border radius responsive
          ),
          elevation: 2,
          shadowColor: AppTheme.boxShadowColor,
          padding: EdgeInsets.symmetric(
            horizontal: spacing.medium, // ✅ Padding horizontal responsive
            vertical: spacing.small, // ✅ Padding vertical responsive
          ),
        ),
        child:
            isLoading
                ? SizedBox(
                  height: responsive.iconSize(20), // ✅ Taille loader responsive
                  width: responsive.iconSize(20), // ✅ Taille loader responsive
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryColor,
                    ),
                  ),
                )
                : _buildButtonContent(context, responsive, spacing),
      ),
    );
  }

  Widget _buildButtonContent(
    BuildContext context,
    Responsive responsive,
    ResponsiveSpacing spacing,
  ) {
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: responsive.iconSize(fontSize),
            color: AppTheme.primaryColor,
          ), // ✅ Icône responsive
          SizedBox(width: spacing.small), // ✅ Espacement responsive
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: responsive.sp(fontSize), // ✅ Texte responsive
                fontWeight: FontWeight.bold,
                fontFamily: AppTheme.fontMontserrat,
                color: AppTheme.primaryColor,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    } else {
      return Text(
        text,
        style: TextStyle(
          fontSize: responsive.sp(fontSize), // ✅ Texte responsive
          fontWeight: FontWeight.bold,
          fontFamily: AppTheme.fontMontserrat,
          color: AppTheme.primaryColor,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        textAlign: TextAlign.center,
      );
    }
  }
}

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final double width;
  final double height;
  final double fontSize;
  final bool isLoading;
  final IconData? icon;

  const SecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.width = double.infinity,
    this.height = 54,
    this.fontSize = 16,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    return SizedBox(
      width: width,
      height: responsive.spacing(height), // ✅ Hauteur responsive
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: AppTheme.secondaryColor,
          side: const BorderSide(color: AppTheme.secondaryColor, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              responsive.spacing(8),
            ), // ✅ Border radius responsive
          ),
          padding: EdgeInsets.symmetric(
            horizontal: spacing.medium, // ✅ Padding horizontal responsive
            vertical: spacing.small, // ✅ Padding vertical responsive
          ),
        ),
        child:
            isLoading
                ? SizedBox(
                  height: responsive.iconSize(20), // ✅ Taille loader responsive
                  width: responsive.iconSize(20), // ✅ Taille loader responsive
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.secondaryColor,
                    ),
                  ),
                )
                : _buildButtonContent(context, responsive, spacing),
      ),
    );
  }

  Widget _buildButtonContent(
    BuildContext context,
    Responsive responsive,
    ResponsiveSpacing spacing,
  ) {
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: responsive.iconSize(fontSize),
            color: AppTheme.secondaryColor,
          ), // ✅ Icône responsive
          SizedBox(width: spacing.small), // ✅ Espacement responsive
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: responsive.sp(fontSize), // ✅ Texte responsive
                fontWeight: FontWeight.bold,
                fontFamily: AppTheme.fontMontserrat,
                color: AppTheme.secondaryColor,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    } else {
      return Text(
        text,
        style: TextStyle(
          fontSize: responsive.sp(fontSize), // ✅ Texte responsive
          fontWeight: FontWeight.bold,
          fontFamily: AppTheme.fontMontserrat,
          color: AppTheme.secondaryColor,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        textAlign: TextAlign.center,
      );
    }
  }
}
