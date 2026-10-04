import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../data/auth_api.dart';
import '../models/member.dart';
import '../services/firebase_auth_service.dart';

const _tokenStorageKey = 'auth_token';

class AuthState {
  final Member? member;
  final String? token;
  final bool isLoading;

  /// True until the stored session has been checked (or rejected) once.
  final bool isRestoring;

  const AuthState({
    this.member,
    this.token,
    this.isLoading = false,
    this.isRestoring = false,
  });

  bool get isLoggedIn => member != null && token != null;

  AuthState copyWith({
    Member? member,
    String? token,
    bool? isLoading,
    bool? isRestoring,
  }) {
    return AuthState(
      member: member ?? this.member,
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
      isRestoring: isRestoring ?? this.isRestoring,
    );
  }
}

final authApiProvider = Provider<AuthApi>((ref) => AuthApi());
final firebaseAuthServiceProvider = Provider<FirebaseAuthService>(
  (ref) => FirebaseAuthService(),
);
final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _restoreSession();
    return const AuthState(isRestoring: true);
  }

  Future<void> _restoreSession() async {
    final storage = ref.read(secureStorageProvider);
    final token = await storage.read(key: _tokenStorageKey);
    if (token == null) {
      state = const AuthState();
      return;
    }

    state = state.copyWith(isLoading: true, token: token);
    try {
      final member = await ref.read(authApiProvider).me(token);
      state = AuthState(member: member, token: token);
    } catch (_) {
      await storage.delete(key: _tokenStorageKey);
      state = const AuthState();
    }
  }

  Future<void> _exchangeAndStore(String idToken) async {
    final result = await ref
        .read(authApiProvider)
        .exchangeFirebaseToken(idToken);
    await ref
        .read(secureStorageProvider)
        .write(key: _tokenStorageKey, value: result.token);
    state = AuthState(member: result.member, token: result.token);
  }

  Future<void> _signIn(Future<String> Function() getIdToken) async {
    state = state.copyWith(isLoading: true);
    try {
      await _exchangeAndStore(await getIdToken());
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> signInWithGoogle() =>
      _signIn(ref.read(firebaseAuthServiceProvider).signInWithGoogle);

  Future<void> signInWithEmail(String email, String password) => _signIn(
    () =>
        ref.read(firebaseAuthServiceProvider).signInWithEmail(email, password),
  );

  Future<void> registerWithEmail(String email, String password) => _signIn(
    () =>
        ref.read(firebaseAuthServiceProvider).signUpWithEmail(email, password),
  );

  Future<void> sendPasswordReset(String email) =>
      ref.read(firebaseAuthServiceProvider).sendPasswordReset(email);

  Future<void> resendVerification() =>
      ref.read(firebaseAuthServiceProvider).resendVerification();

  /// Reloads the Firebase user, re-exchanges a fresh token so the server can
  /// sync verification (and grant the welcome credit), and updates the member.
  Future<void> refreshEmailVerification() async {
    final fresh = await ref
        .read(firebaseAuthServiceProvider)
        .reloadAndGetIdToken();
    await _exchangeAndStore(fresh.idToken);
  }

  Future<void> refreshMember() async {
    final token = state.token;
    if (token == null) return;
    try {
      final member = await ref.read(authApiProvider).me(token);
      state = state.copyWith(member: member);
    } catch (_) {
      // Ignore silently: refreshing the balance is not critical and must not break the current session.
    }
  }

  Future<void> logout() async {
    final token = state.token;
    if (token != null) {
      try {
        await ref.read(authApiProvider).logout(token);
      } catch (_) {
        // The server session may already be gone; local sign-out must still succeed.
      }
    }
    await ref.read(firebaseAuthServiceProvider).signOut();
    await ref.read(secureStorageProvider).delete(key: _tokenStorageKey);
    state = const AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
