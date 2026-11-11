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
import 'data/services/content_bundle.dart';
import 'data/services/content_versions.dart';
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

  // The server's teaching content from the last launch, else the bundled
  // copy; a newer one is fetched now for the next launch.
  final bundle = ContentBundle(
    client,
    File(p.join(dir.path, 'content_bundle.json')),
  );
  await bundle.load();
  if (account.bearer != null) unawaited(bundle.refresh());
  Future<T> served<T>(Future<T> Function(ContentBundle?) read) async {
    try {
      return await read(bundle);
    } on Object catch (e) {
      // a served file this build can't read: the bundled copy, reported
      errors.report('error', 'served content not readable: $e');
      return read(null);
    }
  }

  final pack = await served(
    (b) => PackRepository(source: AssetPackSource(served: b)).load(),
  );
  final config = await served(
    (b) async => AppConfig.fromYaml(
      b?.yamlOf('app-config.yaml') ??
          await rootBundle.loadString('assets/spec/app-config.yaml'),
    ),
  );
  final flags = Flags(
    client,
    store,
    defaults: config.flags,
    overrides: Flags.parseOverrides(Env.flagOverrides),
  );
  await flags.load();
  unawaited(flags.refresh());
  // the version of each content file this launch teaches from, served or
  // bundled (PLAT-04); the template's comes with each problem
  final versions = contentVersions(
    served: bundle.yamlOf,
    bundled: {
      for (final name in ['app-config', 'policy', 'skill-map'])
        '$name.yaml': await rootBundle.loadString('assets/spec/$name.yaml'),
    },
  );
  final sessions = SessionRepository(
    db: db,
    api: HttpApi(client),
    identity: (
      deviceId: account.deviceRef,
      appVersion: Env.appVersion,
      isDemo: Env.isDemo,
      contentVersions: versions,
    ),
    onRejected: (sessionId, rejected) => errors.report(
      'error',
      'events refused: ${rejected.join('; ')}',
      screen: 'lesson',
      sessionId: sessionId,
    ),
    onFailed: (sessionId, message) =>
        errors.report('error', message, screen: 'lesson', sessionId: sessionId),
    template: await served(
      (b) async => ComparisonTemplate.fromYaml(
        b?.yamlOf('comparison-two-step.yaml') ??
            await rootBundle.loadString('assets/spec/comparison-two-step.yaml'),
      ),
    ),
  );
  // the server's problems this phone has shown, for a case left part way
  await sessions.loadProblems(pack);
  final sitting = Sitting(
    capMs: config.sessionCapMinutes * 60 * 1000,
    store: store,
  );
  await sitting.load();
  runApp(
    AuraApp(
      deps: Deps(
        account: account,
        family: FamilyRepository(client),
        client: client,
        sessions: sessions,
        pack: pack,
        // the case partner's voice from the server; the phone's own voice
        // whenever the server reads nothing aloud or a line can't go out
        voice: CloudVoice(
          fetch: (text, voiceId) => client.postBytes('/api/voice/speak', {
            'text': text,
            'voice': ?voiceId,
          }),
          warmer: (lines, voiceId) => client.post('/api/voice/warm', {
            'lines': lines,
            'voice': ?voiceId,
          }),
          player: FileClipPlayer(),
          fallback: DeviceVoice(),
        ),
        sitting: sitting,
        config: config,
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
