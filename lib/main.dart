import 'dart:async';
import 'dart:io';

import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/foundation.dart' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
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
import 'data/services/error_reporter.dart';
import 'data/services/flags.dart';
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

  final store = SecureKeyStore();
  final account = AccountRepository(
    store: store,
    social: PlatformSocialSignIn(),
  );
  final client = ApiClient(
    baseUrl: Env.apiBase,
    bearer: () => account.bearer,
    onUnauthorized: account.unauthorized,
  );
  account.client = client;
  await account.load();

  final errors = ErrorReporter(
    client,
    hasToken: () => account.bearer != null,
    appVersion: Env.appVersion,
    platform: Platform.operatingSystem,
    osVersion: Platform.operatingSystemVersion,
  );
  // held from before sign-in go once a token exists
  account.addListener(errors.schedule);
  FlutterError.onError = (d) {
    FlutterError.presentError(d);
    errors.report(
      d.library == 'rendering library' ? 'render' : 'error',
      d.exceptionAsString(),
      stack: d.stack?.toString(),
    );
  };
  PlatformDispatcher.instance.onError = (e, stack) {
    errors.report('crash', '$e', stack: '$stack');
    return false; // still the platform's to log
  };

  final pack = await PackRepository(source: AssetPackSource()).load();
  final config = AppConfig.fromYaml(
    await rootBundle.loadString('assets/spec/app-config.yaml'),
  );
  final flags = Flags(client, store, defaults: config.flags);
  await flags.load();
  unawaited(flags.refresh());
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
            deviceId: account.deviceRef,
            appVersion: Env.appVersion,
            isDemo: Env.isDemo,
          ),
          onRejected: (sessionId, rejected) => errors.report(
            'error',
            'events refused: ${rejected.join('; ')}',
            screen: 'lesson',
            sessionId: sessionId,
          ),
        ),
        pack: pack,
        voice: DeviceVoice(),
        sitting: Sitting(capMs: config.sessionCapMinutes * 60 * 1000),
        deviceLock: LocalDeviceLock(),
        outbox: db,
        store: store,
        flags: flags,
        timeZone: () async =>
            (await FlutterTimezone.getLocalTimezone()).identifier,
      ),
    ),
  );
}
