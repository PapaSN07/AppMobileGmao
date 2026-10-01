import 'package:flutter/material.dart';

/// Bandeau affiché au-dessus d'une liste montrée sans réseau, à partir de la
/// dernière copie enregistrée sur le téléphone.
class OfflineDataBanner extends StatelessWidget {
  const OfflineDataBanner({super.key, required this.since});

  final DateTime since;

  static String describe(DateTime since) {
    String two(int n) => n.toString().padLeft(2, '0');
    return 'Hors ligne : données du ${two(since.day)}/${two(since.month)} '
        'à ${two(since.hour)}h${two(since.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off, size: 18, color: Colors.orange.shade800),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              describe(since),
              style: TextStyle(
                color: Colors.orange.shade900,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
