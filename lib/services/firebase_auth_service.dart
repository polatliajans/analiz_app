import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../l10n/app_l10n.dart';
import 'apple_sign_in_logic.dart';
import 'auth_failure.dart';

/// Thin wrapper around Firebase Auth, Google Sign-In and Sign in with Apple. Every method returns
/// a Firebase ID token (or nothing) and converts SDK errors to [AuthFailure].
class FirebaseAuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  bool _googleInitialized = false;

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AuthFailure {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(authErrorKindFromCode(e.code));
    } on GoogleSignInException catch (e) {
      throw AuthFailure(
        e.code == GoogleSignInExceptionCode.canceled ||
                e.code == GoogleSignInExceptionCode.interrupted
            ? AuthErrorKind.cancelled
            : AuthErrorKind.unknown,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      throw AuthFailure(
        e.code == AuthorizationErrorCode.canceled
            ? AuthErrorKind.cancelled
            : AuthErrorKind.unknown,
      );
    } catch (_) {
      throw const AuthFailure(AuthErrorKind.unknown);
    }
  }

  Future<void> _applyLanguage() =>
      _auth.setLanguageCode(AppL10n.current.localeName);

  Future<String> _idToken(User? user, {bool forceRefresh = false}) async {
    final token = await user?.getIdToken(forceRefresh);
    if (token == null) throw const AuthFailure(AuthErrorKind.unknown);
    return token;
  }

  Future<String> signInWithGoogle() => _guard(() async {
    final google = GoogleSignIn.instance;
    if (!_googleInitialized) {
      // On Android the server client id is read from google-services.json
      // (default_web_client_id).
      await google.initialize();
      _googleInitialized = true;
    }
    final account = await google.authenticate();
    final googleIdToken = account.authentication.idToken;
    if (googleIdToken == null) throw const AuthFailure(AuthErrorKind.unknown);
    final credential = await _auth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: googleIdToken),
    );
    return _idToken(credential.user);
  });

  /// iOS only. Native Sign in with Apple with a SHA-256 nonce; the raw nonce
  /// goes to Firebase, the hash to Apple. Apple only returns the name on the
  /// very first authorization, so it is copied onto the Firebase user then.
  /// Email may be absent (or a private relay address); callers must cope.
  Future<String> signInWithApple() => _guard(() async {
    final rawNonce = generateAppleNonce();
    final apple = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: sha256ofString(rawNonce),
    );
    final identityToken = apple.identityToken;
    if (identityToken == null) throw const AuthFailure(AuthErrorKind.unknown);
    final credential = await _auth.signInWithCredential(
      OAuthProvider('apple.com').credential(
        idToken: identityToken,
        rawNonce: rawNonce,
        accessToken: apple.authorizationCode,
      ),
    );
    final user = credential.user;
    final name = appleDisplayName(apple.givenName, apple.familyName);
    var nameApplied = false;
    if (user != null &&
        name != null &&
        (user.displayName == null || user.displayName!.trim().isEmpty)) {
      try {
        await user.updateDisplayName(name);
        nameApplied = true;
      } catch (_) {
        // Cosmetic only; sign-in itself succeeded.
      }
    }
    // Refresh so the ID token carries the freshly set name claim.
    return _idToken(user, forceRefresh: nameApplied);
  });

  /// App Store rule 5.1.1(v): deleting an account created with Sign in with
  /// Apple must also revoke the Apple token. Step 1 (before anything is
  /// deleted): re-authorizes with Apple to get a fresh authorization code.
  /// Returns null for non-Apple users or when the user cancels/it is
  /// unavailable. Has no side effect on the account, so a later failure of
  /// the server deletion leaves everything intact. Never throws.
  Future<String?> prepareAppleRevocation() async {
    try {
      final user = _auth.currentUser;
      final isApple =
          user?.providerData.any((p) => p.providerId == 'apple.com') ?? false;
      if (!isApple) return null;
      final rawNonce = generateAppleNonce();
      final apple = await SignInWithApple.getAppleIDCredential(
        scopes: const [],
        nonce: sha256ofString(rawNonce),
      );
      return apple.authorizationCode;
    } catch (_) {
      return null;
    }
  }

  /// Step 2 (after the server deleted the account): hands the code from
  /// [prepareAppleRevocation] to Firebase to revoke the Apple token (needs the
  /// Apple provider's key configured in the Firebase console). Best effort:
  /// never throws, so the finished deletion is never blocked.
  Future<void> revokeAppleToken(String authorizationCode) async {
    try {
      await _auth.revokeTokenWithAuthorizationCode(authorizationCode);
    } catch (_) {}
  }

  Future<String> signUpWithEmail(String email, String password) =>
      _guard(() async {
        final credential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        final user = credential.user;
        await _applyLanguage();
        await user?.sendEmailVerification();
        return _idToken(user);
      });

  Future<String> signInWithEmail(String email, String password) =>
      _guard(() async {
        final credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        return _idToken(credential.user);
      });

  Future<void> sendPasswordReset(String email) => _guard(() async {
    await _applyLanguage();
    await _auth.sendPasswordResetEmail(email: email);
  });

  Future<void> resendVerification() => _guard(() async {
    await _applyLanguage();
    await _auth.currentUser?.sendEmailVerification();
  });

  Future<({String idToken, bool emailVerified})> reloadAndGetIdToken() =>
      _guard(() async {
        final user = _auth.currentUser;
        await user?.reload();
        final refreshed = _auth.currentUser;
        final token = await _idToken(refreshed, forceRefresh: true);
        return (idToken: token, emailVerified: refreshed!.emailVerified);
      });

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {}
    try {
      if (_googleInitialized) await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }
}
