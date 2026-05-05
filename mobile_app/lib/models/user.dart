class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final String avatarUrl;
  final double walletBalance;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'customer',
    this.avatarUrl = '',
    this.walletBalance = 0.0,
  });

  /// Handles both the /me response (flat object) and the /login data object.
  /// API fields: id, username (or name), email, role, profile_picture, wallet_balance
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      // /me returns 'username'; /login data also has 'username'
      name: json['username']?.toString() ??
          json['name']?.toString() ??
          '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'customer',
      avatarUrl: json['profile_picture']?.toString() ??
          json['avatar_url']?.toString() ??
          json['avatar']?.toString() ??
          '',
      walletBalance: json['wallet_balance'] != null
          ? double.tryParse(json['wallet_balance'].toString()) ?? 0.0
          : 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': name,
        'email': email,
        'role': role,
        'profile_picture': avatarUrl,
        'wallet_balance': walletBalance,
      };
}
