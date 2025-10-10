import 'package:flutter/material.dart';

class OtScreen extends StatefulWidget {
  const OtScreen({super.key});

  @override
  State<OtScreen> createState() => _OtScreenState();
}

class _OtScreenState extends State<OtScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ordre de Travail')),
      body: Center(child: Text('Contenu de l\'ordre de travail'))
    );
  }
}