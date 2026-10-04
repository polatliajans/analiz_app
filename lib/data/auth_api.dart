import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_http.dart';

import '../config/api_config.dart';
import '../l10n/app_l10n.dart';
import '../models/member.dart';

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
  Future<AuthResult> register({
    String? name,
    required String email,
    required String password,
  }) async {
    final body = {'email': email, 'password': password};
    if (name != null) body['name'] = name;

    final response = await _post('/auth/register', body);
    return _parseAuthResult(response);
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final response = await _post('/auth/login', {
      'email': email,
      'password': password,
    });
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

  Future<http.Response> _post(String path, Map<String, String> body) async {
    final http.Response response;
    try {
      response = await ApiHttp.post(
        Uri.parse('${ApiConfig.baseUrl}$path'),
        body: body,
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      throw AuthException(AppL10n.current.errorRequestFailed('$e'));
    }

    if (response.statusCode == 422) {
      throw AuthException(AppL10n.current.errorInvalidCredentialsOrEmailTaken);
    }
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw AuthException(AppL10n.current.errorServer(response.statusCode));
    }

    return response;
  }

  AuthResult _parseAuthResult(http.Response response) {
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return AuthResult(
      member: Member.fromJson(json['member'] as Map<String, dynamic>),
      token: json['token'] as String,
    );
  }
}
