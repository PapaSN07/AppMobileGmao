import 'package:appmobilegmao/screens/ot_work_orders_screen.dart';
import 'package:flutter/material.dart';

class OtScreen extends StatefulWidget {
  const OtScreen({super.key});

  @override
  State<OtScreen> createState() => _OtScreenState();
}

class _OtScreenState extends State<OtScreen> {
  @override
  Widget build(BuildContext context) {
    return const OTWorkOrdersScreen(
      showBottomNavigationBar: false,
      isTab: true,
    );
  }
}
