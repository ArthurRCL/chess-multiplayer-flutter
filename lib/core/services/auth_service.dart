import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../storage/secure_storage.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.watch(apiServiceProvider),
    ref.watch(secureStorageProvider),
    ref,
  );
});

/// Provider síncrono que representa o estado de autenticação.
/// Começa como `null` (desconhecido), depois muda para `true` / `false`.
/// Usa `StateProvider` para evitar problemas de rebuild com `FutureProvider`.
final isLoggedInProvider = StateProvider<bool?>((ref) => null);


class AuthService {
  final ApiService _api;
  final SecureStorageService _storage;
  final Ref _ref;

  AuthService(this._api, this._storage, this._ref);

  Future<void> login(String email, String senha) async {
    final data = await _api.login(email, senha);
    await _storage.saveAuth(
      token: data['token'] as String,
      refreshToken: data['refreshToken'] as String,
      email: data['email'] as String,
      userId: data['id'].toString(),
    );
    _ref.read(isLoggedInProvider.notifier).state = true;
  }

  Future<void> register(String email, String senha) async {
    final data = await _api.register(email, senha);
    await _storage.saveAuth(
      token: data['token'] as String,
      refreshToken: data['refreshToken'] as String,
      email: data['email'] as String,
      userId: data['id'].toString(),
    );
    _ref.read(isLoggedInProvider.notifier).state = true;
  }

  Future<void> logout() async {
    await _storage.clearAuth();
    _ref.read(isLoggedInProvider.notifier).state = false;
  }
}
