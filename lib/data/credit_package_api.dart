import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/credit_package.dart';

class CreditPackageException implements Exception {
  final String message;
  CreditPackageException(this.message);

  @override
  String toString() => message;
}

class CreditPackageApi {
  Future<List<CreditPackage>> fetchActivePackages() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/credit-packages');

    final http.Response response;
    try {
      response = await http.get(uri).timeout(const Duration(seconds: 15));
    } catch (e) {
      throw CreditPackageException('Kredi paketleri alınamadı: $e');
    }

    if (response.statusCode != 200) {
      throw CreditPackageException(
        'Kredi paketleri alınamadı: ${response.statusCode}',
      );
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => CreditPackage.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
