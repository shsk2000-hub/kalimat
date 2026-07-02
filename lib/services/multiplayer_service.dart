import 'dart:async';
import 'dart:math';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../data/round_prompts.dart';
import '../models/game_settings.dart';
import '../models/room_state.dart';
import '../utils/player_identity.dart';
import 'firebase_bootstrap.dart';

class MultiplayerService {
  MultiplayerService._();

  static final MultiplayerService instance = MultiplayerService._();

  final ValueNotifier<RoomState?> roomState = ValueNotifier<RoomState?>(null);
  final ValueNotifier<bool> isConnected = ValueNotifier<bool>(false);
  final ValueNotifier<String?> lastError = ValueNotifier<String?>(null);

  final Random _random = Random();

  StreamSubscription<DatabaseEvent>? _roomSubscription;
  Timer? _roundTimer;
  String? _playerId;
  String? _roomCode;

  DatabaseReference get _rooms => FirebaseDatabase.instance.ref('rooms');
  DatabaseReference get _roomCodes => FirebaseDatabase.instance.ref('roomCodes');

  Future<void> connect() async {
    await FirebaseBootstrap.ensureInitialized();
    _playerId = await PlayerIdentity.currentId();
    isConnected.value = true;
    lastError.value = null;
  }

  Future<RoomState> createRoom({
    required GameSettings settings,
    required String playerName,
  }) async {
    await connect();
    final playerId = _requirePlayerId();

    for (var attempt = 0; attempt < 12; attempt++) {
      final code = _generateRoomCode();
      final codeRef = _roomCodes.child(code);
      final codeSnapshot = await codeRef.get();
      if (codeSnapshot.exists) {
        continue;
      }

      await codeRef.set(true);
      try {
        final roomRef = _rooms.child(code);
        await roomRef.set(_newRoomPayload(
          code: code,
          hostId: playerId,
          settings: settings,
          playerName: playerName,
        ));
        _attachRoomListener(code);
        return _waitForRoomState();
      } catch (error) {
        await codeRef.remove();
        rethrow;
      }
    }

    throw Exception('تعذر إنشاء غرفة، حاول مرة أخرى');
  }

  Future<RoomState> joinRoom({
    required String code,
    required String playerName,
  }) async {
    await connect();
    final playerId = _requirePlayerId();
    final roomRef = _rooms.child(code.trim());
    final snapshot = await roomRef.get();

    if (!snapshot.exists || snapshot.value is! Map) {
      throw Exception('الغرفة غير موجودة');
    }

    final room = _asStringKeyedMap(snapshot.value);
    if (room['phase'] != 'lobby') {
      throw Exception('الجولة جارية بالفعل');
    }

    final players = _playersMap(room);
    if (players.values.any((player) => player['name'] == playerName.trim())) {
      throw Exception('الاسم مستخدم في الغرفة');
    }

    await roomRef.child('players').child(playerId).set({
      'name': playerName.trim(),
      'points': 0,
      'isHost': false,
      'hasSubmitted': false,
      'hasReviewed': false,
    });

    _attachRoomListener(code.trim());
    return _waitForRoomState();
  }

  Future<void> startRound() async {
    final code = _requireRoomCode();
    final playerId = _requirePlayerId();
    final roomRef = _rooms.child(code);

    await roomRef.runTransaction((mutableData) {
      if (mutableData == null) {
        return Transaction.abort();
      }

      final room = _transactionRoom(mutableData);
      if (room['hostId'] != playerId) {
        return Transaction.abort();
      }

      final phase = room['phase'] as String;
      if (phase != 'lobby' && phase != 'results') {
        return Transaction.abort();
      }

      var roundIndex = room['roundIndex'] as int? ?? 0;
      if (phase == 'results') {
        roundIndex += 1;
        final numberOfRounds =
            (room['settings'] as Map)['numberOfRounds'] as int? ?? 1;
        if (roundIndex >= numberOfRounds) {
          room['phase'] = 'finished';
          return Transaction.success(room);
        }
      }

      _resetRoundState(room);
      room['roundIndex'] = roundIndex;
      room['phase'] = 'playing';
      room['prompt'] = _promptForRound(roundIndex);
      final duration =
          (room['settings'] as Map)['roundDurationSeconds'] as int? ?? 30;
      room['roundEndsAt'] = DateTime.now().millisecondsSinceEpoch + duration * 1000;

      return Transaction.success(room);
    });

    _scheduleRoundTimeout();
  }

