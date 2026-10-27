import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app.dart';
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
  final sessions = SessionRepository(db: db, api: FakeApi());
  final pack = await PackRepository(source: AssetPackSource()).load();
  runApp(AuraApp(sessions: sessions, pack: pack, voice: DeviceVoice()));
}
