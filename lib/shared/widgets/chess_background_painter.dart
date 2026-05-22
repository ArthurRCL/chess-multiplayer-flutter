import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Pinta um padrão de tabuleiro diagonal no fundo — efeito imersivo premium.
class ChessBackgroundPainter extends CustomPainter {
  final double opacity;
  final double squareSize;

  const ChessBackgroundPainter({
    this.opacity = 0.045,
    this.squareSize = 48,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final lightPaint = Paint()
      ..color = AppColors.gold2.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    final int cols = (size.width / squareSize).ceil() + 2;
    final int rows = (size.height / squareSize).ceil() + 2;

    // Deslocamento diagonal para dar perspectiva
    final double offsetX = -squareSize / 2;

    for (int r = -1; r < rows; r++) {
      for (int c = -1; c < cols; c++) {
        final isDark = (r + c) % 2 == 0;
        if (!isDark) continue;

        final rect = Rect.fromLTWH(
          offsetX + c * squareSize,
          r * squareSize.toDouble(),
          squareSize,
          squareSize,
        );
        canvas.drawRect(rect, lightPaint);
      }
    }
  }

  @override
  bool shouldRepaint(ChessBackgroundPainter old) =>
      old.opacity != opacity || old.squareSize != squareSize;
}

/// Widget wrapper que aplica o fundo com gradiente + tabuleiro.
class ChessBackground extends StatelessWidget {
  final Widget child;
  final double boardOpacity;

  const ChessBackground({
    super.key,
    required this.child,
    this.boardOpacity = 0.045,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Gradiente base
        Container(
          decoration: const BoxDecoration(
            gradient: AppGradients.background,
          ),
        ),
        // Padrão de tabuleiro
        CustomPaint(
          painter: ChessBackgroundPainter(opacity: boardOpacity),
          child: const SizedBox.expand(),
        ),
        // Vinheta nas bordas
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.4,
              colors: [
                Colors.transparent,
                Color(0xCC000000),
              ],
              stops: [0.5, 1.0],
            ),
          ),
        ),
        // Conteúdo
        child,
      ],
    );
  }
}