  Future<void> submitWords(List<String> words) async {
    final code = _requireRoomCode();
    final playerId = _requirePlayerId();
    final roomRef = _rooms.child(code);

    await roomRef.runTransaction((mutableData) {
      if (mutableData == null) {
        return Transaction.abort();
      }

      final room = _transactionRoom(mutableData);
      if (room['phase'] != 'playing') {
        return Transaction.abort();
      }

      final players = _playersMap(room);
      final player = players[playerId];
      if (player == null || player['hasSubmitted'] == true) {
        return Transaction.abort();
      }

      room['submissions'] ??= <String, dynamic>{};
      (room['submissions'] as Map)[playerId] = words;
      player['hasSubmitted'] = true;

      if (players.values.every((entry) => entry['hasSubmitted'] == true)) {
        _enterReviewPhase(room);
      }

      return Transaction.success(room);
    });
  }

  Future<void> approveResults(Map<String, List<String>> reviewsByPlayer) async {
    final code = _requireRoomCode();
    final playerId = _requirePlayerId();
    final roomRef = _rooms.child(code);

    await roomRef.runTransaction((mutableData) {
      if (mutableData == null) {
        return Transaction.abort();
      }

      final room = _transactionRoom(mutableData);
      if (room['phase'] != 'review' || room['hostId'] != playerId) {
        return Transaction.abort();
      }

      final players = _playersMap(room);
      for (final entry in players.entries) {
        final approvedWords = reviewsByPlayer[entry.key];
        if (approvedWords == null) {
          return Transaction.abort();
        }
        room['reviews'] ??= <String, dynamic>{};
        (room['reviews'] as Map)[entry.key] = approvedWords;
        final roundScore = approvedWords.length;
        entry.value['points'] = (entry.value['points'] as int? ?? 0) + roundScore;
        entry.value['hasReviewed'] = true;
      }

      room['phase'] = 'results';
      return Transaction.success(room);
    });
  }

  Future<void> leaveRoom() async {
    _roundTimer?.cancel();
    _roundTimer = null;
    await _roomSubscription?.cancel();
    _roomSubscription = null;

    final code = _roomCode;
    final playerId = _playerId;
    _roomCode = null;
    roomState.value = null;

    if (code == null || playerId == null) {
      return;
    }

    final roomRef = _rooms.child(code);
    final snapshot = await roomRef.get();
    if (!snapshot.exists || snapshot.value is! Map) {
      await _roomCodes.child(code).remove();
      return;
    }

    final room = _asStringKeyedMap(snapshot.value);
    final players = _playersMap(room)..remove(playerId);
    room['submissions'] = _asStringKeyedMap(room['submissions'])..remove(playerId);
    room['reviews'] = _asStringKeyedMap(room['reviews'])..remove(playerId);

    if (players.isEmpty) {
      await roomRef.remove();
      await _roomCodes.child(code).remove();
      return;
    }

    if (room['hostId'] == playerId) {
      final nextHost = players.keys.first;
      room['hostId'] = nextHost;
      for (final entry in players.entries) {
        entry.value['isHost'] = entry.key == nextHost;
      }
    }

    if (room['phase'] == 'playing' || room['phase'] == 'review') {
      room['phase'] = 'lobby';
      _resetRoundState(room);
    }

    room['players'] = players;
    await roomRef.set(room);
  }

  void dispose() {
    unawaited(leaveRoom());
    isConnected.value = false;
  }

