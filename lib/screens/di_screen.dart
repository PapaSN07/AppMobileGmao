import 'package:flutter/material.dart';

class DiScreen extends StatefulWidget {
  const DiScreen({super.key});

  @override
  State<DiScreen> createState() => _DiScreenState();
}

class _DiScreenState extends State<DiScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Demande d\'Intervention')),
      body: Center(child: Text('Contenu de la demande d\'intervention'))
    );
  }
}