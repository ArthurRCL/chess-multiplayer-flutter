import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────── Model ───────────────────────────────────────────

class RelatorioData {
  final String abertura;
  final String visaoGeral;
  final int notaBrancas;
  final String analiseBrancas;
  final List<String> dicasBrancas;
  final int notaNegras;
  final String analiseNegras;
  final List<String> dicasNegras;

  RelatorioData({
    required this.abertura,
    required this.visaoGeral,
    required this.notaBrancas,
    required this.analiseBrancas,
    required this.dicasBrancas,
    required this.notaNegras,
    required this.analiseNegras,
    required this.dicasNegras,
  });

  factory RelatorioData.fromJson(Map<String, dynamic> json) {
    List<String> toStringList(dynamic v) {
      if (v is List) return v.map((e) => e.toString()).toList();
      return [];
    }

    return RelatorioData(
      abertura: json['abertura']?.toString() ?? 'Abertura Livre',
      visaoGeral: json['visao_geral']?.toString() ?? '',
      notaBrancas: (json['nota_brancas'] as num?)?.toInt().clamp(1, 10) ?? 5,
      analiseBrancas: json['analise_brancas']?.toString() ?? '',
      dicasBrancas: toStringList(json['dicas_brancas']),
      notaNegras: (json['nota_negras'] as num?)?.toInt().clamp(1, 10) ?? 5,
      analiseNegras: json['analise_negras']?.toString() ?? '',
      dicasNegras: toStringList(json['dicas_negras']),
    );
  }

  String toClipboardText() => '''
♟ RELATÓRIO DE DESEMPENHO - Análise por IA ♟

🏛️ Abertura: $abertura

📋 Visão Geral
$visaoGeral

♔ BRANCAS — Nota: $notaBrancas/10
$analiseBrancas

Dicas:
${dicasBrancas.asMap().entries.map((e) => '  ${e.key + 1}. ${e.value}').join('\n')}

♚ NEGRAS — Nota: $notaNegras/10
$analiseNegras

Dicas:
${dicasNegras.asMap().entries.map((e) => '  ${e.key + 1}. ${e.value}').join('\n')}
''';
}

// ─────────────────────────── Estado ──────────────────────────────────────────

enum _Estado { carregando, sucesso, erro }

// ─────────────────────────── Dialog ──────────────────────────────────────────

class RelatorioIADialog extends StatefulWidget {
  final Future<Map<String, dynamic>> Function() onGerarRelatorio;

  const RelatorioIADialog({super.key, required this.onGerarRelatorio});

  static Future<void> mostrar(
    BuildContext context, {
    required Future<Map<String, dynamic>> Function() onGerarRelatorio,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.82),
      builder: (_) => RelatorioIADialog(onGerarRelatorio: onGerarRelatorio),
    );
  }

  @override
  State<RelatorioIADialog> createState() => _RelatorioIADialogState();
}

