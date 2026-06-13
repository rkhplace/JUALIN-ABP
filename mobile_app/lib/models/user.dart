import '../utils/image_url_helper.dart';

class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final String avatarUrl;
  final double walletBalance;
  final String bio;
  final String gender;
  final String birthday;
  final String region;
  final String city;
  final String phone;
  final String status;
  final String verificationStatus;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'customer',
    this.avatarUrl = '',
    this.walletBalance = 0.0,
    this.bio = '',
    this.gender = '',
    this.birthday = '',
    this.region = '',
    this.city = '',
    this.phone = '',
    this.status = 'active',
    this.verificationStatus = '',
  });

  /// Handles both the /me response (flat object) and the /login data object.
  /// API fields: id, username (or name), email, role, profile_picture, wallet_balance
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: _parseInt(json['id']),
      // /me returns 'username'; /login data also has 'username'
      name: json['username']?.toString() ?? json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'customer',
      avatarUrl: ImageUrlHelper.resolve(
        json['profile_picture'] ?? json['avatar_url'] ?? json['avatar'],
      ),
      walletBalance: json['wallet_balance'] != null
          ? double.tryParse(json['wallet_balance'].toString()) ?? 0.0
          : 0.0,
      bio: json['bio']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      birthday: _dateOnly(json['birthday']),
      region: json['region']?.toString() ??
          json['address']?.toString() ??
          json['location']?.toString() ??
          '',
      city: json['city']?.toString() ?? '',
      phone: json['phone']?.toString() ??
          json['phone_number']?.toString() ??
          json['no_hp']?.toString() ??
          '',
      status: json['status']?.toString() ?? 'active',
      verificationStatus: json['verification_status']?.toString() ??
          json['seller_verification_status']?.toString() ??
          (json['seller_verified'] == true || json['is_verified'] == true
              ? 'verified'
              : ''),
    );
  }

  static String _dateOnly(dynamic value) {
    if (value == null) return '';
    return value.toString().split('T').first;
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': name,
        'email': email,
        'role': role,
        'profile_picture': avatarUrl,
        'wallet_balance': walletBalance,
        'bio': bio,
        'gender': gender,
        'birthday': birthday,
        'region': region,
        'city': city,
        'phone': phone,
        'status': status,
        'verification_status': verificationStatus,
      };
}
