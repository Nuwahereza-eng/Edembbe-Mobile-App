import 'dart:async';

import 'package:flutter/material.dart';

import 'tr.dart';

/// Shown while an answer is on its way (10 to 90 seconds, longer for a scan), so the screen never looks frozen.
class LoadingPanel extends StatefulWidget {
  const LoadingPanel({super.key, required this.messages});

  /// Friendly steps shown in turn, e.g. "Reading your document...", "Checking the law...".
  final List<String> messages;

  @override
  State<LoadingPanel> createState() => _LoadingPanelState();
}

class _LoadingPanelState extends State<LoadingPanel> {
  late final Timer _timer;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _seconds++));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // A new message every 8 seconds, staying on the last one.
    final index = (_seconds ~/ 8).clamp(0, widget.messages.length - 1);
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr(widget.messages[index]), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            const LinearProgressIndicator(minHeight: 6, borderRadius: BorderRadius.all(Radius.circular(3))),
            const SizedBox(height: 10),
            Text(
              '${context.tr('This can take up to a minute or two.')} ${_seconds}s',
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

/// A plain error with a Try again button.
class ErrorPanel extends StatelessWidget {
  const ErrorPanel({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFCE8E6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr(message), style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(context.tr('Try again')),
            ),
          ],
        ),
      ),
    );
  }
}
