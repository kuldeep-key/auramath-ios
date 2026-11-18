// The Orchard path (JRN-03, REW-04): one drawn country, a land per stop,
// each assembled from a kit of land families, variants, moods, ways in,
// landmarks and props, picked by the stop's number so it is always the
// same land. A faithful port of the prototype's generator (orchard.html,
// 16 Nov: `oland`, `omake`, `orchardGeom`, `orchardSVG`); it returns SVG
// markup that MiniSvg paints and animates. The names on the signs come
// from the server, never from here, and nothing here counts anything
// about the child (REW-03): one more stop, then fog.
// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, prefer_interpolation_to_compose_strings, avoid_dynamic_calls, unnecessary_string_interpolations, constant_identifier_names, prefer_function_declarations_over_variables
library;

import 'dart:math' as math;

part 'orchard_sprites.dart';

/// A sprite with its half width [w], height [h] (to keep things apart) and
/// whether it lies flat on the ground.
class OK {
  const OK(this.w, this.h, this.flat, this.f);
  final num w;
  final num h;
  final bool flat;
  final String Function([dynamic]) f;
}

/// JavaScript's truthiness, for the ported sprites.
bool t(Object? x) =>
    x != null && x != false && x != 0 && x != '' && !(x is double && x.isNaN);

int _u32(int x) => x & 0xFFFFFFFF;
int _imul(int a, int b) => _u32(_u32(a) * _u32(b));

/// The prototype's hash `oh(i, k)`: a stable number in [0, 1).
double oh(int i, int k) {
  var x = _u32(_imul(i + 1, 0x9E3779B1) ^ _imul(k + 7, 0x85EBCA6B));
  x ^= x >> 15;
  x = _imul(x, 0x2C1B3C6D);
  x ^= x >> 12;
  x = _imul(x, 0x297A2D39);
  x ^= x >> 15;
  return _u32(x) / 4294967296;
}

/// The prototype's seeded random `mkr(s)`.
double Function() mkr(int s) {
  var v = _imul(s + 11, 2654435761) % 2147483646 + 1;
  return () {
    v = v * 16807 % 2147483647;
    return v / 2147483647;
  };
}

int _jsRound(num x) => (x + 0.5).floor();

String osh(num x, num y, num rx, num ry) =>
    '<ellipse cx="$x" cy="$y" rx="$rx" ry="$ry" fill="rgba(20,70,40,0.22)"/>';

/// Puts a sprite on the map; `--d` staggers its sway.
String oat(num x, num y, num s, String inner, [String? cls]) =>
    '<g${cls != null ? ' class="$cls"' : ''} transform="translate(${x.toStringAsFixed(1)} ${y.toStringAsFixed(1)})${s != 1 ? ' scale(${s.toStringAsFixed(2)})' : ''}" style="--d:${(-(x.abs() % 7)).toStringAsFixed(1)}s">$inner</g>';

const Map<String, List<String>> OPAL = {
  'green': ['#3F9B57', '#57B866', '#8BD98A'],
  'deep': ['#2F8750', '#46A85F', '#7CCB7C'],
  'lemon': ['#4E9E4E', '#6CBF5E', '#A4E08A'],
  'fig': ['#3C8A63', '#55A878', '#86D0A0'],
  'gold': ['#8FAE3E', '#B5CC52', '#DDE88A'],
  'pink': ['#E07FA8', '#F29DC0', '#FFD0E0'],
  'white': ['#C9DDBE', '#E6F2DC', '#FFFFFF'],
  'amber': ['#C9652A', '#E58A3A', '#F7B655'],
  'red': ['#B8452F', '#D9603F', '#F08A5E'],
  'yellow': ['#C99A1E', '#E5B93A', '#F7DC7A'],
};

