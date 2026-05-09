import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

final secureStorageProvider = Provider<SecureStorageService>(
  (_) => SecureStorageService(),
);

/// Abstração de armazenamento:
/// - Web (Chrome): usa SharedPreferences (sem criptografia local, OK para dev)
/// - Mobile (Android/iOS): usa FlutterSecureStorage com criptografia nativa
class SecureStorageService {
  static const _tokenKey = 'jwt_token';
  static const _userIdKey = 'user_id';
  static const _emailKey = 'user_email';

  // Usado apenas em mobile
  final _secureStorage = kIsWeb
      ? null
      : const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  // ── Escrita ───────────────────────────────────────────────────────────────

  Future<void> saveAuth({
    required String token,
    required String email,
    required String userId,
  }) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setString(_tokenKey, token),
        prefs.setString(_emailKey, email),
        prefs.setString(_userIdKey, userId),
      ]);
    } else {
      await Future.wait([
        _secureStorage!.write(key: _tokenKey, value: token),
        _secureStorage.write(key: _emailKey, value: email),
        _secureStorage.write(key: _userIdKey, value: userId),
      ]);
    }
  }

  // ── Leitura ───────────────────────────────────────────────────────────────

  Future<String?> getToken() => _read(_tokenKey);
  Future<String?> getEmail() => _read(_emailKey);
  Future<String?> getUserId() => _read(_userIdKey);

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ── Limpeza ───────────────────────────────────────────────────────────────

  Future<void> clearAuth() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove(_tokenKey),
        prefs.remove(_emailKey),
        prefs.remove(_userIdKey),
      ]);
    } else {
      await _secureStorage!.deleteAll();
    }
  }

  // ── Helper ────────────────────────────────────────────────────────────────

  Future<String?> _read(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    }
    return _secureStorage!.read(key: key);
  }
}
