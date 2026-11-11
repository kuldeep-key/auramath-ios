import 'package:flutter/services.dart';

import 'content_bundle.dart';

/// Where a content pack's JSON, and Julia's tutor policy, come from.
abstract interface class PackSource {
  Future<String> read();

  /// The spec pack's `tutor/policy.yaml`.
  Future<String> readPolicy();

  /// The spec pack's comparison template, for its steps' hint start rungs.
  Future<String> readTemplate();
}

/// The sample pack bundled with the app, until packs are downloaded; the
/// policy the server served ([served]) when there is one.
class AssetPackSource implements PackSource {
  AssetPackSource({this.served});

  final ContentBundle? served;

  @override
  Future<String> read() =>
      rootBundle.loadString('assets/sample_pack/pack.json');

  @override
  Future<String> readPolicy() async =>
      served?.yamlOf('policy.yaml') ??
      await rootBundle.loadString('assets/spec/policy.yaml');

  @override
  Future<String> readTemplate() async =>
      served?.yamlOf('comparison-two-step.yaml') ??
      await rootBundle.loadString('assets/spec/comparison-two-step.yaml');
}
