import 'package:yaml/yaml.dart';

/// A tutor the child can choose (tutor/tutors.yaml `tutors`, TTR-01). Its
/// [name] is null until Key names it; [costumes] are art keys by world
/// (null: not designed for that world yet).
typedef Tutor = ({
  String id,
  String kind,
  String? name,
  String defaultVoice,
  Map<String, String?> costumes,
});

/// A look the child can be (avatar/looks.yaml `looks`, ACC-12): an id and
/// its art key by world. Never a gender (PRV-07).
typedef Look = ({String id, Map<String, String?> costumes});

/// A world's skin slots (rewards/catalogue.yaml `worlds`, journey.yaml
/// `skin`): the words a tutor line and the reward screens fill in.
typedef WorldWords = ({
  String name,
  String role,
  String task,
  String solved,
  String first,
});

/// The journey's settings, from the spec pack's files the server serves
/// (else the copies in `assets/spec`): who can teach (tutors.yaml), who the
/// child can be (looks.yaml), the worlds and their words (catalogue.yaml,
/// rules.yaml `worlds`), first run's order (journey.yaml) and how long each
/// celebration may last (rules.yaml `celebrations`). Provisional values:
/// they change with the files, never with a release (PLAT-03).
class JourneyConfig {
  const JourneyConfig({
    this.tutors = const [],
    this.enabledTutors = const [],
    this.defaultTutor = 'teacher_1',
    this.voices = const ['voice_a', 'voice_b', 'voice_c'],
    this.looks = const [],
    this.worlds = const {},
    this.enabledWorlds = const ['detective'],
    this.defaultWorld = 'detective',
    this.comingSoonWorlds = 2,
    this.firstRun = const [
      'whos_learning',
      'world_picker',
      'look',
      'tutor',
      'meet_tutor',
      'home',
    ],
    this.celebrationMs = const {},
    this.endOfCaseOrder = const [
      'case_solved',
      'polish_cleared',
      'big_badge',
      'move_up_line',
    ],
    this.endOfSessionOrder = const [
      'streak_moment',
      'session_badge',
      'secret_badge',
    ],
  });

  /// From tutors.yaml, looks.yaml, catalogue.yaml, rules.yaml and
  /// journey.yaml; a file that's missing ([null]) keeps the defaults.
  factory JourneyConfig.fromYaml({
    String? tutors,
    String? looks,
    String? catalogue,
    String? rules,
    String? journey,
  }) {
    YamlMap? read(String? text) {
      if (text == null) return null;
      final y = loadYaml(text);
      return y is YamlMap ? y : null;
    }

    Map<String, String?> costumes(Object? c) => {
      if (c is Map)
        for (final MapEntry(:key, :value) in c.entries)
          '$key': value is String ? value : null,
    };

    const base = JourneyConfig();
    final t = read(tutors);
    final lk = read(looks);
    final cat = read(catalogue);
    final r = read(rules);
    final j = read(journey);
    final voices = (t?['voices'] as YamlMap?)?['enabled'] as List?;
    final worlds = cat?['worlds'] as YamlMap?;
    final ruleWorlds = r?['worlds'] as YamlMap?;
    final celebrations =
        (r?['celebrations'] as YamlMap?)?['moments'] as YamlMap?;
    final order = (j?['first_run'] as YamlMap?)?['order'] as List?;
    return JourneyConfig(
      tutors: [
        for (final x in (t?['tutors'] as List? ?? const []).whereType<Map>())
          (
            id: '${x['id']}',
            kind: '${x['kind'] ?? 'grown_up_teacher'}',
            name: x['name'] is String ? x['name'] as String : null,
            defaultVoice: '${x['default_voice'] ?? 'voice_a'}',
            costumes: costumes(x['costume']),
          ),
      ],
      enabledTutors: [for (final e in t?['enabled'] as List? ?? []) '$e'],
      defaultTutor: '${t?['default'] ?? base.defaultTutor}',
      voices: voices == null ? base.voices : [for (final v in voices) '$v'],
      looks: [
        for (final x in (lk?['looks'] as List? ?? const []).whereType<Map>())
          (id: '${x['id']}', costumes: costumes(x['costume'])),
      ],
      worlds: {
        if (worlds != null)
          for (final MapEntry(:key, :value) in worlds.entries)
            if (value is Map)
              '$key': (
                name: '${value['name'] ?? key}',
                role: '${value['role'] ?? ''}',
                task: '${value['task'] ?? ''}',
                solved: '${value['solved'] ?? ''}',
                first: '${value['first'] ?? ''}',
              ),
      },
      enabledWorlds: ruleWorlds?['enabled'] is List
          ? [for (final w in ruleWorlds!['enabled'] as List) '$w']
          : base.enabledWorlds,
      defaultWorld: '${ruleWorlds?['default'] ?? base.defaultWorld}',
      comingSoonWorlds:
          ruleWorlds?['coming_soon_tiles'] as int? ?? base.comingSoonWorlds,
      firstRun: order == null ? base.firstRun : [for (final s in order) '$s'],
      celebrationMs: {
        if (celebrations != null)
          for (final MapEntry(:key, :value) in celebrations.entries)
            if (value is Map && value['max_ms'] is int)
              '$key': value['max_ms'] as int,
      },
      endOfCaseOrder: _list(r?['end_of_case_order']) ?? base.endOfCaseOrder,
      endOfSessionOrder:
          _list((r?['session_badge'] as YamlMap?)?['end_of_session_order']) ??
          base.endOfSessionOrder,
    );
  }

