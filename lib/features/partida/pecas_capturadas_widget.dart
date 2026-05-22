import 'package:flutter/material.dart';

/// Exibe as peças capturadas de um lado (brancas ou negras).
class PecasCapturadas extends StatelessWidget {
  /// Lista de caracteres FEN das peças capturadas (ex: ['p','p','n','r']).
  final List<String> pecas;

  /// Rótulo exibido acima das peças (ex: "Capturadas por brancas").
  final String label;

  const PecasCapturadas({
    super.key,
    required this.pecas,
    required this.label,
  });

  static const _unicode = {
    'K': '♔', 'Q': '♕', 'R': '♖', 'B': '♗', 'N': '♘', 'P': '♙',
    'k': '♚', 'q': '♛', 'r': '♜', 'b': '♝', 'n': '♞', 'p': '♟',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 1,
          runSpacing: 1,
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
                  return Text(
                    _unicode[p] ?? p,
                    style: const TextStyle(fontSize: 20),
                  );
                }).toList(),
        ),
      ],
    );
  }
}
