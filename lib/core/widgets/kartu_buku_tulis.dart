import 'package:flutter/material.dart';
import '../theme.dart';

class KartuBukuTulis extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color backgroundColor;
  final BoxShadow? shadow;
  final BoxShadow? pressedShadow;

  const KartuBukuTulis({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.besar),
    this.radius = AppSizes.radiusKartu,
    this.backgroundColor = AppColors.kartu,
    this.shadow,
    this.pressedShadow,
  });

  @override
  State<KartuBukuTulis> createState() => _KartuBukuTulisState();
}

class _KartuBukuTulisState extends State<KartuBukuTulis> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      setState(() => _isPressed = false);
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // pas ditekan kartu geser ke arah bayangan, bayangannya mengecil
    const geser = AppSizes.geserTekan;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: AppDurations.animasiTekan,
        margin: EdgeInsets.only(
          left: _isPressed ? geser : 0,
          top: _isPressed ? geser : 0,
          right: _isPressed ? 0 : geser,
          bottom: _isPressed ? 0 : geser,
        ),
        padding: widget.padding,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          border: Border.all(color: AppColors.ink, width: AppSizes.border),
          borderRadius: BorderRadius.circular(widget.radius),
          boxShadow: [
            _isPressed
                ? (widget.pressedShadow ?? AppTheme.bayanganDefaultTertekan)
                : (widget.shadow ?? AppTheme.bayanganDefault),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}
