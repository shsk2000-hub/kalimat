import 'package:flutter/material.dart';

import '../models/game_settings.dart';
import '../models/round_result.dart';
import '../utils/app_theme.dart';
import '../widgets/primary_pill_button.dart';
import 'round_results_screen.dart';

class WordReviewScreen extends StatefulWidget {
  const WordReviewScreen({
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

  @override
  State<WordReviewScreen> createState() => _WordReviewScreenState();
}

class _WordReviewScreenState extends State<WordReviewScreen> {
  late final Set<String> _approvedWords;

  @override
  void initState() {
    super.initState();
    _approvedWords = Set<String>.from(widget.roundResult.submittedWords);
  }

  int get _approvedCount => _approvedWords.length;
  int get _rejectedCount =>
      widget.roundResult.submittedWords.length - _approvedCount;

  void _toggleWord(String word, bool approved) {
    setState(() {
      if (approved) {
        _approvedWords.add(word);
      } else {
        _approvedWords.remove(word);
      }
    });
  }

  void _approveResults() {
    final approved = widget.roundResult.submittedWords
        .where(_approvedWords.contains)
        .toList();

    final reviewedResult = widget.roundResult.copyWith(
      approvedWords: approved,
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => RoundResultsScreen(
          settings: widget.settings,
          roundIndex: widget.roundIndex,
          roundResult: reviewedResult,
          completedRounds: widget.completedRounds,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مراجعة الكلمات'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'الجولة ${widget.roundIndex + 1} - مراجعة قبل اعتماد النتائج',
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'إجمالي الكلمات: ${widget.roundResult.submittedWords.length}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'المعتمدة: $_approvedCount | المرفوضة: $_rejectedCount',
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'أزل علامة الصح عن أي كلمة خاطئة أو غير مقبولة، ثم اضغط اعتماد النتائج.',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                      ),
                    ),
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                widget.settings.playerName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const CircleAvatar(
                                radius: 14,
                                backgroundColor: AppTheme.lightBlue,
                                child: Icon(
                                  Icons.person,
                                  size: 16,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '$_approvedCount معتمدة / $_rejectedCount مرفوضة',
                          style: const TextStyle(color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (widget.roundResult.submittedWords.isEmpty)
                      const Text(
                        'لم تُرسل كلمات',
                        textAlign: TextAlign.right,
                      )
                    else
                      ...widget.roundResult.submittedWords.map((word) {
                        final isApproved = _approvedWords.contains(word);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Checkbox(
                                value: isApproved,
                                onChanged: (value) {
                                  _toggleWord(word, value ?? false);
                                },
                              ),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          word,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          isApproved ? 'معتمدة' : 'مرفوضة',
                                          style: TextStyle(
                                            color: isApproved
                                                ? AppTheme.successGreen
                                                : Colors.red,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 8),
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: isApproved
                                          ? AppTheme.successGreen
                                          : Colors.red.shade300,
                                      child: Icon(
                                        isApproved
                                            ? Icons.check
                                            : Icons.close,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            PrimaryPillButton(
              label: 'اعتماد النتائج',
              icon: Icons.verified_user_outlined,
              onPressed: _approveResults,
            ),
          ],
        ),
      ),
    );
  }
}
