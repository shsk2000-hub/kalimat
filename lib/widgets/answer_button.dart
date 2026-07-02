import 'package:flutter/material.dart';

class AnswerButton extends StatelessWidget {
  const AnswerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isSelected = false,
    this.isCorrect,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isSelected;
  final bool? isCorrect;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Color? backgroundColor;
    if (isCorrect == true) {
      backgroundColor = Colors.green.shade100;
    } else if (isCorrect == false) {
      backgroundColor = Colors.red.shade100;
    } else if (isSelected) {
      backgroundColor = colorScheme.primaryContainer;
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          alignment: Alignment.centerLeft,
        ),
        child: Text(label),
      ),
    );
  }
}
