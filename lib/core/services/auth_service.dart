import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../storage/secure_storage.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.watch(apiServiceProvider),
    ref.watch(secureStorageProvider),
  );
});

final isLoggedInProvider = FutureProvider<bool>((ref) async {
  return ref.watch(secureStorageProvider).isLoggedIn();
});

class AuthService {
  final ApiService _api;
  final SecureStorageService _storage;

  AuthService(this._api, this._storage);

  Future<void> login(String email, String senha) async {
    final data = await _api.login(email, senha);
    await _storage.saveAuth(
      token: data['token'] as String,
      email: data['email'] as String,
      userId: data['id'].toString(),
    );
  }

  Future<void> register(String email, String senha) async {
    final data = await _api.register(email, senha);
    await _storage.saveAuth(
      token: data['token'] as String,
      email: data['email'] as String,
      userId: data['id'].toString(),
    );
  }

  Future<void> logout() => _storage.clearAuth();
}
