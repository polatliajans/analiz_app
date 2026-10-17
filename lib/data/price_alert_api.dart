import 'dart:convert';

import '../config/api_config.dart';
import '../l10n/app_localizations.dart';
import '../models/price_alert.dart';
import '../utils/price_alert_logic.dart';
import 'api_http.dart';

enum PriceAlertErrorKind {
  proRequired,
  limitReached,
  duplicate,
  unauthorized,
  other,
}

PriceAlertErrorKind priceAlertErrorKindFromCode(String? code) {
  switch (code) {
    case 'pro_required':
      return PriceAlertErrorKind.proRequired;
    case 'alert_limit_reached':
      return PriceAlertErrorKind.limitReached;
    case 'alert_duplicate':
      return PriceAlertErrorKind.duplicate;
    default:
      return PriceAlertErrorKind.other;
  }
}

class PriceAlertException implements Exception {
  final PriceAlertErrorKind kind;
  final int? statusCode;
  final int? limit;
  final String? serverMessage;

  const PriceAlertException(
    this.kind, {
    this.statusCode,
    this.limit,
    this.serverMessage,
  });

  /// Builds the exception for a non-success API response.
  factory PriceAlertException.fromResponse(int status, String body) {
    String? code;
    String? message;
    int? limit;
    try {
      final json = jsonDecode(body);
      if (json is Map<String, dynamic>) {
        code = json['code'] as String?;
        message = json['message'] as String?;
        limit = (json['limit'] as num?)?.toInt();
      }
    } catch (_) {}
    var kind = priceAlertErrorKindFromCode(code);
    if (kind == PriceAlertErrorKind.other && status == 401) {
      kind = PriceAlertErrorKind.unauthorized;
    }
    return PriceAlertException(
      kind,
      statusCode: status,
      limit: limit,
      serverMessage: message,
    );
  }

  @override
  String toString() => 'PriceAlertException($kind, $statusCode)';
}

/// Localized, user-facing text for any error thrown by an alert action.
String priceAlertErrorText(AppLocalizations l10n, Object error) {
  if (error is PriceAlertException) {
    switch (error.kind) {
      case PriceAlertErrorKind.proRequired:
        return l10n.alertErrorProRequired;
      case PriceAlertErrorKind.limitReached:
        return l10n.alertErrorLimitReached(error.limit ?? 20);
      case PriceAlertErrorKind.duplicate:
        return l10n.alertErrorDuplicate;
      case PriceAlertErrorKind.unauthorized:
        return l10n.mustLogIn;
      case PriceAlertErrorKind.other:
        final status = error.statusCode;
        return status == null
            ? l10n.alertErrorGeneric
            : l10n.errorServer(status);
    }
  }
  return l10n.alertErrorGeneric;
}

class PriceAlertApi {
  Map<String, String> _auth(String token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  Future<PriceAlertList> fetchAlerts(String token) async {
    final response = await ApiHttp.get(
      Uri.parse('${ApiConfig.baseUrl}/alerts'),
      headers: _auth(token),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw PriceAlertException.fromResponse(
        response.statusCode,
        response.body,
      );
    }
    return PriceAlertList.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<PriceAlert> create(
    String token, {
    required int coinId,
    required double targetPrice,
    required AlertDirection direction,
  }) async {
    final response = await ApiHttp.post(
      Uri.parse('${ApiConfig.baseUrl}/alerts'),
      headers: _auth(token),
      body: {
        'coin_id': '$coinId',
        'target_price': formatAlertPrice(targetPrice),
        'direction': direction.apiValue,
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw PriceAlertException.fromResponse(
        response.statusCode,
        response.body,
      );
    }
    return PriceAlert.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> cancel(String token, int alertId) async {
    final response = await ApiHttp.delete(
      Uri.parse('${ApiConfig.baseUrl}/alerts/$alertId'),
      headers: _auth(token),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw PriceAlertException.fromResponse(
        response.statusCode,
        response.body,
      );
    }
  }
}
