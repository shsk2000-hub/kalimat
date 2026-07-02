import 'game_settings.dart';

enum RoomPhase {
  lobby,
  playing,
  review,
  results,
  finished,
}

class RoomPlayer {
  const RoomPlayer({
    required this.id,
    required this.name,
    required this.points,
    required this.isHost,
    required this.hasSubmitted,
    required this.hasReviewed,
  });

  final String id;
  final String name;
  final int points;
  final bool isHost;
  final bool hasSubmitted;
  final bool hasReviewed;

  factory RoomPlayer.fromJson(Map<String, dynamic> json) {
    return RoomPlayer(
      id: json['id'] as String,
      name: json['name'] as String,
      points: json['points'] as int? ?? 0,
      isHost: json['isHost'] as bool? ?? false,
      hasSubmitted: json['hasSubmitted'] as bool? ?? false,
      hasReviewed: json['hasReviewed'] as bool? ?? false,
    );
  }
}

class RoundPlayerResult {
  const RoundPlayerResult({
    required this.playerId,
    required this.playerName,
    required this.approvedWords,
    required this.roundScore,
    required this.totalPoints,
  });

  final String playerId;
  final String playerName;
  final List<String> approvedWords;
  final int roundScore;
  final int totalPoints;

  factory RoundPlayerResult.fromJson(Map<String, dynamic> json) {
    return RoundPlayerResult(
      playerId: json['playerId'] as String,
      playerName: json['playerName'] as String,
      approvedWords: (json['approvedWords'] as List<dynamic>? ?? [])
          .map((word) => word as String)
          .toList(),
      roundScore: json['roundScore'] as int? ?? 0,
      totalPoints: json['totalPoints'] as int? ?? 0,
    );
  }
}

class RoomState {
  const RoomState({
    required this.code,
    required this.playerId,
    required this.isHost,
    required this.settings,
    required this.phase,
    required this.roundIndex,
    required this.players,
    required this.prompt,
    required this.roundEndsAt,
    required this.mySubmittedWords,
    required this.myApprovedWords,
    required this.roundResults,
  });

  final String code;
  final String playerId;
  final bool isHost;
  final GameSettings settings;
  final RoomPhase phase;
  final int roundIndex;
  final List<RoomPlayer> players;
  final String? prompt;
  final int? roundEndsAt;
  final List<String> mySubmittedWords;
  final List<String> myApprovedWords;
  final List<RoundPlayerResult> roundResults;

  factory RoomState.fromJson(Map<String, dynamic> json) {
    final playerId = json['playerId'] as String;
    final players = (json['players'] as List<dynamic>? ?? [])
        .map((player) => RoomPlayer.fromJson(player as Map<String, dynamic>))
        .toList();
    final myName = players
        .where((player) => player.id == playerId)
        .map((player) => player.name)
        .firstOrNull;

    return RoomState(
      code: json['code'] as String,
      playerId: playerId,
      isHost: json['isHost'] as bool? ?? false,
      settings: GameSettings.fromJson(
        json['settings'] as Map<String, dynamic>,
        playerName: myName ?? '',
      ),
      phase: RoomPhase.values.byName(json['phase'] as String),
      roundIndex: json['roundIndex'] as int? ?? 0,
      players: (json['players'] as List<dynamic>? ?? [])
          .map((player) => RoomPlayer.fromJson(player as Map<String, dynamic>))
          .toList(),
      prompt: json['prompt'] as String?,
      roundEndsAt: json['roundEndsAt'] as int?,
      mySubmittedWords: (json['mySubmittedWords'] as List<dynamic>? ?? [])
          .map((word) => word as String)
          .toList(),
      myApprovedWords: (json['myApprovedWords'] as List<dynamic>? ?? [])
          .map((word) => word as String)
          .toList(),
      roundResults: (json['roundResults'] as List<dynamic>? ?? [])
          .map(
            (result) =>
                RoundPlayerResult.fromJson(result as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}
