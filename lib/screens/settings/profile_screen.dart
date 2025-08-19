import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: _appBar());
  }

  AppBar _appBar() {
    return AppBar(
      title: Text(
        "Modifier le profil",
        style: TextStyle(color: AppTheme.secondaryColor),
      ),
      backgroundColor: AppTheme.primaryColor,
      elevation: 0,
    );
  }
}
