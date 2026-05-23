import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/api_service.dart';
import '../../core/services/websocket_service.dart';
import '../../core/storage/secure_storage.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/theme/theme_preference_provider.dart';
import '../../shared/widgets/animated_status_chip.dart';
import 'services/pre_move_service.dart';
import 'tabuleiro_widget.dart';
import 'widgets/relogio_widget.dart';
import 'widgets/painel_fim_partida.dart';
import '../home/themes_screen.dart';
import 'chess_logic.dart';

// ── Estado da partida ─────────────────────────────────────────────────────────

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
  final String? meuEmail;
  final int tempoBrancasMs;
  final int tempoNegrasMs;
  final String? motivoFim;
  final bool modoSolo;

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
    this.meuEmail,
    this.tempoBrancasMs = -1,
    this.tempoNegrasMs = -1,
    this.motivoFim,
    this.modoSolo = false,
  });

  bool get finalizada => status == 'FINALIZADA';
  // No modo solo sempre é minha vez (controlo os dois lados)
  bool get minhaVez =>
      modoSolo ||
      (vezDe == 'BRANCAS' && minhasCorEhBrancas) ||
      (vezDe == 'NEGRAS' && !minhasCorEhBrancas);

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
    String? meuEmail,
    int? tempoBrancasMs,
    int? tempoNegrasMs,
    String? motivoFim,
    bool? modoSolo,
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
        meuEmail: meuEmail ?? this.meuEmail,
        tempoBrancasMs: tempoBrancasMs ?? this.tempoBrancasMs,
        tempoNegrasMs: tempoNegrasMs ?? this.tempoNegrasMs,
        motivoFim: motivoFim ?? this.motivoFim,
        modoSolo: modoSolo ?? this.modoSolo,
      );
}

// ── Tela da Partida ───────────────────────────────────────────────────────────

class PartidaScreen extends ConsumerStatefulWidget {
  final String partidaId;
  const PartidaScreen({super.key, required this.partidaId});

  @override
  ConsumerState<PartidaScreen> createState() => _PartidaScreenState();
}

class _PartidaScreenState extends ConsumerState<PartidaScreen> {
  PartidaState _estado = const PartidaState();
  String? _casaSelecionada;
  Set<String> _movimentosPossiveis = {};

  // Pré-movimento: gerenciado por service de responsabilidade única
  final _preMoveService = PreMoveService();

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  // ── Inicialização ─────────────────────────────────────────────────────────

  Future<void> _inicializar() async {
    try {
      final api = ref.read(apiServiceProvider);
      final storage = ref.read(secureStorageProvider);

      final info = await api.buscarPartida(widget.partidaId);
      final email = await storage.getEmail();

      var status = info['status'] as String?;
      var fen = info['fen'] as String?;

      if (info['status'] == 'AGUARDANDO' &&
          info['jogadorBrancasEmail'] != email) {
        final newState = await api.entrarNaPartida(widget.partidaId);
        status = newState['status'] as String?;
        fen = newState['fen'] as String?;
      }

      final minhasCorEhBrancas = info['jogadorBrancasEmail'] == email;
      // Modo solo: o mesmo usuário é os dois jogadores
      final ehModoSolo = info['jogadorBrancasEmail'] == info['jogadorNegrasEmail'] &&
          info['jogadorNegrasEmail'] != null;

      if (mounted) {
        setState(() {
          _estado = _estado.copyWith(
            fen: fen,
            status: status,
            minhasCorEhBrancas: minhasCorEhBrancas,
            meuEmail: email,
            modoSolo: ehModoSolo,
          );
        });
      }

      _conectarWebSocket(email ?? '');
    } catch (e) {
      if (mounted) {
        setState(() {
          _estado = _estado.copyWith(erro: 'Erro ao carregar partida: $e');
        });
      }
    }
  }

