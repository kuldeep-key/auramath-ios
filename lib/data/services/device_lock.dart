import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Face ID / Touch ID / fingerprint, to open the grown-up area (Lock 644:20,
/// GPass 652:173). The passcode stays the fallback everywhere.
abstract interface class DeviceLock {
  Future<bool> available();

  /// True when the grown-up passed; false when they cancelled or failed.
  Future<bool> unlock(String reason);
}

class LocalDeviceLock implements DeviceLock {
  final _auth = LocalAuthentication();

  @override
  Future<bool> available() async =>
      await _auth.isDeviceSupported() && await _auth.canCheckBiometrics;

  @override
  Future<bool> unlock(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
      );
    } on PlatformException {
      // not enrolled, locked out: the passcode is the way in
      return false;
    } on LocalAuthException {
      return false;
    }
  }
}
