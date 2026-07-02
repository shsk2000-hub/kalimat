import 'package:flutter/material.dart';

class RoundIndicator extends StatelessWidget {
  const RoundIndicator({
    super.key,
    required this.currentRound,
  });

  final int currentRound;

  @override
  Widget build(BuildContext context) {
    return Text(
      'الجولة $currentRound',
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4A4A4A),
          ),
    );
  }
}
