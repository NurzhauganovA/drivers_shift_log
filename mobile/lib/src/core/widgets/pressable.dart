import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Scales its child down slightly while pressed, like iOS controls.
class Pressable extends StatefulWidget {
  const Pressable({
    required this.child,
    required this.onPressed,
    this.scale = 0.96,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final double scale;
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => _setPressed(true) : null,
          onTapCancel: () => _setPressed(false),
          onTapUp: (_) => _setPressed(false),
          onTap: enabled
              ? () {
                  HapticFeedback.selectionClick();
                  widget.onPressed!();
                }
              : null,
          child: AnimatedScale(
            scale: _pressed ? widget.scale : 1,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            // An explicit label replaces the child's own semantics instead of
            // being read together with them.
            child: ExcludeSemantics(excluding: widget.semanticLabel != null, child: widget.child),
          ),
        ),
      ),
    );
  }
}
