import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Renderiza o tabuleiro de xadrez 8x8.
/// Agora utiliza assets em SVG para máxima fidelidade e suporta Drag & Drop.
class TabuleiroWidget extends StatelessWidget {
  final String fen;
  final String? casaSelecionada;
  /// Casa de origem do pré-movimento pendente (pintada em âmbar).
  final String? casaPreMove;
  final bool invertido;
  final Color lightSquare;
  final Color darkSquare;
  final Color highlightColor;
  final Color selectedColor;
  final void Function(String casa) onCasaTocada;
  final void Function(String from, String to) onArrastado;

  const TabuleiroWidget({
    super.key,
    required this.fen,
    required this.casaSelecionada,
    this.casaPreMove,
    required this.invertido,
    required this.lightSquare,
    required this.darkSquare,
    required this.highlightColor,
    required this.selectedColor,
    required this.onCasaTocada,
    required this.onArrastado,
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

  /// Mapeia o caractere FEN para o SVG da peça Cburnett
  String? _getSvgAsset(String char) {
    switch (char) {
      case 'K': return 'assets/pieces/wK.svg';
      case 'Q': return 'assets/pieces/wQ.svg';
      case 'R': return 'assets/pieces/wR.svg';
      case 'B': return 'assets/pieces/wB.svg';
      case 'N': return 'assets/pieces/wN.svg';
      case 'P': return 'assets/pieces/wP.svg';
      case 'k': return 'assets/pieces/bK.svg';
      case 'q': return 'assets/pieces/bQ.svg';
      case 'r': return 'assets/pieces/bR.svg';
      case 'b': return 'assets/pieces/bB.svg';
      case 'n': return 'assets/pieces/bN.svg';
      case 'p': return 'assets/pieces/bP.svg';
      default: return null;
    }
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
      child: Column(
        children: fileiras.map((fileira) {
          return Expanded(
            child: Row(
              children: colOrdem.map((ci) {
                final col = colunas[ci];
                final casa = '$col$fileira';
                // a1 (0 + 1 = 1) -> 1 % 2 == 0 é falso, então é escuro.
                final isClara = (ci + fileira) % 2 == 0;
                final peca = pecas[casa];
                final asset = peca != null ? _getSvgAsset(peca) : null;
                final selecionada = casaSelecionada == casa;

                return Expanded(
                  child: DragTarget<String>(
                    onAccept: (from) {
                      if (from != casa) {
                        onArrastado(from, casa);
                      }
                    },
                    builder: (context, candidateData, rejectedData) {
                      Color corFundo = isClara ? lightSquare : darkSquare;
                      if (selecionada) {
                        corFundo = selectedColor;
                      } else if (casa == casaPreMove) {
                        // Pré-movimento: destaque âmbar/laranja
                        corFundo = const Color(0xFFFFA726).withOpacity(0.75);
                      } else if (candidateData.isNotEmpty) {
                        corFundo = highlightColor;
                      }

                      return GestureDetector(
                        onTap: () => onCasaTocada(casa),
                        child: Container(
                          color: corFundo,
                          child: Stack(
                            children: [
                              // Coordenada numérica (esquerda)
                              if (ci == (invertido ? 7 : 0))
                                Positioned(
                                  top: 2,
                                  left: 3,
                                  child: Text(
                                    '$fileira',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      color: isClara ? darkSquare : lightSquare,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              // Coordenada alfabética (fundo direito)
                              if (fileira == (invertido ? 8 : 1))
                                Positioned(
                                  bottom: 0,
                                  right: 3,
                                  child: Text(
                                    col,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      color: isClara ? darkSquare : lightSquare,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              // Peça com suporte a Drag
                              if (asset != null)
                                Positioned.fill(
                                  child: Draggable<String>(
                                    data: casa,
                                    feedback: SizedBox(
                                      // Multiplica um pouco o tamanho no drag para efeito visual
                                      width: MediaQuery.of(context).size.width / 8 * 1.2,
                                      height: MediaQuery.of(context).size.width / 8 * 1.2,
                                      child: SvgPicture.asset(asset),
                                    ),
                                    childWhenDragging: Opacity(
                                      opacity: 0.3,
                                      child: SvgPicture.asset(asset),
                                    ),
                                    child: SvgPicture.asset(asset),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}
