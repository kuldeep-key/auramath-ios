import 'package:auramath/ui/features/lesson/view_models/place_value.dart';
import 'package:flutter_test/flutter_test.dart';

/// Acts until done; returns the steps taken.
List<PlaceStep> run(PlaceValue p) {
  final steps = <PlaceStep>[];
  while (p.step != PlaceStep.done) {
    steps.add(p.step);
    p.act();
  }
  return steps;
}

void main() {
  test('186 − 107: break a ten, take the ones, then the tens and hundreds', () {
    final p = PlaceValue(left: 186, right: 107, subtract: true);
    expect(p.step, PlaceStep.breakTen);
    expect(run(p), [
      PlaceStep.breakTen,
      PlaceStep.takeOnes,
      PlaceStep.takeHundreds,
    ]);
    expect(p.value, 79);
    expect(p.answer, 79);
  });

  test('205 − 37: no tens to break, so a hundred is broken first', () {
    final p = PlaceValue(left: 205, right: 37, subtract: true);
    final steps = run(p);
    expect(steps.first, PlaceStep.breakHundred);
    expect(p.value, 168);
  });

  test('186 + 79: ones make a ten, tens make a hundred', () {
    final p = PlaceValue(left: 186, right: 79, subtract: false);
    expect(run(p), [
      PlaceStep.addOnes,
      PlaceStep.makeTen,
      PlaceStep.addTens,
      PlaceStep.makeHundred,
    ]);
    expect(p.value, 265);
  });

  test('every subtraction and addition up to 300 ends on the answer', () {
    for (var a = 10; a <= 300; a += 7) {
      for (var b = 1; b <= a; b += 11) {
        final take = PlaceValue(left: a, right: b, subtract: true);
        run(take);
        expect(take.value, a - b, reason: '$a − $b');
        expect(
          [take.hundreds, take.tens, take.ones].every((d) => d >= 0),
          isTrue,
        );
        final add = PlaceValue(left: a, right: b, subtract: false);
        run(add);
        expect(add.value, a + b, reason: '$a + $b');
        expect(add.ones < 10 && add.tens < 10, isTrue, reason: '$a + $b');
      }
    }
  });
}
