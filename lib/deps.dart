import 'package:auramath_engine/auramath_engine.dart';

import 'data/repositories/account_repository.dart';
import 'data/repositories/family_repository.dart';
import 'data/repositories/session_repository.dart';
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
  });

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
}
