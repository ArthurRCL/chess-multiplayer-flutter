import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage.dart';

/// URL do backend.
/// - Web (Chrome): usa localhost diretamente
/// - Android Emulator: usa 10.0.2.2 (loopback do emulador)
/// - Produção: passa via --dart-define=API_BASE_URL=https://...
String get _baseUrl {
  const custom = String.fromEnvironment('API_BASE_URL', defaultValue: '');
  if (custom.isNotEmpty) return custom;
  // O backend agora está rodando na Oracle Cloud
  return 'http://163.176.148.73:8080';
}

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(ref.watch(secureStorageProvider));
});

class ApiService {
  late final Dio _dio;
  final SecureStorageService _storage;

  ApiService(this._storage) {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  // ── Auth ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String email, String senha) async {
    final res = await _dio.post('/api/auth/login', data: {
      'email': email,
      'senha': senha,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register(String email, String senha) async {
    final res = await _dio.post('/api/auth/register', data: {
      'email': email,
      'senha': senha,
    });
    return res.data as Map<String, dynamic>;
  }

  // ── Partidas ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> criarPartida({String modoTempo = 'SEM_LIMITE'}) async {
    final res = await _dio.post(
      '/api/partidas',
      queryParameters: {'modoTempo': modoTempo},
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> buscarPartida(String id) async {
    final res = await _dio.get('/api/partidas/$id');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> entrarNaPartida(String id) async {
    final res = await _dio.post('/api/partidas/$id/entrar');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> entrarModoSolo(String id) async {
    final res = await _dio.post('/api/partidas/$id/solo');
    return res.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> historico() async {
    final res = await _dio.get('/api/partidas/historico');
    return res.data as List<dynamic>;
  }

  // ── IA ────────────────────────────────────────────────────────────────────

  /// Solicita ao backend a geração de um relatório de desempenho via IA (Groq/LLaMA).
  /// O timeout é estendido para 30s pois a IA pode demorar alguns segundos.
  Future<Map<String, dynamic>> gerarRelatorioIA(String partidaId) async {
    final res = await _dio.get(
      '/api/partidas/$partidaId/relatorio-ia',
      options: Options(receiveTimeout: const Duration(seconds: 30)),
    );
    final data = res.data as Map<String, dynamic>;
    if (data.containsKey('erro')) throw Exception(data['erro']);
    return data;
  }
}
