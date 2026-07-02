import 'package:flutter/material.dart';

class GameCountdownTimer extends StatelessWidget {
  const GameCountdownTimer({
    super.key,
    required this.secondsRemaining,
  });

  final int secondsRemaining;

  static const Color timerBlue = Color(0xFF2196F3);

  @override
  Widget build(BuildContext context) {
    return Text(
      '$secondsRemaining',
      style: Theme.of(context).textTheme.displayLarge?.copyWith(
            fontSize: 72,
            fontWeight: FontWeight.w700,
            color: timerBlue,
            height: 1,
          ),
    );
  }
}
