import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../models/game_settings.dart';
import '../models/room_state.dart';
import '../utils/server_config.dart';

class MultiplayerService {
  MultiplayerService._();

  static final MultiplayerService instance = MultiplayerService._();

  final ValueNotifier<RoomState?> roomState = ValueNotifier<RoomState?>(null);
  final ValueNotifier<bool> isConnected = ValueNotifier<bool>(false);
  final ValueNotifier<String?> lastError = ValueNotifier<String?>(null);

  io.Socket? _socket;

  Future<void> connect() async {
    if (_socket?.connected == true) {
      return;
    }

    _socket?.dispose();

    final completer = Completer<void>();
    final socket = io.io(
      ServerConfig.serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableAutoConnect()
          .build(),
    );

    _socket = socket;

    socket.onConnect((_) {
      isConnected.value = true;
      lastError.value = null;
      if (!completer.isCompleted) {
        completer.complete();
      }
    });

    socket.onDisconnect((_) {
      isConnected.value = false;
    });

    socket.on('room_state', (data) {
      if (data is Map) {
        roomState.value = RoomState.fromJson(Map<String, dynamic>.from(data));
      }
    });

    socket.onConnectError((error) {
      lastError.value = 'تعذر الاتصال بالخادم';
      if (!completer.isCompleted) {
        completer.completeError(Exception('تعذر الاتصال بالخادم'));
      }
      if (kDebugMode) {
        print('Socket connect error: $error');
      }
    });

    await completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () {
        throw TimeoutException('انتهت مهلة الاتصال بالخادم');
      },
    );
  }

  Future<RoomState> createRoom({
    required GameSettings settings,
    required String playerName,
  }) async {
    await connect();
    final socket = _requireSocket();

    final response = await _emitWithAck(socket, 'create_room', {
      'settings': settings.toJson(),
      'playerName': playerName,
    });

    return _handleRoomResponse(response);
  }

  Future<RoomState> joinRoom({
    required String code,
    required String playerName,
  }) async {
    await connect();
    final socket = _requireSocket();

    final response = await _emitWithAck(socket, 'join_room', {
      'code': code.trim(),
      'playerName': playerName.trim(),
    });

    return _handleRoomResponse(response);
  }

  Future<void> startRound() async {
    final socket = _requireSocket();
    final response = await _emitWithAck(socket, 'start_round', {});
    _handleActionResponse(response);
  }

  Future<void> submitWords(List<String> words) async {
    final socket = _requireSocket();
    final response = await _emitWithAck(socket, 'submit_words', {
      'words': words,
    });
    _handleActionResponse(response);
  }

  Future<void> approveResults(Map<String, List<String>> reviewsByPlayer) async {
    final socket = _requireSocket();
    final response = await _emitWithAck(socket, 'approve_results', {
      'reviews': reviewsByPlayer,
    });
    _handleActionResponse(response);
  }

  void leaveRoom() {
    _socket?.emit('leave_room');
    roomState.value = null;
  }

  void dispose() {
    leaveRoom();
    _socket?.dispose();
    _socket = null;
    isConnected.value = false;
  }

  io.Socket _requireSocket() {
    final socket = _socket;
    if (socket == null || !socket.connected) {
      throw StateError('غير متصل بالخادم');
    }
    return socket;
  }

  Future<Map<String, dynamic>> _emitWithAck(
    io.Socket socket,
    String event,
    Map<String, dynamic> payload,
  ) async {
    final completer = Completer<Map<String, dynamic>>();

    socket.emitWithAck(event, payload, ack: (response) {
      if (response is Map) {
        completer.complete(Map<String, dynamic>.from(response));
        return;
      }
      completer.complete({'ok': false, 'error': 'استجابة غير صالحة'});
    });

    return completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () => {'ok': false, 'error': 'انتهت مهلة الاتصال'},
    );
  }

  RoomState _handleRoomResponse(Map<String, dynamic> response) {
    if (response['ok'] != true) {
      final error = response['error'] as String? ?? 'حدث خطأ';
      lastError.value = error;
      throw Exception(error);
    }

    final roomJson = response['room'];
    if (roomJson is! Map) {
      throw Exception('استجابة غير صالحة من الخادم');
    }

    final room = RoomState.fromJson(Map<String, dynamic>.from(roomJson));
    roomState.value = room;
    lastError.value = null;
    return room;
  }

  void _handleActionResponse(Map<String, dynamic> response) {
    if (response['ok'] != true) {
      final error = response['error'] as String? ?? 'حدث خطأ';
      lastError.value = error;
      throw Exception(error);
    }
    lastError.value = null;
  }
}
