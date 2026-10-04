class OnboardingSlide {
  final int? id;
  final String title;
  final String body;
  final String? imageUrl;

  const OnboardingSlide({
    this.id,
    required this.title,
    required this.body,
    this.imageUrl,
  });

  factory OnboardingSlide.fromJson(Map<String, dynamic> json) {
    final image = json['image_url'];
    return OnboardingSlide(
      id: json['id'] as int?,
      title: json['title'] as String,
      body: json['body'] as String,
      imageUrl: image is String && image.isNotEmpty ? image : null,
    );
  }
}
