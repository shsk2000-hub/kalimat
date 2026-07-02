import 'package:flutter/material.dart';

import '../models/game_settings.dart';
import '../models/round_result.dart';
import '../widgets/player_card.dart';
import '../widgets/primary_pill_button.dart';
import '../widgets/round_progress_label.dart';
import 'game_screen.dart';

class LobbyScreen extends StatelessWidget {
  const LobbyScreen({
    super.key,
    required this.settings,
    required this.roundIndex,
    this.completedRounds = const [],
  });

  final GameSettings settings;
  final int roundIndex;
  final List<RoundResult> completedRounds;

  int get _totalPoints =>
      completedRounds.fold(0, (total, round) => total + round.score);

  void _startRound(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(
          settings: settings,
          roundIndex: roundIndex,
          completedRounds: completedRounds,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('استعداد للعب'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RoundProgressLabel(
                currentRound: roundIndex + 1,
                totalRounds: settings.numberOfRounds,
              ),
              const SizedBox(height: 8),
              Text(
                settings.roundTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF6B6B6B),
                    ),
              ),
              const SizedBox(height: 28),
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'اللاعبون',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              PlayerCard(
                playerName: settings.playerName,
                points: _totalPoints,
              ),
              const Spacer(),
              PrimaryPillButton(
                label: 'بدء الجولة',
                onPressed: () => _startRound(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
