import 'package:flutter/material.dart';

class GenerateDocumentButton extends StatelessWidget {
  final VoidCallback onPressed;

  const GenerateDocumentButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Center( // Center it by default
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green, // Button color
          padding: const EdgeInsets.symmetric(horizontal: 85, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: const Icon(Icons.description, color: Colors.white),
        label: const Text(
          "Generate Document",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
