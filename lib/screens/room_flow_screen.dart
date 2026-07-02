import 'package:flutter/material.dart';

import '../models/room_state.dart';
import '../services/multiplayer_service.dart';
import '../utils/app_theme.dart';
import '../widgets/game_countdown_timer.dart';
import '../widgets/player_card.dart';
import '../widgets/primary_pill_button.dart';
import '../widgets/room_code_display.dart';
import '../widgets/round_indicator.dart';
import '../widgets/round_progress_label.dart';
import '../widgets/share_room_link_card.dart';
import '../widgets/submit_words_button.dart';
import '../widgets/words_input_field.dart';
import 'game_setup_screen.dart';

class RoomFlowScreen extends StatefulWidget {
  const RoomFlowScreen({super.key});

  @override
  State<RoomFlowScreen> createState() => _RoomFlowScreenState();
}

class _RoomFlowScreenState extends State<RoomFlowScreen> {
  final _multiplayer = MultiplayerService.instance;

  @override
  void initState() {
    super.initState();
    _multiplayer.roomState.addListener(_onRoomChanged);
  }

  @override
  void dispose() {
    _multiplayer.roomState.removeListener(_onRoomChanged);
    super.dispose();
  }

  void _onRoomChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});

    final state = _multiplayer.roomState.value;
    if (state?.phase == RoomPhase.finished) {
      _multiplayer.leaveRoom();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const GameSetupScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _multiplayer.roomState.value;
    if (state == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return switch (state.phase) {
      RoomPhase.lobby => _LobbyPhaseView(state: state),
      RoomPhase.playing => _PlayingPhaseView(state: state),
      RoomPhase.review => _ReviewPhaseView(state: state),
      RoomPhase.results => _ResultsPhaseView(state: state),
      RoomPhase.finished => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
    };
  }
}

class _LobbyPhaseView extends StatelessWidget {
  const _LobbyPhaseView({required this.state});

  final RoomState state;

