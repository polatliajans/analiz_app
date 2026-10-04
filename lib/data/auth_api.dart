import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_http.dart';

import '../config/api_config.dart';
import '../l10n/app_l10n.dart';
import '../models/member.dart';
import '../services/auth_failure.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthResult {
  final Member member;
  final String token;

  const AuthResult({required this.member, required this.token});
}

class AuthApi {
  /// Exchanges a Firebase ID token for a Sanctum session.
  Future<AuthResult> exchangeFirebaseToken(String idToken) async {
    final http.Response response;
    try {
      response = await ApiHttp.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/firebase'),
        body: {'id_token': idToken},
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      throw AuthException(AppL10n.current.errorRequestFailed('$e'));
    }

    if (response.statusCode == 403) {
      throw const AuthFailure(AuthErrorKind.emailUnverifiedConflict);
    }
    if (response.statusCode == 401 || response.statusCode == 422) {
      throw AuthException(_serverMessage(response));
    }
    if (response.statusCode != 200) {
      throw AuthException(AppL10n.current.errorServer(response.statusCode));
    }
    return _parseAuthResult(response);
  }

  Future<void> logout(String token) async {
    await ApiHttp.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/logout'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 10));
  }

  /// Tells the server which language the member picked (used for push
  /// notifications). Callers treat failures as non-fatal.
  Future<void> updateLocale(String token, String locale) async {
    await ApiHttp.put(
      Uri.parse('${ApiConfig.baseUrl}/auth/locale'),
      headers: {'Authorization': 'Bearer $token'},
      body: {'locale': locale},
    ).timeout(const Duration(seconds: 10));
  }

  Future<Member> me(String token) async {
    final response = await ApiHttp.get(
      Uri.parse('${ApiConfig.baseUrl}/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw AuthException(AppL10n.current.errorSessionInvalid);
    }

    return Member.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  String _serverMessage(http.Response response) {
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final message = json['message'];
      if (message is String && message.isNotEmpty) return message;
    } catch (_) {}
    return AppL10n.current.errorServer(response.statusCode);
  }

  AuthResult _parseAuthResult(http.Response response) {
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return AuthResult(
      member: Member.fromJson(json['member'] as Map<String, dynamic>),
      token: json['token'] as String,
    );
  }
}
