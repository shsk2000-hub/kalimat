import 'dart:async';

import 'package:flutter/material.dart';

import '../data/round_prompts.dart';
import '../models/game_settings.dart';
import '../models/round_result.dart';
import '../widgets/game_countdown_timer.dart';
import '../widgets/round_indicator.dart';
import '../widgets/submit_words_button.dart';
import '../widgets/words_input_field.dart';
import 'word_review_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.settings,
    required this.roundIndex,
    this.completedRounds = const [],
  });

  final GameSettings settings;
  final int roundIndex;
  final List<RoundResult> completedRounds;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final _wordsController = TextEditingController();

  late int _secondsRemaining;
  late String _currentPrompt;

  Timer? _timer;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _currentPrompt = roundPrompts[widget.roundIndex % roundPrompts.length];
    _secondsRemaining = widget.settings.roundDurationSeconds;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _wordsController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }

      if (_secondsRemaining <= 1) {
        _timer?.cancel();
        setState(() => _secondsRemaining = 0);
        _submitWords();
        return;
      }

      setState(() => _secondsRemaining--);
    });
  }

  List<String> _parseWords(String raw) {
    return raw
        .split('\n')
        .map((word) => word.trim())
        .where((word) => word.isNotEmpty)
        .toList();
  }

  void _submitWords() {
    if (_isSubmitting) {
      return;
    }

    _isSubmitting = true;
    _timer?.cancel();

    final words = _parseWords(_wordsController.text);
    final roundResult = RoundResult.fromSubmission(
      prompt: _currentPrompt,
      submittedWords: words,
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => WordReviewScreen(
          settings: widget.settings,
          roundIndex: widget.roundIndex,
          roundResult: roundResult,
          completedRounds: widget.completedRounds,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inputEnabled = _secondsRemaining > 0 && !_isSubmitting;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('الجولة بدأت'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              RoundIndicator(currentRound: widget.roundIndex + 1),
              const SizedBox(height: 24),
              GameCountdownTimer(secondsRemaining: _secondsRemaining),
              const SizedBox(height: 32),
              Text(
                _currentPrompt,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F1F1F),
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
              SubmitWordsButton(
                enabled: inputEnabled,
                onPressed: _submitWords,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
