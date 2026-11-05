import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../config/env.dart';
import 'api.dart';

/// The platform's own sign-in sheets. Each returns the ID token the backend
/// verifies (`/api/auth/google`, `/api/auth/apple`), or null if the grown-up
/// closed the sheet.
abstract interface class SocialSignIn {
  /// [serverClientId] is the backend's Google client id, from
  /// `/api/auth/config`: Google mints the token for it.
  Future<String?> google({required String serverClientId});

  Future<({String idToken, String nonce})?> apple();

  Future<void> signOut();
}

class PlatformSocialSignIn implements SocialSignIn {
  bool _googleReady = false;

  @override
  Future<String?> google({required String serverClientId}) async {
    if (Env.googleIosClientId.isEmpty) {
      throw const ApiException(
        "Google sign-in isn't set up in this build yet (no client id)",
      );
    }
    if (!_googleReady) {
      await GoogleSignIn.instance.initialize(
        clientId: Env.googleIosClientId,
        serverClientId: serverClientId,
      );
      _googleReady = true;
    }
    try {
      final account = await GoogleSignIn.instance.authenticate();
      return account.authentication.idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw ApiException('Google sign-in failed: ${e.description ?? e.code}');
    }
  }

  @override
  Future<({String idToken, String nonce})?> apple() async {
    // Apple puts the SHA-256 of the nonce in the token; the server checks
    // it against the raw nonce we send alongside.
    final raw = base64UrlEncode(
      List.generate(32, (_) => Random.secure().nextInt(256)),
    );
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email],
        nonce: sha256.convert(utf8.encode(raw)).toString(),
      );
      final token = credential.identityToken;
      if (token == null) {
        throw const ApiException('Apple sent no identity token');
      }
      return (idToken: token, nonce: raw);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      throw ApiException('Apple sign-in failed: ${e.message}');
    }
  }

  @override
  Future<void> signOut() async {
    if (_googleReady) await GoogleSignIn.instance.signOut();
  }
}
