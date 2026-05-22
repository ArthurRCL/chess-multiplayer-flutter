import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/api_service.dart';
import '../../core/services/websocket_service.dart';
import '../../core/storage/secure_storage.dart';
import '../../shared/theme/app_theme.dart';
import 'tabuleiro_widget.dart';
import 'chess_logic.dart';
import 'pecas_capturadas_widget.dart';

// Estado da partida em tempo real
class PartidaState {
  final String fen;
  final String status; // AGUARDANDO, EM_ANDAMENTO, FINALIZADA
  final String vezDe; // BRANCAS ou NEGRAS
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
      // 1. Buscar informações da partida via REST
      final info =
          await ref.read(apiServiceProvider).buscarPartida(widget.partidaId);
      final email = await ref.read(secureStorageProvider).getEmail();

      // 2. Tentar ingressar (se ainda aguardando e não for o criador)
      if (info['status'] == 'AGUARDANDO' &&
          info['jogadorBrancasEmail'] != email) {
        await ref.read(apiServiceProvider).entrarNaPartida(widget.partidaId);
      }

      final minhasCorEhBrancas = info['jogadorBrancasEmail'] == email;

      setState(() {
        _estado = _estado.copyWith(
          fen: info['fen'] as String?,
          status: info['status'] as String?,
          minhasCorEhBrancas: minhasCorEhBrancas,
        );
      });

      // 3. Conectar ao WebSocket
      ref.read(webSocketServiceProvider).conectar(
            partidaId: widget.partidaId,
            userEmail: email ?? '',
            onConnected: () => setState(() {
              _estado = _estado.copyWith(wsConectado: true);
            }),
            onEstado: (data) {
              // O body vem como string JSON — parsear
              final raw = data['raw'] as String?;
              if (raw == null) return;
              final parsed = jsonDecode(raw) as Map<String, dynamic>;
              setState(() {
                _casaSelecionada = null; // Limpa seleção ao receber novo estado
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
            },
            onErro: (erro) => setState(() {
              _estado = _estado.copyWith(erro: erro);
            }),
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
      // Selecionar peça: só aceita se houver peça da cor correta
      setState(() {
        _casaSelecionada = casa;
      });
    } else if (_casaSelecionada == casa) {
      // Tocar na mesma casa: desseleciona
      setState(() {
        _casaSelecionada = null;
      });
    } else {
      // Verificar se o destino é um movimento válido
      final movimentos =
          ChessLogic.movimentosPossiveis(_estado.fen, _casaSelecionada!);
      if (movimentos.contains(casa)) {
        // Mover peça
        final from = _casaSelecionada!;
        setState(() {
          _casaSelecionada = null;
        });
        ref.read(webSocketServiceProvider).enviarMovimento(
              widget.partidaId,
              from,
              casa,
            );
      } else {
        // Tentar selecionar nova peça no destino clicado
        setState(() {
          _casaSelecionada = casa;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const chessTheme = AppTheme.defaultTheme;
    final capturadas = ChessLogic.pecasCapturadas(_estado.fen);

    // Quem está em cima e quem está em baixo depende da orientação
    // Jogador adversário = topo; jogador local = base
    final pecasTopoLabel = _estado.minhasCorEhBrancas
        ? 'Capturadas pelo adversário'
        : 'Capturadas por mim';
    final pecasTopoList = _estado.minhasCorEhBrancas
        ? capturadas.negras // Brancas capturadas (adversário capturou)
        : capturadas.brancas; // Negras capturadas pelo adversário

    final pecasBaseLabel =
        _estado.minhasCorEhBrancas ? 'Capturadas por mim' : 'Capturadas pelo adversário';
    final pecasBaseList = _estado.minhasCorEhBrancas
        ? capturadas.brancas // Negras capturadas (eu capturei)
        : capturadas.negras;

    return Scaffold(
      appBar: AppBar(
        title: Text(_estado.status == 'AGUARDANDO'
            ? 'Aguardando adversário...'
            : 'Partida em andamento'),
        actions: [
          if (_estado.status == 'EM_ANDAMENTO')
            TextButton(
              onPressed: _desistir,
              child: const Text('Desistir',
                  style: TextStyle(color: Colors.redAccent)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Indicador de status
          _StatusBar(estado: _estado, theme: theme),

          // Peças capturadas pelo adversário (topo)
          _PainelCapturadas(
            label: pecasTopoLabel,
            pecas: pecasTopoList,
          ),

          // Tabuleiro
          Expanded(
            child: Center(
              child: TabuleiroWidget(
                fen: _estado.fen,
                casaSelecionada: _casaSelecionada,
                invertido: !_estado.minhasCorEhBrancas,
                lightSquare: chessTheme.lightSquare,
                darkSquare: chessTheme.darkSquare,
                highlightColor: chessTheme.highlightColor,
                selectedColor: chessTheme.selectedColor,
                onCasaTocada: _onCasaTocada,
              ),
            ),
          ),

          // Peças capturadas por mim (base)
          _PainelCapturadas(
            label: pecasBaseLabel,
            pecas: pecasBaseList,
          ),

          // Mensagem de erro
          if (_estado.erro != null)
            Container(
              color: Colors.redAccent.withValues(alpha: 0.2),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(_estado.erro!,
                  style: const TextStyle(color: Colors.redAccent)),
            ),
        ],
      ),
    );
  }

  void _desistir() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Desistir da partida?'),
        content: const Text('Seu adversário será declarado vencedor.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
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

// ─────────────────────────────────────────────────────────────────────────────
//  Painel compacto de peças capturadas
// ─────────────────────────────────────────────────────────────────────────────
class _PainelCapturadas extends StatelessWidget {
  final String label;
  final List<String> pecas;

  const _PainelCapturadas({required this.label, required this.pecas});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      color: theme.colorScheme.surface.withValues(alpha: 0.85),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: PecasCapturadas(label: label, pecas: pecas),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Barra de status
// ─────────────────────────────────────────────────────────────────────────────
class _StatusBar extends StatelessWidget {
  final PartidaState estado;
  final ThemeData theme;

  const _StatusBar({required this.estado, required this.theme});

  @override
  Widget build(BuildContext context) {
    String mensagem;
    Color cor;

    if (estado.status == 'AGUARDANDO') {
      mensagem = '⏳ Aguardando o segundo jogador entrar...';
      cor = Colors.orange;
    } else if (estado.xequeMate) {
      mensagem = '♚ Xeque-mate! Vencedor: ${estado.vencedorEmail ?? "?"}';
      cor = Colors.amber;
    } else if (estado.afogamento) {
      mensagem = '🤝 Afogamento — empate!';
      cor = Colors.blueGrey;
    } else if (estado.status == 'FINALIZADA') {
      mensagem = estado.vencedorEmail != null
          ? '🏆 Partida encerrada. Vencedor: ${estado.vencedorEmail}'
          : '🤝 Empate';
      cor = Colors.amber;
    } else if (estado.xeque) {
      mensagem = '⚠ Xeque! Vez das ${estado.vezDe.toLowerCase()}';
      cor = Colors.redAccent;
    } else {
      mensagem = '▶ Vez das ${estado.vezDe.toLowerCase()}';
      cor = theme.colorScheme.primary;
    }

    return Container(
      width: double.infinity,
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Text(mensagem,
          textAlign: TextAlign.center,
          style: TextStyle(color: cor, fontWeight: FontWeight.bold)),
    );
  }
}
