import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

typedef SseCallback = void Function();
typedef SseConnectedCallback = void Function(bool isReconnect);

class SseService {
  final Dio _dio;
  final String _baseUrl;

  String? _token;
  CancelToken? _cancelToken;
  Timer? _reconnectTimer;
  bool _disposed = false;
  int _retryCount = 0;
  bool _hasConnectedOnce = false;

  static const _maxRetryDelay = Duration(seconds: 10);
  static const _initialRetryDelay = Duration(seconds: 2);

  SseCallback? onSyncNeeded;
  SseCallback? onLinksUpdated;
  SseCallback? onCaregiverDataChanged;
  SseCallback? onPatientProfileChanged;
  SseConnectedCallback? onConnected;

  SseService(this._baseUrl)
    : _dio = Dio(
        BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(hours: 24),
        ),
      );

  Future<void> connect(String token) async {
    _token = token;
    _disposed = false;
    _retryCount = 0;
    _hasConnectedOnce = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _cancelToken?.cancel();
    _cancelToken = null;
    await _startConnection();
  }

  Future<void> _startConnection() async {
    if (_disposed || _token == null) return;

    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    try {
      debugPrint('[SSE] Connecting to $_baseUrl/sse/sync');

      final response = await _dio.get<ResponseBody>(
        '/sse/sync',
        options: Options(
          headers: {'Authorization': 'Bearer $_token'},
          responseType: ResponseType.stream,
        ),
        cancelToken: _cancelToken,
      );

      final stream = response.data?.stream;
      if (stream == null) {
        debugPrint('[SSE] No stream received');
        _scheduleReconnect();
        return;
      }

      final isReconnect = _hasConnectedOnce;
      _hasConnectedOnce = true;
      _retryCount = 0;
      debugPrint('[SSE] Connected successfully');
      onConnected?.call(isReconnect);

      String buffer = '';

      await for (final chunk in stream) {
        if (_disposed) break;

        buffer += utf8.decode(chunk);
        final lines = buffer.split('\n');
        buffer = lines.removeLast();

        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isEmpty || trimmed.startsWith(':')) continue;

          if (trimmed.startsWith('data: ')) {
            final jsonStr = trimmed.substring(6);
            try {
              final data = jsonDecode(jsonStr) as Map<String, dynamic>;
              final event = data['event'] as String?;
              debugPrint('[SSE] Received event: $event');

              switch (event) {
                case 'sync_needed':
                  onSyncNeeded?.call();
                  break;
                case 'links_updated':
                  onLinksUpdated?.call();
                  break;
                case 'caregiver_data_changed':
                  onCaregiverDataChanged?.call();
                  break;
                case 'patient_profile_changed':
                  onPatientProfileChanged?.call();
                  break;
              }
            } catch (e) {
              debugPrint('[SSE] Error parsing event: $e');
            }
          }
        }
      }

      if (!_disposed) {
        debugPrint('[SSE] Stream ended, reconnecting...');
        _scheduleReconnect();
      }
    } on DioException catch (e) {
      if (_disposed || e.type == DioExceptionType.cancel) return;

      debugPrint('[SSE] Connection error: ${e.type} - ${e.message}');

      if (e.response?.statusCode == 401) {
        debugPrint('[SSE] Unauthorized, stopping');
        return;
      }

      _scheduleReconnect();
    } catch (e) {
      if (_disposed) return;
      debugPrint('[SSE] Unknown error: $e');
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_disposed) return;

    _reconnectTimer?.cancel();

    final delay = Duration(
      milliseconds:
          (_initialRetryDelay.inMilliseconds * (1 << _retryCount.clamp(0, 5)))
              .clamp(0, _maxRetryDelay.inMilliseconds),
    );
    _retryCount++;

    debugPrint(
      '[SSE] Reconnecting in ${delay.inSeconds}s (attempt $_retryCount)',
    );

    _reconnectTimer = Timer(delay, () {
      if (!_disposed) _startConnection();
    });
  }

  void disconnect() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _cancelToken?.cancel();
    _cancelToken = null;
    _token = null;
    debugPrint('[SSE] Disconnected');
  }
}
