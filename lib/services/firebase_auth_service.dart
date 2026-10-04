import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../l10n/app_l10n.dart';
import 'auth_failure.dart';

/// Thin wrapper around Firebase Auth and Google Sign-In. Every method returns
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
