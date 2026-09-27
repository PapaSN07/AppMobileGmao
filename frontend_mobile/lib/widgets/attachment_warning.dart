import 'package:appmobilegmao/models/attached_file_note.dart';
import 'package:flutter/material.dart';

/// Avertissement affiché sous chaque pièce jointe : le fichier n'est pas encore
/// transmis à Coswin (seul son nom est noté dans le commentaire).
class AttachmentNotSentWarning extends StatelessWidget {
  const AttachmentNotSentWarning({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange.shade800),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              AttachedFileNote.notSentWarning,
              style: TextStyle(fontSize: 11, color: Colors.orange.shade900, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
