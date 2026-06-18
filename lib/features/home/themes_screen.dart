import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/theme/board_theme_preset.dart';
import '../../shared/theme/theme_preference_provider.dart';

class ThemesScreen extends ConsumerStatefulWidget {
  const ThemesScreen({super.key});

  @override
  ConsumerState<ThemesScreen> createState() => _ThemesScreenState();
}

class _ThemesScreenState extends ConsumerState<ThemesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _saveAnim;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _saveAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _saveAnim.dispose();
    super.dispose();
  }

  void _showSavedFeedback() {
    setState(() => _saved = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saved = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(themePreferenceProvider);
    final notifier = ref.read(themePreferenceProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personalizar'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            // ── Header ──────────────────────────────────────────────────────
            const _SectionHeader(
              icon: Icons.palette_outlined,
              title: 'Tema do Tabuleiro',
              subtitle: 'Escolha o estilo visual do tabuleiro de xadrez',
            ),
            const SizedBox(height: 16),

            // ── Grid de temas de tabuleiro ───────────────────────────────────
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: BoardTheme.values.map((theme) {
                final selected = prefs.boardTheme == theme;
                return _BoardThemeCard(
                  theme: theme,
                  selected: selected,
                  onTap: () => notifier.setBoardTheme(theme),
                );
              }).toList(),
            ),

            const SizedBox(height: 36),

            // ── Header peças ─────────────────────────────────────────────────
            const _SectionHeader(
              icon: Icons.extension_outlined,
              title: 'Estilo das Peças',
              subtitle: 'Escolha a aparência das peças no tabuleiro',
            ),
            const SizedBox(height: 16),

            // ── Lista de estilos de peça ─────────────────────────────────────
            ...PieceStyle.values.map((style) {
              final selected = prefs.pieceStyle == style;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PieceStyleCard(
                  style: style,
                  selected: selected,
                  onTap: style.disponivel
                      ? () => notifier.setPieceStyle(style)
                      : null,
                ),
              );
            }),

            const SizedBox(height: 32),

            // ── Botão de confirmação ─────────────────────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _saved
                  ? const _ConfirmedButton(key: ValueKey('saved'))
                  : ElevatedButton.icon(
                      key: const ValueKey('save'),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Salvar Preferências'),
                      onPressed: () {
                        _showSavedFeedback();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.palette,
                                    color: AppColors.gold2, size: 18),
                                const SizedBox(width: 10),
                                Text(
                                  'Tema "${prefs.boardTheme.label}" aplicado!',
                                  style: const TextStyle(
                                      color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─── Widget: Header de seção ──────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.gold2.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.gold2.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, color: AppColors.gold2, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Cinzel',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Widget: Card de Tema de Tabuleiro ────────────────────────────────────────

class _BoardThemeCard extends StatefulWidget {
  final BoardTheme theme;
  final bool selected;
  final VoidCallback onTap;

  const _BoardThemeCard({
    required this.theme,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_BoardThemeCard> createState() => _BoardThemeCardState();
}

class _BoardThemeCardState extends State<_BoardThemeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.0,
      upperBound: 0.05,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColors.gold2.withValues(alpha: 0.08)
                : AppColors.surface1,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.selected ? AppColors.gold2 : AppColors.glassBorder,
              width: widget.selected ? 2 : 1,
            ),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: AppColors.gold2.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preview do tabuleiro (miniaturizado 4x4)
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _BoardPreview(theme: widget.theme),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(widget.theme.icon,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.theme.label,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: widget.selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: widget.selected
                            ? AppColors.gold2
                            : AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.selected)
                    const Icon(Icons.check_circle,
                        size: 16, color: AppColors.gold2),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Widget: Preview miniatura do tabuleiro (4x4) ────────────────────────────

class _BoardPreview extends StatelessWidget {
  final BoardTheme theme;
  const _BoardPreview({required this.theme});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Column(
        children: List.generate(4, (row) {
          return Expanded(
            child: Row(
              children: List.generate(4, (col) {
                final isLight = (row + col) % 2 == 0;
                return Expanded(
                  child: Container(
                    color: isLight ? theme.previewLight : theme.previewDark,
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Widget: Card de Estilo de Peça ──────────────────────────────────────────

class _PieceStyleCard extends StatelessWidget {
  final PieceStyle style;
  final bool selected;
  final VoidCallback? onTap;

  const _PieceStyleCard({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locked = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: locked
              ? AppColors.surface1.withValues(alpha: 0.5)
              : (selected
                  ? AppColors.gold2.withValues(alpha: 0.08)
                  : AppColors.surface1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: locked
                ? AppColors.glassBorder.withValues(alpha: 0.4)
                : (selected ? AppColors.gold2 : AppColors.glassBorder),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected && !locked
              ? [
                  BoxShadow(
                    color: AppColors.gold2.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            // Ícone representativo das peças
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: locked
                    ? AppColors.surface2.withValues(alpha: 0.5)
                    : (selected
                        ? AppColors.gold2.withValues(alpha: 0.15)
                        : AppColors.surface2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '♛',
                  style: TextStyle(
                    fontSize: 26,
                    color: locked
                        ? AppColors.textMuted.withValues(alpha: 0.4)
                        : (selected ? AppColors.gold2 : AppColors.textSecondary),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        style.label,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: locked
                              ? AppColors.textMuted.withValues(alpha: 0.5)
                              : (selected
                                  ? AppColors.gold2
                                  : AppColors.textPrimary),
                        ),
                      ),
                      if (locked) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.purple2.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.purple2.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            'Em breve',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.purple1,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    style.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: locked
                          ? AppColors.textMuted.withValues(alpha: 0.4)
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (selected && !locked)
              const Icon(Icons.check_circle, color: AppColors.gold2, size: 20),
            if (locked)
              Icon(Icons.lock_outline,
                  color: AppColors.textMuted.withValues(alpha: 0.4), size: 18),
          ],
        ),
      ),
    );
  }
}

// ─── Botão de confirmação animado ────────────────────────────────────────────

class _ConfirmedButton extends StatelessWidget {
  const _ConfirmedButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check, color: AppColors.success),
          const SizedBox(width: 10),
          Text(
            'Preferências salvas!',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}
