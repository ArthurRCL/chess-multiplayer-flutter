import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/api_service.dart';
import '../../core/services/websocket_service.dart';
import '../../core/storage/secure_storage.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/animated_status_chip.dart';
import 'tabuleiro_widget.dart';

// Estado da partida em tempo real
class PartidaState {
  final String fen;
  final String status;
  final String vezDe;
  final String? vencedorEmail;
  final bool xeque;
  final bool xequeMate;
  final bool afogamento;
  final bool wsConectado;
  final String? erro;
  final bool minhasCorEhBrancas;

  const PartidaState({
    this.fen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
    this.status = 'AGUARDANDO',
    this.vezDe = 'BRANCAS',
    this.vencedorEmail,
    this.xeque = false,
    this.xequeMate = false,
    this.afogamento = false,
    this.wsConectado = false,
    this.erro,
    this.minhasCorEhBrancas = true,
  });

  PartidaState copyWith({
    String? fen,
    String? status,
    String? vezDe,
    String? vencedorEmail,
    bool? xeque,
    bool? xequeMate,
    bool? afogamento,
    bool? wsConectado,
    String? erro,
    bool? minhasCorEhBrancas,
  }) =>
      PartidaState(
        fen: fen ?? this.fen,
        status: status ?? this.status,
        vezDe: vezDe ?? this.vezDe,
        vencedorEmail: vencedorEmail ?? this.vencedorEmail,
        xeque: xeque ?? this.xeque,
        xequeMate: xequeMate ?? this.xequeMate,
        afogamento: afogamento ?? this.afogamento,
        wsConectado: wsConectado ?? this.wsConectado,
        erro: erro,
        minhasCorEhBrancas: minhasCorEhBrancas ?? this.minhasCorEhBrancas,
      );
}

class PartidaScreen extends ConsumerStatefulWidget {
  final String partidaId;
  const PartidaScreen({super.key, required this.partidaId});

  @override
  ConsumerState<PartidaScreen> createState() => _PartidaScreenState();
}

