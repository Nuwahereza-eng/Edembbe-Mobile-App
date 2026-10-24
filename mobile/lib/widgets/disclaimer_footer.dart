import 'package:flutter/material.dart';

import 'tr.dart';

const String disclaimerText =
    'Eddembe gives legal information, not legal advice. For advice on your case, talk to a lawyer or a legal aid clinic.';

class DisclaimerFooter extends StatelessWidget {
  const DisclaimerFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF9A825).withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 20, color: Color(0xFF8D6E00)),
          const SizedBox(width: 8),
          Expanded(child: Text(context.tr(disclaimerText), style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