final Map<String, Map<String, dynamic>> OFAM = {
  'garden': {
    'nouns': ['Garden', 'Patch', 'Plot', 'Beds'],
    'g': '#B6E98F',
    'lip': '#7CC27A',
    'dk': '#1E7A46',
    'sc': [
      ['tuft', 5],
      ['fl:#fff', 3],
      ['fl:#FFF0A6', 2],
    ],
    'lay': {'t': 'beds'},
    'lm': ['glasshouse', 'well', 'cart', 'barn'],
    'pr': ['barrow', 'can', 'pots', 'pumpkins', 'crate', 'scare'],
    'ent': ['soft', 'fence', 'hedge'],
  },
  'nursery': {
    'nouns': ['Row', 'Nursery', 'Rows', 'Saplings'],
    'g': '#9FDDA3',
    'lip': '#5DB07A',
    'dk': '#1E7A46',
    'tex': 'stripes',
    'sc': [
      ['tuft', 5],
      ['fl:#fff', 4],
    ],
    'lay': {'t': 'curve'},
    'lm': ['well', 'glasshouse', 'cart'],
    'pr': ['crate', 'barrel', 'spade', 'bath', 'barrow', 'can'],
    'ent': ['soft', 'fence'],
  },
  'orchard': {
    'nouns': ['Orchard', 'Lane', 'Terrace', 'Walk', 'Gate'],
    'g': '#86CC72',
    'lip': '#4E9E4E',
    'dk': '#1E7A46',
    'sc': [
      ['tuft', 5],
      ['fl:#FFE873', 3],
      ['fl:#fff', 2],
    ],
    'lay': {'t': 'rows', 'dx': 50, 'dy': 44},
    'lm': ['cart', 'well', 'barn', 'cottage', 'gazebo'],
    'pr': ['basket', 'hive', 'picnic', 'basket', 'crate', 'lantern'],
    'ent': ['wall', 'wall', 'hedge', 'fence'],
    'vars': [
      {
        'w': 'Lemon',
        'a': ['round', 'lemon', '#FFD84A'],
        'b': ['round', 'fig', '#8E6BC9'],
        'fruit': '#FFD84A',
      },
      {
        'w': 'Apple',
        'a': ['round', 'green', '#F0643C'],
        'fruit': '#F0643C',
      },
      {
        'w': 'Cherry',
        'a': ['round', 'deep', '#D9562B'],
        'fruit': '#D9562B',
      },
      {
        'w': 'Plum',
        'a': ['round', 'fig', '#7B4FC9'],
        'fruit': '#7B4FC9',
      },
      {
        'w': 'Pear',
        'a': ['round', 'lemon', '#C9D94A'],
        'fruit': '#C9D94A',
      },
      {
        'w': 'Orange',
        'a': ['round', 'deep', '#F7941D'],
        'fruit': '#F7941D',
      },
      {
        'w': 'Peach',
        'a': ['round', 'green', '#FFA98A'],
        'fruit': '#FFA98A',
      },
    ],
  },
  'wood': {
    'nouns': ['Wood', 'Pines', 'Hollow', 'Firs'],
    'g': '#79C79C',
    'lip': '#3E8F6C',
    'dk': '#14664A',
    'sc': [
      ['tuft', 5],
      ['mush', 1.4],
      ['peb', 1.2],
      ['fern', 2],
      ['fl:#BFD9FF', 1.5],
    ],
    'lay': {
      't': 'wood',
      'n': 64,
      'it': [
        [
          0.72,
          ['fir'],
        ],
        [
          0.28,
          ['round', 'deep'],
        ],
      ],
    },
    'lm': ['cabin', 'camp', 'treehouse'],
    'pr': ['log', 'toad', 'stump', 'lantern', 'crate'],
    'ent': ['stream', 'soft', 'fence'],
  },
  'hill': {
    'nouns': ['Hill', 'Top', 'Rise', 'Lookout'],
    'g': '#DCD67C',
    'lip': '#A9A64E',
    'dk': '#9C8F2E',
    'tex': 'wind',
    'sc': [
      ['wheat', 5],
      ['lav', 2],
      ['tuft', 3],
    ],
    'lay': {
      't': 'wood',
      'n': 14,
      'it': [
        [
          0.55,
          ['round', 'gold'],
        ],
        [
          0.45,
          ['rock'],
        ],
      ],
    },
    'lm': ['twisty', 'windmill', 'balloon', 'ring'],
    'pr': ['scope', 'menhirs', 'kite', 'hay', 'bath'],
    'ent': ['soft', 'fence'],
  },
  'blossom': {
    'nouns': ['Grove', 'Walk', 'Blossoms', 'Arbour'],
    'g': '#BFE8A6',
    'lip': '#7FBF80',
    'dk': '#2E8A55',
    'sc': [
      ['tuft', 4],
      ['petal', 5],
      ['fl:#FFD0E0', 3],
    ],
    'lay': {'t': 'rows', 'dx': 56, 'dy': 50},
    'lm': ['gazebo', 'fountain', 'well', 'bigwillow'],
    'pr': ['lantern', 'picnic', 'bath', 'basket', 'lantern'],
    'air': 'petal',
    'vars': [
      {
        'w': 'Blossom',
        'a': ['round', 'pink', '#fff'],
      },
      {
        'w': 'Petal',
        'a': ['round', 'pink', '#fff'],
        'b': ['round', 'white', '#FFD0E0'],
      },
      {
        'w': 'Almond',
        'a': ['round', 'white', '#FFD0E0'],
      },
    ],
  },
  'vineyard': {
    'nouns': ['Vineyard', 'Vines', 'Slope', 'Terrace'],
    'g': '#C9DE8A',
    'lip': '#96B55A',
    'dk': '#6E8F2E',
    'tex': 'furrow',
    'sc': [
      ['tuft', 5],
      ['fl:#fff', 2],
      ['peb', 1],
    ],
    'lay': {
      't': 'field',
      'dx': 36,
      'dy': 38,
      'it': ['vine'],
      'edge': ['cypress'],
    },
    'lm': ['cottage', 'cart', 'well', 'barn'],
    'pr': ['barrel', 'basket', 'crate', 'barrel', 'lantern'],
    'vars': [
      {'w': 'Grape', 'fruit': '#7B4FC9'},
      {'w': 'Muscat', 'fruit': '#B8D94A'},
    ],
  },
  'meadow': {
    'nouns': ['Meadow', 'Field', 'Green', 'Common'],
    'g': '#A8E68A',
    'lip': '#6FC070',
    'dk': '#1E7A46',
    'sc': [
      ['fl:#fff', 4],
      ['fl:#FFE873', 4],
      ['fl:#FFB3D1', 3],
      ['fl:#BFD9FF', 3],
      ['tuft', 4],
      ['bell', 2],
    ],
    'lay': {
      't': 'open',
      'n': 12,
      'it': [
        ['round', 'green'],
        ['bush', 'green'],
      ],
    },
    'lm': ['windmill', 'balloon', 'barn', 'well'],
    'pr': ['hive', 'picnic', 'bath', 'hay', 'kite', 'hive'],
  },
  'pond': {
    'nouns': ['Pond', 'Pool', 'Water', 'Shallows'],
    'g': '#8FD6A8',
    'lip': '#4FA57C',
    'dk': '#14664A',
    'sc': [
      ['tuft', 5],
      ['reed', 3],
      ['fl:#fff', 2],
      ['peb', 1.5],
      ['bell', 1.5],
    ],
    'lay': {
      't': 'open',
      'n': 12,
      'it': [
        ['willow'],
        ['bush', 'deep'],
        ['willow'],
      ],
    },
    'lm': ['pond'],
    'pr': ['log', 'lantern', 'bath', 'picnic', 'stump'],
    'ent': ['soft', 'hedge', 'fence'],
  },
  'birch': {
    'nouns': ['Birches', 'Copse', 'Glen', 'Dell'],
    'g': '#B9E4A0',
    'lip': '#7DBB7A',
    'dk': '#2E8A55',
    'sc': [
      ['tuft', 5],
      ['fern', 3],
      ['fl:#fff', 2],
      ['mush', 1],
    ],
    'lay': {
      't': 'wood',
      'n': 50,
      'it': [
        [
          0.85,
          ['birch'],
        ],
        [
          0.15,
          ['bush', 'green'],
        ],
      ],
    },
    'lm': ['camp', 'cabin', 'well', 'treehouse'],
    'pr': ['log', 'stump', 'toad', 'lantern', 'picnic'],
    'vars': [
      {'w': 'Birch', 'pal': 'green'},
      {'w': 'Silver', 'pal': 'yellow'},
    ],
  },
  'autumn': {
    'nouns': ['Maples', 'Harvest', 'Hollow', 'Lane'],
    'g': '#E3D58A',
    'lip': '#B8A552',
    'dk': '#A07A1E',
    'sc': [
      ['leaf:#E58A3A', 4],
      ['leaf:#D9603F', 3],
      ['leaf:#E5B93A', 3],
      ['tuft', 3],
      ['mush', 1.5],
    ],
    'lay': {
      't': 'wood',
      'n': 38,
      'it': [
        [
          0.4,
          ['round', 'amber'],
        ],
        [
          0.3,
          ['round', 'red'],
        ],
        [
          0.3,
          ['round', 'yellow'],
        ],
      ],
    },
    'lm': ['barn', 'cottage', 'cart', 'treehouse'],
    'pr': ['hay', 'pumpkins', 'scare', 'basket', 'log', 'pumpkins'],
    'air': 'leaf',
    'adj': ['Amber', 'Russet', 'Copper', 'Crunchy', 'Golden'],
    'moods': ['day', 'day', 'evening', 'mist'],
  },
  'snow': {
    'nouns': ['Pines', 'Drift', 'Frost', 'Hollow'],
    'g': '#EEF6FC',
    'lip': '#B9D3E6',
    'dk': '#7FA7C9',
    'tex': 'snow',
    'sc': [
      ['snowl', 5],
      ['peb', 1],
      ['tuftw', 3],
    ],
    'lay': {
      't': 'wood',
      'n': 46,
      'it': [
        [
          0.8,
          ['fir', 1],
        ],
        [
          0.2,
          ['rock', 1],
        ],
      ],
    },
    'lm': ['igloo', 'cabin', 'camp'],
    'pr': ['snowman', 'sled', 'lantern', 'log', 'snowman'],
    'air': 'snow',
    'adj': ['Snowy', 'Frosty', 'Wintry', 'Icy', 'Hushed'],
    'ent': ['stream', 'soft', 'fence'],
    'moods': ['day', 'mist', 'dusk'],
    'bf': ['#fff', '#DDEEFA'],
  },
  'sunflower': {
    'nouns': ['Field', 'Acre', 'Rows', 'Corner'],
    'g': '#C6E58A',
    'lip': '#8FBF5A',
    'dk': '#4E8F2E',
    'tex': 'furrow',
    'sc': [
      ['tuft', 5],
      ['fl:#fff', 2],
    ],
    'lay': {
      't': 'field',
      'dx': 26,
      'dy': 42,
      'it': ['sunflower'],
      'edge': [
        ['round', 'green'],
      ],
    },
    'lm': ['scarebarn', 'windmill', 'cottage', 'barn'],
    'pr': ['scare', 'hay', 'barrow', 'can', 'hive'],
    'adj': ['Sunflower', 'Sunny', 'Golden', 'Bright', 'Tall'],
  },
  'lavender': {
    'nouns': ['Fields', 'Rows', 'Slope', 'Lane'],
    'g': '#CFE3A0',
    'lip': '#9DBB6A',
    'dk': '#6E8F2E',
    'tex': 'furrow',
    'sc': [
      ['tuft', 4],
      ['fl:#fff', 2],
      ['peb', 1],
    ],
    'lay': {
      't': 'field',
      'dx': 27,
      'dy': 30,
      'it': ['lav'],
      'edge': ['cypress'],
    },
    'lm': ['cottage', 'well', 'windmill', 'fountain'],
    'pr': ['hive', 'basket', 'bath', 'hive', 'lantern'],
    'adj': ['Lavender', 'Violet', 'Humming', 'Purple', 'Sweet'],
  },
  'mushroom': {
    'nouns': ['Glade', 'Nook', 'Hollow', 'Ring'],
    'g': '#7CC59A',
    'lip': '#3E8F6C',
    'dk': '#14664A',
    'sc': [
      ['mush', 3],
      ['fern', 4],
      ['tuft', 4],
      ['bell', 3],
    ],
    'lay': {
      't': 'wood',
      'n': 34,
      'it': [
        [
          0.45,
          ['gmush', '#F0643C'],
        ],
        [
          0.2,
          ['gmush', '#9B7FE0'],
        ],
        [
          0.35,
          ['fir'],
        ],
      ],
    },
    'lm': ['treehouse', 'camp', 'cabin'],
    'pr': ['toad', 'lantern', 'stump', 'log', 'toad'],
    'air': 'fire',
    'adj': ['Toadstool', 'Firefly', 'Mossy', 'Secret', 'Glowing'],
    'moods': ['dusk', 'dusk', 'mist'],
  },
  'bamboo': {
    'nouns': ['Thicket', 'Grove', 'Garden', 'Stems'],
    'g': '#A6E0A0',
    'lip': '#62B070',
    'dk': '#1E7A46',
    'sc': [
      ['tuft', 4],
      ['peb', 3],
      ['fern', 3],
      ['fl:#fff', 2],
    ],
    'lay': {
      't': 'wood',
      'n': 50,
      'it': [
        [
          0.82,
          ['bamboo'],
        ],
        [
          0.18,
          ['rock'],
        ],
      ],
    },
    'lm': ['gazebo', 'fountain', 'pond'],
    'pr': ['lantern', 'bath', 'lantern', 'stump', 'picnic'],
    'adj': ['Bamboo', 'Rustling', 'Green', 'Whispering', 'Quiet'],
  },
  'crag': {
    'nouns': ['Crag', 'Rocks', 'Ridge', 'Tor'],
    'g': '#BFD9A0',
    'lip': '#8FAE72',
    'dk': '#5E7F4A',
    'tex': 'wind',
    'sc': [
      ['lav', 3],
      ['peb', 4],
      ['tuft', 4],
      ['fl:#fff', 1.5],
    ],
    'lay': {
      't': 'wood',
      'n': 30,
      'it': [
        [
          0.5,
          ['rock'],
        ],
        [
          0.25,
          ['fir'],
        ],
        [
          0.25,
          ['cypress'],
        ],
      ],
    },
    'lm': ['ring', 'balloon', 'camp', 'windmill'],
    'pr': ['menhirs', 'scope', 'kite', 'log', 'lantern'],
    'adj': ['Windy', 'Stony', 'High', 'Heather', 'Eagle'],
  },
  'berry': {
    'nouns': ['Patch', 'Brambles', 'Bushes', 'Tangle'],
    'g': '#A9E090',
    'lip': '#6CB870',
    'dk': '#1E7A46',
    'sc': [
      ['tuft', 5],
      ['fl:#fff', 3],
      ['fl:#FFB3D1', 2],
    ],
    'lay': {
      't': 'field',
      'dx': 42,
      'dy': 42,
      'it': ['berry'],
      'edge': [
        ['round', 'green'],
      ],
    },
    'lm': ['cart', 'cottage', 'well', 'barn'],
    'pr': ['basket', 'crate', 'picnic', 'basket', 'hive'],
    'vars': [
      {'w': 'Berry', 'fruit': '#D9562B'},
      {'w': 'Bramble', 'fruit': '#5B3FA8'},
      {'w': 'Bilberry', 'fruit': '#3F5BD9'},
    ],
  },
};

/// One land's kit picks.
class OLand {
  OLand({
    required this.fam,
    required this.v,
    required this.mood,
    required this.ent,
    required this.lm,
    required this.pr,
    this.bank,
  });
  final String fam;
  final Map<String, dynamic> v;
  final String mood;
  final String ent;
  final String lm;
  final List<String> pr;
  final String? bank;
}

final List<OLand> _olands = [];

/// The land at stop [i]: always the same for the same number.
OLand oland(int i) {
  while (_olands.length <= i) {
    _olands.add(omake(_olands.length));
  }
  return _olands[i];
}

