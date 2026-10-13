import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A reusable widget that provides a smooth, physical spring bounce effect
/// on touch with haptic feedback, making buttons and cards feel responsive and alive.
class BouncyTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;
  final bool enableHaptic;
  final Duration duration;

  const BouncyTap({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.94,
    this.enableHaptic = true,
    this.duration = const Duration(milliseconds: 100),
  });

  @override
  State<BouncyTap> createState() => _BouncyTapState();
}

class _BouncyTapState extends State<BouncyTap> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      reverseDuration: const Duration(milliseconds: 220),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleFactor).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      if (widget.enableHaptic) {
        HapticFeedback.lightImpact();
      }
      _controller.forward();
    }
  }

  void _onTapCancel() {
    if (widget.onTap != null) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap != null
          ? () {
              _controller.reverse();
              widget.onTap!();
            }
          : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