class _PartidaScreenState extends ConsumerState<PartidaScreen> {
  PartidaState _estado = const PartidaState();
  String? _casaSelecionada;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    try {
      final info =
          await ref.read(apiServiceProvider).buscarPartida(widget.partidaId);
      final email = await ref.read(secureStorageProvider).getEmail();

      var status = info['status'] as String?;
      var fen = info['fen'] as String?;

      if (info['status'] == 'AGUARDANDO' &&
          info['jogadorBrancasEmail'] != email) {
        final newState = await ref.read(apiServiceProvider).entrarNaPartida(widget.partidaId);
        status = newState['status'] as String?;
        fen = newState['fen'] as String?;
      }

      final minhasCorEhBrancas = info['jogadorBrancasEmail'] == email;

      setState(() {
        _estado = _estado.copyWith(
          fen: fen,
          status: status,
          minhasCorEhBrancas: minhasCorEhBrancas,
        );
      });

      ref.read(webSocketServiceProvider).conectar(
            partidaId: widget.partidaId,
            userEmail: email ?? '',
            onConnected: () {
              if (mounted) {
                setState(() {
                  _estado = _estado.copyWith(wsConectado: true);
                });
              }
            },
            onEstado: (data) {
              final raw = data['raw'] as String?;
              if (raw == null) return;
              final parsed = jsonDecode(raw) as Map<String, dynamic>;
              if (mounted) {
                setState(() {
                  _estado = _estado.copyWith(
                    fen: parsed['fen'] as String?,
                    status: parsed['status'] as String?,
                    vezDe: parsed['vezDe'] as String?,
                    vencedorEmail: parsed['vencedorEmail'] as String?,
                    xeque: parsed['xeque'] as bool? ?? false,
                    xequeMate: parsed['xequeMate'] as bool? ?? false,
                    afogamento: parsed['afogamento'] as bool? ?? false,
                  );
                });
              }
            },
            onErro: (erro) {
              if (mounted) {
                setState(() {
                  _estado = _estado.copyWith(erro: erro);
                });
              }
            },
          );
    } catch (e) {
      setState(() {
        _estado = _estado.copyWith(erro: 'Erro ao carregar partida: $e');
      });
    }
  }

  @override
  void dispose() {
    ref.read(webSocketServiceProvider).desconectar();
    super.dispose();
  }

  void _onCasaTocada(String casa) {
    if (_estado.status != 'EM_ANDAMENTO') return;

    final minhaVez =
        (_estado.vezDe == 'BRANCAS' && _estado.minhasCorEhBrancas) ||
            (_estado.vezDe == 'NEGRAS' && !_estado.minhasCorEhBrancas);
    if (!minhaVez) return;

    if (_casaSelecionada == null) {
      setState(() {
        _casaSelecionada = casa;
      });
    } else {
      final from = _casaSelecionada!;
      setState(() {
        _casaSelecionada = null;
      });
      ref.read(webSocketServiceProvider).enviarMovimento(
            widget.partidaId,
            from,
            casa,
          );
    }
  }

  void _onArrastado(String from, String to) {
    if (_estado.status != 'EM_ANDAMENTO') return;

    final minhaVez =
        (_estado.vezDe == 'BRANCAS' && _estado.minhasCorEhBrancas) ||
            (_estado.vezDe == 'NEGRAS' && !_estado.minhasCorEhBrancas);
    if (!minhaVez) return;

    setState(() {
      _casaSelecionada = null; // Limpa se houver algo selecionado por clique
    });

    ref.read(webSocketServiceProvider).enviarMovimento(
          widget.partidaId,
          from,
          to,
        );
  }

  @override
  Widget build(BuildContext context) {
    const chessTheme = AppTheme.defaultTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_estado.status == 'AGUARDANDO'
            ? 'Aguardando...'
            : 'Partida em andamento'),
        actions: [
          if (_estado.status == 'EM_ANDAMENTO')
            IconButton(
              tooltip: 'Desistir',
              icon: const Icon(Icons.flag_outlined, color: AppColors.danger),
              onPressed: _desistir,
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppGradients.background,
        ),
        child: Column(
          children: [
            // Status bar premium
            _buildStatusBar(),

            // Tabuleiro com borda elegante
            Expanded(
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.gold2, width: 4),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: TabuleiroWidget(
                    fen: _estado.fen,
                    casaSelecionada: _casaSelecionada,
                    invertido: !_estado.minhasCorEhBrancas,
                    lightSquare: chessTheme.lightSquare,
                    darkSquare: chessTheme.darkSquare,
                    highlightColor: chessTheme.highlightColor,
                    selectedColor: chessTheme.selectedColor,
                    onCasaTocada: _onCasaTocada,
                    onArrastado: _onArrastado,
                  ),
                ),
              ),
            ),

            // Mensagem de erro
            if (_estado.erro != null)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.danger.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.danger),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _estado.erro!,
                        style: const TextStyle(color: AppColors.danger),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    StatusType chipType;
    String chipLabel;
    bool pulse = false;

    if (_estado.status == 'AGUARDANDO') {
      chipType = StatusType.waiting;
      chipLabel = 'Aguardando adversário...';
      pulse = true;
    } else if (_estado.xequeMate) {
      chipType = StatusType.checkmate;
      chipLabel = 'Xeque-mate! Vencedor: ${_estado.vencedorEmail?.split('@').first ?? "?"}';
    } else if (_estado.afogamento) {
      chipType = StatusType.draw;
      chipLabel = 'Afogamento — Empate';
    } else if (_estado.status == 'FINALIZADA') {
      chipType = StatusType.finished;
      chipLabel = _estado.vencedorEmail != null
          ? 'Vencedor: ${_estado.vencedorEmail?.split('@').first}'
          : 'Empate';
    } else if (_estado.xeque) {
      chipType = StatusType.check;
      chipLabel = '⚠ Xeque! Vez das ${_estado.vezDe.toLowerCase()}';
      pulse = true;
    } else {
      chipType = StatusType.playing;
      chipLabel = 'Vez das ${_estado.vezDe.toLowerCase()}';
      pulse = true;
    }

    return Container(
      width: double.infinity,
      color: AppColors.surface1,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Center(
        child: AnimatedStatusChip(
          label: chipLabel,
          type: chipType,
          pulsing: pulse,
        ),
      ),
    );
  }

  void _desistir() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Desistir da partida?'),
        content: const Text('Seu adversário será declarado vencedor. Você tem certeza?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.textPrimary,
            ),
            onPressed: () {
              Navigator.pop(context);
              ref.read(webSocketServiceProvider).desistir(widget.partidaId);
            },
            child: const Text('Desistir'),
          ),
        ],
      ),
    );
  }
}
