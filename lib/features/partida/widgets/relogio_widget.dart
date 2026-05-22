import 'dart:async';
import 'package:flutter/material.dart';

/// Widget de relógio regressivo para xadrez.
///
/// Responsabilidade única: exibir e atualizar o tempo restante de um jogador.
/// As cores mudam dinamicamente conforme o tempo diminui (verde → amarelo → vermelho),
/// seguindo o padrão visual do Lichess e Chess.com.
class RelogioWidget extends StatefulWidget {
  /// Tempo restante em milissegundos. -1 = sem limite (relógio não exibido).
  final int tempoMs;

  /// Se true, o relógio está rodando (vez deste jogador).
  final bool ativo;

  /// Label do jogador (ex: "Você" ou "Adversário").
  final String label;

  const RelogioWidget({
    super.key,
    required this.tempoMs,
    required this.ativo,
    required this.label,
  });

  @override
  State<RelogioWidget> createState() => _RelogioWidgetState();
}

class _RelogioWidgetState extends State<RelogioWidget> {
  Timer? _timer;
  int _tempoMs = 0;

  @override
  void initState() {
    super.initState();
    _tempoMs = widget.tempoMs;
    _gerenciarTimer();
  }

  @override
  void didUpdateWidget(RelogioWidget old) {
    super.didUpdateWidget(old);
    // Sincroniza com o tempo vindo do servidor
    if ((widget.tempoMs - _tempoMs).abs() > 200 || !widget.ativo) {
      _tempoMs = widget.tempoMs;
    }
    _gerenciarTimer();
  }

  void _gerenciarTimer() {
    _timer?.cancel();
    if (widget.ativo && _tempoMs > 0 && widget.tempoMs != -1) {
      _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (!mounted) return;
        setState(() {
          _tempoMs = (_tempoMs - 100).clamp(0, double.maxFinite.toInt());
        });
        if (_tempoMs <= 0) _timer?.cancel();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatarTempo(int ms) {
    if (ms <= 0) return '0:00';
    final totalSegundos = ms ~/ 1000;
    final minutos = totalSegundos ~/ 60;
    final segundos = totalSegundos % 60;
    return '$minutos:${segundos.toString().padLeft(2, '0')}';
  }

  Color _corDoTempo(int ms) {
    if (ms <= 0) return const Color(0xFFE53935);   // vermelho — esgotado
    if (ms < 10000) return const Color(0xFFE53935); // vermelho — < 10s
    if (ms < 30000) return const Color(0xFFFFA726); // laranja — < 30s
    if (ms < 60000) return const Color(0xFFFFEE58); // amarelo — < 1min
    return const Color(0xFF81C784);                 // verde — confortável
  }

  @override
  Widget build(BuildContext context) {
    // Sem limite: não renderiza nada
    if (widget.tempoMs == -1) return const SizedBox.shrink();

    final cor = _corDoTempo(_tempoMs);
    final texto = _formatarTempo(_tempoMs);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: widget.ativo
            ? cor.withValues(alpha: 0.18)
            : const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.ativo ? cor : const Color(0xFF3A3A3A),
          width: widget.ativo ? 2 : 1,
        ),
        boxShadow: widget.ativo
            ? [BoxShadow(color: cor.withValues(alpha: 0.25), blurRadius: 12)]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 18,
            color: widget.ativo ? cor : const Color(0xFF888888),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 11,
                  color: widget.ativo ? cor.withValues(alpha: 0.85) : const Color(0xFF888888),
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                texto,
                style: TextStyle(
                  fontSize: 26,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  color: widget.ativo ? cor : const Color(0xFF888888),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
