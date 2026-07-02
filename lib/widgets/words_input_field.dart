import 'package:flutter/material.dart';

class WordsInputField extends StatelessWidget {
  const WordsInputField({
    super.key,
    required this.controller,
    this.enabled = true,
  });

  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      maxLines: 8,
      minLines: 8,
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
      decoration: const InputDecoration(
        hintText: 'اكتب كلمة في كل سطر',
        hintTextDirection: TextDirection.rtl,
        alignLabelWithHint: true,
      ),
    );
  }
}