  static List<String>? _list(Object? l) =>
      l is List ? [for (final x in l) '$x'] : null;

  /// Every tutor the file lists, enabled or not.
  final List<Tutor> tutors;

  /// tutors.yaml `enabled`: the picker shows these only, and is skipped
  /// with one (TTR-01).
  final List<String> enabledTutors;

  /// tutors.yaml `default`: the tutor of a child who hasn't chosen one.
  final String defaultTutor;

  /// tutors.yaml `voices.enabled`: the voice set (TTR-02, TTR-06).
  final List<String> voices;

  /// looks.yaml `looks`, in order (eight: look_01 to look_08).
  final List<Look> looks;

  /// catalogue.yaml `worlds`, by world id.
  final Map<String, WorldWords> worlds;

  /// rules.yaml `worlds.enabled` (REW-22): the worlds a child can choose.
  final List<String> enabledWorlds;
  final String defaultWorld;

  /// rules.yaml `worlds.coming_soon_tiles`: greyed tiles with no names.
  final int comingSoonWorlds;

  /// journey.yaml `first_run.order` (JRN-01).
  final List<String> firstRun;

  /// rules.yaml `celebrations.moments.*.max_ms` (REW-16), by moment.
  final Map<String, int> celebrationMs;

  /// rules.yaml `end_of_case_order` and `session_badge
  /// .end_of_session_order`.
  final List<String> endOfCaseOrder;
  final List<String> endOfSessionOrder;

  /// The tutors the child can pick, in the file's order; the default alone
  /// when the file names none.
  List<Tutor> get pickable {
    final on = [
      for (final id in enabledTutors)
        ?tutors.where((t) => t.id == id).firstOrNull,
    ];
    if (on.isNotEmpty) return on;
    return [?tutorById(defaultTutor)];
  }

  Tutor? tutorById(String? id) => tutors.where((t) => t.id == id).firstOrNull;

  /// The voice [tutorId] starts with (tutors.yaml `default_voice`); a voice
  /// that left the set falls back to it (`voice_switched_off`).
  String voiceFor(String tutorId, [String? chosen]) {
    if (chosen != null && voices.contains(chosen)) return chosen;
    final v = tutorById(tutorId)?.defaultVoice;
    if (v != null) return v;
    return voices.isEmpty ? 'voice_a' : voices.first;
  }

  /// The words of [world], else of the default world, else Detective's.
  WorldWords wordsOf(String? world) =>
      worlds[world] ??
      worlds[defaultWorld] ??
      (
        name: 'Detective',
        role: 'lead detective',
        task: 'case',
        solved: 'Case cracked!',
        first: 'First Case',
      );

  /// The longest [moment] may play (REW-16); 1.5 s for one the file
  /// doesn't time.
  Duration maxFor(String moment) =>
      Duration(milliseconds: celebrationMs[moment] ?? 1500);

  /// The world picker shows only while two or more worlds are enabled
  /// (JRN-01: skipped while one is).
  bool get pickWorld => enabledWorlds.length > 1;

  /// The tutor picker shows only while two or more tutors are enabled.
  bool get pickTutor => pickable.length > 1;
}
