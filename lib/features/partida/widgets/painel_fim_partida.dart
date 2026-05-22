import 'package:flutter/material.dart';

/// Overlay exibido ao final de uma partida.
///
/// Responsabilidade única: apresentar o resultado e as ações pós-partida
/// (revanche e voltar ao início). Não contém lógica de negócio.
class PainelFimPartida extends StatelessWidget {
  final String? vencedorEmail;
  final String? motivoFim;
  final String meuEmail;
  final VoidCallback onRevanche;
  final VoidCallback onVoltar;

  const PainelFimPartida({
    super.key,
    required this.vencedorEmail,
    required this.motivoFim,
    required this.meuEmail,
    required this.onRevanche,
    required this.onVoltar,
  });

  String get _titulo {
    if (vencedorEmail == null) return 'Empate!';
    if (vencedorEmail == meuEmail) return 'Você venceu!';
    return 'Você perdeu.';
  }

  String get _subtitulo {
    switch (motivoFim) {
      case 'XEQUE_MATE':
        return 'Por xeque-mate';
      case 'TIMEOUT':
        return vencedorEmail == meuEmail
            ? 'O adversário ficou sem tempo'
            : 'Seu tempo esgotou';
      case 'DESISTENCIA':
        return vencedorEmail == meuEmail
            ? 'O adversário desistiu'
            : 'Você desistiu';
      case 'AFOGAMENTO':
        return 'Afogamento — Empate';
      default:
        return vencedorEmail != null
            ? 'Vencedor: ${vencedorEmail!.split('@').first}'
            : 'Empate';
    }
  }

  Color get _corTitulo {
    if (vencedorEmail == null) return const Color(0xFFFFEE58);
    if (vencedorEmail == meuEmail) return const Color(0xFF81C784);
    return const Color(0xFFE57373);
  }

  IconData get _icone {
    if (vencedorEmail == null) return Icons.handshake_outlined;
    if (vencedorEmail == meuEmail) return Icons.emoji_events_rounded;
    return Icons.sentiment_dissatisfied_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0D0D0D),
            Color(0xFF1A1A2E),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _corTitulo.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _corTitulo.withValues(alpha: 0.2),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ícone animado
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.5, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Icon(_icone, size: 56, color: _corTitulo),
          ),
          const SizedBox(height: 16),

          // Título principal
          Text(
            _titulo,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: _corTitulo,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),

          // Subtítulo (motivo)
          Text(
            _subtitulo,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Color(0xFF9E9E9E),
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Botões de ação
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Voltar ao início
              OutlinedButton.icon(
                onPressed: onVoltar,
                icon: const Icon(Icons.home_outlined, size: 18),
                label: const Text('Início'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF9E9E9E),
                  side: const BorderSide(color: Color(0xFF3A3A3A)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Revanche — destaque visual
              ElevatedButton.icon(
                onPressed: onRevanche,
                icon: const Icon(Icons.replay_rounded, size: 18),
                label: const Text(
                  'Revanche',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: const Color(0xFF0D0D0D),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  shadowColor: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
