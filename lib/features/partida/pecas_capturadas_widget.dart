import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../shared/theme/board_theme_preset.dart';

/// Exibe as peças capturadas de um lado (brancas ou negras).
/// Usa os mesmos SVG assets do tabuleiro para visual consistente.
class PecasCapturadas extends StatelessWidget {
  /// Lista de caracteres FEN das peças capturadas (ex: ['p','p','n','r']).
  final List<String> pecas;

  /// Rótulo exibido acima das peças (ex: "Capturadas por brancas").
  final String label;

  /// Estilo de peças a ser usado — deve coincidir com o do tabuleiro.
  final PieceStyle pieceStyle;

  const PecasCapturadas({
    super.key,
    required this.pecas,
    required this.label,
    this.pieceStyle = PieceStyle.tradicional,
  });

  /// Retorna o caminho do SVG a partir do caractere FEN e da pasta de estilo.
  String? _svgPath(String fenChar) {
    final folder = pieceStyle.assetFolder;
    const map = {
      'K': 'wK', 'Q': 'wQ', 'R': 'wR', 'B': 'wB', 'N': 'wN', 'P': 'wP',
      'k': 'bK', 'q': 'bQ', 'r': 'bR', 'b': 'bB', 'n': 'bN', 'p': 'bP',
    };
    final name = map[fenChar];
    return name != null ? '$folder/$name.svg' : null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 2,
          runSpacing: 2,
          children: pecas.isEmpty
              ? [
                  Text(
                    '—',
                    style: TextStyle(
                      fontSize: 18,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                ]
              : pecas.map((p) {
                  final path = _svgPath(p);
                  if (path == null) {
                    return const SizedBox.shrink();
                  }
                  return SizedBox(
                    width: 22,
                    height: 22,
                    child: SvgPicture.asset(
                      path,
                      fit: BoxFit.contain,
                    ),
                  );
                }).toList(),
        ),
      ],
    );
  }
}
