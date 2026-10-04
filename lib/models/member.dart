class Member {
  final int id;
  final String? name;
  final String email;
  final String role;
  final int creditBalance;
  final bool emailVerified;
  final String? locale;

  const Member({
    required this.id,
    this.name,
    required this.email,
    required this.role,
    required this.creditBalance,
    this.emailVerified = true,
    this.locale,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] as int,
      name: json['name'] as String?,
      email: json['email'] as String,
      role: json['role'] as String,
      creditBalance: json['credit_balance'] as int,
      emailVerified: json['email_verified'] as bool? ?? true,
      locale: json['locale'] as String?,
    );
  }
}
