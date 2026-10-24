import 'package:flutter/material.dart';

class DisclaimerFooter extends StatelessWidget {
  const DisclaimerFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Eddembe gives legal information, not legal advice.',
        style: TextStyle(fontSize: 13, color: Colors.black87),
      ),
    );
  }
}
