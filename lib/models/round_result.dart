class RoundResult {
  const RoundResult({
    required this.prompt,
    required this.submittedWords,
    required this.approvedWords,
  });

  final String prompt;
  final List<String> submittedWords;
  final List<String> approvedWords;

  int get score => approvedWords.length;
  int get approvedCount => approvedWords.length;
  int get rejectedCount => submittedWords.length - approvedWords.length;

  factory RoundResult.fromSubmission({
    required String prompt,
    required List<String> submittedWords,
  }) {
    return RoundResult(
      prompt: prompt,
      submittedWords: submittedWords,
      approvedWords: List<String>.from(submittedWords),
    );
  }

  RoundResult copyWith({
    List<String>? approvedWords,
  }) {
    return RoundResult(
      prompt: prompt,
      submittedWords: submittedWords,
      approvedWords: approvedWords ?? this.approvedWords,
    );
  }
}
