/// Representa um pré-movimento registrado pelo jogador durante o turno do adversário.
///
/// Imutável por design — um pré-move nunca é modificado, apenas substituído ou descartado.
class PreMove {
  final String from;
  final String to;
  final String? promocao;

  const PreMove({
    required this.from,
    required this.to,
    this.promocao,
  });

  @override
  String toString() => 'PreMove($from → $to${promocao != null ? " =$promocao" : ""})';
}
