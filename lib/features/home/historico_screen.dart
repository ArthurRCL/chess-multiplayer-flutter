import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/api_service.dart';
import 'package:go_router/go_router.dart';

class HistoricoScreen extends ConsumerWidget {
  const HistoricoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Meu Histórico')),
      body: FutureBuilder<List<dynamic>>(
        future: ref.read(apiServiceProvider).historico(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          final partidas = snapshot.data ?? [];
          if (partidas.isEmpty) {
            return Center(
              child: Text(
                'Nenhuma partida ainda.\nCrie uma e convide alguém! ♟',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: partidas.length,
            itemBuilder: (_, i) {
              final p = partidas[i] as Map<String, dynamic>;
              final status = p['status'] as String;
              final vencedor = p['vencedorEmail'] as String?;
              final id = p['id'] as String;

              IconData icon;
              Color cor;
              String label;

              switch (status) {
                case 'FINALIZADA':
                  icon = vencedor != null ? Icons.emoji_events : Icons.handshake;
                  cor = vencedor != null ? Colors.amber : Colors.blueGrey;
                  label = vencedor != null ? '🏆 $vencedor' : '🤝 Empate';
                case 'EM_ANDAMENTO':
                  icon = Icons.sports_esports;
                  cor = Colors.greenAccent;
                  label = 'Em andamento';
                default:
                  icon = Icons.hourglass_empty;
                  cor = Colors.orange;
                  label = 'Aguardando';
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Icon(icon, color: cor),
                  title: Text(
                    '${p['jogadorBrancasEmail']} vs ${p['jogadorNegrasEmail'] ?? '?'}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(label,
                      style: TextStyle(color: cor, fontSize: 12)),
                  trailing: status == 'EM_ANDAMENTO'
                      ? const Icon(Icons.chevron_right)
                      : null,
                  onTap: status == 'EM_ANDAMENTO'
                      ? () => context.push('/partida/$id')
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
