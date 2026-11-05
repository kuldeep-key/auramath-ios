import 'lesson.dart';

/// Inputs as flat JSON, `{"type": "<camelCaseClassName>", ...fields}`, with
/// enums by name. This is what the event log stores.
Map<String, Object?> inputToJson(LessonInput i) => switch (i) {
  Started() => {'type': 'started'},
  BarADrawn() => {'type': 'barADrawn'},
  BarBPlaced() => {'type': 'barBPlaced'},
  BarBSized(:final rel) => {'type': 'barBSized', 'rel': rel.name},
  PieceDropped(:final piece, :final target) => {
    'type': 'pieceDropped',
    'piece': piece.name,
    'target': target.name,
  },
  OpChosen(:final op) => {'type': 'opChosen', 'op': op.name},
  NumberEntered(:final value) => {'type': 'numberEntered', 'value': value},
  SideLessonDone() => {'type': 'sideLessonDone'},
  Undo() => {'type': 'undo'},
  KnowIt(:final value) => {'type': 'knowIt', 'value': value},
  PartChecked(:final value) => {'type': 'partChecked', 'value': value},
  KnowTotalChecked(:final value) => {
    'type': 'knowTotalChecked',
    'value': value,
  },
  HintTaken() => {'type': 'hintTaken'},
  ShowMeHowTaken() => {'type': 'showMeHowTaken'},
  EasierTaken() => {'type': 'easierTaken'},
  QuietFor(:final ms) => {'type': 'quietFor', 'ms': ms},
};

LessonInput inputFromJson(Map<String, Object?> j) {
  int n(String k) => j[k] as int;
  return switch (j['type']) {
    'started' => const Started(),
    'barADrawn' => const BarADrawn(),
    'barBPlaced' => const BarBPlaced(),
    'barBSized' => BarBSized(Relation.values.byName(j['rel'] as String)),
    'pieceDropped' => PieceDropped(
      Piece.values.byName(j['piece'] as String),
      Target.values.byName(j['target'] as String),
    ),
    'opChosen' => OpChosen(Op.values.byName(j['op'] as String)),
    'numberEntered' => NumberEntered(n('value')),
    'sideLessonDone' => const SideLessonDone(),
    'undo' => const Undo(),
    'knowIt' => KnowIt(n('value')),
    'partChecked' => PartChecked(n('value')),
    'knowTotalChecked' => KnowTotalChecked(n('value')),
    'hintTaken' => const HintTaken(),
    'showMeHowTaken' => const ShowMeHowTaken(),
    'easierTaken' => const EasierTaken(),
    'quietFor' => QuietFor(n('ms')),
    final t => throw FormatException('unknown input type: $t'),
  };
}

Map<String, Object?> decisionToJson(Decision d) => switch (d) {
  Coach(:final lineId, :final slots) => {
    'type': 'coach',
    'lineId': lineId,
    'slots': slots,
  },
  Wobble() => {'type': 'wobble'},
  ShakeHelp() => {'type': 'shakeHelp'},
  OpenSideLesson(:final kind) => {'type': 'openSideLesson', 'kind': kind.name},
  AskWhatQuestionAsks() => {'type': 'askWhatQuestionAsks'},
  OpenRecheck() => {'type': 'openRecheck'},
  CheckOnePart() => {'type': 'checkOnePart'},
  DrawIt() => {'type': 'drawIt'},
  ShowHint(:final lineId) => {'type': 'showHint', 'lineId': lineId},
  SuggestShowMeHow() => {'type': 'suggestShowMeHow'},
  SwitchProblem(:final problemId) => {
    'type': 'switchProblem',
    'problemId': problemId,
  },
  PulseHelp() => {'type': 'pulseHelp'},
  GlowPiece() => {'type': 'glowPiece'},
  ShowHand() => {'type': 'showHand'},
  AskStillThere() => {'type': 'askStillThere'},
  Solved(:final by, :final badgeId, :final nextProblemId) => {
    'type': 'solved',
    'by': by.name,
    'badgeId': badgeId,
    'nextProblemId': nextProblemId,
  },
};
