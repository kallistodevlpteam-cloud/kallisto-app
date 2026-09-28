import 'package:flutter/material.dart';
import 'tokens.dart';

class KPanel extends StatelessWidget {
  const KPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  @override
  Widget build(BuildContext context) => Material(
    color: color ?? KTokens.panel(context),
    shape: RoundedRectangleBorder(
      side: BorderSide(color: KTokens.border(context)),
      borderRadius: BorderRadius.circular(KTokens.radiusMd),
    ),
    clipBehavior: Clip.antiAlias,
    child: Padding(padding: padding, child: child),
  );
}

class KSection extends StatelessWidget {
  const KSection({
    super.key,
    required this.title,
    required this.description,
    required this.child,
    this.tag,
  });
  final String title;
  final String description;
  final Widget child;
  final String? tag;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 32),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            if (tag != null) KBadge(tag!),
          ],
        ),
        const SizedBox(height: 6),
        Text(description, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 16),
        child,
      ],
    ),
  );
}

/// Content-driven wrapping avoids fixed-height grid overflows at large text sizes.
class KGrid extends StatelessWidget {
  const KGrid({
    super.key,
    required this.children,
    this.minWidth = 270,
    this.gap = 16,
  });
  final List<Widget> children;
  final double minWidth;
  final double gap;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = ((constraints.maxWidth + gap) / (minWidth + gap))
          .floor()
          .clamp(1, 4);
      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}

enum KBadgeTone { neutral, success, warning, danger, info }

class KBadge extends StatelessWidget {
  const KBadge(
    this.label, {
    super.key,
    this.tone = KBadgeTone.neutral,
    this.icon,
  });
  final String label;
  final KBadgeTone tone;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = switch (tone) {
      KBadgeTone.success => dark ? const Color(0xFF34D399) : KTokens.success,
      KBadgeTone.warning => dark ? const Color(0xFFFBBF24) : KTokens.warning,
      KBadgeTone.danger => dark ? const Color(0xFFF87171) : KTokens.danger,
      KBadgeTone.info => dark ? const Color(0xFF60A5FA) : KTokens.accent,
      KBadgeTone.neutral => Theme.of(context).colorScheme.onSurfaceVariant,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: .16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class KImage extends StatelessWidget {
  const KImage(
    this.asset, {
    super.key,
    this.height = 180,
    this.label = 'Kallisto project reference',
  });
  final String asset;
  final double height;
  final String label;
  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/images/$asset',
    height: height,
    width: double.infinity,
    fit: BoxFit.cover,
    semanticLabel: label,
    errorBuilder: (context, error, stack) => Container(
      height: height,
      color: KTokens.quiet(context),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_outlined),
            SizedBox(height: 8),
            Text('Image unavailable'),
          ],
        ),
      ),
    ),
  );
}

/// InkWell provides pointer, keyboard, focus, semantics, and touch behavior.
class KInteractiveCard extends StatefulWidget {
  const KInteractiveCard({
    super.key,
    required this.child,
    required this.onTap,
    required this.label,
  });
  final Widget child;
  final VoidCallback onTap;
  final String label;
  @override
  State<KInteractiveCard> createState() => _KInteractiveCardState();
}

class _KInteractiveCardState extends State<KInteractiveCard> {
  bool active = false;
  bool hovered = false;
  bool focused = false;
  bool pressed = false;
  @override
  Widget build(BuildContext context) => AnimatedScale(
    scale: pressed ? .985 : 1,
    duration: KTokens.motion(context, KTokens.fast),
    child: AnimatedContainer(
      duration: KTokens.motion(context, KTokens.fast),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: active
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .07),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : [],
        border: Border.all(
          color: active
              ? Theme.of(context).colorScheme.primary
              : KTokens.border(context),
          width: 1,
        ),
      ),
      child: Material(
        color: KTokens.panel(context),
        borderRadius: BorderRadius.circular(11),
        clipBehavior: Clip.antiAlias,
        child: Semantics(
          button: true,
          label: widget.label,
          child: InkWell(
            onTap: widget.onTap,
            onHover: (value) => setState(() {
              hovered = value;
              active = hovered || focused;
            }),
            onFocusChange: (value) => setState(() {
              focused = value;
              active = hovered || focused;
            }),
            onHighlightChanged: (value) => setState(() => pressed = value),
            child: widget.child,
          ),
        ),
      ),
    ),
  );
}

class KSpecimen extends StatelessWidget {
  const KSpecimen({
    super.key,
    required this.name,
    required this.detail,
    required this.child,
  });
  final String name;
  final String detail;
  final Widget child;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      child,
      const SizedBox(height: 12),
      Text(name, style: Theme.of(context).textTheme.titleMedium),
      Text(detail, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

void showDemoMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
