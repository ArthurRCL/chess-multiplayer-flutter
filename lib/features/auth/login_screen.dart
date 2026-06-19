import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/auth_service.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/chess_background_painter.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/loading_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  bool _loading = false;
  String? _erro;
  bool _senhaVisivel = false;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      await ref
          .read(authServiceProvider)
          .login(_emailCtrl.text.trim(), _senhaCtrl.text);
      ref.invalidate(isLoggedInProvider);
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() {
        _erro = 'Email ou senha inválidos';
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
                        // Logo / Título
                        _buildHeader(),
                        const SizedBox(height: 48),

                        // Form Card
                        GlassCard(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                _buildEmailField(),
                                const SizedBox(height: 20),
                                _buildPasswordField(),
                                if (_erro != null) ...[
                                  const SizedBox(height: 16),
                                  _buildErrorMsg(),
                                ],
                                const SizedBox(height: 32),
                                LoadingButton(
                                  onPressed: _login,
                                  loading: _loading,
                                  label: 'ENTRAR',
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
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.gold2.withOpacity(0.2),
                AppColors.gold2.withOpacity(0.05),
              ],
            ),
            border: Border.all(color: AppColors.gold2.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold2.withOpacity(0.2),
                blurRadius: 30,
              ),
            ],
          ),
          child: SvgPicture.asset(
            'assets/pieces/wQ.svg',
            width: 64,
            height: 64,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'XADREZ ONLINE',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Cinzel',
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.gold2,
            letterSpacing: 2,
            shadows: [
              Shadow(
                color: AppColors.gold2.withOpacity(0.3),
                blurRadius: 12,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Mova suas peças com maestria.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ],
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
      obscureText: !_senhaVisivel,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: 'Senha',
        prefixIcon: const Icon(Icons.lock_outlined),
        suffixIcon: IconButton(
          icon: Icon(
            _senhaVisivel ? Icons.visibility_off : Icons.visibility,
            color: AppColors.textMuted,
          ),
          onPressed: () => setState(() {
            _senhaVisivel = !_senhaVisivel;
          }),
        ),
      ),
      validator: (v) => (v == null || v.length < 6)
          ? 'Senha deve ter pelo menos 6 caracteres'
          : null,
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
          'Não tem uma conta?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        TextButton(
          onPressed: () => context.go('/register'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.gold2,
            textStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          child: const Text('Cadastre-se'),
        ),
      ],
    );
  }
}
