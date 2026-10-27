enum BigSide { a, b }

/// What the question asks for: both together, or the second item alone.
enum Ask { total, b }

class Item {
  const Item({required this.name, required this.pic});

  factory Item.fromJson(Map<String, Object?> j) =>
      Item(name: j['name'] as String, pic: j['pic'] as String);

  final String name;
  final String pic;
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
  });

  factory ComparisonProblem.fromJson(Map<String, Object?> j) {
    final a = j['a'] as Map<String, Object?>;
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

  int get bValue => big == BigSide.a ? aValue - diff : aValue + diff;
  int get total => aValue + bValue;
}
