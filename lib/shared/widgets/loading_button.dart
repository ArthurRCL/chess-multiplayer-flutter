import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Botão premium com gradiente dourado, shimmer no loading e scale press.
class LoadingButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool loading;
  final String label;
  final IconData? icon;
  final double? width;

  const LoadingButton({
    super.key,
    required this.onPressed,
    required this.loading,
    required this.label,
    this.icon,
    this.width,
  });

  @override
  State<LoadingButton> createState() => _LoadingButtonState();
}

class _LoadingButtonState extends State<LoadingButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerCtrl;
  late final Animation<double> _shimmerAnim;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _shimmerAnim = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut),
    );
    if (widget.loading) _shimmerCtrl.repeat();
  }

  @override
  void didUpdateWidget(LoadingButton old) {
    super.didUpdateWidget(old);
    if (widget.loading && !_shimmerCtrl.isAnimating) {
      _shimmerCtrl.repeat();
    } else if (!widget.loading && _shimmerCtrl.isAnimating) {
      _shimmerCtrl.stop();
    }
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.loading;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        if (!disabled) widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedOpacity(
          opacity: disabled ? 0.7 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: SizedBox(
            width: widget.width ?? double.infinity,
            height: 54,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AnimatedBuilder(
                animation: _shimmerAnim,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: disabled
                          ? LinearGradient(
                              begin: Alignment(_shimmerAnim.value - 0.5, 0),
                              end: Alignment(_shimmerAnim.value + 0.5, 0),
                              colors: const [
                                AppColors.gold3,
                                AppColors.gold1,
                                AppColors.gold0,
                                AppColors.gold1,
                                AppColors.gold3,
                              ],
                              stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                            )
                          : AppGradients.gold,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold2.withOpacity(0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: child,
                  );
                },
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: disabled
                        ? const SizedBox(
                            key: ValueKey('loading'),
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation(AppColors.bg0),
                            ),
                          )
                        : Row(
                            key: const ValueKey('label'),
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.icon != null) ...[
                                Icon(
                                  widget.icon,
                                  size: 18,
                                  color: AppColors.bg0,
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                widget.label,
                                style: const TextStyle(
                                  color: AppColors.bg0,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