  void _conectarWebSocket(String email) {
    ref.read(webSocketServiceProvider).conectar(
          partidaId: widget.partidaId,
          userEmail: email,
          onConnected: () {
            if (mounted) setState(() => _estado = _estado.copyWith(wsConectado: true));
          },
          onEstado: _onEstadoRecebido,
          onErro: (erro) {
            if (mounted) setState(() => _estado = _estado.copyWith(erro: erro));
          },
          onNovaPartida: _onRevancheAceita,
        );
  }

  // ── Handlers de WebSocket ─────────────────────────────────────────────────

  void _onEstadoRecebido(Map<String, dynamic> data) {
    final raw = data['raw'] as String?;
    if (raw == null) return;
    final parsed = jsonDecode(raw) as Map<String, dynamic>;

    final novoStatus = parsed['status'] as String? ?? _estado.status;
    final novaVez = parsed['vezDe'] as String? ?? _estado.vezDe;

    if (!mounted) return;
    setState(() {
      _estado = _estado.copyWith(
        fen: parsed['fen'] as String?,
        status: novoStatus,
        vezDe: novaVez,
        vencedorEmail: parsed['vencedorEmail'] as String?,
        xeque: parsed['xeque'] as bool? ?? false,
        xequeMate: parsed['xequeMate'] as bool? ?? false,
        afogamento: parsed['afogamento'] as bool? ?? false,
        tempoBrancasMs: (parsed['tempoBrancasMs'] as num?)?.toInt() ?? _estado.tempoBrancasMs,
        tempoNegrasMs: (parsed['tempoNegrasMs'] as num?)?.toInt() ?? _estado.tempoNegrasMs,
        motivoFim: parsed['motivoFim'] as String?,
      );
    });

    // Executa pré-movimento automaticamente se agora é minha vez
    _tentarExecutarPreMove();
  }