  void _attachRoomListener(String code) {
    _roomCode = code;
    _roomSubscription?.cancel();
    _roomSubscription = _rooms.child(code).onValue.listen((event) {
      final value = event.snapshot.value;
      if (value is! Map || _playerId == null) {
        roomState.value = null;
        return;
      }

      roomState.value = _deserializeRoom(
        _asStringKeyedMap(value),
        _playerId!,
        code,
      );
      _scheduleRoundTimeout();
    });
  }

  Future<RoomState> _waitForRoomState() async {
    for (var attempt = 0; attempt < 20; attempt++) {
      final state = roomState.value;
      if (state != null) {
        return state;
      }
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }

    throw Exception('تعذر تحميل بيانات الغرفة');
  }

  void _scheduleRoundTimeout() {
    _roundTimer?.cancel();
    final state = roomState.value;
    if (state == null || state.phase != RoomPhase.playing || !state.isHost) {
      return;
    }

    final endsAt = state.roundEndsAt;
    if (endsAt == null) {
      return;
    }

    final delayMs = endsAt - DateTime.now().millisecondsSinceEpoch;
    final delay = Duration(milliseconds: delayMs < 0 ? 0 : delayMs);
    _roundTimer = Timer(delay, () {
      unawaited(_forceReviewPhase());
    });
  }

  Future<void> _forceReviewPhase() async {
    final code = _roomCode;
    final playerId = _playerId;
    if (code == null || playerId == null) {
      return;
    }

    final roomRef = _rooms.child(code);
    await roomRef.runTransaction((mutableData) {
      if (mutableData == null) {
        return Transaction.abort();
      }

      final room = _transactionRoom(mutableData);
      if (room['phase'] != 'playing' || room['hostId'] != playerId) {
        return Transaction.abort();
      }

      final players = _playersMap(room);
      for (final entry in players.entries) {
        if (entry.value['hasSubmitted'] != true) {
          room['submissions'] ??= <String, dynamic>{};
          (room['submissions'] as Map)[entry.key] =
              (room['submissions'] as Map)[entry.key] ?? <String>[];
          entry.value['hasSubmitted'] = true;
        }
      }

      _enterReviewPhase(room);
      return Transaction.success(room);
    });
  }

  Map<String, dynamic> _newRoomPayload({
    required String code,
    required String hostId,
    required GameSettings settings,
    required String playerName,
  }) {
    return {
      'code': code,
      'hostId': hostId,
      'phase': 'lobby',
      'roundIndex': 0,
      'prompt': null,
      'roundEndsAt': null,
      'settings': settings.toJson(),
      'players': {
        hostId: {
          'name': playerName,
          'points': 0,
          'isHost': true,
          'hasSubmitted': false,
          'hasReviewed': false,
        },
      },
      'submissions': <String, dynamic>{},
      'reviews': <String, dynamic>{},
    };
  }

  void _resetRoundState(Map<String, dynamic> room) {
    room['prompt'] = null;
    room['roundEndsAt'] = null;
    room['submissions'] = <String, dynamic>{};
    room['reviews'] = <String, dynamic>{};

    final players = _playersMap(room);
    for (final player in players.values) {
      player['hasSubmitted'] = false;
      player['hasReviewed'] = false;
    }
    room['players'] = players;
  }

  void _enterReviewPhase(Map<String, dynamic> room) {
    room['phase'] = 'review';
    final players = _playersMap(room);
    final submissions = _asStringKeyedMap(room['submissions']);
    final reviews = <String, dynamic>{};

    for (final entry in players.entries) {
      final words = List<String>.from(submissions[entry.key] as List? ?? []);
      reviews[entry.key] = words;
      entry.value['hasReviewed'] = false;
    }

    room['reviews'] = reviews;
    room['players'] = players;
  }

