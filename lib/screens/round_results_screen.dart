import 'package:flutter/material.dart';

import '../models/game_settings.dart';
import '../models/round_result.dart';
import '../utils/app_theme.dart';
import '../widgets/primary_pill_button.dart';
import '../widgets/round_progress_label.dart';
import 'game_setup_screen.dart';
import 'lobby_screen.dart';

class RoundResultsScreen extends StatelessWidget {
  const RoundResultsScreen({
    super.key,
    required this.settings,
    required this.roundIndex,
    required this.roundResult,
    this.completedRounds = const [],
  });

  final GameSettings settings;
  final int roundIndex;
  final RoundResult roundResult;
  final List<RoundResult> completedRounds;

  bool get _isLastRound => roundIndex >= settings.numberOfRounds - 1;

  List<RoundResult> get _allCompletedRounds => [
        ...completedRounds,
        roundResult,
      ];

  int get _totalScore =>
      _allCompletedRounds.fold(0, (total, round) => total + round.score);

  void _goNext(BuildContext context) {
    if (_isLastRound) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const GameSetupScreen(),
        ),
        (_) => false,
      );
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => LobbyScreen(
          settings: settings,
          roundIndex: roundIndex + 1,
          completedRounds: _allCompletedRounds,
        ),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نتائج الجولة'),
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
              const SizedBox(height: 24),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppTheme.cardBorder),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'الأول 🥇',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppTheme.lightBlue,
                            child: Text(
                              '${roundResult.score}',
                              style: const TextStyle(
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              settings.playerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Text(
                            '${roundResult.score} نقطة',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (roundResult.approvedWords.isNotEmpty) ...[
                        const Divider(height: 28),
                        ...roundResult.approvedWords.map(
                          (word) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                const Text(
                                  '+1',
                                  style: TextStyle(
                                    color: AppTheme.successGreen,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  word,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const CircleAvatar(
                                  radius: 12,
                                  backgroundColor: AppTheme.successGreen,
                                  child: Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (!_isLastRound) ...[
                        const Divider(height: 28),
                        Text(
                          'إجمالي النقاط: $_totalScore',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const Spacer(),
              PrimaryPillButton(
                label: _isLastRound ? 'العودة للرئيسية' : 'الجولة التالية',
                onPressed: () => _goNext(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
