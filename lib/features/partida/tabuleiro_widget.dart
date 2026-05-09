import 'package:flutter/material.dart';

/// Renderiza o tabuleiro de xadrez 8x8.
/// Recebe o FEN para determinar as peças, e callbacks para interação.
class TabuleiroWidget extends StatelessWidget {
  final String fen;
  final String? casaSelecionada;
  final bool invertido;
  final Color lightSquare;
  final Color darkSquare;
  final Color highlightColor;
  final Color selectedColor;
  final void Function(String casa) onCasaTocada;

  const TabuleiroWidget({
    super.key,
    required this.fen,
    required this.casaSelecionada,
    required this.invertido,
    required this.lightSquare,
    required this.darkSquare,
    required this.highlightColor,
    required this.selectedColor,
    required this.onCasaTocada,
  });

  // Parseia a parte de posição do FEN para um mapa {casa: peça}
  Map<String, String> _parsearFen(String fen) {
    final posicao = fen.split(' ').first;
    final linhas = posicao.split('/');
    final mapa = <String, String>{};
    const colunas = 'abcdefgh';

    for (int fileira = 0; fileira < 8; fileira++) {
      int coluna = 0;
      for (final char in linhas[fileira].split('')) {
        final num = int.tryParse(char);
        if (num != null) {
          coluna += num;
        } else {
          final casa = '${colunas[coluna]}${8 - fileira}';
          mapa[casa] = char;
          coluna++;
        }
      }
    }
    return mapa;
  }

  @override
  Widget build(BuildContext context) {
    final pecas = _parsearFen(fen);
    const colunas = 'abcdefgh';

    final fileiras = invertido
        ? List.generate(8, (i) => i + 1)
        : List.generate(8, (i) => 8 - i);
    final colOrdem = invertido
        ? List.generate(8, (i) => 7 - i)
        : List.generate(8, (i) => i);

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: darkSquare, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: fileiras.map((fileira) {
            return Expanded(
              child: Row(
                children: colOrdem.map((ci) {
                  final col = colunas[ci];
                  final casa = '$col$fileira';
                  final isClara = (ci + fileira) % 2 == 0;
                  final peca = pecas[casa];
                  final selecionada = casaSelecionada == casa;

                  Color corFundo = isClara ? lightSquare : darkSquare;
                  if (selecionada) corFundo = selectedColor;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onCasaTocada(casa),
                      child: Container(
                        color: corFundo,
                        child: Stack(
                          children: [
                            // Coordenada (canto inferior esquerdo da coluna a / canto superior direito da fileira 8)
                            if (ci == 0)
                              Positioned(
                                top: 2,
                                left: 3,
                                child: Text(
                                  '$fileira',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: isClara ? darkSquare : lightSquare,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            if (fileira == (invertido ? 8 : 1))
                              Positioned(
                                bottom: 2,
                                right: 3,
                                child: Text(
                                  col,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: isClara ? darkSquare : lightSquare,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            // Peça
                            if (peca != null)
                              Center(
                                child: FittedBox(
                                  child: Padding(
                                    padding: const EdgeInsets.all(2),
                                    child: Text(
                                      _fenParaUnicode(peca),
                                      style: const TextStyle(fontSize: 36),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Converte o caractere FEN para o símbolo Unicode da peça.
  /// Brancas: maiúsculas → símbolos brancos; Negras: minúsculas → símbolos negros
  String _fenParaUnicode(String fen) {
    const map = {
      'K': '♔', 'Q': '♕', 'R': '♖', 'B': '♗', 'N': '♘', 'P': '♙',
      'k': '♚', 'q': '♛', 'r': '♜', 'b': '♝', 'n': '♞', 'p': '♟',
    };
    return map[fen] ?? fen;
  }
}
