/// A single multiple-choice quiz question embedded in a [SafetyVideo].
///
/// All user-facing text is stored as a localized [Map] keyed by language code
/// (en, hi, bn, te, mr, or). Use the [localize] helper from
/// `presentation/widgets` to resolve.
class QuizQuestion {
  const QuizQuestion({
    required this.questionId,
    required this.question,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
  });

  final String questionId;
  final Map<String, String> question;
  final List<Map<String, String>> options;
  final int correctOptionIndex;
  final Map<String, String> explanation;

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    final rawOptions = map['options'] as List<dynamic>? ?? const [];
    return QuizQuestion(
      questionId: map['questionId'] as String? ?? '',
      question: _stringMap(map['question']),
      options: rawOptions
          .map((o) => _stringMap(o))
          .toList(),
      correctOptionIndex: (map['correctOptionIndex'] as num?)?.toInt() ?? 0,
      explanation: _stringMap(map['explanation']),
    );
  }

  Map<String, dynamic> toMap() => {
        'questionId': questionId,
        'question': question,
        'options': options,
        'correctOptionIndex': correctOptionIndex,
        'explanation': explanation,
      };

  static Map<String, String> _stringMap(dynamic raw) {
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
    }
    return const {};
  }
}