  RoomState _deserializeRoom(
    Map<String, dynamic> room,
    String playerId,
    String code,
  ) {
    final playersMap = _playersMap(room);
    final players = playersMap.entries
        .map(
          (entry) => RoomPlayer(
            id: entry.key,
            name: entry.key == playerId
                ? entry.value['name'] as String
                : entry.value['name'] as String,
            points: entry.value['points'] as int? ?? 0,
            isHost: entry.value['isHost'] as bool? ?? false,
            hasSubmitted: entry.value['hasSubmitted'] as bool? ?? false,
            hasReviewed: entry.value['hasReviewed'] as bool? ?? false,
          ),
        )
        .toList();

    final myName = playersMap[playerId]?['name'] as String? ?? '';
    final submissions = _asStringKeyedMap(room['submissions']);
    final reviews = _asStringKeyedMap(room['reviews']);
    final mySubmission = List<String>.from(submissions[playerId] as List? ?? []);
    final myReview = List<String>.from(reviews[playerId] as List? ?? mySubmission);
    final isHost = room['hostId'] == playerId;
    final phase = RoomPhase.values.byName(room['phase'] as String);

    final reviewSubmissions = phase == RoomPhase.review && isHost
        ? playersMap.entries
            .map(
              (entry) => ReviewSubmission(
                playerId: entry.key,
                playerName: entry.value['name'] as String,
                words: List<String>.from(submissions[entry.key] as List? ?? []),
                approvedWords: List<String>.from(
                  reviews[entry.key] as List? ??
                      submissions[entry.key] as List? ??
                      [],
                ),
              ),
            )
            .toList()
        : <ReviewSubmission>[];

    final roundResults = phase == RoomPhase.results
        ? () {
            final results = playersMap.entries
                .map((entry) {
                  final approvedWords =
                      List<String>.from(reviews[entry.key] as List? ?? []);
                  final roundScore = approvedWords.length;
                  return RoundPlayerResult(
                    playerId: entry.key,
                    playerName: entry.value['name'] as String,
                    approvedWords: approvedWords,
                    roundScore: roundScore,
                    totalPoints: entry.value['points'] as int? ?? 0,
                  );
                })
                .toList();
            results.sort((a, b) => b.roundScore.compareTo(a.roundScore));
            return results;
          }()
        : <RoundPlayerResult>[];

    return RoomState(
      code: code,
      playerId: playerId,
      isHost: isHost,
      settings: GameSettings.fromJson(
        _asStringKeyedMap(room['settings']),
        playerName: myName,
      ),
      phase: phase,
      roundIndex: room['roundIndex'] as int? ?? 0,
      players: players,
      prompt: room['prompt'] as String?,
      roundEndsAt: room['roundEndsAt'] as int?,
      mySubmittedWords: mySubmission,
      myApprovedWords: myReview,
      reviewSubmissions: reviewSubmissions,
      roundResults: roundResults,
    );
  }

  Map<String, dynamic> _transactionRoom(Object? mutableData) {
    return _asStringKeyedMap(mutableData);
  }

  Map<String, Map<String, dynamic>> _playersMap(Map<String, dynamic> room) {
    final rawPlayers = _asStringKeyedMap(room['players']);
    return rawPlayers.map(
      (key, value) => MapEntry(key, _asStringKeyedMap(value)),
    );
  }

  Map<String, dynamic> _asStringKeyedMap(Object? value) {
    if (value is! Map) {
      return {};
    }

    return value.map(
      (key, entryValue) => MapEntry(key.toString(), entryValue),
    );
  }

  String _generateRoomCode() {
    return (_random.nextInt(9000) + 1000).toString();
  }

  String _promptForRound(int roundIndex) {
    return roundPrompts[roundIndex % roundPrompts.length];
  }

  String _requirePlayerId() {
    final playerId = _playerId;
    if (playerId == null) {
      throw StateError('غير متصل بالخادم');
    }
    return playerId;
  }

  String _requireRoomCode() {
    final code = _roomCode;
    if (code == null) {
      throw StateError('غير متصل بغرفة');
    }
    return code;
  }
}