  void _onRevancheAceita(String novaPartidaId) {
    if (!mounted) return;
    // Navega para a nova partida substituindo a tela atual
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PartidaScreen(partidaId: novaPartidaId),
      ),
    );
  }

  // ── Pré-movimentos ────────────────────────────────────────────────────────

  void _tentarExecutarPreMove() {
    if (!_estado.minhaVez || _estado.status != 'EM_ANDAMENTO') return;
    final preMove = _preMoveService.consumir();
    if (preMove == null) return;

    ref.read(webSocketServiceProvider).enviarMovimento(
          widget.partidaId,
          preMove.from,
          preMove.to,
          promocao: preMove.promocao,
        );
  }

  // ── Interações com o tabuleiro ────────────────────────────────────────────

  void _onCasaTocada(String casa) {
    if (_estado.status != 'EM_ANDAMENTO') return;

    if (_estado.minhaVez) {
      _tratarMovimentoNormal(casa);
    } else {
      _tratarPreMove(casa);
    }
  }

  void _tratarMovimentoNormal(String casa) {
    if (_casaSelecionada == null) {
      final possiveis = ChessLogic.movimentosPossiveis(_estado.fen, casa);
      if (possiveis.isNotEmpty) {
        setState(() {
          _casaSelecionada = casa;
          _movimentosPossiveis = possiveis;
        });
      }
    } else {
      if (_movimentosPossiveis.contains(casa)) {
        final from = _casaSelecionada!;
        setState(() {
          _casaSelecionada = null;
          _movimentosPossiveis.clear();
        });
        _enviarMovimento(from, casa);
      } else {
        final possiveis = ChessLogic.movimentosPossiveis(_estado.fen, casa);
        if (possiveis.isNotEmpty) {
          setState(() {
            _casaSelecionada = casa;
            _movimentosPossiveis = possiveis;
          });
        } else {
          setState(() {
            _casaSelecionada = null;
            _movimentosPossiveis.clear();
          });
        }
      }
    }
  }

  void _tratarPreMove(String casa) {
    if (_casaSelecionada == null) {
      final possiveis = ChessLogic.movimentosPossiveis(_estado.fen, casa, ignorarVez: true);
      if (possiveis.isNotEmpty) {
        setState(() {
          _casaSelecionada = casa;
          _movimentosPossiveis = possiveis;
        });
      }
    } else {
      if (_movimentosPossiveis.contains(casa)) {
        final from = _casaSelecionada!;
        setState(() {
          _casaSelecionada = null;
          _movimentosPossiveis.clear();
        });
        _registrarPreMove(from, casa);
      } else {
        final possiveis = ChessLogic.movimentosPossiveis(_estado.fen, casa, ignorarVez: true);
        if (possiveis.isNotEmpty) {
          setState(() {
            _casaSelecionada = casa;
            _movimentosPossiveis = possiveis;
          });
        } else {
          setState(() {
            _casaSelecionada = null;
            _movimentosPossiveis.clear();
          });
        }
      }
    }
  }

  void _onArrastado(String from, String to) {
    if (_estado.status != 'EM_ANDAMENTO') return;
    setState(() {
      _casaSelecionada = null;
      _movimentosPossiveis.clear();
    });

    final possiveis = ChessLogic.movimentosPossiveis(_estado.fen, from, ignorarVez: !_estado.minhaVez);
    if (!possiveis.contains(to)) return;

    if (_estado.minhaVez) {
      _enviarMovimento(from, to);
    } else {
      _registrarPreMove(from, to);
    }
  }

  // ── Helpers de Movimento ──────────────────────────────────────────────────

  void _enviarMovimento(String from, String to) {
    String? promocao;
    if (ChessLogic.isPromocao(_estado.fen, from, to)) {
      promocao = 'q'; // Auto-promove para Dama por padrão
    }
    ref.read(webSocketServiceProvider).enviarMovimento(
          widget.partidaId, from, to, promocao: promocao);
  }

  void _registrarPreMove(String from, String to) {
    String? promocao;
    if (ChessLogic.isPromocao(_estado.fen, from, to)) {
      promocao = 'q';
    }
    _preMoveService.registrar(from, to, promocao: promocao);
  }

  // ── Ações ─────────────────────────────────────────────────────────────────

  void _desistir() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Desistir da partida?'),
        content: const Text(
            'Seu adversário será declarado vencedor. Você tem certeza?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.textPrimary,
            ),
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(webSocketServiceProvider)
                  .desistir(widget.partidaId);
            },
            child: const Text('Desistir'),
          ),
        ],
      ),
    );
  }

  void _solicitarRevanche() {
    ref.read(webSocketServiceProvider).solicitarRevanche(widget.partidaId);
  }

  @override
  void dispose() {
    ref.read(webSocketServiceProvider).desconectar();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final themePrefs = ref.watch(themePreferenceProvider);
    final chessTheme = themePrefs.boardTheme.toChessTheme();

    // Os relógios: adversário em cima, meu embaixo
    final meuTempoMs = _estado.minhasCorEhBrancas
        ? _estado.tempoBrancasMs
        : _estado.tempoNegrasMs;
    final adversarioTempoMs = _estado.minhasCorEhBrancas
        ? _estado.tempoNegrasMs
        : _estado.tempoBrancasMs;
    final minhaVezAtiva = _estado.minhaVez && _estado.status == 'EM_ANDAMENTO';
    final adversarioAtivo = !_estado.minhaVez && _estado.status == 'EM_ANDAMENTO';

    // Indicação visual de pré-movimento: destaca casa de origem em laranja
    final preMoveAtual = _preMoveService.atual;
    final casaPreMoveFrom = preMoveAtual?.from;

    return Scaffold(
      appBar: AppBar(
        title: Text(_estado.modoSolo
            ? '♟ Modo Solo'
            : (_estado.status == 'AGUARDANDO'
                ? 'Aguardando...'
                : 'Partida em andamento')),
        actions: [
          IconButton(
            tooltip: 'Personalizar temas',
            icon: const Icon(Icons.palette_outlined, color: AppColors.gold2),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ThemesScreen()),
            ),
          ),
          if (_estado.status == 'EM_ANDAMENTO')
            IconButton(
              tooltip: 'Desistir',
              icon: const Icon(Icons.flag_outlined, color: AppColors.danger),
              onPressed: _desistir,
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: Column(
          children: [
            // Status bar premium
            _buildStatusBar(),

            // Relógio do adversário (topo)
            if (adversarioTempoMs != -1)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    RelogioWidget(
                      tempoMs: adversarioTempoMs,
                      ativo: adversarioAtivo,
                      label: 'Adversário',
                    ),
                  ],
                ),
              ),

            // Tabuleiro com borda elegante
            Expanded(
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
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
                    casaPreMove: casaPreMoveFrom,
                    movimentosPossiveis: _movimentosPossiveis,
                    invertido: !_estado.minhasCorEhBrancas,
                    lightSquare: chessTheme.lightSquare,
                    darkSquare: chessTheme.darkSquare,
                    highlightColor: chessTheme.highlightColor,
                    selectedColor: chessTheme.selectedColor,
                    pieceStyle: themePrefs.pieceStyle,
                    onCasaTocada: _onCasaTocada,
                    onArrastado: _onArrastado,
                  ),
                ),
              ),
            ),

            // Relógio do jogador (base)
            if (meuTempoMs != -1)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    RelogioWidget(
                      tempoMs: meuTempoMs,
                      ativo: minhaVezAtiva,
                      label: 'Você',
                    ),
                  ],
                ),
              ),

            // Painel de fim de partida (substituindo o chip antigo quando finalizada)
            if (_estado.finalizada)
              Padding(
                padding: const EdgeInsets.all(16),
                child: PainelFimPartida(
                  vencedorEmail: _estado.vencedorEmail,
                  motivoFim: _estado.motivoFim,
                  meuEmail: _estado.meuEmail ?? '',
                  onRevanche: _solicitarRevanche,
                  onVoltar: () => Navigator.of(context).pop(),
                ),
              ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    // Se finalizada, o PainelFimPartida já exibe o resultado — chip mínimo
    if (_estado.finalizada) {
      return Container(
        width: double.infinity,
        color: AppColors.surface1,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
        child: Center(
          child: AnimatedStatusChip(
            label: _estado.vencedorEmail != null
                ? 'Fim de jogo'
                : 'Empate',
            type: StatusType.finished,
            pulsing: false,
          ),
        ),
      );
    }

    StatusType chipType;
    String chipLabel;
    bool pulse = false;

    if (_estado.status == 'AGUARDANDO') {
      chipType = StatusType.waiting;
      chipLabel = 'Aguardando adversário...';
      pulse = true;
    } else if (_estado.xequeMate) {
      chipType = StatusType.checkmate;
      chipLabel =
          'Xeque-mate! Vencedor: ${_estado.vencedorEmail?.split('@').first ?? "?"}';
    } else if (_estado.afogamento) {
      chipType = StatusType.draw;
      chipLabel = 'Afogamento — Empate';
    } else if (_estado.xeque) {
      chipType = StatusType.check;
      chipLabel = '⚠ Xeque! Vez das ${_estado.vezDe.toLowerCase()}';
      pulse = true;
    } else {
      chipType = StatusType.playing;
      if (_estado.modoSolo) {
        // No modo solo mostra de qual cor é a vez
        chipLabel = 'Vez das ${_estado.vezDe == "BRANCAS" ? "\u2659 Brancas" : "\u265f Negras"}';
      } else {
        chipLabel = _estado.minhaVez ? 'Sua vez' : 'Vez do adversário';
      }
      if (_preMoveService.temPreMove) {
        chipLabel += ' · Pré-move registrado';
      }
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
}
