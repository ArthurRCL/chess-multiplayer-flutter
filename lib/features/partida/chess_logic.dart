/// Motor de lógica de xadrez para calcular movimentos legais no frontend.
/// Usado para mostrar o "caminho da peça" ao selecionar uma casa.
library chess_logic;

class ChessLogic {
  /// Dada uma posição FEN e uma casa de origem, retorna todas as casas
  /// para as quais a peça pode legalmente se mover (sem deixar o rei em xeque).
  static Set<String> movimentosPossiveis(String fen, String casaOrigem, {bool ignorarVez = false}) {
    final partes = fen.split(' ');
    final posicao = partes[0];
    final vezDeFen = partes.length > 1 ? partes[1] : 'w';
    final castling = partes.length > 2 ? partes[2] : 'KQkq';
    final enPassant = partes.length > 3 ? partes[3] : '-';

    final tabuleiro = _parsearFen(posicao);
    final peca = tabuleiro[casaOrigem];
    if (peca == null) return {};

    final ehBranca = peca == peca.toUpperCase();
    final vezEhBranca = vezDeFen == 'w';

    // A peça deve ser da cor que tem a vez (a menos que seja um pré-movimento/ignorarVez)
    if (!ignorarVez && ehBranca != vezEhBranca) return {};

    final candidatos = _movimentosBrutos(
      tabuleiro: tabuleiro,
      origem: casaOrigem,
      peca: peca,
      castling: castling,
      enPassant: enPassant,
    );

    // Filtrar movimentos que deixam o próprio rei em xeque
    final legais = <String>{};
    for (final destino in candidatos) {
      final tabuleiroApos = _aplicarMovimento(
        Map.from(tabuleiro),
        casaOrigem,
        destino,
        peca,
        enPassant,
      );
      if (!_reiEmXeque(tabuleiroApos, ehBranca)) {
        legais.add(destino);
      }
    }

    return legais;
  }

  // ──────────────────────────────────────────────────────────
  //  Helpers internos
  // ──────────────────────────────────────────────────────────

