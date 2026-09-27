import 'package:flutter/material.dart';
import '../theme.dart';

class TombolStabilo extends StatefulWidget {
  final String teks;
  final VoidCallback? onPressed;
  final bool isLoading;

  const TombolStabilo({
    super.key,
    required this.teks,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  State<TombolStabilo> createState() => _TombolStabiloState();
}

class _TombolStabiloState extends State<TombolStabilo> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = false);
    }
  }

  void _handleTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool disabled = widget.onPressed == null || widget.isLoading;
    const geser = AppSizes.geserTekan;

    return GestureDetector(
      onTapDown: disabled ? null : _handleTapDown,
      onTapUp: disabled ? null : _handleTapUp,
      onTapCancel: disabled ? null : _handleTapCancel,
      onTap: disabled ? null : widget.onPressed,
      child: AnimatedContainer(
        duration: AppDurations.animasiTekan,
        height: AppSizes.tinggiTombol,
        margin: EdgeInsets.only(
          left: _isPressed ? geser : 0,
          top: _isPressed ? geser : 0,
          right: _isPressed ? 0 : geser,
          bottom: _isPressed ? 0 : geser,
        ),
        decoration: BoxDecoration(
          color: disabled ? AppColors.garis : AppColors.stabilo,
          border: Border.all(color: AppColors.ink, width: AppSizes.border),
          borderRadius: BorderRadius.circular(AppSizes.radiusTombol),
          // tombol utama stabilo pakai bayangan gelap (lihat theme.dart)
          boxShadow: [
            _isPressed
                ? AppTheme.bayanganGelapTertekan
                : AppTheme.bayanganGelap,
          ],
        ),
        child: Center(
          child: widget.isLoading
              ? const SizedBox(
                  width: AppSizes.indikatorMuat,
                  height: AppSizes.indikatorMuat,
                  child: CircularProgressIndicator(
                    strokeWidth: AppSizes.tebalIndikatorMuat,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.ink),
                  ),
                )
              : Text(
                  widget.teks,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
        ),
      ),
    );
  }
}
