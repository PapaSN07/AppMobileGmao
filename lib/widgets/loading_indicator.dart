import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:appmobilegmao/utils/responsive.dart';

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Center(
      child: CircularProgressIndicator(
        color: AppTheme.secondaryColor,
        strokeWidth: responsive.spacing(4), // ✅ Épaisseur responsive
      ),
    );
  }
}
