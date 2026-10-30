import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../services/api.dart';
import '../services/api_client.dart';
import '../services/key_store.dart';
import '../services/social_sign_in.dart';

/// Who is using this phone. A grown-up's phone holds a parent token; a
/// child's own phone holds a device token from pairing (DEV-02), which can
/// start lessons but never read the family's record (DEV-04).
enum Role { none, parent, device }

/// Which sign-in doors this server can open (`/api/auth/config`).
typedef AuthConfig = ({
  String? googleServerClientId,
  bool apple,
  bool emailLink,
});

/// What a grown-up tells us about the child before signing in (ACC-04).
/// Sent with the child once there is an account to hold it.
class SetupDraft {
  String? name;
  int? age;
  String? schoolYear;

  /// `chosen` or `not_sure`.
  String? startingPoint;
  List<String> canDo = [];
  String? goal;

  /// The grown-up tapped "I agree" on Data (ACC-03).
  bool agreed = false;

  Map<String, Object?> toChildJson() => {
    'displayName': name,
    'age': ?age,
    'schoolYear': ?schoolYear,
    'startingPoint': ?startingPoint,
    if (canDo.isNotEmpty) 'canDo': canDo,
    'goal': ?goal,
  };
}

/// The phone's account state: tokens, the active child, and the grown-up
/// lock. The router listens to it, so a change of role moves the screens.
class AccountRepository extends ChangeNotifier {
  AccountRepository({
    required this._store,
    required this._social,
    String Function()? newId,
  }) : _newId = newId ?? const Uuid().v4;

  final KeyStore _store;
  final SocialSignIn _social;
  final String Function() _newId;

  /// Set by `main` once the client exists (the client reads [bearer]).
  late final ApiClient client;

  String? _parentToken;
  String? _deviceToken;
  String? _deviceId;
  String? _installId;
  String? _childId;
  bool _grownUpsUnlocked = false;
  bool _removed = false;
  bool _useFaceId = false;

  final draft = SetupDraft();

  Role get role => _parentToken != null
      ? Role.parent
      : _deviceToken != null
      ? Role.device
      : Role.none;

  String? get bearer => _parentToken ?? _deviceToken;

  /// The child learning on this phone, once chosen.
  String? get childId => _childId;

  /// This phone, as event envelopes name it (`dv_` + 8–32 letters/digits):
  /// the paired device's credential id, or a per-install id.
  String get deviceRef {
    final hex = (_deviceId ?? _installId ?? '').replaceAll('-', '');
    return 'dv_${hex.length > 32 ? hex.substring(0, 32) : hex}';
  }

  /// The grown-up area is open until the app leaves it (ACC-07).
  bool get grownUpsUnlocked => _grownUpsUnlocked;

  /// The server refused this phone's token: the parent removed it (DEV-03).
  bool get removed => _removed;

  /// The grown-up chose Face ID / fingerprint for the grown-up area
  /// (Lock 644:20). A setting of this phone, not the account.
  bool get useFaceId => _useFaceId;

  Future<void> setUseFaceId(bool on) async {
    _useFaceId = on;
    await _store.write('useFaceId', on ? '1' : null);
    notifyListeners();
  }

  Future<void> load() async {
    _parentToken = await _store.read('parentToken');
    _deviceToken = await _store.read('deviceToken');
    _deviceId = await _store.read('deviceId');
    _childId = await _store.read('childId');
    _installId = await _store.read('installId');
    _useFaceId = await _store.read('useFaceId') == '1';
    if (_installId == null) {
      _installId = _newId();
      await _store.write('installId', _installId);
    }
    notifyListeners();
  }

  // ------------------------------------------------------------ sign-in

  Future<AuthConfig> authConfig() async {
    final j = await client.get('/api/auth/config') as Map<String, Object?>;
    final google = j['googleClientId'] as String?;
    return (
      googleServerClientId: google == null || google.isEmpty ? null : google,
      apple: j['appleSignIn'] == true,
      emailLink: j['emailLink'] == true,
    );
  }

