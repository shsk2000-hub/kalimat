class GameSettings {
  const GameSettings({
    required this.playerName,
    required this.roundTitle,
    required this.roundDurationSeconds,
    required this.numberOfRounds,
  });

  final String playerName;
  final String roundTitle;
  final int roundDurationSeconds;
  final int numberOfRounds;

  static const String gameName = 'تحدي الكلمات';

  Map<String, dynamic> toJson() {
    return {
      'roundTitle': roundTitle,
      'roundDurationSeconds': roundDurationSeconds,
      'numberOfRounds': numberOfRounds,
    };
  }

  factory GameSettings.fromJson(Map<String, dynamic> json, {String? playerName}) {
    return GameSettings(
      playerName: playerName ?? json['playerName'] as String? ?? '',
      roundTitle: json['roundTitle'] as String,
      roundDurationSeconds: json['roundDurationSeconds'] as int,
      numberOfRounds: json['numberOfRounds'] as int,
    );
  }
}