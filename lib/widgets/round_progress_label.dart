import 'package:flutter/material.dart';

class RoundProgressLabel extends StatelessWidget {
  const RoundProgressLabel({
    super.key,
    required this.currentRound,
    required this.totalRounds,
  });

  final int currentRound;
  final int totalRounds;

  @override
  Widget build(BuildContext context) {
    return Text(
      'الجولة $currentRound من $totalRounds',
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4A4A4A),
          ),
    );
  }
}
