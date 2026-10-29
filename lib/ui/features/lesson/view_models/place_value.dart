/// What the child does next on the side-lesson board (Figma T1 649:239).
enum PlaceStep {
  /// Not enough ones: tap a ten to make ten ones.
  breakTen,

  /// Not enough tens: tap a hundred to make ten tens.
  breakHundred,
  takeOnes,
  takeTens,
  takeHundreds,
  addOnes,

  /// Ten ones or more: tap the ones to make a ten.
  makeTen,
  addTens,

  /// Ten tens or more: tap the tens to make a hundred.
  makeHundred,
  addHundreds,
  done,
}

/// The column sum the side lesson works through, one place at a time, the
/// way Julia teaches it: hundreds, tens and ones as blocks the child
/// breaks and joins. Pure state; the board draws it.
class PlaceValue {
  PlaceValue({required this.left, required this.right, required this.subtract})
    : hundreds = left ~/ 100,
      tens = left ~/ 10 % 10,
      ones = left % 10 {
    _advance();
  }

  final int left;
  final int right;
  final bool subtract;

  int hundreds;
  int tens;
  int ones;
  PlaceStep step = PlaceStep.done;

  int get rightHundreds => right ~/ 100;
  int get rightTens => right ~/ 10 % 10;
  int get rightOnes => right % 10;
  int get answer => subtract ? left - right : left + right;

  /// What the blocks show now.
  int get value => hundreds * 100 + tens * 10 + ones;

  final Set<PlaceStep> _done = {};

  /// The child's action for the current step (a tap on the blocks, or the
  /// step's button). Anything else is ignored.
  void act() {
    switch (step) {
      case PlaceStep.breakTen:
        tens--;
        ones += 10;
      case PlaceStep.breakHundred:
        hundreds--;
        tens += 10;
      case PlaceStep.takeOnes:
        ones -= rightOnes;
      case PlaceStep.takeTens:
        tens -= rightTens;
      case PlaceStep.takeHundreds:
        hundreds -= rightHundreds;
      case PlaceStep.addOnes:
        ones += rightOnes;
      case PlaceStep.makeTen:
        ones -= 10;
        tens++;
      case PlaceStep.addTens:
        tens += rightTens;
      case PlaceStep.makeHundred:
        tens -= 10;
        hundreds++;
      case PlaceStep.addHundreds:
        hundreds += rightHundreds;
      case PlaceStep.done:
        return;
    }
    _done.add(step);
    _advance();
  }

  void _advance() {
    step = subtract ? _nextTake() : _nextAdd();
  }

  PlaceStep _nextTake() {
    if (!_done.contains(PlaceStep.takeOnes)) {
      if (ones >= rightOnes) return PlaceStep.takeOnes;
      return tens > 0 ? PlaceStep.breakTen : PlaceStep.breakHundred;
    }
    if (rightTens > 0 && !_done.contains(PlaceStep.takeTens)) {
      return tens >= rightTens ? PlaceStep.takeTens : PlaceStep.breakHundred;
    }
    if (rightHundreds > 0 && !_done.contains(PlaceStep.takeHundreds)) {
      return PlaceStep.takeHundreds;
    }
    return PlaceStep.done;
  }

  PlaceStep _nextAdd() {
    if (!_done.contains(PlaceStep.addOnes)) return PlaceStep.addOnes;
    if (ones >= 10) return PlaceStep.makeTen;
    if (rightTens > 0 && !_done.contains(PlaceStep.addTens)) {
      return PlaceStep.addTens;
    }
    if (tens >= 10) return PlaceStep.makeHundred;
    if (rightHundreds > 0 && !_done.contains(PlaceStep.addHundreds)) {
      return PlaceStep.addHundreds;
    }
    return PlaceStep.done;
  }
}
