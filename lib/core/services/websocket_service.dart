import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

String get _wsUrl {
  const custom = String.fromEnvironment('WS_BASE_URL', defaultValue: '');
  if (custom.isNotEmpty) return custom;
  if (kIsWeb) return 'http://localhost:8080/ws';
  return 'http://10.0.2.2:8080/ws';
}

final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  return WebSocketService(ref.watch(secureStorageProvider));
});

typedef EstadoCallback = void Function(Map<String, dynamic> estado);
typedef ErroCallback = void Function(String erro);

class WebSocketService {
  final SecureStorageService _storage;
  StompClient? _client;
  bool _connected = false;

  WebSocketService(this._storage);

  Future<void> conectar({
    required String partidaId,
    required EstadoCallback onEstado,
    required ErroCallback onErro,
    required String userEmail,
    VoidCallback? onConnected,
  }) async {
    final token = await _storage.getToken();

    _client = StompClient(
      config: StompConfig.sockJS(
        url: _wsUrl,
        onConnect: (frame) {
          _connected = true;
          onConnected?.call();

          // Inscreve no canal de estado da partida (broadcast)
          _client!.subscribe(
            destination: '/topic/partida/$partidaId/estado',
            callback: (frame) {
              if (frame.body != null) {
                // Parsing manual — em produção usar json.decode
                onEstado({'raw': frame.body});
              }
            },
          );

          // Inscreve no canal de erros privado
          _client!.subscribe(
            destination: '/user/queue/errors',
            callback: (frame) {
              onErro(frame.body ?? 'Erro desconhecido');
            },
          );
        },
        onDisconnect: (_) {
          _connected = false;
        },
        onWebSocketError: (error) => onErro('Erro de conexão: $error'),
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
      ),
    );

    _client!.activate();
  }

  void enviarMovimento(String partidaId, String from, String to, {String? promocao}) {
    if (!_connected || _client == null) return;
    final body = '{"from":"$from","to":"$to"${promocao != null ? ',"promocao":"$promocao"' : ''}}';
    _client!.send(
      destination: '/app/partida/$partidaId/mover',
      body: body,
    );
  }

  void desistir(String partidaId) {
    if (!_connected || _client == null) return;
    _client!.send(destination: '/app/partida/$partidaId/desistir', body: '{}');
  }

  void desconectar() {
    _client?.deactivate();
    _connected = false;
  }

  bool get isConnected => _connected;
}

// Alias para evitar importação do Flutter no service
typedef VoidCallback = void Function();