OLand omake(int j) {
  if (j < 5) {
    return switch (j) {
      0 => OLand(
        fam: 'garden',
        v: const {},
        mood: 'day',
        ent: 'none',
        lm: 'glasshouse',
        pr: const ['barrow', 'can', 'pots', 'pumpkins'],
      ),
      1 => OLand(
        fam: 'nursery',
        v: const {},
        mood: 'day',
        ent: 'soft',
        lm: 'well',
        pr: const ['crate', 'barrel', 'spade', 'bath'],
      ),
      2 => OLand(
        fam: 'orchard',
        v: (OFAM['orchard']!['vars'] as List)[0] as Map<String, dynamic>,
        mood: 'day',
        ent: 'wall',
        lm: 'cart',
        pr: const ['basket', 'hive', 'picnic', 'basket'],
      ),
      3 => OLand(
        fam: 'wood',
        v: const {},
        mood: 'day',
        ent: 'stream',
        bank: 'oak',
        lm: 'cabin',
        pr: const ['log', 'toad', 'stump', 'lantern'],
      ),
      _ => OLand(
        fam: 'hill',
        v: const {},
        mood: 'day',
        ent: 'soft',
        lm: 'twisty',
        pr: const ['scope', 'menhirs', 'kite', 'hay'],
      ),
    };
  }
  final keys = OFAM.keys.toList();
  final recent = _olands.sublist(math.max(0, _olands.length - 7));
  T pick<T>(List a, int k) => a[(oh(j, k) * a.length).floor()] as T;
  String fam;
  var t = 0;
  do {
    fam = pick<String>(keys, 11 + t);
    t++;
  } while (recent.any((l) => l.fam == fam) && t < 60);
  final F = OFAM[fam]!;
  final v = F['vars'] != null
      ? pick<Map<String, dynamic>>(F['vars'] as List, 3)
      : <String, dynamic>{};
  final mood = pick<String>(
    (F['moods'] as List?) ??
        const ['day', 'day', 'day', 'evening', 'mist', 'dusk'],
    5,
  );
  var ent = pick<String>(
    (F['ent'] as List?) ??
        const ['soft', 'soft', 'hedge', 'fence', 'wall', 'stream', 'stream'],
    9,
  );
  if (ent == 'stream' && _olands[j - 1].ent == 'stream') ent = 'soft';
  String lm;
  t = 0;
  final recent5 = recent.sublist(math.max(0, recent.length - 5));
  do {
    lm = pick<String>(F['lm'] as List, 13 + t);
    t++;
  } while (recent5.any((l) => l.lm == lm) && t < 12);
  final prs = F['pr'] as List;
  final p0 = (oh(j, 17) * prs.length).floor();
  final pr = [for (var k = 0; k < 4; k++) prs[(p0 + k) % prs.length] as String];
  return OLand(
    fam: fam,
    v: v,
    mood: mood,
    ent: ent,
    lm: lm,
    pr: pr,
    bank: ent == 'stream'
        ? pick<String>(const ['oak', 'willow', 'none', 'willow'], 31)
        : null,
  );
}

/// The map's measures: width, a stop's height, the room below the first
/// stop and above the last.
const double opW = 390, opSTEP = 380, opBOT = 190, opTOP = 340;

double olandX(int i) => i < 5
    ? const [128.0, 266.0, 116.0, 272.0, 128.0][i]
    : (i.isOdd ? 264 : 124) + _jsRound((oh(i, 1) - 0.5) * 22).toDouble();

typedef Pt = List<double>;
typedef Seg = List<Pt>;

Pt bez(Seg s, double t) {
  final u = 1 - t;
  return [
    u * u * u * s[0][0] +
        3 * u * u * t * s[1][0] +
        3 * u * t * t * s[2][0] +
        t * t * t * s[3][0],
    u * u * u * s[0][1] +
        3 * u * u * t * s[1][1] +
        3 * u * t * t * s[2][1] +
        t * t * t * s[3][1],
  ];
}

/// The path from stop [lo] to stop [hi] and on into the fog ([open]), or
/// ending at stop [hi] (the top, section 15).
class OGeom {
  OGeom(int lo, int hi, {bool open = true}) {
    final n = hi - lo + 1;
    H = opBOT + (n - 1) * opSTEP + opTOP;
    for (var j = 0; j < n; j++) {
      P.add([olandX(lo + j), H - opBOT - j * opSTEP]);
    }
    for (var i = 1; i < n; i++) {
      final a = P[i - 1], b = P[i];
      segs.add([
        a,
        [a[0], a[1] - opSTEP * .52],
        [b[0], b[1] + opSTEP * .52],
        b,
      ]);
    }
    final l = P[n - 1], ex = l[0] > 195 ? 120.0 : 270.0;
    tail = [
      l,
      [l[0], l[1] - 150],
      [ex, l[1] - 170],
      [ex, l[1] - 320],
    ];
    String f(Pt p) => '${p[0].toStringAsFixed(1)} ${p[1].toStringAsFixed(1)}';
    final b = StringBuffer('M${_n(P[0][0])} ${_n(H + 30)} L${f(P[0])}');
    for (final s in [...segs, if (open) tail]) {
      b.write(' C${f(s[1])} ${f(s[2])} ${f(s[3])}');
    }
    d = b.toString();
    for (var y = H + 30; y > P[0][1]; y -= 12) {
      pts.add([P[0][0], y]);
    }
    for (final s in [...segs, if (open) tail]) {
      for (double t = 0; t <= 1; t += .04) {
        pts.add(bez(s, t));
      }
    }
  }

  late final double H;
  final List<Pt> P = [];
  final List<Seg> segs = [];
  late final Seg tail;
  late final String d;
  final List<Pt> pts = [];
}

/// A number as JavaScript prints it: no ".0" on whole numbers.
String _n(num x) =>
    x == x.roundToDouble() ? x.toInt().toString() : x.toString();

/// What the signs say (the app's approved words, not the prototype's).
class OrchardWords {
  const OrchardWords({
    required this.explored,
    required this.here,
    required this.next,
    required this.lookBack,
  });
  final String explored;
  final String here;
  final String next;
  final String lookBack;
}

/// A stop on the drawn stretch: its name and state (`earned`, `explored`,
/// `here` or `next`; inside a level's land (Figma section 15, 17 Nov)
/// also `walked`, `ahead`, `peak`, `peakEarned` and `peakExplored`). An
/// empty [name] has no sign; [sub] replaces the sign's second line.
class OrchardStop {
  const OrchardStop(this.name, this.state, {this.sub});
  final String name;
  final String state;
  final String? sub;
}

/// Figma section 15 (17 Nov): one level is one land of [stopsPerLand]
/// stops, the last its peak. Stop [g] of the whole path is stop
/// `g % stopsPerLand` of level `g ~/ stopsPerLand`'s land.
const stopsPerLand = 5;

/// The land under stop [g] when every level is one land: the level's own
/// land (its way in, colours and light) at its first stop, and for the
/// stops after it the same land, open ground between them, each with
/// another of the land's landmarks and props.
OLand olandInLevel(int g) {
  final level = g ~/ stopsPerLand, k = g % stopsPerLand;
  final base = oland(level);
  if (k == 0) return base;
  final lms = (OFAM[base.fam]!['lm'] as List?)?.cast<String>() ?? [base.lm];
  final at = math.max(0, lms.indexOf(base.lm));
  final prs = (OFAM[base.fam]!['pr'] as List?)?.cast<String>() ?? base.pr;
  return OLand(
    fam: base.fam,
    v: base.v,
    mood: base.mood,
    ent: 'soft',
    lm: lms[(at + k) % lms.length],
    pr: [for (var p = 0; p < 4; p++) prs[(k * 2 + p) % prs.length]],
  );
}

/// Whether a way in lies below stop [g]: only where a new level's land
/// starts.
bool wayInBelow(int g) => g % stopsPerLand == 0;

/// The drawn stretch: SVG markup plus what the screen needs to put the
/// walker on the path, scroll to the child's stop and hear a tapped stop.
class OrchardScene {
  OrchardScene._(this.svg, this.geom, this.lo, this.here);
  final String svg;
  final OGeom geom;
  final int lo;
  final int here;
  double get width => opW;
  double get height => geom.H;
}

