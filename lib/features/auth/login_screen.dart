import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/loading_button.dart';
import '../../core/services/auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  bool _loading = false;
  String? _erro;
  bool _senhaVisivel = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _erro = null; });
    try {
      await ref.read(authServiceProvider).login(_emailCtrl.text.trim(), _senhaCtrl.text);
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() { _erro = 'Email ou senha inválidos'; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo / título
                Icon(Icons.sports_esports, size: 72, color: theme.colorScheme.primary),
                const SizedBox(height: 8),
                Text(
                  '♟ Xadrez Online',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Entre para jogar',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 36),
                // Formulário
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (v) => (v == null || !v.contains('@'))
                            ? 'Email inválido' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _senhaCtrl,
                        obscureText: !_senhaVisivel,
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(_senhaVisivel
                                ? Icons.visibility_off : Icons.visibility),
                            onPressed: () =>
                                setState(() { _senhaVisivel = !_senhaVisivel; }),
                          ),
                        ),
                        validator: (v) => (v == null || v.length < 6)
                            ? 'Senha deve ter pelo menos 6 caracteres' : null,
                      ),
                      if (_erro != null) ...[
                        const SizedBox(height: 12),
                        Text(_erro!,
                            style: const TextStyle(color: Colors.redAccent)),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: LoadingButton(
                          onPressed: _login,
                          loading: _loading,
                          label: 'Entrar',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => context.go('/register'),
                        child: Text(
                          'Não tem conta? Cadastre-se',
                          style: TextStyle(color: theme.colorScheme.secondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
