import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/storage/secure_storage.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/glass_card.dart';
import 'themes_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, ref),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    // Card — Criar partida
                    ActionCard(
                      icon: Icons.add_circle_outline,
                      title: 'Nova Partida',
                      subtitle: 'Crie uma sala e convide um amigo',
                      isPrimary: true,
                      onTap: () => _mostrarOpcoesDeTempo(context, ref),
                    ),
                    const SizedBox(height: 16),

                    // Card — Modo Solo (Teste)
                    ActionCard(
                      icon: Icons.person,
                      title: 'Modo Solo',
                      subtitle: 'Jogue os dois lados para testar',
                      accentColor: AppColors.gold2,
                      onTap: () => _jogarSolo(context, ref),
                    ),
                    const SizedBox(height: 20),

                    // Card — Histórico
                    ActionCard(
                      icon: Icons.history_edu,
                      title: 'Meu Histórico',
                      subtitle: 'Veja suas partidas anteriores',
                      accentColor: AppColors.purple1,
                      onTap: () => context.push('/historico'),
                    ),
                    const SizedBox(height: 16),

                    // Card — Personalizar
                    ActionCard(
                      icon: Icons.palette_outlined,
                      title: 'Personalizar',
                      subtitle: 'Temas de tabuleiro e estilos de peças',
                      accentColor: const Color(0xFF00D4FF),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ThemesScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border(
          bottom: BorderSide(color: AppColors.glassBorder, width: 1),
        ),
      ),
      child: FutureBuilder<String?>(
        future: ref.read(secureStorageProvider).getEmail(),
        builder: (ctx, snap) {
          final nome = snap.data?.split('@').first ?? 'Jogador';
          return Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppGradients.gold,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold2.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    nome[0].toUpperCase(),
                    style: GoogleFonts.cinzel(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.bg0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bem-vindo,',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      nome,
                      style: GoogleFonts.cinzel(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: AppColors.textSecondary),
                tooltip: 'Sair',
                onPressed: () => _confirmLogout(context, ref),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sair do Jogo?'),
        content: const Text('Tem certeza que deseja desconectar sua conta?'),
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
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authServiceProvider).logout();
              ref.invalidate(isLoggedInProvider);
              if (context.mounted) context.go('/login');
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  void _mostrarOpcoesDeTempo(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Controle de Tempo',
                style: GoogleFonts.cinzel(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildTimeOption(context, ref, 'Bullet (1 min)', 'BULLET', Icons.flash_on),
              _buildTimeOption(context, ref, 'Blitz (3 min)', 'BLITZ_3', Icons.timer),
              _buildTimeOption(context, ref, 'Blitz (5 min)', 'BLITZ_5', Icons.timer),
              _buildTimeOption(context, ref, 'Rápido (10 min)', 'RAPIDO', Icons.hourglass_bottom),
              _buildTimeOption(context, ref, 'Sem Limite', 'SEM_LIMITE', Icons.all_inclusive),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeOption(BuildContext context, WidgetRef ref, String title, String modo, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppColors.gold2),
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16)),
      onTap: () {
        Navigator.pop(context);
        _criarPartida(context, ref, modoTempo: modo);
      },
    );
  }

  Future<void> _criarPartida(BuildContext context, WidgetRef ref, {String modoTempo = 'SEM_LIMITE'}) async {
    try {
      final data = await ref.read(apiServiceProvider).criarPartida(modoTempo: modoTempo);
      final link = data['linkConvite'] as String;
      final id = data['id'] as String;

      if (!context.mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
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

  Future<void> _jogarSolo(BuildContext context, WidgetRef ref) async {
    try {
      // Cria a partida normalmente
      final data = await ref.read(apiServiceProvider).criarPartida();
      final id = data['id'] as String;

      // Entra automaticamente como as negras (modo solo)
      await ref.read(apiServiceProvider).entrarModoSolo(id);

      if (!context.mounted) return;
      context.push('/partida/$id');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao iniciar modo solo: $e')),
        );
      }
    }
  }
}

class _ConviteSheet extends StatelessWidget {
  final String link;
  final String partidaId;

  const _ConviteSheet({required this.link, required this.partidaId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 32,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.glassBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.gold2.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.qr_code_2, size: 64, color: AppColors.gold2),
          ),
          const SizedBox(height: 24),
          Text(
            'Sala Criada! ♟',
            style: GoogleFonts.cinzel(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Compartilhe o link abaixo com seu adversário para iniciar a partida.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.bg0,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    link,
                    style: const TextStyle(
                      color: AppColors.gold2,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, color: AppColors.gold2),
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
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.share),
                  label: const Text('Compartilhar'),
                  onPressed: () => Share.share(
                    'Vamos jogar xadrez? Clique no link: $link',
                    subject: 'Convite de partida de xadrez',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Entrar'),
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/partida/$partidaId');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
