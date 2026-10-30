import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Small secrets that outlive the app: tokens and ids. The Keychain on iOS,
/// the Keystore on Android.
abstract interface class KeyStore {
  Future<String?> read(String key);

  /// A null [value] deletes the key.
  Future<void> write(String key, String? value);
}

class SecureKeyStore implements KeyStore {
  static const _storage = FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String? value) => value == null
      ? _storage.delete(key: key)
      : _storage.write(key: key, value: value);
}

/// For tests.
class MemoryKeyStore implements KeyStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String? value) async =>
      value == null ? values.remove(key) : values[key] = value;
}