String _esc(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

/// The prototype's `orchardSVG()`. [stops] are the stops [lo] to
/// [lo] + stops.length - 1, the child at [here]; [bloom] (0 to 3) is how
/// far the child's land has bloomed.
///
/// [landAt] gives the land under each stop (one land a stop by default);
/// [wayIn] says where one land ends and the next starts below a stop (at
/// every stop by default). With [top] the path ends under open sky: no
/// fog and nothing promised after the last stop (section 15, the end of
/// v1).
OrchardScene orchardSVG({
  required int lo,
  required int here,
  required List<OrchardStop> stops,
  required int bloom,
  required OrchardWords words,
  OLand Function(int i) landAt = oland,
  bool Function(int i)? wayIn,
  bool top = false,
}) {
  bool border(int i) => wayIn?.call(i) ?? true;
  final hi = lo + stops.length - 1;
  final G = OGeom(lo, hi, open: !top);
  const W = opW;
  final H = G.H, P = G.P;
  const HS = opSTEP / 2;
  final L = <int, OLand>{};
  for (var i = lo; i <= hi + 1; i++) {
    L[i] = landAt(i);
  }
  String nameOf(int i) => stops[i - lo].name;
  double Y(int i) => H - opBOT - (i - lo) * opSTEP;
  bool clear(num x, num y, num r) => G.pts.every(
    (p) => (p[0] - x) * (p[0] - x) + (p[1] - y) * (p[1] - y) > r * r,
  );
  ({double x, double y, double w, double h, bool left}) signBox(int j) {
    final x = P[j][0],
        y = P[j][1],
        w = nameOf(lo + j).length * 10.2 + 34,
        left = x > 195;
    return (x: left ? x - 62 - w : x + 62, y: y - 34, w: w, h: 58, left: left);
  }

  bool offSigns(num x, num y, num m) {
    for (var j = 0; j < P.length; j++) {
      if (nameOf(lo + j).isEmpty) continue;
      final b = signBox(j);
      if (!(x < b.x - m ||
          x > b.x + b.w + m ||
          y < b.y - m ||
          y > b.y + b.h + m)) {
        return false;
      }
    }
    return true;
  }

  bool free(num x, num y, num r) =>
      clear(x, y, r + 30) &&
      offSigns(x, y, r) &&
      P.every(
        (p) =>
            (p[0] - x) * (p[0] - x) + (p[1] - y) * (p[1] - y) >
            (r + 58) * (r + 58),
      );
  bool box(num x, num y, num w, num h) {
    if (!clear(x, y, w + 28)) return false;
    for (var j = 0; j < P.length; j++) {
      final p = P[j], b = signBox(j);
      final hitS =
          !(x + w < b.x - 6 ||
              x - w > b.x + b.w + 6 ||
              y + 6 < b.y - 4 ||
              y - h > b.y + b.h + 20);
      final hitP =
          !(x + w < p[0] - 58 ||
              x - w > p[0] + 58 ||
              y + 6 < p[1] - 96 ||
              y - h > p[1] + 44);
      if (hitS || hitP) return false;
    }
    return true;
  }

  final o = <String>[], tints = <String>[];
  final late = <(double, String)>[];
  void stand(num y, String s) => late.add((y.toDouble(), s));

  // --- borders between lands, and where the path crosses each one
  final BF = <int, double Function(num)>{};
  final CR = <int, ({double x, double y, double a})>{};
  for (var i = lo + 1; i <= hi; i++) {
    final by = Y(i) + HS,
        e = L[i]!.ent,
        ph = oh(i, 21) * 6,
        tl = (oh(i, 22) - .5) * .2;
    BF[i] = e == 'stream'
        ? (x) => by + 20 * math.sin((x - 195) / 64 + ph) + (x - 195) * tl
        : e == 'soft'
        ? (x) => by + 10 * math.sin(x / 50 + ph)
        : (x) => by;
    final s = G.segs[i - lo - 1];
    var bt = .5, bd = 1e9;
    for (double t = 0; t <= 1; t += .004) {
      final p = bez(s, t), d = (p[1] - BF[i]!(p[0])).abs();
      if (d < bd) {
        bd = d;
        bt = t;
      }
    }
    final p = bez(s, bt), q = bez(s, math.min(1, bt + .01));
    CR[i] = (
      x: p[0],
      y: p[1],
      a: math.atan2(q[0] - p[0], p[1] - q[1]) * 180 / math.pi,
    );
  }
  int zoneOf(num x, num y) {
    for (var i = lo + 1; i <= hi; i++) {
      if (y > BF[i]!(x)) return i - 1;
    }
    return hi;
  }

  final streams = <int>[], walls = <int>[];
  for (var i = lo + 1; i <= hi; i++) {
    if (L[i]!.ent == 'stream') {
      streams.add(i);
    } else if (L[i]!.ent != 'soft') {
      walls.add(i);
    }
  }
  bool wetG(num x, num y, num r) =>
      streams.any((i) => (y - BF[i]!(x)).abs() < 40 + r);
  bool wetS(num x, num y, num h) => streams.any((i) {
    final c = BF[i]!(x);
    return (y > c - 46 && y - h < c + 30) ||
        ((x - CR[i]!.x) * (x - CR[i]!.x) +
                (y - h * .4 - CR[i]!.y) * (y - h * .4 - CR[i]!.y) <
            86 * 86);
  });
  bool atWall(num x, num y, num w, num h) => walls.any((i) {
    final by = BF[i]!(0);
    return (y > by - 32 && y < by + 12) ||
        ((x - CR[i]!.x).abs() < 58 + w && y > by - 74 && y - h < by + 6);
  });
  final placed = <({double x, double y, double w, double h})>[];
  bool place(num x, num y, num w, num h, [bool loose = false]) {
    if (x < w * .45 || x > W - w * .45 || y - h < 4 || y > H - 34) return false;
    if (!box(x, y, w, h) || wetS(x, y, h) || atWall(x, y, w, h)) return false;
    for (final p in placed) {
      if ((p.x - x).abs() < (p.w + w) * (loose ? .62 : .84) &&
          (p.y - y).abs() < math.max(16, (p.h + h) * .24)) {
        return false;
      }
    }
    placed.add((
      x: x.toDouble(),
      y: y.toDouble(),
      w: w.toDouble(),
      h: h.toDouble(),
    ));
    return true;
  }

  // --- ground: each land its own colour, edged by its border
  String zoneShape(double Function(num) fn, String c, String lip) {
    final e = StringBuffer();
    for (var x = W; x >= 0; x -= 15) {
      e.write(' L$x ${fn(x).toStringAsFixed(1)}');
    }
    return '<path d="M0 0 H$W V${fn(W).toStringAsFixed(1)}$e Z" fill="$c"/><path d="M$W ${fn(W).toStringAsFixed(1)}$e" fill="none" stroke="$lip" stroke-width="7" opacity="0.35" transform="translate(0 4)"/>';
  }

  for (var i = lo + 1; i <= hi; i++) {
    // the same land on both sides: no edge
    if (!border(i)) continue;
    o.add(
      zoneShape(
        BF[i]!,
        OFAM[L[i]!.fam]!['g'] as String,
        OFAM[L[i]!.fam]!['lip'] as String,
      ),
    );
  }

  // --- ways in. Bank trees and landmarks are registered first so nothing
  // else is planted on them
  ({OK M, double k, double x, double y, double w, double h}) lmSpot(int i) {
    final M = OLM[L[i]!.lm]!,
        sx = P[i - lo][0],
        y0 = P[i - lo][1],
        left = sx > 195,
        low = L[i + 1] != null && L[i + 1]!.ent == 'stream';
    final k = math
            .min(1.5, math.min((low ? 106 : 118) / M.h, 56 / M.w))
            .toDouble(),
        hw = M.w * k;
    return (
      M: M,
      k: k,
      x: left ? hw + 6 : W - hw - 6,
      y: low ? y0 + 152 : y0 - 62,
      w: hw,
      h: M.h * k,
    );
  }

  final LS =
      <int, ({OK M, double k, double x, double y, double w, double h})>{};
  for (var i = lo; i <= hi; i++) {
    final s = lmSpot(i);
    LS[i] = s;
    placed.add((x: s.x, y: s.y, w: s.w, h: s.h));
  }
  final BK = <int, ({double x, double y, bool big, bool flip})>{};
  for (final i in streams) {
    if (L[i]!.bank != null && L[i]!.bank != 'none') {
      final c = CR[i]!;
      final x = c.a > 0
              ? math.max(66.0, c.x - 140)
              : math.min(W - 66, c.x + 140),
          y = BF[i]!(x) + 64,
          big = L[i]!.bank == 'oak';
      if (!placed.any(
        (p) => (p.x - x).abs() < p.w + 50 && (p.y - y).abs() < 110,
      )) {
        BK[i] = (x: x, y: y, big: big, flip: c.a <= 0);
        placed.add((x: x, y: y, w: big ? 56 : 44, h: big ? 136 : 110));
      }
    }
  }

  void drawLand(int i) {
    final D = L[i]!,
        F = OFAM[D.fam]!,
        v = D.v,
        sx = P[i - lo][0],
        y0 = P[i - lo][1],
        top = y0 - HS,
        left = sx > 195;
    final b = i < here
            ? 3
            : i == here
            ? bloom
            : 0,
        cur = i == here,
        snow = D.fam == 'snow';
    double fx(double t) =>
        left ? W * t : W * (1 - t); // fx(small) is the sign's side of the land
    double mx(num x) => left ? W - x : x.toDouble();
    String tag(int t, String s) =>
        cur && t > 0 ? '<g class="bl bl$t">$s</g>' : s;
    final rs = mkr(i * 31 + 5), rt = mkr(i * 31 + 9), rp = mkr(i * 31 + 17);
    final String? fruit =
        (v['fruit'] as String?) ??
        (v['a'] != null ? (v['a'] as List)[2] as String : null);
    final dk = F['dk'] as String;
    // texture
    for (var k = 0; k < 12; k++) {
      final x = rt() * W, y = top + rt() * opSTEP, rx = 26 + rt() * 40;
      if (wetG(x, y, rx * .4) || zoneOf(x, y) != i) continue;
      o.add(
        '<ellipse cx="${x.toStringAsFixed(0)}" cy="${y.toStringAsFixed(0)}" rx="${rx.toStringAsFixed(0)}" ry="${(rx * .42).toStringAsFixed(0)}" fill="${k.isOdd ? '#fff' : dk}" opacity="${k.isOdd ? .14 : .08}"/>',
      );
    }
    final tex = F['tex'];
    final lay = F['lay'] as Map<String, dynamic>;
    if (tex == 'stripes') {
      for (var y = y0 + HS - 40; y > top + 40; y -= 46) {
        o.add(
          '<path d="M-20 ${y.toStringAsFixed(0)} q${W / 2} -26 ${W + 40} 0" fill="none" stroke="#fff" stroke-width="20" opacity="0.1"/>',
        );
      }
    }
    if (tex == 'furrow') {
      for (var y = y0 + HS - 34; y > top + 30; y -= (lay['dy'] as num)) {
        o.add(
          '<path d="M-20 ${(y + 6).toStringAsFixed(0)} q${W / 4} -14 ${W / 2 + 20} 0 t${W / 2 + 20} 0" fill="none" stroke="$dk" stroke-width="12" opacity="0.12" stroke-linecap="round"/>',
        );
      }
    }
    if (tex == 'wind') {
      for (var k = 0; k < 12; k++) {
        final x = 20 + rt() * (W - 40), y = top + 30 + rt() * (opSTEP - 60);
        if (zoneOf(x, y) == i && free(x, y, 20)) {
          o.add(
            '<path d="M${x.toStringAsFixed(0)} ${y.toStringAsFixed(0)} q14 -7 28 0 q8 4 16 0" fill="none" stroke="#fff" stroke-width="2.2" stroke-linecap="round" opacity="0.5"/>',
          );
        }
      }
    }
    if (tex == 'snow') {
      for (var k = 0; k < 16; k++) {
        final x = 10 + rt() * (W - 20), y = top + rt() * opSTEP;
        if (zoneOf(x, y) == i) {
          o.add(
            '<path class="twinkle" style="animation-delay:${-(k % 5) * .6}s" d="M${x.toStringAsFixed(0)} ${y.toStringAsFixed(0)} l1.4 3.6 3.6 1.4 -3.6 1.4 -1.4 3.6 -1.4 -3.6 -3.6 -1.4 3.6 -1.4 z" fill="#fff"/>',
          );
        }
      }
    }
    // small ground pieces; the land grows more of them with every solved case
    final sc = F['sc'] as List;
    final tw = sc.fold<num>(0, (a, c) => a + ((c as List)[1] as num));
    final bf =
        (F['bf'] as List?)?.cast<String>() ??
        const ['#fff', '#FFE873', '#FFB3D1', '#BFD9FF'];
    for (var k = 0; k < 66; k++) {
      final x = 8 + rs() * (W - 16), y = top + rs() * opSTEP, r = rs();
      if (k >= 36 + 10 * b) continue;
      if (!free(x, y, 8) || wetG(x, y, 6) || zoneOf(x, y) != i) continue;
      var code = (sc[0] as List)[0] as String;
      if (k < 36) {
        num a = r * tw;
        for (final c in sc) {
          a -= (c as List)[1] as num;
          if (a <= 0) {
            code = c[0] as String;
            break;
          }
        }
      } else {
        code = 'fl:${bf[k % bf.length]}';
      }
      final parts = code.split(':');
      final nm = parts[0], arg = parts.length > 1 ? parts[1] : null;
      final gx = double.parse(x.toStringAsFixed(0)),
          gy = double.parse(y.toStringAsFixed(0));
      o.add(
        tag(k < 36 ? 0 : 1 + ((k - 36) / 10).floor(), _og(nm, gx, gy, arg)),
      );
    }
    // the way in
    if (i > lo && border(i)) {
      final c = CR[i]!, by = BF[i]!(0), e = D.ent;
      if (e == 'wall') {
        final wall = StringBuffer();
        for (var r = 0; r < 2; r++) {
          for (var x = -10 + (r > 0 ? 14 : 0); x < W + 10; x += 30) {
            if ((x + 14 - c.x).abs() < 50) continue;
            wall.write(
              '<rect x="$x" y="${by - 22 + r * 14}" width="28" height="13" rx="5" fill="${const ['#CBD2DD', '#B9C1CE', '#D8DEE8'][((x / 30) + r).truncate() % 3]}" stroke="#9AA4B5" stroke-width="1"/>',
            );
          }
        }
        stand(
          by,
          '<g>$wall<g transform="translate(${c.x.toStringAsFixed(1)} $by)"><rect x="-44" y="-58" width="12" height="62" rx="4" fill="#8A5A34"/><rect x="32" y="-58" width="12" height="62" rx="4" fill="#8A5A34"/><path d="M-46 -52 q46 -40 92 0 v10 q-46 -38 -92 0 z" fill="#A9713F" stroke="#6E4525" stroke-width="2"/><ellipse cx="0" cy="-70" rx="8" ry="10" fill="${fruit ?? '#FFD84A'}" stroke="#0F2A73" stroke-width="2"/><path d="M0 -80 q5 -5 9 -1" stroke="#3F9B57" stroke-width="2.4" fill="none" stroke-linecap="round"/><g fill="#C58B52" stroke="#6E4525" stroke-width="1.5"><path d="M-33 -34 l-22 6 v30 l22 -4 z"/><path d="M33 -34 l22 6 v30 l-22 -4 z"/></g></g></g>',
        );
      } else if (e == 'hedge') {
        final hd = StringBuffer();
        for (var x = -8; x < W + 8; x += 30) {
          if ((x + 15 - c.x).abs() < 52) continue;
          hd.write(
            '<rect x="$x" y="${by - 25}" width="34" height="27" rx="13" fill="${(x / 30).remainder(2).truncate() != 0 ? '#3F9B57' : '#4BAA62'}"/><circle cx="${x + 10}" cy="${by - 19}" r="5" fill="#7CCB7C" opacity="0.7"/><circle cx="${x + 24}" cy="${by - 10}" r="2.2" fill="${fruit ?? '#FFB3D1'}"/>',
          );
        }
        stand(
          by,
          '<g>$hd<g transform="translate(${c.x.toStringAsFixed(1)} $by)"><path d="M-40 2 v-40 q40 -44 80 0 v40" fill="none" stroke="#2F8750" stroke-width="15" stroke-linecap="round"/><path d="M-40 2 v-40 q40 -44 80 0 v40" fill="none" stroke="#57B866" stroke-width="7" stroke-linecap="round" stroke-dasharray="3 9"/><g fill="${fruit ?? '#FFB3D1'}"><circle cx="-38" cy="-30" r="3.4"/><circle cx="-22" cy="-56" r="3.4"/><circle cx="0" cy="-64" r="3.4"/><circle cx="22" cy="-56" r="3.4"/><circle cx="38" cy="-30" r="3.4"/><circle cx="-41" cy="-8" r="3"/><circle cx="41" cy="-8" r="3"/></g></g></g>',
        );
      } else if (e == 'fence') {
        final ps = StringBuffer();
        for (var x = 6; x < W; x += 28) {
          if ((x - c.x).abs() < 44) continue;
          ps.write(
            '<rect x="${x - 3}" y="${by - 22}" width="6" height="24" rx="2.5" fill="${snow ? '#B58150' : '#C99B5A'}" stroke="#8A5E36" stroke-width="1"/>',
          );
        }
        final posts = [
          for (final d in const [-42, 42])
            '<rect x="${d - 5}" y="-40" width="10" height="44" rx="4" fill="#8A5A34"/><rect x="${d - 6}" y="-56" width="12" height="15" rx="3" fill="#FFE38A" stroke="#0F2A73" stroke-width="2"/><path d="M${d - 8} -56 l8 -7 l8 7 z" fill="#0F2A73"/><circle class="twinkle" cx="$d" cy="-48" r="2.6" fill="#fff"/>',
        ].join();
        stand(
          by,
          '<g><path d="M0 ${by - 16} H${(c.x - 44).toStringAsFixed(0)} M${(c.x + 44).toStringAsFixed(0)} ${by - 16} H$W M0 ${by - 7} H${(c.x - 44).toStringAsFixed(0)} M${(c.x + 44).toStringAsFixed(0)} ${by - 7} H$W" stroke="#D9B274" stroke-width="4" stroke-linecap="round"/>$ps<g transform="translate(${c.x.toStringAsFixed(1)} $by)">$posts</g></g>',
        );
      } else if (e == 'stream') {
        final cy = BF[i]!, ice = snow || L[i - 1]!.fam == 'snow';
        final sdb = StringBuffer('M-30 ${cy(-30).toStringAsFixed(1)}');
        for (var x = -15; x <= W + 30; x += 15) {
          sdb.write(' L$x ${cy(x).toStringAsFixed(1)}');
        }
        final sd = sdb.toString();
        o.add(
          '<g stroke-linecap="round" stroke-linejoin="round" fill="none"><path d="$sd" stroke="${ice ? '#fff' : '#E9DDAE'}" stroke-width="70"/><path d="$sd" stroke="${ice ? '#DCEAF5' : '#D9CB94'}" stroke-width="60" stroke-dasharray="2 9" opacity="0.6"/><path d="$sd" stroke="${ice ? '#A9D4EE' : '#5FB4F0'}" stroke-width="52"/><path d="$sd" stroke="${ice ? '#D3ECFA' : '#8FD2FF'}" stroke-width="36"/><path class="${ice ? '' : 'shimmer'}" d="$sd" stroke="#fff" stroke-width="3" stroke-dasharray="14 46" opacity="0.8" transform="translate(0 -6)"/><path class="${ice ? '' : 'shimmer s2'}" d="$sd" stroke="#fff" stroke-width="2" stroke-dasharray="6 70" opacity="0.65" transform="translate(0 8)"/></g>',
        );
        bool onW(num x) => (x - c.x).abs() > 62 && x > 10 && x < W - 10;
        double sl(num x) =>
            math.atan2(cy(x + 4) - cy(x - 4), 8) * 180 / math.pi;
        if (!ice) {
          const pads = [
            [.12, -7],
            [.2, 8],
            [.78, -6],
            [.9, 7],
            [.3, -9],
          ];
          for (var k = 0; k < pads.length; k++) {
            final x = W * pads[k][0], d = pads[k][1];
            if (!onW(x)) continue;
            o.add(
              '<g transform="translate(${x.toStringAsFixed(0)} ${(cy(x) + d).toStringAsFixed(0)})"><path d="M0 0 L8 -3 A8.5 6 0 1 0 8 3 Z" fill="#4FAE6A" stroke="#2F8750" stroke-width="1"/>${k.isOdd ? '' : '<circle cx="-2" cy="-1" r="2.6" fill="#fff"/><circle cx="-2" cy="-1" r="1.1" fill="#FFC531"/>'}</g>',
            );
          }
          const ducks = [
            [.26, 2],
            [.84, -3],
          ];
          for (var k = 0; k < ducks.length; k++) {
            final x = W * ducks[k][0], d = ducks[k][1];
            if (!onW(x)) continue;
            o.add(
              '<g class="duck" style="animation-delay:${-k * 1.7}s"><g transform="translate(${x.toStringAsFixed(0)} ${(cy(x) + d).toStringAsFixed(0)}) scale(${k > 0 ? -1 : 1} 1)"><path d="M-12 2 q-8 2 -14 0" stroke="#fff" stroke-width="1.5" fill="none" opacity="0.7" stroke-linecap="round"/><ellipse cx="0" cy="0" rx="10" ry="6.5" fill="#fff" stroke="#C9D2E0" stroke-width="1"/><path d="M-9 -2 q-5 -4 -6 2 z" fill="#fff" stroke="#C9D2E0" stroke-width="1"/><circle cx="8" cy="-6" r="5" fill="#fff" stroke="#C9D2E0" stroke-width="1"/><path d="M12 -6 l6 1.5 l-6 2 z" fill="#F2A23A"/><circle cx="9.5" cy="-7.5" r="1" fill="#0F2A73"/></g></g>',
            );
          }
          {
            final x = c.x > 195 ? W * .07 : W * .93;
            if (onW(x)) {
              o.add(
                '<g transform="translate(${x.toStringAsFixed(0)} ${(cy(x) + 2).toStringAsFixed(0)}) rotate(${sl(x).toStringAsFixed(0)})"><path d="M-22 -6 q22 -7 44 0 q-3 13 -22 13 q-19 0 -22 -13 z" fill="#C58B52" stroke="#6E4525" stroke-width="2" stroke-linejoin="round"/><path d="M-14 -3 q14 -4 28 0 M-4 -6 v12 M8 -6 v11" stroke="#6E4525" stroke-width="1.6" fill="none"/><path d="M-6 0 l-20 -12 M10 0 l18 -12" stroke="#8A5A34" stroke-width="2.4" stroke-linecap="round"/></g>',
              );
            }
          }
          final rr = mkr(i * 31 + 23);
          for (var j = 0; j < 16; j++) {
            final x = 12 + rr() * (W - 24), y = cy(x) + (j.isOdd ? 1 : -1) * 37;
            if ((x - c.x).abs() > 58 && free(x, y, 8)) {
              stand(
                y,
                OG.reed(
                  double.parse(x.toStringAsFixed(0)),
                  double.parse(y.toStringAsFixed(0)),
                ),
              );
            }
          }
        } else {
          for (final fd in const [
            [.16, -4],
            [.8, 5],
            [.3, 6],
          ]) {
            final x = W * fd[0], d = fd[1];
            if (onW(x)) {
              o.add(
                '<path d="M${(x - 12).toStringAsFixed(0)} ${(cy(x) + d).toStringAsFixed(0)} q12 -7 24 0 M${(x - 4).toStringAsFixed(0)} ${(cy(x) + d + 6).toStringAsFixed(0)} q9 -5 18 0" fill="none" stroke="#fff" stroke-width="1.6" stroke-linecap="round" opacity="0.9"/>',
              );
            }
          }
        }
        late.add((
          -1e9,
          '<g transform="translate(${c.x.toStringAsFixed(1)} ${c.y.toStringAsFixed(1)}) rotate(${c.a.toStringAsFixed(1)})"><rect x="-31" y="-50" width="62" height="100" rx="8" fill="#6E4525"/>${[for (var k = 0; k < 9; k++) '<rect x="-28" y="${-48 + k * 10.8}" width="56" height="9" rx="3" fill="${k.isOdd ? '#C58B52' : '#D29A60'}"/>'].join()}<rect x="-37" y="-54" width="8" height="108" rx="4" fill="#8A5A34"/><rect x="29" y="-54" width="8" height="108" rx="4" fill="#8A5A34"/><g fill="#A9713F" stroke="#6E4525" stroke-width="1.2"><circle cx="-33" cy="-54" r="5.5"/><circle cx="33" cy="-54" r="5.5"/><circle cx="-33" cy="54" r="5.5"/><circle cx="33" cy="54" r="5.5"/></g></g>',
        ));
        final k = BK[i];
        if (k != null) {
          stand(
            k.y,
            '<g transform="translate(${k.x.toStringAsFixed(0)} ${k.y.toStringAsFixed(0)}) scale(${k.flip ? -.9 : .9} 0.9)">${k.big ? OLM['oak']!.f() : '<g transform="scale(1.55)">${OS.willow()}</g>'}</g>',
          );
        }
      }
    }
    // the landmark
    {
      final s = LS[i]!;
      final inner = s.M.f(
        D.lm == 'cart'
            ? fruit
            : D.lm == 'cabin'
            ? snow
            : null,
      );
      final g =
          '<g transform="translate(${s.x.toStringAsFixed(0)} ${s.y.toStringAsFixed(0)}) scale(${(left ? 1 : -1) * s.k} ${s.k})">$inner</g>';
      if (s.M.flat) {
        o.add(g);
      } else {
        stand(s.y, g);
      }
      if (b >= 3) {
        final sp = StringBuffer();
        for (var k = 0; k < 6; k++) {
          final a = k * 1.05 + i,
              px = s.x + math.cos(a) * (s.w + 8),
              py = s.y - s.h * .55 + math.sin(a) * s.h * .5;
          sp.write(
            '<path class="glint" style="animation-delay:${-k * .4}s" d="M${px.toStringAsFixed(0)} ${py.toStringAsFixed(0)} l2 5 5 2 -5 2 -2 5 -2 -5 -5 -2 5 -2 z" fill="#FFF3B0" stroke="#FFC531" stroke-width="0.8"/>',
          );
        }
        late.add((1e8, tag(3, sp.toString())));
      }
      if (D.lm == 'scarebarn' &&
          place(s.x + (left ? 64 : -64), s.y + 6, 16, 54)) {
        stand(
          s.y + 6,
          oat(s.x + (left ? 64 : -64), s.y + 6, 1, OPR['scare']!.f()),
        );
      }
    }
    // planting
    ({num w, num h, bool loose, bool flat, String Function(num x) f}) mk(
      Object d,
    ) {
      final dl = d is String ? [d] : d as List;
      final kd = dl[0] as String,
          a1 = dl.length > 1 ? dl[1] : null,
          a2 = dl.length > 2 ? dl[2] : null;
      ({num w, num h, bool loose, bool flat, String Function(num x) f}) it(
        num w,
        num h,
        String Function(num x) f, {
        bool loose = false,
        bool flat = false,
      }) => (w: w, h: h, loose: loose, flat: flat, f: f);
      return switch (kd) {
        'round' => it(24, 62, (x) => OS.round(a1, b >= 1 ? a2 : null, x)),
        'fir' => it(17, 60, (_) => OS.fir(t(a1) ? a1 : snow), loose: true),
        'birch' => it(15, 70, (_) => OS.birch(v['pal'] ?? a1), loose: true),
        'willow' => it(26, 70, (_) => OS.willow()),
        'cypress' => it(11, 66, (_) => OS.cypress(), loose: true),
        'bush' => it(18, 24, (_) => OS.bush(a1, a2)),
        'gmush' => it(24, 52, (_) => OS.gmush(a1)),
        'bamboo' => it(12, 62, (_) => OS.bamboo(), loose: true),
        'rock' => it(
          13,
          13,
          (_) => OS.rock(t(a1) ? a1 : snow),
          loose: true,
          flat: true,
        ),
        'sunflower' => it(10, 44, (_) => OS.sunflower(), loose: true),
        'vine' => it(
          16,
          34,
          (_) => OS.vine(b >= 1 ? fruit : null),
          loose: true,
        ),
        'lav' => it(13, 20, (_) => OS.lav(), loose: true),
        'berry' => it(
          18,
          24,
          (_) => OS.bush('green', b >= 1 ? fruit : null),
          loose: true,
        ),
        _ => it(18, 24, (_) => OS.bush('green')),
      };
    }

    bool put(
      num x,
      num y,
      ({num w, num h, bool loose, bool flat, String Function(num x) f}) it,
      num s,
    ) {
      if (zoneOf(x, y) != i || zoneOf(x, y - 10) != i) return false;
      if (!place(x, y, it.w * s, it.h * s, it.loose)) return false;
      stand(y, oat(x, y, s, it.f(x)));
      return true;
    }

    final yb = y0 + HS - 42, yt = top + 26;
    final lt = lay['t'];
    if (lt == 'beds') {
      String crop(int t, num cx, num cy) => t == 0
          ? OS.sprout(cx, cy)
          : t == 1
          ? '<g><path d="M$cx ${cy - 2} l-4 -9 M$cx ${cy - 2} v-11 M$cx ${cy - 2} l4 -9" stroke="#3F9B57" stroke-width="1.8" stroke-linecap="round" fill="none"/><ellipse cx="$cx" cy="$cy" rx="3.4" ry="2.6" fill="#F2A23A"/></g>'
          : '<g><circle cx="$cx" cy="${cy - 4}" r="6.5" fill="#57B866"/><circle cx="${cx - 2}" cy="${cy - 5}" r="4" fill="#8BD98A"/><circle cx="${cx + 1}" cy="${cy - 4}" r="2" fill="#C9F0B0"/></g>';
      for (final bed in [
        [262, y0 + 104, -5, 0],
        [46, y0 - 150, -4, 2],
        [44, y0 + 112, 4, 1],
        [52, y0 - 24, 3, 0],
        [300, y0 - 130, 4, 1],
        [330, y0 + 30, -3, 2],
      ]) {
        final bx = mx(bed[0]), by = bed[1], rot = bed[2], tt = bed[3].toInt();
        if (!free(bx, by, 40) ||
            zoneOf(bx, by) != i ||
            wetG(bx, by, 30) ||
            !place(bx, by + 24, 50, 50, true)) {
          continue;
        }
        final s = StringBuffer();
        for (var r = 0; r < 2; r++) {
          for (var c = 0; c < 4; c++) {
            s.write(crop((tt + i) % 3, bx - 33 + c * 22, by - 3 + r * 20));
          }
        }
        o.add(
          '<g transform="rotate($rot $bx $by)"><rect x="${bx - 48}" y="${by - 24}" width="96" height="52" rx="14" fill="#8A5E36"/><rect x="${bx - 45}" y="${by - 22}" width="90" height="44" rx="12" fill="#B58150"/><path d="M${bx - 40} ${by - 1} h80" stroke="#9A6B3F" stroke-width="2" stroke-dasharray="3 5"/>$s</g>',
        );
      }
      if (i == 0) {
        final fence = StringBuffer();
        for (var x = 6; x < W; x += 22) {
          if ((x + 6 - sx).abs() < 40) continue;
          fence.write(
            '<path d="M$x ${H - 8} v-30 l6 -7 l6 7 v30 z" fill="#fff" stroke="#D5DCE8" stroke-width="1.5"/>',
          );
        }
        stand(
          H - 8,
          '<g><rect x="0" y="${H - 30}" width="${sx - 40}" height="5" rx="2" fill="#E6EBF3"/><rect x="${sx + 40}" y="${H - 30}" width="$W" height="5" rx="2" fill="#E6EBF3"/>$fence</g>',
        );
      }
    } else if (lt == 'curve') {
      var r = 0;
      for (var y = yb; y > yt; y -= 44, r++) {
        final kind = const [0, 2, 1, 3, 0, 2, 1][r % 7];
        for (var x = 22 + (r.isOdd ? 22 : 0); x < W - 12; x += 44) {
          final jx = x + (rs() - .5) * 12,
              jy = y + 10 * math.sin(x / 70 + r) + (rs() - .5) * 8,
              s = .82 + rs() * .5,
              q = rs(),
              q2 = rs();
          if (q < .14) continue;
          final vv = q2 < .16 ? (r + 1 + (q2 * 18).floor()) % 4 : kind;
          put(jx, jy, (
            w: 12,
            h: vv == 3 ? 26 : 44,
            loose: true,
            flat: false,
            f: (_) => OS.young(vv),
          ), s);
        }
      }
    } else if (lt == 'rows') {
      final A = mk(v['a'] ?? const ['round', 'green']),
          B = v['b'] != null ? mk(v['b'] as Object) : null;
      var r = 0;
      List<double>? ladder;
      final fallen = <List<double>>[];
      final dx = lay['dx'] as num, dy = lay['dy'] as num;
      for (var y = yb; y > yt; y -= dy, r++) {
        var ci = 0;
        for (num x = 24 + (r.isOdd ? dx / 2 : 0); x < W - 10; x += dx) {
          final second = B != null && (r + ci++) % 3 == 1,
              jx = x + (rs() - .5) * 12,
              jy = y + (rs() - .5) * 10,
              s = .82 + rs() * .3;
          if (put(jx, jy, second ? B : A, s) && !second) {
            fallen.add([jx, jy]);
            if (ladder == null && jx > 50 && jx < W - 60) ladder = [jx, jy, s];
          }
        }
      }
      if (b >= 1 && fruit != null && D.fam == 'orchard') {
        for (var n = 0; n < math.min(5, fallen.length); n++) {
          final x = fallen[n][0], y = fallen[n][1];
          for (var k = 0; k < 3; k++) {
            final px = x - 22 + k * 17 + n * 3, py = y + 7 + (k % 2) * 5;
            if (free(px, py, 4) && !wetG(px, py, 4)) {
              o.add(
                tag(
                  1,
                  '<ellipse cx="${px.toStringAsFixed(0)}" cy="${py.toStringAsFixed(0)}" rx="3.6" ry="2.8" fill="$fruit" stroke="rgba(0,0,0,0.15)" stroke-width="0.6"/>',
                ),
              );
            }
          }
        }
        if (ladder != null) {
          final x = ladder[0], y = ladder[1], s = ladder[2];
          stand(
            y + 1,
            tag(
              1,
              '<g transform="translate(${(x + 17 * s).toStringAsFixed(0)} ${(y + 2).toStringAsFixed(0)}) rotate(-13)"><path d="M-6 0 v-50 M6 0 v-50" stroke="#C58B52" stroke-width="3" stroke-linecap="round"/><path d="M-6 -8 h12 M-6 -19 h12 M-6 -30 h12 M-6 -41 h12" stroke="#A9713F" stroke-width="2.6"/></g>',
            ),
          );
        }
      }
    } else if (lt == 'wood') {
      final its = [
        for (final e in lay['it'] as List)
          ((e as List)[0] as num, mk(e[1] as Object)),
      ];
      for (var k = 0; k < (lay['n'] as num); k++) {
        final x = 14 + rs() * (W - 28),
            y = yt + rs() * (yb - yt + 16),
            s = .8 + rs() * .5,
            q = rs();
        num a = q;
        var it = its[0].$2;
        for (final (w, c) in its) {
          a -= w;
          if (a <= 0) {
            it = c;
            break;
          }
        }
        put(x, y, it, it.flat ? 1 + s * .4 : s);
      }
    } else if (lt == 'field') {
      final it = mk((lay['it'] as List)[0] as Object),
          ed = mk((lay['edge'] as List)[0] as Object);
      for (var k = 0; k < 7; k++) {
        final x = rs() < .5 ? 14 + rs() * 46 : W - 60 + rs() * 46,
            y = yt + rs() * (yb - yt),
            s = .85 + rs() * .3;
        put(x, y, ed, s);
      }
      final dx = lay['dx'] as num, dy = lay['dy'] as num;
      var r = 0;
      for (var y = yb; y > yt; y -= dy, r++) {
        for (num x = 16 + (r.isOdd ? dx / 2 : 0); x < W - 10; x += dx) {
          final jy = y + 7 * math.sin(x / 60 + r), s = .9 + rs() * .25;
          if (rs() < .05) continue;
          put(x, jy, it, s);
        }
      }
    } else if (lt == 'open') {
      final its = [for (final d in lay['it'] as List) mk(d as Object)];
      for (var k = 0; k < (lay['n'] as num) * 2; k++) {
        final x = rs() < .5 ? 16 + rs() * 74 : W - 90 + rs() * 74,
            y = yt + rs() * (yb - yt),
            s = .85 + rs() * .35;
        put(x, y, its[k % its.length], s);
      }
    }
    // props, then an animal once the land is lively
    final anchors = [
      [fx(.1), y0 + 84],
      [fx(.3), y0 + 132],
      [fx(.12), y0 + 158],
      [fx(.93), y0 + 76],
      [fx(.92), y0 + 140],
      [fx(.92), y0 - 92],
      [fx(.9), y0 - 152],
      [fx(.14), y0 - 118],
      [fx(.3), y0 - 158],
      [fx(.46), y0 + 170],
      [fx(.5), y0 - 40],
      [fx(.7), y0 + 168],
    ];
    void drop(String key, int t, int off, [Object? arg]) {
      final M = OPR[key];
      if (M == null || t > b) return;
      for (var k = 0; k < anchors.length; k++) {
        final a = anchors[(off + k) % anchors.length];
        final x = a[0], y = a[1];
        if (zoneOf(x, y) != i || zoneOf(x, y - 12) != i) continue;
        if (place(x, y, M.w, M.h)) {
          stand(key == 'kite' ? 1e7 : y, tag(t, oat(x, y, 1, M.f(arg))));
          return;
        }
      }
    }

    for (var k = 0; k < D.pr.length; k++) {
      final key = D.pr[k];
      drop(
        key,
        k < 2 ? 0 : k - 1,
        (rp() * anchors.length).floor(),
        key == 'basket' ? fruit : null,
      );
    }
    drop(
      const ['bunny', 'hog', 'robin'][(oh(i, 61) * 3).floor()],
      2,
      (rp() * anchors.length).floor(),
    );
    if (b >= 2 && !snow) {
      final bx = 40 + oh(i, 62) * 200, byy = y0 - 120 + oh(i, 63) * 200;
      late.add((
        1e7,
        tag(
          2,
          '<g class="bfly" style="offset-path:path(\'M${bx.toStringAsFixed(0)} ${byy.toStringAsFixed(0)} q70 -60 130 -6 q-50 54 -130 6\');animation-delay:${-(i % 5) * 3}s"><path d="M0 0 q-9 -10 -12 -2 q0 8 12 2 q9 -10 12 -2 q0 8 -12 2" fill="${i.isOdd ? '#FFF0A6' : '#fff'}" stroke="${i.isOdd ? '#E5A100' : '#2F6BFF'}" stroke-width="1.5"/></g>',
        ),
      ));
    }
    // things in the air, and the light
    final air = F['air'] ?? (D.mood == 'dusk' ? 'fire' : null);
    if (air != null) {
      final ra = mkr(i * 31 + 29);
      final a = StringBuffer();
      for (var k = 0; k < 9; k++) {
        final x = 14 + ra() * (W - 28),
            y = top + 20 + ra() * (opSTEP - 60),
            dl = -(ra() * 7);
        final dls = dl.toStringAsFixed(1);
        a.write(
          air == 'fire'
              ? '<circle class="twinkle" style="animation-delay:${dls}s" cx="${x.toStringAsFixed(0)}" cy="${y.toStringAsFixed(0)}" r="2.6" fill="#FFF3A0" stroke="#FFC531" stroke-width="1" opacity="0.95"/>'
              : air == 'snow'
              ? '<circle class="fall" style="animation-delay:${dls}s" cx="${x.toStringAsFixed(0)}" cy="${y.toStringAsFixed(0)}" r="${(1.6 + ra() * 1.4).toStringAsFixed(1)}" fill="#fff"/>'
              : '<ellipse class="fall" style="animation-delay:${dls}s" cx="${x.toStringAsFixed(0)}" cy="${y.toStringAsFixed(0)}" rx="3.4" ry="2" fill="${air == 'petal' ? '#FFD0E0' : const ['#E58A3A', '#D9603F', '#E5B93A'][k % 3]}"/>',
        );
      }
      late.add((1e7, '<g pointer-events="none">$a</g>'));
    }
    if (D.mood != 'day') {
      tints.add(
        '<rect x="0" y="${(top - 14).toStringAsFixed(0)}" width="$W" height="${opSTEP + 28}" fill="url(#om-${D.mood})" pointer-events="none"/>',
      );
    }
  }

  for (var i = lo; i <= hi; i++) {
    drawLand(i);
  }

  // --- stops and their signs
  final discs = StringBuffer(), ups = StringBuffer();
  for (var j = 0; j < P.length; j++) {
    final x = P[j][0],
        y = P[j][1],
        i = lo + j,
        nm = _esc(nameOf(i)),
        s = stops[j].state,
        b = signBox(j);
    final sub =
        stops[j].sub ??
        switch (s) {
          'explored' => words.explored,
          'here' => words.here,
          'next' => words.next,
          _ => '',
        };
    final peak = s.startsWith('peak');
    // a land's peak: a bigger gold stop (section 15)
    final disc = peak
        ? '<ellipse cx="$x" cy="${y + 12}" rx="60" ry="35" fill="rgba(20,70,40,0.28)"/><ellipse cx="$x" cy="${y + 7}" rx="56" ry="32" fill="#D9A441"/><ellipse cx="$x" cy="$y" rx="56" ry="32" fill="#FFE38A" stroke="#C99B2E" stroke-width="3"/><ellipse cx="$x" cy="$y" rx="46" ry="25" fill="none" stroke="#C99B2E" stroke-width="2" stroke-dasharray="3 6"/>'
        : '<ellipse cx="$x" cy="${y + 10}" rx="50" ry="30" fill="rgba(20,70,40,0.28)"/><ellipse cx="$x" cy="${y + 6}" rx="46" ry="27" fill="${s == 'next' ? '#C9B88F' : '#D9A441'}"/><ellipse cx="$x" cy="$y" rx="46" ry="27" fill="${s == 'next'
              ? '#FFF7E2'
              : s == 'here'
              ? '#FFE38A'
              : '#FFEFB8'}" stroke="${s == 'here' ? '#0F2A73' : 'rgba(15,42,115,0.35)'}" stroke-width="${s == 'here' ? 3 : 2}"/>';
    final steps =
        '<ellipse cx="${x - 14}" cy="${y + 4}" rx="4" ry="6" fill="rgba(15,42,115,0.3)" transform="rotate(-20 ${x - 14} ${y + 4})"/><ellipse cx="${x + 16}" cy="${y + 10}" rx="4" ry="6" fill="rgba(15,42,115,0.3)" transform="rotate(15 ${x + 16} ${y + 10})"/>';
    final mark = s == 'peak'
        // the summit flag, until the level is passed
        ? '<g><line x1="$x" y1="${y + 2}" x2="$x" y2="${y - 70}" stroke="#6E4525" stroke-width="5" stroke-linecap="round"/><path class="flag" d="M${x + 2} ${y - 70} h34 l-8 11 l8 11 h-34 z" fill="#FFC531" stroke="#0F2A73" stroke-width="2.5" stroke-linejoin="round"/><path d="M${x + 17} ${y - 66} l2.2 4.5 5 .7 -3.6 3.5 .9 5 -4.5 -2.4 -4.5 2.4 .9 -5 -3.6 -3.5 5 -.7 z" fill="#0F2A73"/></g>'
        : s == 'walked'
        ? '<g>$steps</g>'
        : s == 'ahead'
        ? ''
        : s == 'earned' || s == 'peakEarned'
        ? '<g class="medal"><path d="M${x - 12} ${y - 58} l8 22 h8 l8 -22 z" fill="#2F6BFF" stroke="#0F2A73" stroke-width="2" stroke-linejoin="round"/><circle cx="$x" cy="${y - 22}" r="21" fill="#FFC531" stroke="#0F2A73" stroke-width="3"/><circle cx="$x" cy="${y - 22}" r="14" fill="#FFE38A"/><path d="M$x ${y - 32} l3.2 6.6 7.2 1 -5.2 5 1.3 7.2 -6.5 -3.5 -6.5 3.5 1.3 -7.2 -5.2 -5 7.2 -1 z" fill="#E5A100"/><path class="glint" d="M${x + 20} ${y - 46} l2 5 5 2 -5 2 -2 5 -2 -5 -5 -2 5 -2 z" fill="#fff"/></g>'
        : s == 'explored' || s == 'peakExplored'
        ? '<g><line x1="$x" y1="${y + 2}" x2="$x" y2="${y - 44}" stroke="#0F2A73" stroke-width="3.5" stroke-linecap="round"/><path class="flag" d="M${x + 1} ${y - 44} q14 -6 26 2 q-12 6 -26 14 z" fill="#2F6BFF" stroke="#0F2A73" stroke-width="2" stroke-linejoin="round"/><ellipse cx="${x - 14}" cy="${y + 4}" rx="4" ry="6" fill="rgba(15,42,115,0.3)" transform="rotate(-20 ${x - 14} ${y + 4})"/><ellipse cx="${x + 16}" cy="${y + 10}" rx="4" ry="6" fill="rgba(15,42,115,0.3)" transform="rotate(15 ${x + 16} ${y + 10})"/></g>'
        : s == 'here'
        ? '<ellipse class="ring" cx="$x" cy="$y" rx="46" ry="27" fill="none" stroke="#FFC531" stroke-width="5"/>'
        : '<path class="bob" d="M${x - 9} ${y - 2} l9 -10 l9 10 M${x - 9} ${y + 9} l9 -10 l9 10" fill="none" stroke="#0F2A73" stroke-width="4" stroke-linecap="round" stroke-linejoin="round" opacity="0.55"/>';
    final px = b.left ? b.x + b.w - 14 : b.x + 14;
    final hasSub = sub.isNotEmpty;
    final sign = nm.isEmpty
        ? ''
        : '<g class="sign"><rect x="${px - 3}" y="${b.y + 12}" width="6" height="${b.h + 2}" rx="3" fill="#6E4525"/><ellipse cx="$px" cy="${b.y + b.h + 15}" rx="12" ry="4" fill="rgba(20,70,40,0.25)"/><rect x="${b.x}" y="${b.y + 4}" width="${b.w}" height="${hasSub ? 48 : 34}" rx="10" fill="#6E4525"/><rect x="${b.x}" y="${b.y}" width="${b.w}" height="${hasSub ? 48 : 34}" rx="10" fill="${s == 'here' ? '#FFF7E2' : '#F3D9AE'}" stroke="#6E4525" stroke-width="2.5"/><text x="${b.x + b.w / 2}" y="${b.y + 22}" text-anchor="middle" font-size="18" font-weight="900" fill="#3B2410" max-width="${b.w - 12}">$nm</text>${hasSub ? '<text x="${b.x + b.w / 2}" y="${b.y + 40}" text-anchor="middle" font-size="13.5" font-weight="800" fill="${s == 'here' ? '#1D3FB8' : '#7A5A36'}" max-width="${b.w - 12}">${_esc(sub)}</text>' : ''}</g>';
    discs.write('<g class="ostop $s" id="ostop$j">$disc</g>');
    ups.write(
      '<g class="ostop-up $s" style="animation-delay:${(.15 + j * .09).toStringAsFixed(2)}s">$mark</g>$sign',
    );
  }
  late.sort((a, b) => a.$1.compareTo(b.$1));

  // --- the fog bank ahead (with the next land's one glimpse in it), and a
  // soft haze behind when older lands are folded away
  final fy = P[P.length - 1][1] - 118, hy = math.max(46.0, fy - 150);
  final fog =
      '<g pointer-events="none"><g opacity="0.5" id="oteaser"><path d="M-10 ${hy + 60} l70 -74 l44 44 l62 -86 l70 96 l40 -38 l124 78 v60 h-410 z" fill="#8FA6D6"/><path d="M${W * .62} ${hy - 18} v-34 l16 -12 l16 12 v34 z" fill="#7C93C8"/><circle class="twinkle" cx="${W * .62 + 16}" cy="${hy - 40}" r="5" fill="#FFE38A"/></g>'
      '<rect x="0" y="0" width="$W" height="${fy + 40}" fill="url(#ofog)"/><g filter="url(#oblur)"><ellipse class="drift" cx="70" cy="${fy - 6}" rx="150" ry="52" fill="#fff"/><ellipse class="drift d2" cx="300" cy="${fy - 28}" rx="170" ry="60" fill="#fff"/><ellipse class="drift" cx="190" cy="${fy - 96}" rx="230" ry="60" fill="#fff" opacity="0.9"/><ellipse class="drift d2" cx="120" cy="${fy - 170}" rx="240" ry="70" fill="#fff" opacity="0.8"/></g></g>';
  final bx = math.max(84.0, math.min(W - 84, P[0][0]));
  final behind = lo > 0
      ? '<rect x="0" y="${H - 150}" width="$W" height="150" fill="url(#ofogb)" pointer-events="none"/><g class="ostop" id="oback"><rect x="${bx - 78}" y="${H - 112}" width="156" height="40" rx="12" fill="#6E4525" transform="translate(0 4)"/><rect x="${bx - 78}" y="${H - 112}" width="156" height="40" rx="12" fill="#F3D9AE" stroke="#6E4525" stroke-width="2.5"/><path d="M${bx - 58} ${H - 97} l8 9 l8 -9" fill="none" stroke="#3B2410" stroke-width="3.4" stroke-linecap="round" stroke-linejoin="round"/><text x="${bx + 12}" y="${H - 86}" text-anchor="middle" font-size="16" font-weight="900" fill="#3B2410" max-width="120">${_esc(words.lookBack)}</text></g>'
      : '';
  String mg(String id, String c, num a) =>
      '<linearGradient id="om-$id" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="$c" stop-opacity="0"/><stop offset="0.1" stop-color="$c" stop-opacity="$a"/><stop offset="0.9" stop-color="$c" stop-opacity="$a"/><stop offset="1" stop-color="$c" stop-opacity="0"/></linearGradient>';
  final svg =
      '<svg viewBox="0 0 $W $H"><defs>${mg('evening', '#FF8A2A', .16)}${mg('mist', '#FFFFFF', .17)}${mg('dusk', '#3B2FA8', .2)}'
      '<linearGradient id="ofog" gradientUnits="userSpaceOnUse" x1="0" y1="${fy + 40}" x2="0" y2="${fy - 110}"><stop offset="0" stop-color="#F4FAFF" stop-opacity="0"/><stop offset="0.55" stop-color="#F4FAFF" stop-opacity="0.9"/><stop offset="1" stop-color="#EAF4FF" stop-opacity="0.96"/></linearGradient>'
      '<linearGradient id="ofogb" gradientUnits="userSpaceOnUse" x1="0" y1="${H - 150}" x2="0" y2="$H"><stop offset="0" stop-color="#F4FAFF" stop-opacity="0"/><stop offset="0.7" stop-color="#F4FAFF" stop-opacity="0.85"/><stop offset="1" stop-color="#EAF4FF" stop-opacity="0.95"/></linearGradient>'
      '<filter id="oblur"><feGaussianBlur stdDeviation="14"/></filter></defs>'
      '<rect width="$W" height="$H" fill="${OFAM[L[lo]!.fam]!['g']}"/>'
      '${o.join()}'
      '<path d="${G.d}" fill="none" stroke="rgba(30,100,55,0.35)" stroke-width="62" stroke-linecap="round"/>'
      '<path d="${G.d}" fill="none" stroke="#D9B274" stroke-width="50" stroke-linecap="round"/>'
      '<path id="opath" d="${G.d}" fill="none" stroke="#F3DCA6" stroke-width="40" stroke-linecap="round"/>'
      '<path d="${G.d}" fill="none" stroke="#fff" stroke-width="3" stroke-dasharray="1 15" stroke-linecap="round" opacity="0.55" transform="translate(-13 0)"/>'
      '<path d="${G.d}" fill="none" stroke="#C99B5A" stroke-width="3" stroke-dasharray="1 21" stroke-linecap="round" opacity="0.6" transform="translate(12 4)"/>'
      '<path id="owalked" d="${G.d}" fill="none" stroke="#FFC531" stroke-width="7" stroke-linecap="round" opacity="0.95"/>'
      '${late.where((l) => l.$1 < -1e8).map((l) => l.$2).join()}'
      '$discs'
      '${late.where((l) => l.$1 >= -1e8).map((l) => l.$2).join()}'
      '${tints.join()}'
      '$ups'
      '<ellipse class="cloud" cx="-80" cy="${H * .55}" rx="120" ry="46" fill="#0F2A73" opacity="0.06"/><ellipse class="cloud c2" cx="-80" cy="${H * .2}" rx="150" ry="54" fill="#0F2A73" opacity="0.05"/>'
      '${top ? '' : fog}$behind</svg>';
  return OrchardScene._(svg, G, lo, here);
}

String _og(String nm, double x, double y, String? arg) => switch (nm) {
  'tuft' => OG.tuft(x, y),
  'tuftw' => OG.tuftw(x, y),
  'fl' => OG.fl(x, y, arg),
  'wheat' => OG.wheat(x, y),
  'lav' => OG.lav(x, y),
  'mush' => OG.mush(x, y),
  'peb' => OG.peb(x, y),
  'leaf' => OG.leaf(x, y, arg),
  'fern' => OG.fern(x, y),
  'petal' => OG.petal(x, y),
  'snowl' => OG.snowl(x, y),
  'bell' => OG.bell(x, y),
  'reed' => OG.reed(x, y),
  _ => '',
};