  @override
  Widget build(BuildContext context) {
    final sortedPlayers = [...state.players]
      ..sort((a, b) => b.points.compareTo(a.points));

    return Scaffold(
      appBar: AppBar(
        title: const Text('انتظار اللاعبين'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            RoomCodeDisplay(code: state.code),
            if (state.isHost) ...[
              const SizedBox(height: 16),
              ShareRoomLinkCard(roomCode: state.code),
            ],
            const SizedBox(height: 24),
            RoundProgressLabel(
              currentRound: state.roundIndex + 1,
              totalRounds: state.settings.numberOfRounds,
            ),
            const SizedBox(height: 8),
            Text(
              state.settings.roundTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                'اللاعبون',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
            const SizedBox(height: 12),
            ...sortedPlayers.asMap().entries.map((entry) {
              final player = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: PlayerCard(
                  playerName: player.name,
                  points: player.points,
                  rank: entry.key + 1,
                ),
              );
            }),
            const SizedBox(height: 24),
            if (state.isHost)
              PrimaryPillButton(
                label: 'بدء الجولة',
                onPressed: () async {
                  try {
                    await MultiplayerService.instance.startRound();
                  } catch (error) {
                    if (!context.mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error.toString())),
                    );
                  }
                },
              )
            else
              const Text(
                'بانتظار المسؤول لبدء الجولة...',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textMuted),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlayingPhaseView extends StatefulWidget {
  const _PlayingPhaseView({required this.state});

  final RoomState state;

  @override
  State<_PlayingPhaseView> createState() => _PlayingPhaseViewState();
}

class _PlayingPhaseViewState extends State<_PlayingPhaseView> {
  final _wordsController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _wordsController.dispose();
    super.dispose();
  }

  List<String> _parseWords(String raw) {
    return raw
        .split('\n')
        .map((word) => word.trim())
        .where((word) => word.isNotEmpty)
        .toList();
  }

  Future<void> _submit() async {
    if (_isSubmitting || widget.state.players
        .any((player) => player.id == widget.state.playerId && player.hasSubmitted)) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await MultiplayerService.instance.submitWords(
        _parseWords(_wordsController.text),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final me = state.players.firstWhere((player) => player.id == state.playerId);
    final inputEnabled = !me.hasSubmitted && !_isSubmitting;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: const Text('الجولة بدأت')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              RoundIndicator(currentRound: state.roundIndex + 1),
              const SizedBox(height: 24),
              _SyncedTimer(
                roundEndsAt: state.roundEndsAt,
                fallbackSeconds: state.settings.roundDurationSeconds,
              ),
              const SizedBox(height: 32),
              Text(
                state.prompt ?? '',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: WordsInputField(
                  controller: _wordsController,
                  enabled: inputEnabled,
                ),
              ),
              const SizedBox(height: 16),
              if (me.hasSubmitted)
                const Text(
                  'تم إرسال كلماتك، بانتظار بقية اللاعبين...',
                  style: TextStyle(color: AppTheme.textMuted),
                )
              else
                SubmitWordsButton(
                  enabled: inputEnabled,
                  onPressed: _submit,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SyncedTimer extends StatefulWidget {
  const _SyncedTimer({
    required this.roundEndsAt,
    required this.fallbackSeconds,
  });

  final int? roundEndsAt;
  final int fallbackSeconds;

  @override
  State<_SyncedTimer> createState() => _SyncedTimerState();
}

class _SyncedTimerState extends State<_SyncedTimer> {
  late int _secondsRemaining;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = _calculate();
    _tick();
  }

  @override
  void didUpdateWidget(covariant _SyncedTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _secondsRemaining = _calculate();
  }

  int _calculate() {
    final endsAt = widget.roundEndsAt;
    if (endsAt == null) {
      return widget.fallbackSeconds;
    }
    final remaining =
        ((endsAt - DateTime.now().millisecondsSinceEpoch) / 1000).ceil();
    return remaining < 0 ? 0 : remaining;
  }

  void _tick() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) {
        return;
      }
      setState(() => _secondsRemaining = _calculate());
      _tick();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GameCountdownTimer(secondsRemaining: _secondsRemaining);
  }
}

class _ReviewPhaseView extends StatefulWidget {
  const _ReviewPhaseView({required this.state});

  final RoomState state;

  @override
  State<_ReviewPhaseView> createState() => _ReviewPhaseViewState();
}

class _ReviewPhaseViewState extends State<_ReviewPhaseView> {
  late Set<String> _approvedWords;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _approvedWords = Set<String>.from(widget.state.mySubmittedWords);
  }

  @override
  void didUpdateWidget(covariant _ReviewPhaseView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.mySubmittedWords != widget.state.mySubmittedWords) {
      _approvedWords = Set<String>.from(widget.state.mySubmittedWords);
    }
  }

  int get _approvedCount => _approvedWords.length;
  int get _rejectedCount =>
      widget.state.mySubmittedWords.length - _approvedCount;

  String get _myName {
    return widget.state.players
        .firstWhere((player) => player.id == widget.state.playerId)
        .name;
  }

  Future<void> _approve() async {
    if (_isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final approved = widget.state.mySubmittedWords
          .where(_approvedWords.contains)
          .toList();
      await MultiplayerService.instance.approveResults(approved);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = widget.state.players
        .firstWhere((player) => player.id == widget.state.playerId);

    return Scaffold(
      appBar: AppBar(title: const Text('مراجعة الكلمات')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'الجولة ${widget.state.roundIndex + 1} - مراجعة قبل اعتماد النتائج',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
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
                    Text(
                      'إجمالي الكلمات: ${widget.state.mySubmittedWords.length}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text('المعتمدة: $_approvedCount | المرفوضة: $_rejectedCount'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppTheme.cardBorder),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$_approvedCount معتمدة / $_rejectedCount مرفوضة'),
                        Text(_myName, style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (widget.state.mySubmittedWords.isEmpty)
                      const Text('لم تُرسل كلمات', textAlign: TextAlign.right)
                    else
                      ...widget.state.mySubmittedWords.map((word) {
                        final isApproved = _approvedWords.contains(word);
                        return CheckboxListTile(
                          value: isApproved,
                          onChanged: me.hasReviewed
                              ? null
                              : (value) {
                                  setState(() {
                                    if (value == true) {
                                      _approvedWords.add(word);
                                    } else {
                                      _approvedWords.remove(word);
                                    }
                                  });
                                },
                          title: Text(word, textAlign: TextAlign.right),
                          subtitle: Text(isApproved ? 'معتمدة' : 'مرفوضة'),
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (me.hasReviewed)
              const Text(
                'تم اعتماد نتائجك، بانتظار بقية اللاعبين...',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textMuted),
              )
            else
              PrimaryPillButton(
                label: 'اعتماد النتائج',
                icon: Icons.verified_user_outlined,
                enabled: !_isSubmitting,
                onPressed: _approve,
              ),
          ],
        ),
      ),
    );
  }
}

class _ResultsPhaseView extends StatelessWidget {
  const _ResultsPhaseView({required this.state});

  final RoomState state;

  bool get _isLastRound => state.roundIndex >= state.settings.numberOfRounds - 1;

  @override
  Widget build(BuildContext context) {
    final medals = ['🥇', '🥈', '🥉'];

    return Scaffold(
      appBar: AppBar(title: const Text('نتائج الجولة')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RoundProgressLabel(
                currentRound: state.roundIndex + 1,
                totalRounds: state.settings.numberOfRounds,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: state.roundResults.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final result = state.roundResults[index];
                    final medal = index < medals.length ? medals[index] : '';

                    return Card(
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
                            Text(
                              '${index + 1} $medal'.trim(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppTheme.lightBlue,
                                  child: Text(
                                    '${result.roundScore}',
                                    style: const TextStyle(
                                      color: AppTheme.primaryBlue,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    result.playerName,
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                Text('${result.roundScore} نقطة'),
                              ],
                            ),
                            if (result.approvedWords.isNotEmpty) ...[
                              const Divider(height: 24),
                              ...result.approvedWords.map(
                                (word) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
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
                                      Text(word),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.check_circle,
                                        color: AppTheme.successGreen,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (state.isHost)
                PrimaryPillButton(
                  label: _isLastRound ? 'إنهاء اللعبة' : 'الجولة التالية',
                  onPressed: () async {
                    try {
                      await MultiplayerService.instance.startRound();
                    } catch (error) {
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error.toString())),
                      );
                    }
                  },
                )
              else
                Text(
                  _isLastRound
                      ? 'بانتظار المسؤول لإنهاء اللعبة...'
                      : 'بانتظار المسؤول للجولة التالية...',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textMuted),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
