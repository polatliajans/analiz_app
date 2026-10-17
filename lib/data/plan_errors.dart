import 'dart:convert';

import 'package:http/http.dart' as http;

import '../l10n/app_l10n.dart';

/// Server refused the request because the feature needs a Pro plan
/// (403 `{code: "pro_required"}`).
class ProRequiredException implements Exception {
  @override
  String toString() => AppL10n.current.errorProOnly;
}

/// The `code` field of a JSON error body, or null when absent/unparseable.
String? errorCodeOf(http.Response response) {
  try {
    final json = jsonDecode(response.body);
    if (json is Map<String, dynamic>) return json['code'] as String?;
  } catch (_) {}
  return null;
}

bool isProRequired(http.Response response) =>
    response.statusCode == 403 && errorCodeOf(response) == 'pro_required';
