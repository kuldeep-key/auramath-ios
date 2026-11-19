import 'package:auramath_engine/auramath_engine.dart';

import 'data/models/journey_config.dart';
import 'data/repositories/account_repository.dart';
import 'data/repositories/family_repository.dart';
import 'data/repositories/look_repository.dart';
import 'data/repositories/session_repository.dart';
import 'data/repositories/visit_repository.dart';
import 'data/services/flags.dart';
import 'data/services/api_client.dart';
import 'data/services/device_lock.dart';
import 'data/services/key_store.dart';
import 'data/services/outbox_db.dart';
import 'data/services/voice.dart';
import 'ui/features/lesson/view_models/sitting.dart';

/// Everything a screen may need, made once in `main` and handed to the
/// route builders. Screens take what they use through their constructors.
class Deps {
  Deps({
    required this.account,
    required this.family,
    required this.client,
    required this.sessions,
    required this.pack,
    required this.voice,
    required this.sitting,
    required this.deviceLock,
    required this.outbox,
    required this.store,
    required this.flags,
    required this.timeZone,
    this.config = const AppConfig(sessionCapMinutes: 30),
    JourneyConfig? journey,
    LookRepository? looks,
    VisitRepository? visits,
  }) : journey = journey ?? looks?.config ?? const JourneyConfig(),
       looks =
           looks ?? LookRepository(client, journey ?? const JourneyConfig()),
       visits =
           visits ??
           VisitRepository(
             client,
             deviceId: () => account.deviceRef,
             appVersion: sessions.identity.appVersion,
             outbox: outbox,
           ) {
    // every session records the child's look, tutor, voice and world
    sessions.lookFor = (childId) => this.looks.sessionLook(childId);
  }

  final AccountRepository account;
  final FamilyRepository family;

  /// For a feature's own repository (`FooRepository(deps.client)`).
  final ApiClient client;
  final SessionRepository sessions;
  final Pack pack;
  final Voice voice;
  final Sitting sitting;
  final DeviceLock deviceLock;

  /// This phone's saved lesson events (read-only outside the lesson): the
  /// badges and trail read what was earned here.
  final OutboxDb outbox;

  /// This phone's small saved settings (the grown-up's lesson settings,
  /// the forgot-passcode marker). Tokens stay inside the account.
  final KeyStore store;

  /// The server's feature flags: every provisional screen asks them.
  final Flags flags;

  /// App-config (served, else bundled): the AI timings, the offline clock.
  final AppConfig config;

  /// The phone's IANA time zone, e.g. `Australia/Sydney`.
  final Future<String> Function() timeZone;

  /// The journey's settings: tutors, looks, worlds, first run, celebration
  /// lengths (D-59, D-51).
  final JourneyConfig journey;

  /// The child's look, tutor, voice and world, as the server keeps them.
  final LookRepository looks;

  /// Events outside a lesson, under this app open's visit (D-60).
  final VisitRepository visits;
}
