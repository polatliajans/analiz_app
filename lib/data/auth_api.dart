import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
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
  Future<AuthResult> register({String? name, required String email, required String password}) async {
    final body = {'email': email, 'password': password};
    if (name != null) body['name'] = name;

    final response = await _post('/auth/register', body);
    return _parseAuthResult(response);
  }

  Future<AuthResult> login({required String email, required String password}) async {
    final response = await _post('/auth/login', {'email': email, 'password': password});
    return _parseAuthResult(response);
  }

  Future<void> logout(String token) async {
    await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/logout'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 10));
  }

  Future<Member> me(String token) async {
    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/auth/me'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw AuthException('Oturum doğrulanamadı.');
    }

    return Member.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<http.Response> _post(String path, Map<String, String> body) async {
    final http.Response response;
    try {
      response = await http
          .post(Uri.parse('${ApiConfig.baseUrl}$path'), body: body)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      throw AuthException('İstek gönderilemedi: $e');
    }

    if (response.statusCode == 422) {
      throw AuthException('Bilgiler hatalı veya bu e-posta zaten kayıtlı.');
    }
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw AuthException('Sunucu hatası: ${response.statusCode}');
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
