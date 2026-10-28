import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'config/env.dart';
import 'data/repositories/pack_repository.dart';
import 'data/repositories/session_repository.dart';
import 'data/services/fake_api.dart';
import 'data/services/outbox_db.dart';
import 'data/services/pack_source.dart';
import 'data/services/voice.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The support folder survives app updates and iOS never purges it.
  final dir = await getApplicationSupportDirectory();
  final db = await OutboxDb.open(p.join(dir.path, 'outbox.db'));
  // ponytail: FakeApi until the backend accepts phone-made session ids and
  // the v2 event names; then swap in the HTTP client here.
  if (Env.childRef.isEmpty || Env.deviceId.isEmpty) {
    throw StateError('No child ref or device id: setup and pairing come first');
  }
  final sessions = SessionRepository(
    db: db,
    api: FakeApi(),
    identity: (
      childRef: Env.childRef,
      deviceId: Env.deviceId,
      appVersion: Env.appVersion,
      isDemo: Env.isDemo,
    ),
  );
  final pack = await PackRepository(source: AssetPackSource()).load();
  final config = AppConfig.fromYaml(
    await rootBundle.loadString('assets/spec/app-config.yaml'),
  );
  runApp(
    AuraApp(
      sessions: sessions,
      pack: pack,
      voice: DeviceVoice(),
      sessionCap: Duration(minutes: config.sessionCapMinutes),
    ),
  );
}
