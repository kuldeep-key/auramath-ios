import 'package:flutter/services.dart';

/// Where a content pack's JSON comes from.
abstract interface class PackSource {
  Future<String> read();
}

/// The sample pack bundled with the app, until packs are downloaded.
class AssetPackSource implements PackSource {
  @override
  Future<String> read() =>
      rootBundle.loadString('assets/sample_pack/pack.json');
}