  /// Asks the server to email a sign-in link. Dev servers also return the
  /// link itself (`devLink`), so it can be followed without a mailbox.
  Future<String?> sendEmailLink(String email) async {
    final j =
        await client.post('/api/auth/email-link', {'email': email})
            as Map<String, Object?>;
    return j['devLink'] as String?;
  }

  /// The token from an emailed link (`…#m=<token>`), exchanged for a
  /// parent credential. 410 when used or expired.
  Future<void> verifyEmailLink(String token) async {
    final j =
        await client.post('/api/auth/email-link/verify', {'token': token})
            as Map<String, Object?>;
    await _signedIn(j['token']! as String);
  }

  /// False if the grown-up closed Google's sheet.
  Future<bool> signInWithGoogle() async {
    final config = await authConfig();
    final serverId = config.googleServerClientId;
    if (serverId == null) {
      throw const ApiException(
        "Google sign-in isn't switched on for this server yet",
        status: 501,
      );
    }
    final idToken = await _social.google(serverClientId: serverId);
    if (idToken == null) return false;
    final j =
        await client.post('/api/auth/google', {'credential': idToken})
            as Map<String, Object?>;
    await _signedIn(j['token']! as String);
    return true;
  }

  /// False if the grown-up closed Apple's sheet.
  Future<bool> signInWithApple() async {
    final apple = await _social.apple();
    if (apple == null) return false;
    final j =
        await client.post('/api/auth/apple', {
              'credential': apple.idToken,
              'nonce': apple.nonce,
            })
            as Map<String, Object?>;
    await _signedIn(j['token']! as String);
    return true;
  }

  Future<void> _signedIn(String token) async {
    _parentToken = token;
    _removed = false;
    await _store.write('parentToken', token);
    notifyListeners();
  }

  /// Signs the grown-up out of this phone. A paired child phone stays
  /// paired.
  Future<void> signOut() async {
    await _social.signOut();
    _parentToken = null;
    _grownUpsUnlocked = false;
    await _store.write('parentToken', null);
    notifyListeners();
  }

  // ------------------------------------------------------------ pairing

  /// The child's phone types the parent's 6-digit code (DEV-02).
  Future<void> redeemPairing(String code, {required String label}) async {
    final j =
        await client.post('/api/devices/redeem', {'code': code, 'label': label})
            as Map<String, Object?>;
    _deviceToken = j['token']! as String;
    _deviceId = j['deviceId']! as String;
    _removed = false;
    await _store.write('deviceToken', _deviceToken);
    await _store.write('deviceId', _deviceId);
    notifyListeners();
  }

  /// Called by the client on any 401. A child phone's token only stops
  /// working when the parent removed the phone.
  void unauthorized() {
    if (role == Role.device) {
      _removed = true;
    } else if (role == Role.parent) {
      // an expired or revoked grown-up credential: sign in again
      _parentToken = null;
      _grownUpsUnlocked = false;
      _store.write('parentToken', null);
    }
    notifyListeners();
  }

  /// After "This phone was removed": back to a fresh phone.
  Future<void> forgetPhone() async {
    _deviceToken = null;
    _deviceId = null;
    _childId = null;
    _removed = false;
    await _store.write('deviceToken', null);
    await _store.write('deviceId', null);
    await _store.write('childId', null);
    notifyListeners();
  }

  // ------------------------------------------------------- child, lock

  Future<void> chooseChild(String? id) async {
    _childId = id;
    await _store.write('childId', id);
    notifyListeners();
  }

  void unlockGrownUps() {
    _grownUpsUnlocked = true;
    notifyListeners();
  }

  void lockGrownUps() {
    if (!_grownUpsUnlocked) return;
    _grownUpsUnlocked = false;
    notifyListeners();
  }
}
