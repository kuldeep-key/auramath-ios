/// The backend validator's rules for a line the child sees
/// (`auramath/core/validator.py`, TUT-02, TUT-12, AI-05), so the app can
/// check its own pack lines the same way: a number not in the question, a
/// step's answer, more than two sentences, more than one question, banned
/// language, or longer than the two-line budget.
abstract final class LineCheck {
  /// The guardrail words beyond policy `lines.forbidden_phrases`
  /// (validator `BANNED_EXTRA`).
  static const bannedExtra = [
    'awesome',
    'amazing',
    'genius',
    'clever',
    'smart',
    'brilliant',
    'good at maths',
    'good at math',
    'bad at',
    'slow',
    'behind',
    'struggling',
    'easy',
    'simple',
    'obviously',
    'incorrect',
    'mistake',
    'error',
    'sorry',
    'as an ai',
    'language model',
  ];

  /// Validator `SAY_CHAR_BUDGET`: about two lines on the phone.
  static const charBudget = 80;

  /// Why [text] fails, in the validator's words; empty when it passes.
  /// [allowed] are the numbers the line may say (the question's); [answers]
  /// those it may not, the current step's answer.
  static List<String> reasons(
    String text, {
    required Set<int> allowed,
    Set<int> answers = const {},
    required List<String> forbidden,
  }) {
    final t = text.trim();
    if (t.isEmpty) return const ['empty'];
    final out = <String>{};
    for (final m in RegExp(r'\d+').allMatches(t)) {
      final n = int.parse(m[0]!);
      if (answers.contains(n)) {
        out.add('states-answer');
      } else if (!allowed.contains(n)) {
        out.add('answer-numeral');
      }
    }
    final sentences = t
        .split(RegExp(r'[.!?]+'))
        .where((s) => s.trim().isNotEmpty);
    if (sentences.length > 2) out.add('too-many-sentences');
    if ('?'.allMatches(t).length > 1) out.add('too-many-questions');
    final lower = t.toLowerCase();
    for (final b in {
      for (final f in forbidden) f.trim().toLowerCase(),
      ...bannedExtra,
    }) {
      final rx = RegExp('(^|[^a-z])${RegExp.escape(b)}([^a-z]|\$)');
      if (rx.hasMatch(lower)) out.add('banned-language');
    }
    // String.length is UTF-16 code units, as the validator counts
    if (t.length > charBudget) out.add('too-long');
    return out.toList();
  }
}