class _RelatorioIADialogState extends State<RelatorioIADialog>
    with TickerProviderStateMixin {
  _Estado _estado = _Estado.carregando;
  RelatorioData? _dados;
  String _mensagemErro = '';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _estado = _Estado.carregando);
    try {
      final json = await widget.onGerarRelatorio();
      if (mounted) {
        setState(() {
          _dados = RelatorioData.fromJson(json);
          _estado = _Estado.sucesso;
        });
        _pulseController.stop();
        _fadeController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _estado = _Estado.erro;
          _mensagemErro = _extrairErro(e);
        });
        _pulseController.stop();
      }
    }
  }

  String _extrairErro(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data.containsKey('erro')) return data['erro'] as String;
      final status = e.response?.statusCode;
      if (status == 502) return 'Erro ao comunicar com a IA. Verifique a chave de API.';
    }
    final msg = e.toString();
    if (msg.contains('timeout') || msg.contains('SocketException')) {
      return 'Conexão com o servidor expirou. Verifique sua rede.';
    }
    if (msg.contains('Exception:')) return msg.replaceFirst('Exception: ', '');
    return 'Não foi possível gerar o relatório. Tente novamente.';
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 640, maxWidth: 520),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D1A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF2A2050), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C3AED).withValues(alpha: 0.3),
              blurRadius: 48,
              spreadRadius: 4,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              Flexible(child: _buildBody()),
              if (_estado != _Estado.carregando) _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 14, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A0F3A), Color(0xFF0F1A35)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(bottom: BorderSide(color: Color(0xFF2A2050), width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withValues(alpha: 0.5), blurRadius: 14)],
            ),
            child: const Center(child: Text('📊', style: TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Relatório de Desempenho',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Powered by Groq · LLaMA 3',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: Color(0xFF7B6FA8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: Color(0xFF6B6B8A), size: 22),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  // ── Body ───────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: switch (_estado) {
        _Estado.carregando => _buildCarregando(),
        _Estado.sucesso    => _buildRelatorio(),
        _Estado.erro       => _buildErro(),
      },
    );
  }

  Widget _buildCarregando() {
    return SizedBox(
      key: const ValueKey('loading'),
      height: 300,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (_, child) => Opacity(opacity: _pulseAnimation.value, child: child),
            child: const Text('🧠', style: TextStyle(fontSize: 56)),
          ),
          const SizedBox(height: 24),
          const Text(
            'Analisando a partida...',
            style: TextStyle(fontFamily: 'Inter', fontSize: 16, color: Color(0xFFB0A8CC), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'A IA está estudando seus movimentos',
            style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF6B6B8A)),
          ),
          const SizedBox(height: 28),
          _buildDotsLoader(),
        ],
      ),
    );
  }

  Widget _buildDotsLoader() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (_, __) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (i) {
          final v = ((_pulseController.value + i * 0.33) % 1.0);
          final opacity = (v < 0.5 ? v * 2 : (1 - v) * 2).clamp(0.3, 1.0);
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withValues(alpha: opacity),
              shape: BoxShape.circle,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildErro() {
    return SizedBox(
      key: const ValueKey('erro'),
      height: 260,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFE57373), size: 52),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Text(
              _mensagemErro,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF9E9E9E), height: 1.55),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () { _fadeController.reset(); _carregar(); },
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Tentar novamente'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF9C84E4),
              side: const BorderSide(color: Color(0xFF7C3AED)),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Relatório Profissional ─────────────────────────────────────────────────

  Widget _buildRelatorio() {
    final d = _dados!;
    return FadeTransition(
      opacity: _fadeAnimation,
      key: const ValueKey('relatorio'),
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Sumário da partida ─────────────────────────────────────────
              _buildSumarioCard(d),
              const SizedBox(height: 12),

              // ── Notas dos jogadores ────────────────────────────────────────
              Row(
                children: [
                  Expanded(child: _buildScoreCard(_buildColorIcon(true, 22), 'Brancas', d.notaBrancas, const Color(0xFFF0E6D3))),
                  const SizedBox(width: 10),
                  Expanded(child: _buildScoreCard(_buildColorIcon(false, 22), 'Negras', d.notaNegras, const Color(0xFF8A8A9A))),
                ],
              ),
              const SizedBox(height: 14),

              // ── Visão Geral ────────────────────────────────────────────────
              _buildSectionHeader(const Text('📋', style: TextStyle(fontSize: 16)), 'Visão Geral'),
              const SizedBox(height: 8),
              _buildTextCard(d.visaoGeral),
              const SizedBox(height: 14),

              // ── Análise Brancas ────────────────────────────────────────────
              _buildSectionHeader(_buildColorIcon(true, 16), 'Análise das Brancas'),
              const SizedBox(height: 8),
              if (d.analiseBrancas.isNotEmpty) ...[
                _buildTextCard(d.analiseBrancas),
                const SizedBox(height: 8),
              ],
              ...d.dicasBrancas.asMap().entries.map(
                (e) => _buildTipItem(e.key + 1, e.value, const Color(0xFF7C3AED)),
              ),
              const SizedBox(height: 14),

              // ── Análise Negras ─────────────────────────────────────────────
              _buildSectionHeader(_buildColorIcon(false, 16), 'Análise das Negras'),
              const SizedBox(height: 8),
              if (d.analiseNegras.isNotEmpty) ...[
                _buildTextCard(d.analiseNegras),
                const SizedBox(height: 8),
              ],
              ...d.dicasNegras.asMap().entries.map(
                (e) => _buildTipItem(e.key + 1, e.value, const Color(0xFF2563EB)),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSumarioCard(RelatorioData d) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF16102A), Color(0xFF0F1828)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2050)),
      ),
      child: Row(
        children: [
          const Text('🏛️', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.abertura,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFD4C8F0),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Abertura identificada pela IA',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF7B6FA8)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.4)),
            ),
            child: const Text(
              '♟ IA',
              style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF9C84E4), fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorIcon(bool isWhite, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isWhite ? Colors.white : const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(size * 0.25),
        border: Border.all(color: isWhite ? Colors.grey.shade300 : Colors.grey.shade600, width: 1.5),
        boxShadow: [
          if (isWhite) BoxShadow(color: Colors.white.withValues(alpha: 0.2), blurRadius: 4)
          else BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 4),
        ],
      ),
    );
  }

  Widget _buildScoreCard(Widget icon, String label, int nota, Color accentColor) {
    final pct = nota / 10.0;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF13102A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2050)),
      ),
      child: Column(
        children: [
          icon,
          const SizedBox(height: 10),
          SizedBox(
            width: 70,
            height: 70,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(70, 70),
                  painter: _RingPainter(progress: pct, color: accentColor),
                ),
                Text(
                  '$nota',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF9E9E9E), fontWeight: FontWeight.w600),
          ),
          Text(
            _notaLabel(nota),
            style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: _notaColor(nota), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _notaLabel(int n) => switch (n) {
    >= 9  => 'Excelente',
    >= 7  => 'Bom',
    >= 5  => 'Regular',
    >= 3  => 'Fraco',
    _     => 'Iniciante',
  };

  Color _notaColor(int n) => switch (n) {
    >= 9  => const Color(0xFF4CAF50),
    >= 7  => const Color(0xFF8BC34A),
    >= 5  => const Color(0xFFFFC107),
    >= 3  => const Color(0xFFFF9800),
    _     => const Color(0xFFF44336),
  };

  Widget _buildSectionHeader(Widget icon, String title) {
    return Row(
      children: [
        icon,
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFFD4C8F0),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Container(height: 1, color: const Color(0xFF2A2050))),
      ],
    );
  }

  Widget _buildTextCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF13102A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E1A3A)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          color: Color(0xFFCCC4E0),
          height: 1.65,
        ),
      ),
    );
  }

  Widget _buildTipItem(int n, String tip, Color accentColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(right: 10, top: 1),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$n',
                style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w800, color: accentColor),
              ),
            ),
          ),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFFCCC4E0), height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF1E1A3A), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_estado == _Estado.sucesso && _dados != null)
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _dados!.toClipboardText()));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Relatório copiado!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 15),
              label: const Text('Copiar'),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF9C84E4)),
            ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Fechar', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Painter do anel de pontuação ────────────────────

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = (size.width - 10) / 2;
    final trackPaint = Paint()
      ..color = const Color(0xFF2A2050)
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset(cx, cy), r, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress || old.color != color;
}
