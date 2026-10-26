import 'dart:async';

import 'package:flutter/material.dart';

import 'layout.dart';
import 'tr.dart';

/// Shown while an answer is on its way (10 to 90 seconds, longer for a scan): what is happening,
/// how long it has taken, and skeleton cards, so the screen never looks frozen.
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
    final theme = Theme.of(context);
    // A new message every 8 seconds, staying on the last one.
    final index = (_seconds ~/ 8).clamp(0, widget.messages.length - 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          child: Row(
            children: [
              const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3)),
              const SizedBox(width: 16),
              Expanded(child: Text(context.tr(widget.messages[index]), style: theme.textTheme.titleMedium)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${context.tr('This can take up to a minute or two.')} ${_seconds}s',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: kGap),
        const SkeletonCard(lines: 5),
        const SizedBox(height: 8),
        const SkeletonCard(lines: 2),
      ],
    );
  }
}

/// A plain error with a Try again button. Never shows raw errors.
class ErrorPanel extends StatelessWidget {
  const ErrorPanel({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card.filled(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr(message),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: scheme.onErrorContainer)),
            const SizedBox(height: 16),
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