  static Map<String, String> _parsearFen(String posicao) {
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

  static int _col(String casa) => casa.codeUnitAt(0) - 'a'.codeUnitAt(0);
  static int _row(String casa) => int.parse(casa[1]) - 1;
  static String? _casa(int col, int row) {
    if (col < 0 || col > 7 || row < 0 || row > 7) return null;
    return '${'abcdefgh'[col]}${row + 1}';
  }

  static bool _ehInimiga(String? peca, bool origemBranca) {
    if (peca == null) return false;
    final pecaBranca = peca == peca.toUpperCase();
    return pecaBranca != origemBranca;
  }

  static bool _ehAmiga(String? peca, bool origemBranca) {
    if (peca == null) return false;
    final pecaBranca = peca == peca.toUpperCase();
    return pecaBranca == origemBranca;
  }

  /// Gera movimentos "brutos" sem verificar xeque.
  static Set<String> _movimentosBrutos({
    required Map<String, String> tabuleiro,
    required String origem,
    required String peca,
    required String castling,
    required String enPassant,
  }) {
    final tipo = peca.toUpperCase();
    final ehBranca = peca == peca.toUpperCase();
    final col = _col(origem);
    final row = _row(origem);
    final movs = <String>{};

    switch (tipo) {
      case 'P':
        _movimentosPeao(tabuleiro, col, row, ehBranca, enPassant, movs);
        break;
      case 'R':
        _movimentosReta(tabuleiro, col, row, ehBranca, movs);
        break;
      case 'B':
        _movimentosDiagonal(tabuleiro, col, row, ehBranca, movs);
        break;
      case 'Q':
        _movimentosReta(tabuleiro, col, row, ehBranca, movs);
        _movimentosDiagonal(tabuleiro, col, row, ehBranca, movs);
        break;
      case 'N':
        _movimentosCavalo(tabuleiro, col, row, ehBranca, movs);
        break;
      case 'K':
        _movimentosRei(tabuleiro, col, row, ehBranca, castling, movs);
        break;
    }

    return movs;
  }

  static void _movimentosPeao(
    Map<String, String> tab,
    int col,
    int row,
    bool ehBranca,
    String enPassant,
    Set<String> movs,
  ) {
    final dir = ehBranca ? 1 : -1;
    final fileiraNova = row + dir;

    // Avançar 1
    final frente = _casa(col, fileiraNova);
    if (frente != null && tab[frente] == null) {
      movs.add(frente);
      // Avançar 2 (se na fileira inicial)
      final filaInicial = ehBranca ? 1 : 6;
      if (row == filaInicial) {
        final duasFrente = _casa(col, row + 2 * dir);
        if (duasFrente != null && tab[duasFrente] == null) {
          movs.add(duasFrente);
        }
      }
    }

    // Capturas diagonais
    for (final dc in [-1, 1]) {
      final casa = _casa(col + dc, fileiraNova);
      if (casa == null) continue;
      // Captura normal
      if (_ehInimiga(tab[casa], ehBranca)) movs.add(casa);
      // En passant
      if (casa == enPassant) movs.add(casa);
    }
  }

  static void _movimentosReta(
    Map<String, String> tab,
    int col,
    int row,
    bool ehBranca,
    Set<String> movs,
  ) {
    for (final dir in [
      [1, 0],
      [-1, 0],
      [0, 1],
      [0, -1],
    ]) {
      var c = col + dir[0];
      var r = row + dir[1];
      while (c >= 0 && c < 8 && r >= 0 && r < 8) {
        final casa = _casa(c, r)!;
        if (tab[casa] == null) {
          movs.add(casa);
        } else if (_ehInimiga(tab[casa], ehBranca)) {
          movs.add(casa);
          break;
        } else {
          break;
        }
        c += dir[0];
        r += dir[1];
      }
    }
  }

  static void _movimentosDiagonal(
    Map<String, String> tab,
    int col,
    int row,
    bool ehBranca,
    Set<String> movs,
  ) {
    for (final dir in [
      [1, 1],
      [1, -1],
      [-1, 1],
      [-1, -1],
    ]) {
      var c = col + dir[0];
      var r = row + dir[1];
      while (c >= 0 && c < 8 && r >= 0 && r < 8) {
        final casa = _casa(c, r)!;
        if (tab[casa] == null) {
          movs.add(casa);
        } else if (_ehInimiga(tab[casa], ehBranca)) {
          movs.add(casa);
          break;
        } else {
          break;
        }
        c += dir[0];
        r += dir[1];
      }
    }
  }

  static void _movimentosCavalo(
    Map<String, String> tab,
    int col,
    int row,
    bool ehBranca,
    Set<String> movs,
  ) {
    const saltos = [
      [2, 1], [2, -1], [-2, 1], [-2, -1],
      [1, 2], [1, -2], [-1, 2], [-1, -2],
    ];
    for (final s in saltos) {
      final casa = _casa(col + s[0], row + s[1]);
      if (casa != null && !_ehAmiga(tab[casa], ehBranca)) {
        movs.add(casa);
      }
    }
  }

  static void _movimentosRei(
    Map<String, String> tab,
    int col,
    int row,
    bool ehBranca,
    String castling,
    Set<String> movs,
  ) {
    for (var dc = -1; dc <= 1; dc++) {
      for (var dr = -1; dr <= 1; dr++) {
        if (dc == 0 && dr == 0) continue;
        final casa = _casa(col + dc, row + dr);
        if (casa != null && !_ehAmiga(tab[casa], ehBranca)) {
          movs.add(casa);
        }
      }
    }

    // Roque curto
    if (ehBranca && castling.contains('K')) {
      if (tab['f1'] == null && tab['g1'] == null) {
        movs.add('g1');
      }
    }
    if (!ehBranca && castling.contains('k')) {
      if (tab['f8'] == null && tab['g8'] == null) {
        movs.add('g8');
      }
    }
    // Roque longo
    if (ehBranca && castling.contains('Q')) {
      if (tab['d1'] == null && tab['c1'] == null && tab['b1'] == null) {
        movs.add('c1');
      }
    }
    if (!ehBranca && castling.contains('q')) {
      if (tab['d8'] == null && tab['c8'] == null && tab['b8'] == null) {
        movs.add('c8');
      }
    }
  }

  /// Aplica o movimento no mapa e retorna o novo estado (sem validar xeque).
  static Map<String, String> _aplicarMovimento(
    Map<String, String> tab,
    String origem,
    String destino,
    String peca,
    String enPassant,
  ) {
    tab[destino] = peca;
    tab.remove(origem);

    final tipo = peca.toUpperCase();
    final ehBranca = peca == peca.toUpperCase();

    // Roque: mover torre junto
    if (tipo == 'K') {
      if (origem == 'e1' && destino == 'g1') {
        tab['f1'] = 'R';
        tab.remove('h1');
      } else if (origem == 'e1' && destino == 'c1') {
        tab['d1'] = 'R';
        tab.remove('a1');
      } else if (origem == 'e8' && destino == 'g8') {
        tab['f8'] = 'r';
        tab.remove('h8');
      } else if (origem == 'e8' && destino == 'c8') {
        tab['d8'] = 'r';
        tab.remove('a8');
      }
    }

    // En passant: remover peão capturado
    if (tipo == 'P' && destino == enPassant && enPassant != '-') {
      final dir = ehBranca ? -1 : 1;
      final row = _row(destino) + dir;
      final casa = _casa(_col(destino), row);
      if (casa != null) tab.remove(casa);
    }

    return tab;
  }

  /// Verifica se o rei da cor indicada está em xeque.
  static bool _reiEmXeque(Map<String, String> tab, bool reiEhBranco) {
    // Encontrar a posição do rei
    final reiChar = reiEhBranco ? 'K' : 'k';
    String? posRei;
    for (final entry in tab.entries) {
      if (entry.value == reiChar) {
        posRei = entry.key;
        break;
      }
    }
    if (posRei == null) return true; // Rei capturado = inválido

    // Verificar se alguma peça inimiga ataca o rei
    for (final entry in tab.entries) {
      final peca = entry.value;
      final pecaEhBranca = peca == peca.toUpperCase();
      if (pecaEhBranca == reiEhBranco) continue; // Peça amiga, ignorar

      final ataques = _movimentosBrutos(
        tabuleiro: tab,
        origem: entry.key,
        peca: peca,
        castling: '-', // Não verificar roque durante xeque
        enPassant: '-',
      );
      if (ataques.contains(posRei)) return true;
    }
    return false;
  }

  // ──────────────────────────────────────────────────────────
  //  Peças capturadas
  // ──────────────────────────────────────────────────────────

  static const _pecasIniciaisBrancas = {
    'P': 8, 'N': 2, 'B': 2, 'R': 2, 'Q': 1, 'K': 1,
  };
  static const _pecasIniciaisNegras = {
    'p': 8, 'n': 2, 'b': 2, 'r': 2, 'q': 1, 'k': 1,
  };

  /// Retorna a lista de peças capturadas de cada cor,
  /// ordenadas por valor (mais valiosas por último).
  static ({List<String> brancas, List<String> negras}) pecasCapturadas(
      String fen) {
    final posicao = fen.split(' ').first;
    final tab = _parsearFen(posicao);

    // Contar peças atuais
    final contagem = <String, int>{};
    for (final p in tab.values) {
      contagem[p] = (contagem[p] ?? 0) + 1;
    }

    // Brancas capturadas = peças negras que sumiram
    final capturadasBrancas = <String>[]; // As que o jogador branco capturou (negras)
    final capturadasNegras = <String>[]; // As que o jogador negro capturou (brancas)

    for (final entry in _pecasIniciaisNegras.entries) {
      final atual = contagem[entry.key] ?? 0;
      final capturadas = entry.value - atual;
      for (var i = 0; i < capturadas; i++) {
        capturadasBrancas.add(entry.key); // Peça negra capturada
      }
    }

    for (final entry in _pecasIniciaisBrancas.entries) {
      final atual = contagem[entry.key] ?? 0;
      final capturadas = entry.value - atual;
      for (var i = 0; i < capturadas; i++) {
        capturadasNegras.add(entry.key); // Peça branca capturada
      }
    }

    // Ordenar por valor
    final ordem = {'p': 1, 'n': 2, 'b': 2, 'r': 5, 'q': 9, 'k': 0};
    capturadasBrancas.sort((a, b) =>
        (ordem[a.toLowerCase()] ?? 0).compareTo(ordem[b.toLowerCase()] ?? 0));
    capturadasNegras.sort((a, b) =>
        (ordem[a.toLowerCase()] ?? 0).compareTo(ordem[b.toLowerCase()] ?? 0));

    return (brancas: capturadasBrancas, negras: capturadasNegras);
  }
}
