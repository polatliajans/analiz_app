class Member {
  final int id;
  final String? name;
  final String email;
  final String role;
  final int creditBalance;

  const Member({
    required this.id,
    this.name,
    required this.email,
    required this.role,
    required this.creditBalance,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] as int,
      name: json['name'] as String?,
      email: json['email'] as String,
      role: json['role'] as String,
      creditBalance: json['credit_balance'] as int,
    );
  }
}
