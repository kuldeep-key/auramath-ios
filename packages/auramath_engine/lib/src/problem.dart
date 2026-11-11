enum BigSide { a, b }

/// The spec step ids this engine can run, in the order it runs them when a
/// problem has no template to read them from (LES-03).
const knownSteps = [
  'name_quantities',
  'draw_known_bar',
  'size_second_bar',
  'place_difference',
  'place_total',
  'choose_operation',
  'find_unknown',
  'find_total',
  'number_sentence',
];

/// The steps the template marks optional: they run only where turned on.
const optionalSteps = {'name_quantities', 'number_sentence'};

/// What the question asks for: both together, or the second item alone.
enum Ask { total, b }

class Item {
  const Item({required this.name, required this.pic});

  factory Item.fromJson(Map<String, Object?> j) =>
      Item(name: j['name'] as String, pic: j['pic'] as String);

  final String name;
  final String pic;
}

/// One option of a choice step as the server serves it with a problem
/// (`problem.steps[].options`, LES-12): its text already in the problem's
/// words or the template's symbols, and whether it is right here.
class ServedOption {
  const ServedOption({
    required this.id,
    required this.text,
    required this.correct,
  });

  final String id;
  final String text;
  final bool correct;
}

/// One step as the server serves it with a problem (`problem.steps[]`,
/// LES-03), in the order the lesson runs them for the problem's level.
class ServedStep {
  const ServedStep({
    required this.id,
    this.optional = false,
    this.hintStartRung,
    this.options = const [],
  });

  /// The spec step id: `draw_known_bar`, `choose_operation`, ...
  final String id;

  /// Runs only where the app turns it on (a flag).
  final bool optional;
  final String? hintStartRung;
  final List<ServedOption> options;
}

/// Which problem comes after this one, by how it went.
class NextProblems {
  const NextProblems({
    required this.fast,
    required this.helped,
    required this.easier,
  });

  factory NextProblems.fromJson(Map<String, Object?> j) => NextProblems(
    fast: j['fast'] as String,
    helped: j['helped'] as String,
    easier: j['easier'] as String,
  );

  final String fast;
  final String helped;
  final String easier;
}

/// A comparison word problem: item a has a value, item b is [diff] more or
/// less, and the child finds b and (for [Ask.total]) both together.
class ComparisonProblem {
  const ComparisonProblem({
    required this.id,
    required this.a,
    required this.b,
    required this.aValue,
    required this.diff,
    required this.big,
    required this.unit,
    required this.ask,
    required this.text,
    required this.say,
    required this.next,
    required this.templateId,
    required this.templateVersion,
    required this.storyId,
    required this.variant,
    this.level,
    this.quantity = 'height',
    this.steps,
  });

  factory ComparisonProblem.fromJson(Map<String, Object?> j) {
    final a = j['a'] as Map<String, Object?>;
    final template = j['template'] as Map<String, Object?>;
    return ComparisonProblem(
      id: j['id'] as String,
      a: Item.fromJson(a),
      b: Item.fromJson(j['b'] as Map<String, Object?>),
      aValue: a['value'] as int,
      diff: j['diff'] as int,
      big: BigSide.values.byName(j['big'] as String),
      unit: j['unit'] as String,
      ask: Ask.values.byName(j['ask'] as String),
      text: j['text'] as String,
      say: j['say'] as String,
      next: NextProblems.fromJson(j['next'] as Map<String, Object?>),
      templateId: template['id'] as String,
      templateVersion: template['version'] as String,
      storyId: j['story'] as String,
      variant: j['variant'] as String,
      level: j['level'] as String?,
      quantity: j['quantity'] as String? ?? 'height',
    );
  }

  final String id;
  final Item a;
  final Item b;
  final int aValue;
  final int diff;
  final BigSide big;
  final String unit;
  final Ask ask;
  final String text;
  final String say;
  final NextProblems next;

  /// The spec's names for this problem, carried into `problem_shown`.
  final String templateId;
  final String templateVersion;
  final String storyId;

  /// `standard`, `easier`, `worked_example` or `check`.
  final String variant;

  /// `L1` to `L5`; null when the problem sits outside the ladder.
  final String? level;

  /// `height` or `mass` (CON-11): a mass story's bars lie across (LES-04).
  final String quantity;
  bool get isMass => quantity == 'mass';

  /// The server's steps for this problem, in order, with their options
  /// (LES-03, LES-12); null for a problem the server didn't serve them
  /// with: then the pack's template, else the engine's own order.
  final List<ServedStep>? steps;

  ServedStep? servedStep(String id) =>
      steps?.where((s) => s.id == id).firstOrNull;

  int get bValue => big == BigSide.a ? aValue - diff : aValue + diff;
  int get total => aValue + bValue;
}
