import 'dart:convert';

import '../config/api_config.dart';
import '../models/onboarding_slide.dart';
import 'api_http.dart';

class OnboardingApi {
  /// Throws on any failure; the provider turns that into the built-in slides.
  Future<List<OnboardingSlide>> fetch() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/onboarding');
    final response = await ApiHttp.get(uri).timeout(const Duration(seconds: 4));

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((e) => OnboardingSlide.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
