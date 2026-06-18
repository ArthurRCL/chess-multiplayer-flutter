import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

String get _wsUrl {
  const custom = String.fromEnvironment('WS_BASE_URL', defaultValue: '');
  if (custom.isNotEmpty) return custom;
  return 'http://163.176.148.73:8080/ws';
}

final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  return WebSocketService(ref.watch(secureStorageProvider));
});

typedef EstadoCallback = void Function(Map<String, dynamic> estado);
typedef ErroCallback = void Function(String erro);

/// Callback disparado quando o servidor confirma uma revanche.
/// [novaPartidaId] é o ID da nova partida para navegação.
typedef NovaPartidaCallback = void Function(String novaPartidaId);

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
    NovaPartidaCallback? onNovaPartida,
  }) async {
    final token = await _storage.getToken();

    _client = StompClient(
      config: StompConfig.sockJS(
        url: _wsUrl,
        onConnect: (frame) {
          _connected = true;
          onConnected?.call();

          // Canal de estado da partida (broadcast de movimentos e relógio)
          _client!.subscribe(
            destination: '/topic/partida/$partidaId/estado',
            callback: (frame) {
              if (frame.body != null) {
                onEstado({'raw': frame.body});
              }
            },
          );

          // Canal de erros privado do usuário
          _client!.subscribe(
            destination: '/user/queue/errors',
            callback: (frame) {
              onErro(frame.body ?? 'Erro desconhecido');
            },
          );

          // Canal de revanche — recebe ID da nova partida
          if (onNovaPartida != null) {
            _client!.subscribe(
              destination: '/topic/partida/$partidaId/revanche',
              callback: (frame) {
                if (frame.body != null) {
                  // Corpo: {"novaPartidaId": "uuid"}
                  final match = RegExp(r'"novaPartidaId"\s*:\s*"([^"]+)"')
                      .firstMatch(frame.body!);
                  if (match != null) {
                    onNovaPartida(match.group(1)!);
                  }
                }
              },
            );
          }
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
    final body =
        '{"from":"$from","to":"$to"${promocao != null ? ',"promocao":"$promocao"' : ''}}';
    _client!.send(
      destination: '/app/partida/$partidaId/mover',
      body: body,
    );
  }

  void desistir(String partidaId) {
    if (!_connected || _client == null) return;
    _client!.send(destination: '/app/partida/$partidaId/desistir', body: '{}');
  }

  /// Solicita revanche via WebSocket. O servidor cria a nova partida com
  /// cores invertidas e faz broadcast do ID para ambos os jogadores.
  void solicitarRevanche(String partidaId) {
    if (!_connected || _client == null) return;
    _client!.send(destination: '/app/partida/$partidaId/revanche', body: '{}');
  }

  void desconectar() {
    _client?.deactivate();
    _connected = false;
  }

  bool get isConnected => _connected;
}

// Alias para evitar importação do Flutter no service
typedef VoidCallback = void Function();
