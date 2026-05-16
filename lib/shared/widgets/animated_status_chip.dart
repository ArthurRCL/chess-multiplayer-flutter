import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Chip de status animado — muda cor e texto com AnimatedSwitcher.
class AnimatedStatusChip extends StatelessWidget {
  final String label;
  final StatusType type;
  final bool pulsing;

  const AnimatedStatusChip({
    super.key,
    required this.label,
    required this.type,
    this.pulsing = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(type);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _ChipInner(
        key: ValueKey('$label-$type'),
        label: label,
        color: color,
        pulsing: pulsing,
      ),
    );
  }

  Color _colorFor(StatusType t) {
    switch (t) {
      case StatusType.waiting:  return AppColors.warning;
      case StatusType.playing:  return AppColors.success;
      case StatusType.check:    return AppColors.danger;
      case StatusType.checkmate:return AppColors.gold2;
      case StatusType.draw:     return AppColors.info;
      case StatusType.finished: return AppColors.purple1;
    }
  }
}

enum StatusType { waiting, playing, check, checkmate, draw, finished }

class _ChipInner extends StatefulWidget {
  final String label;
  final Color color;
  final bool pulsing;

  const _ChipInner({
    super.key,
    required this.label,
    required this.color,
    required this.pulsing,
  });

  @override
  State<_ChipInner> createState() => _ChipInnerState();
}

class _ChipInnerState extends State<_ChipInner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _alpha;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _alpha = Tween(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
    if (widget.pulsing) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_ChipInner old) {
    super.didUpdateWidget(old);
    if (widget.pulsing && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.pulsing && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 1.0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _alpha,
      builder: (_, __) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.12 * _alpha.value + 0.08),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: widget.color.withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dot pulsante
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(_alpha.value),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
