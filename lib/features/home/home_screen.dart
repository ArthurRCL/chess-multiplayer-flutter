import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/storage/secure_storage.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('♟ Xadrez Online'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Histórico',
            onPressed: () => context.push('/historico'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () async {
              await ref.read(authServiceProvider).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Saudação
              FutureBuilder<String?>(
                future: ref.read(secureStorageProvider).getEmail(),
                builder: (ctx, snap) => Text(
                  'Olá, ${snap.data?.split('@').first ?? 'jogador'}!',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'O que deseja fazer?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 48),

              // Card — Criar partida
              _ActionCard(
                icon: Icons.add_circle_outline,
                title: 'Nova Partida',
                subtitle: 'Crie uma sala e convide um amigo via link',
                onTap: () => _criarPartida(context, ref),
              ),
              const SizedBox(height: 20),

              // Card — Histórico
              _ActionCard(
                icon: Icons.history_edu,
                title: 'Histórico',
                subtitle: 'Veja suas partidas anteriores',
                onTap: () => context.push('/historico'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _criarPartida(BuildContext context, WidgetRef ref) async {
    try {
      final data = await ref.read(apiServiceProvider).criarPartida();
      final link = data['linkConvite'] as String;
      final id = data['id'] as String;

      if (!context.mounted) return;

      showModalBottomSheet(
        context: context,
        builder: (_) => _ConviteSheet(link: link, partidaId: id),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao criar partida')),
        );
      }
    }
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 40, color: theme.colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        )),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        )),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConviteSheet extends StatelessWidget {
  final String link;
  final String partidaId;

  const _ConviteSheet({required this.link, required this.partidaId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Partida criada! ♟',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.primary,
              )),
          const SizedBox(height: 8),
          Text('Compartilhe o link com seu adversário:',
              style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.primary),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(link,
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: link));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Link copiado!')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.share),
                  label: const Text('Compartilhar'),
                  onPressed: () => Share.share(
                    'Vamos jogar xadrez? Clique no link: $link',
                    subject: 'Convite de partida de xadrez',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    side: BorderSide(color: theme.colorScheme.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/partida/$partidaId');
                  },
                  child: const Text('Entrar na sala'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
