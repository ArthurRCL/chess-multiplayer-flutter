import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/api_service.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/animated_status_chip.dart';
import '../../shared/widgets/glass_card.dart';

class HistoricoScreen extends ConsumerStatefulWidget {
  const HistoricoScreen({super.key});

  @override
  ConsumerState<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends ConsumerState<HistoricoScreen> {
  late Future<List<dynamic>> _historicoFuture;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _carregar() {
    _historicoFuture = ref.read(apiServiceProvider).historico();
  }

  Future<void> _deletar(String id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir do Histórico?'),
        content: const Text('Isso removerá esta partida do seu histórico.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.textPrimary,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await ref.read(apiServiceProvider).deletarPartida(id);
        setState(() {
          _carregar();
        });
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Histórico'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _historicoFuture,
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erro: ${snapshot.error}',
                style: const TextStyle(color: AppColors.danger),
              ),
            );
          }

          final partidas = snapshot.data ?? [];
          if (partidas.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: partidas.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (_, i) {
              final p = partidas[i] as Map<String, dynamic>;
              final status = p['status'] as String;
              final vencedor = p['vencedorEmail'] as String?;
              final id = p['id'] as String;

              final isEmAndamento = status == 'EM_ANDAMENTO';
              final isFinalizada = status == 'FINALIZADA';

              StatusType chipType;
              String chipLabel;

              if (isFinalizada) {
                if (vencedor != null) {
                  chipType = StatusType.finished;
                  chipLabel = '🏆 ${_shortEmail(vencedor)}';
                } else {
                  chipType = StatusType.draw;
                  chipLabel = '🤝 Empate';
                }
              } else if (isEmAndamento) {
                chipType = StatusType.playing;
                chipLabel = 'Em andamento';
              } else {
                chipType = StatusType.waiting;
                chipLabel = 'Aguardando';
              }

              return GlassCard(
                elevation: 0,
                padding: const EdgeInsets.all(16),
                onTap: isEmAndamento || status == 'AGUARDANDO' ? () => context.push('/partida/$id') : null,
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.surface2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: Icon(
                        isFinalizada ? Icons.emoji_events : Icons.sports_esports,
                        color: isFinalizada ? AppColors.gold2 : AppColors.purple1,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Brancas vs Negras',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_shortEmail(p['jogadorBrancasEmail'])} vs ${_shortEmail(p['jogadorNegrasEmail'] ?? '?')}',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          AnimatedStatusChip(
                            label: chipLabel,
                            type: chipType,
                            pulsing: isEmAndamento,
                          ),
                        ],
                      ),
                    ),
                    if (isEmAndamento)
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                    if (isFinalizada)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                        onPressed: () => _deletar(id),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _shortEmail(String email) {
    if (email == '?') return email;
    return email.split('@').first;
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface1,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: const Icon(Icons.history, size: 64, color: AppColors.gold2),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nenhuma partida ainda',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crie uma nova partida na tela inicial e convide alguém para jogar! ♟',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            OutlinedButton(
              onPressed: () => context.pop(),
              child: const Text('Voltar para o Início'),
            ),
          ],
        ),
      ),
    );
  }
}
