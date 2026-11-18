/// The server's casebook answers (wt-rj services/casebook.py), for tests.
const sampleCasebook = <String, Object?>{
  'world': 'detective',
  'days': [
    {
      'date': '2026-11-18',
      'sessionBadges': <Object?>[],
      'cases': [
        {
          'problemId': 'lemon',
          'sessionId': 's3',
          'name': 'Tree Word Problem',
          'sticker': {
            'stickerId': 'sticker.lemon_tree',
            'object': 'lemon tree',
          },
          'solvedAt': 1795000000000,
        },
      ],
    },
    {
      'date': '2026-11-16',
      'sessionBadges': [
        {
          'badgeId': 'session.checked_it',
          'kind': 'session',
          'name': 'Checked it',
          'subtitle': 'Tree Word Problem',
        },
      ],
      'cases': [
        {
          'problemId': 'tree',
          'sessionId': 's2',
          'name': 'Tree Word Problem',
          'sticker': {'stickerId': 'sticker.fig_tree', 'object': 'fig tree'},
          'solvedAt': 1794800000000,
        },
        {
          'problemId': 'mango',
          'sessionId': 's2',
          'name': 'Mango Word Problem',
          'sticker': {
            'stickerId': 'sticker.mango_tree',
            'object': 'mango tree',
          },
          'solvedAt': 1794800100000,
        },
      ],
    },
  ],
};

const sampleCase = <String, Object?>{
  'problemId': 'lemon',
  'sessionId': 's3',
  'name': 'Tree Word Problem',
  'sticker': {'stickerId': 'sticker.lemon_tree', 'object': 'lemon tree'},
  'solvedAt': 1795000000000,
  'date': '2026-11-18',
  'drawing': {
    'barA': 18.6,
    'barB': 7.9,
    'pieces': [
      {'object': 'label_a', 'target': 'bar_a', 'value': 186},
      {'object': 'difference', 'target': 'gap', 'value': 107},
      {'object': 'total', 'target': 'across_both', 'value': 265},
    ],
  },
  'sessionBadge': {
    'badgeId': 'session.all_by_myself',
    'kind': 'session',
    'name': 'All by myself',
  },
  'badges': [
    {
      'badgeId': 'stop.orchard.l1',
      'kind': 'skill_mastered',
      'name': 'Seedling Path',
    },
  ],
};

/// [sampleCase] as the server sends it since REW-15's labels (wt-rj
/// 5b0de43): the sticker's subject, the bank story and the bar model.
final sampleLabelledCase = <String, Object?>{
  ...sampleCase,
  'sticker': {
    'stickerId': 'sticker.lemon_tree',
    'object': 'lemon tree',
    'subject': 'tree',
  },
  'story': {
    'storyId': 'lemon-fig',
    'a': 'lemon tree',
    'b': 'fig tree',
    'kind': 'tree',
    'unit': 'cm',
    'quantity': 'height',
  },
  'bars': {
    'relation': 'shorter',
    'unit': 'cm',
    'barA': {'label': 'lemon tree', 'value': 186, 'given': true},
    'barB': {'label': 'fig tree', 'value': 79, 'given': false},
    'gap': {'value': 107, 'given': true},
    'acrossBoth': {'value': 265, 'given': false},
  },
};

/// A generated story's case: no bank story, so bars with numbers only.
final sampleGeneratedCase = <String, Object?>{
  ...sampleCase,
  'name': null,
  'sticker': {
    'stickerId': 'sticker.red_kite',
    'object': 'red kite',
    'subject': 'story',
  },
  'story': null,
  'bars': {
    'relation': 'taller',
    'unit': null,
    'barA': {'label': null, 'value': 186, 'given': true},
    'barB': {'label': null, 'value': 79, 'given': false},
    'gap': {'value': 107, 'given': true},
    'acrossBoth': null,
  },
};

/// A case as the server answers it for a real lesson (taken from a device
/// run): A's number is the story's and B's the child typed, so the lesson
/// placed only the difference; `bars` carries both numbers.
const sampleCaseFromLesson = <String, Object?>{
  'problemId': 'g_ec1b71424eba40ed',
  'sessionId': '89533e8c-522d-4bc8-b9af-ca887e5be882',
  'name': 'Tree Word Problem',
  'sticker': {
    'stickerId': 'sticker.apple_tree',
    'object': 'apple tree',
    'subject': 'tree',
  },
  'solvedAt': 1794984590932,
  'story': {
    'storyId': 'apple-palm',
    'a': 'apple tree',
    'b': 'palm tree',
    'kind': 'tree',
    'unit': 'cm',
    'quantity': 'height',
  },
  'bars': {
    'relation': 'taller',
    'unit': 'cm',
    'barA': {'label': 'apple tree', 'value': 55, 'given': true},
    'barB': {'label': 'palm tree', 'value': 20, 'given': false},
    'gap': {'value': 35, 'given': true},
    'acrossBoth': null,
  },
  'date': '2026-11-18',
  'drawing': {
    'barA': 5.5,
    'barB': 2.0,
    'pieces': [
      {'object': 'difference', 'target': 'gap', 'value': 35},
    ],
  },
  'sessionBadge': {
    'badgeId': 'session.first_case',
    'kind': 'session',
    'name': 'First Case',
  },
  'badges': <Object?>[],
};
