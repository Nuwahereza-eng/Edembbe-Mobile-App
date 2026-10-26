import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Material 3 window size classes: compact (< 600dp), medium (600–839dp), expanded (≥ 840dp).
enum WindowClass { compact, medium, expanded }

WindowClass windowClassOf(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width < 600) return WindowClass.compact;
  if (width < 840) return WindowClass.medium;
  return WindowClass.expanded;
}

/// Reading content is kept to this width on wide screens.
const double kMaxContentWidth = 840;

/// Space between items, on the 4dp grid.
const double kGap = 16;

/// A scrolling page: 16dp side padding on phones, 24dp on wider screens, and content centred
/// at most [maxWidth] wide. The scroll area itself stays full width.
class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children, this.maxWidth = kMaxContentWidth, this.controller});

  final List<Widget> children;
  final double maxWidth;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final gutter = windowClassOf(context) == WindowClass.compact ? 16.0 : 24.0;
      final side = math.max(gutter, (constraints.maxWidth - maxWidth) / 2);
      return ListView(
        controller: controller,
        padding: EdgeInsets.fromLTRB(side, 8, side, 32),
        children: children,
      );
    });
  }
}

/// A section heading in the M3 type scale.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Semantics(header: true, child: Text(text, style: Theme.of(context).textTheme.titleMedium)),
    );
  }
}

/// A large outlined icon, one sentence and one action.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message, this.actionLabel, this.onAction});

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      child: Column(
        children: [
          ExcludeSemantics(child: Icon(icon, size: 64, color: scheme.outline)),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 24),
            FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

/// A grey placeholder card shown while an answer is on its way.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, this.lines = 4});

  final int lines;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    Widget bar(double widthFactor) => FractionallySizedBox(
          widthFactor: widthFactor,
          child: Container(
            height: 14,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
          ),
        );
    return ExcludeSemantics(
      child: Card.outlined(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [bar(0.4), for (var i = 0; i < lines; i++) bar(i == lines - 1 ? 0.6 : 1)],
          ),
        ),
      ),
    );
  }
}
