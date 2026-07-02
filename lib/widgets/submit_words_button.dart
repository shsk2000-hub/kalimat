import 'package:flutter/material.dart';

import 'game_countdown_timer.dart';

class SubmitWordsButton extends StatelessWidget {
  const SubmitWordsButton({
    super.key,
    required this.onPressed,
    this.enabled = true,
  });

  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: GameCountdownTimer.timerBlue,
          backgroundColor: const Color(0xFFE8F1FB),
          side: BorderSide.none,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: const Text('إرسال الكلمات'),
      ),
    );
  }
}
