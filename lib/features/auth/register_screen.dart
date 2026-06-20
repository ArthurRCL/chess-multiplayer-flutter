import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/auth_service.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/chess_background_painter.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/loading_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _confirmarCtrl = TextEditingController();
  bool _loading = false;
  String? _erro;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.1, 1.0, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.1, 1.0, curve: Curves.easeOutCubic),
    ));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    _confirmarCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      await ref.read(authServiceProvider).register(
            _emailCtrl.text.trim(),
            _senhaCtrl.text,
          );
      // O AuthService já atualiza isLoggedInProvider internamente.
      // O GoRouter detecta a mudança e redireciona automaticamente para /home.
    } catch (e) {
      setState(() {
        _erro = 'Erro ao criar conta. Email já cadastrado?';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ChessBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header customizado (sem AppBar padrão)
              _buildCustomHeader(),

              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Junte-se ao\nTabuleiro',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Cinzel',
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Crie sua conta para jogar online',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 40),

                              // Form Card
                              GlassCard(
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      _buildEmailField(),
                                      const SizedBox(height: 20),
                                      _buildPasswordField(),
                                      const SizedBox(height: 20),
                                      _buildConfirmPasswordField(),
                                      if (_erro != null) ...[
                                        const SizedBox(height: 16),
                                        _buildErrorMsg(),
                                      ],
                                      const SizedBox(height: 32),
                                      LoadingButton(
                                        onPressed: _register,
                                        loading: _loading,
                                        label: 'CRIAR CONTA',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Footer links
                              _buildFooterLinks(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: AppColors.textPrimary,
            tooltip: 'Voltar',
            onPressed: () => context.go('/login'),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.gold2.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.gold2.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.shield_outlined,
                    size: 16, color: AppColors.gold2.withOpacity(0.8)),
                const SizedBox(width: 6),
                Text(
                  'Registro Seguro',
                  style: TextStyle(
                    color: AppColors.gold2.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailCtrl,
      keyboardType: TextInputType.emailAddress,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: const InputDecoration(
        labelText: 'E-mail',
        prefixIcon: Icon(Icons.email_outlined),
      ),
      validator: (v) =>
          (v == null || !v.contains('@')) ? 'Email inválido' : null,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _senhaCtrl,
      obscureText: true,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: const InputDecoration(
        labelText: 'Senha',
        helperText: 'Mínimo de 6 caracteres',
        helperStyle: TextStyle(color: AppColors.textMuted),
        prefixIcon: Icon(Icons.lock_outlined),
      ),
      validator: (v) =>
          (v == null || v.length < 6) ? 'Senha muito curta' : null,
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmarCtrl,
      obscureText: true,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: const InputDecoration(
        labelText: 'Confirmar senha',
        prefixIcon: Icon(Icons.lock_clock_outlined),
      ),
      validator: (v) =>
          v != _senhaCtrl.text ? 'As senhas não coincidem' : null,
    );
  }

  Widget _buildErrorMsg() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.danger.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _erro!,
              style: const TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLinks() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Já tem uma conta?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        TextButton(
          onPressed: () => context.go('/login'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.gold2,
            textStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          child: const Text('Faça Login'),
        ),
      ],
    );
  }
}
