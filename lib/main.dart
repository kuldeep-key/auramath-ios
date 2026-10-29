import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'config/env.dart';
import 'data/repositories/account_repository.dart';
import 'data/repositories/family_repository.dart';
import 'data/repositories/pack_repository.dart';
import 'data/repositories/session_repository.dart';
import 'data/services/api_client.dart';
import 'data/services/device_lock.dart';
import 'data/services/key_store.dart';
import 'data/services/outbox_db.dart';
import 'data/services/pack_source.dart';
import 'data/services/social_sign_in.dart';
import 'data/services/voice.dart';
import 'deps.dart';
import 'ui/features/lesson/view_models/sitting.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Env.apiBase.isEmpty) {
    throw StateError(
      'No API_BASE: build with --dart-define-from-file=env/<env>.json',
    );
  }
  // The support folder survives app updates and iOS never purges it.
  final dir = await getApplicationSupportDirectory();
  final db = await OutboxDb.open(p.join(dir.path, 'outbox.db'));

  final account = AccountRepository(
    store: SecureKeyStore(),
    social: PlatformSocialSignIn(),
  );
  final client = ApiClient(
    baseUrl: Env.apiBase,
    bearer: () => account.bearer,
    onUnauthorized: account.unauthorized,
  );
  account.client = client;
  await account.load();

  final pack = await PackRepository(source: AssetPackSource()).load();
  final config = AppConfig.fromYaml(
    await rootBundle.loadString('assets/spec/app-config.yaml'),
  );
  runApp(
    AuraApp(
      deps: Deps(
        account: account,
        family: FamilyRepository(client),
        client: client,
        sessions: SessionRepository(
          db: db,
          api: HttpApi(client),
          identity: (
            // ponytail: replaced by the server's child_ref per session in
            // the online-first lesson change
            childRef: 'ch_pending0',
            deviceId: account.deviceRef,
            appVersion: Env.appVersion,
            isDemo: Env.isDemo,
          ),
        ),
        pack: pack,
        voice: DeviceVoice(),
        sitting: Sitting(capMs: config.sessionCapMinutes * 60 * 1000),
        deviceLock: LocalDeviceLock(),
      ),
    ),
  );
}
