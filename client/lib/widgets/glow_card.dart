import 'package:flutter/material.dart';

import '../theme/glowup_theme.dart';

class GlowCard extends StatefulWidget {
  const GlowCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
    this.accent,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? accent;

  @override
  State<GlowCard> createState() => _GlowCardState();
}

class _GlowCardState extends State<GlowCard> {
  bool _hovering = false;
  bool _pressed = false;

  void _setHover(bool hovering) {
    if (_hovering == hovering) return;
    setState(() => _hovering = hovering);
  }

  void _setPressed(bool pressed) {
    if (_pressed == pressed) return;
    setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(26);
    final baseColor = theme.cardColor;
    final accent = widget.accent ?? theme.colorScheme.primary;
    final overlayOpacity = _pressed
        ? 0.18
        : _hovering
            ? 0.12
            : 0.06;
    final blendedColor = Color.alphaBlend(
      accent.withOpacity(overlayOpacity),
      baseColor,
    );

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: blendedColor,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(_hovering ? 0.24 : 0.12),
            blurRadius: _hovering ? 28 : 20,
            offset: const Offset(0, 14),
          ),
        ],
        border: Border.all(
          color: _hovering
              ? accent.withOpacity(0.32)
              : accent.withOpacity(0.16),
          width: 1.3,
        ),
      ),
      child: Padding(padding: widget.padding, child: widget.child),
    );

    if (widget.onTap != null) {
      content = GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        onTap: widget.onTap,
        child: content,
      );
    }

    return MouseRegion(
      onEnter: (_) => _setHover(true),
      onExit: (_) {
        _setHover(false);
        _setPressed(false);
      },
      cursor:
          widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: content,
    );
  }
}
