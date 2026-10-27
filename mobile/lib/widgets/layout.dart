import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

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

/// The top of a main page: a heading and one calm sentence under it.
class PageIntro extends StatelessWidget {
  const PageIntro({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(header: true, child: Text(title, style: theme.textTheme.headlineSmall)),
          const SizedBox(height: 8),
          Text(subtitle, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

/// A soft green rounded square behind a leading icon or number, the same on every card and list.
/// It grows with large text instead of clipping a number.
class LeadingTile extends StatelessWidget {
  const LeadingTile({super.key, required this.child, this.size = 40});

  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // Sized by its content (at least [size]), never stretched to the space a ListTile offers its leading.
    return Container(
      constraints: BoxConstraints(minWidth: size, minHeight: size),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: scheme.secondaryContainer, borderRadius: BorderRadius.circular(size * 0.28)),
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: IconTheme.merge(
          data: IconThemeData(color: scheme.primary, size: size >= 40 ? 24 : 20),
          child: DefaultTextStyle.merge(
            style: theme.textTheme.labelLarge?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A whole card that is one button. Keyboard and D-pad focus (button phones) shows as a primary border.
/// With [selected] set it is a choice: the selected card also gets a soft green fill, and [child] should
/// carry a mark too, so selection never relies on colour alone.
class TappableCard extends StatefulWidget {
  const TappableCard({super.key, required this.child, required this.onTap, this.selected});

  final Widget child;
  final VoidCallback onTap;
  final bool? selected;

  @override
  State<TappableCard> createState() => _TappableCardState();
}

class _TappableCardState extends State<TappableCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selected = widget.selected ?? false;
    final shape = selected || _focused
        ? RoundedRectangleBorder(borderRadius: kCardRadius, side: BorderSide(color: scheme.primary, width: 2))
        : null;
    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: widget.selected,
        child: Card(
          color: selected ? scheme.secondaryContainer : null,
          shape: shape,
          child: InkWell(
            // M3 state layers in the brand green: 8% hovered, 10% focused or pressed.
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed) || states.contains(WidgetState.focused)) {
                return scheme.primary.withValues(alpha: 0.10);
              }
              if (states.contains(WidgetState.hovered)) return scheme.primary.withValues(alpha: 0.08);
              return null;
            }),
            onFocusChange: (focused) => setState(() => _focused = focused),
            onTap: widget.onTap,
            child: widget.child,
          ),
        ),
      ),
    );
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
