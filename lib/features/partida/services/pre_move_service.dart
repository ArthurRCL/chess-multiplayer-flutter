import '../models/pre_move.dart';

/// Responsabilidade única: gerenciar a fila de pré-movimentos.
///
/// O Lichess e o Chess.com permitem apenas 1 pré-movimento por vez.
/// Registrar um novo substitui o anterior automaticamente.
///
/// Este service é 100% client-side — o servidor nunca conhece o pré-move.
/// Se o movimento for ilegal quando executado, o erro é descartado silenciosamente.
class PreMoveService {
  PreMove? _pendente;

  /// Registra um pré-movimento, substituindo qualquer um anterior.
  void registrar(String from, String to, {String? promocao}) {
    _pendente = PreMove(from: from, to: to, promocao: promocao);
  }

  /// Consome e retorna o pré-movimento pendente, se houver.
  /// Após consumir, a fila fica vazia.
  PreMove? consumir() {
    final move = _pendente;
    _pendente = null;
    return move;
  }

  /// Cancela o pré-movimento pendente sem executá-lo.
  void cancelar() => _pendente = null;

  /// Retorna true se há um pré-movimento aguardando execução.
  bool get temPreMove => _pendente != null;

  /// Retorna o pré-movimento atual sem consumi-lo (útil para renderização).
  PreMove? get atual => _pendente;
}
