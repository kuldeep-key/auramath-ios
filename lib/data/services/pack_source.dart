import 'package:flutter/services.dart';

/// Where a content pack's JSON, and Julia's tutor policy, come from.
abstract interface class PackSource {
  Future<String> read();

  /// The spec pack's `tutor/policy.yaml`.
  Future<String> readPolicy();
}

/// The sample pack bundled with the app, until packs are downloaded.
class AssetPackSource implements PackSource {
  @override
  Future<String> read() =>
      rootBundle.loadString('assets/sample_pack/pack.json');

  @override
  Future<String> readPolicy() =>
      rootBundle.loadString('assets/spec/policy.yaml');
}
