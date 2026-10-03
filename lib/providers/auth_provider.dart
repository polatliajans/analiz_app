import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../data/auth_api.dart';
import '../models/member.dart';

const _tokenStorageKey = 'auth_token';

class AuthState {
  final Member? member;
  final String? token;
  final bool isLoading;

  const AuthState({this.member, this.token, this.isLoading = false});

  bool get isLoggedIn => member != null && token != null;

  AuthState copyWith({Member? member, String? token, bool? isLoading}) {
    return AuthState(
      member: member ?? this.member,
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final authApiProvider = Provider<AuthApi>((ref) => AuthApi());
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) => const FlutterSecureStorage());

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _restoreSession();
    return const AuthState();
  }

  Future<void> _restoreSession() async {
    final storage = ref.read(secureStorageProvider);
    final token = await storage.read(key: _tokenStorageKey);
    if (token == null) return;

    state = state.copyWith(isLoading: true, token: token);
    try {
      final member = await ref.read(authApiProvider).me(token);
      state = AuthState(member: member, token: token);
    } catch (_) {
      await storage.delete(key: _tokenStorageKey);
      state = const AuthState();
    }
  }

  Future<void> register({String? name, required String email, required String password}) async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await ref.read(authApiProvider).register(name: name, email: email, password: password);
      await ref.read(secureStorageProvider).write(key: _tokenStorageKey, value: result.token);
      state = AuthState(member: result.member, token: result.token);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await ref.read(authApiProvider).login(email: email, password: password);
      await ref.read(secureStorageProvider).write(key: _tokenStorageKey, value: result.token);
      state = AuthState(member: result.member, token: result.token);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> refreshMember() async {
    final token = state.token;
    if (token == null) return;
    try {
      final member = await ref.read(authApiProvider).me(token);
      state = state.copyWith(member: member);
    } catch (_) {
      // Sessizce yoksay — bakiye tazeleme kritik değil, mevcut oturumu bozmasın.
    }
  }

  Future<void> logout() async {
    final token = state.token;
    if (token != null) {
      await ref.read(authApiProvider).logout(token);
    }
    await ref.read(secureStorageProvider).delete(key: _tokenStorageKey);
    state = const AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
