import 'package:yaml/yaml.dart';

/// The version of each content file a launch teaches from (PLAT-04), for
/// `session_started.content_versions`. The template's own version is added
/// per problem by the lesson.
///
/// * `app-config`, `policy`, `skill-map`: the served copy, else the copy
///   bundled with the app ([bundled]).
/// * `arithmetic`, `scoring`: the server holds these (the phone ships no
///   copy), so they are named once the content bundle has been served.
/// * `line-library`: the tutor lines live inside the policy file
///   (`lines.pack`); its own `lines.version` when the content gives one,
///   else the policy's version.
///
/// The served bundle's own `contentVersions` ([held]) fill in the keys
/// the server holds (`arithmetic`, `scoring`, `line-library`) that the
/// files gave none for; what the phone read wins, as the backend's
/// `with_server_versions` does.
///
/// A file that is missing, unreadable or has no `x.y.z` version is left
/// out: the event schema takes only semver values.
Map<String, String> contentVersions({
  required String? Function(String fileName) served,
  required Map<String, String> bundled,
  Map<String, String> held = const {},
}) {
  Object? read(String file) {
    final text = served(file) ?? bundled[file];
    if (text == null) return null;
    try {
      return loadYaml(text);
    } on Object {
      return null;
    }
  }

  String? versionOf(Object? doc) {
    final v = doc is Map ? '${doc['version'] ?? ''}' : '';
    return _semver.hasMatch(v) ? v : null;
  }

  final out = <String, String>{};
  void put(String key, String? v) {
    if (v != null) out[key] = v;
  }

  for (final name in ['app-config', 'skill-map', 'arithmetic', 'scoring']) {
    put(name, versionOf(read('$name.yaml')));
  }
  final policy = read('policy.yaml');
  final policyVersion = versionOf(policy);
  put('policy', policyVersion);
  final lines = policy is Map ? policy['lines'] : null;
  put('line-library', versionOf(lines) ?? policyVersion);
  for (final key in const ['arithmetic', 'scoring', 'line-library']) {
    if (!out.containsKey(key)) {
      final v = held[key];
      if (v != null && _semver.hasMatch(v)) out[key] = v;
    }
  }
  return out;
}

final _semver = RegExp(r'^\d+\.\d+\.\d+$');
