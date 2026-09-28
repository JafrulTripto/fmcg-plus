class UserModel {
  final String id;
  final String phone;
  final String name;
  final String? nameBn;
  final String role;
  final bool isActive;
  final bool phoneVerified;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.phone,
    required this.name,
    this.nameBn,
    this.role = 'customer',
    this.isActive = true,
    this.phoneVerified = false,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nameBn: json['name_bn'] as String?,
      role: json['role'] as String? ?? 'customer',
      isActive: json['is_active'] as bool? ?? true,
      phoneVerified: json['phone_verified'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'name': name,
      'name_bn': nameBn,
      'role': role,
      'is_active': isActive,
      'phone_verified': phoneVerified,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class StoreModel {
  final String id;
  final String name;
  final String ownerName;
  final String ownerPhone;
  final String? address;

  const StoreModel({
    required this.id,
    required this.name,
    required this.ownerName,
    required this.ownerPhone,
    this.address,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      ownerName: json['owner_name'] as String? ?? '',
      ownerPhone: json['owner_phone'] as String? ?? '',
      address: json['address'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'owner_name': ownerName,
      'owner_phone': ownerPhone,
      'address': address,
    };
  }
}

class AuthSession {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final String tokenType;
  final UserModel user;
  final StoreModel? store;
  final String? memberRole;

  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    this.tokenType = 'Bearer',
    required this.user,
    this.store,
    this.memberRole,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['access_token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String? ?? '',
      expiresIn: (json['expires_in'] as num?)?.toInt() ?? 3600,
      tokenType: json['token_type'] as String? ?? 'Bearer',
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
      store: json['store'] != null ? StoreModel.fromJson(json['store'] as Map<String, dynamic>) : null,
      memberRole: json['member_role'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_in': expiresIn,
      'token_type': tokenType,
      'user': user.toJson(),
      'store': store?.toJson(),
      'member_role': memberRole,
    };
  }
}

class SendOtpResult {
  final String? sessionId;
  final String provider;
  final String message;
  final bool isAlreadyRegistered;

  const SendOtpResult({
    this.sessionId,
    required this.provider,
    required this.message,
    this.isAlreadyRegistered = false,
  });

  factory SendOtpResult.fromJson(Map<String, dynamic> json) {
    return SendOtpResult(
      sessionId: json['session_id'] as String?,
      provider: json['provider'] as String? ?? 'mock',
      message: json['message'] as String? ?? '',
      isAlreadyRegistered: json['registered'] as bool? ?? (json['code'] == 'ALREADY_REGISTERED'),
    );
  }
}

class CheckPhoneResult {
  final bool registered;
  final String phone;
  final String? role;
  final String? name;
  final String? storeName;
  final String message;

  const CheckPhoneResult({
    required this.registered,
    required this.phone,
    this.role,
    this.name,
    this.storeName,
    required this.message,
  });

  factory CheckPhoneResult.fromJson(Map<String, dynamic> json) {
    return CheckPhoneResult(
      registered: json['registered'] as bool? ?? false,
      phone: json['phone'] as String? ?? '',
      role: json['role'] as String?,
      name: json['name'] as String?,
      storeName: json['store_name'] as String?,
      message: json['message'] as String? ?? '',
    );
  }
}

class VerifyOtpResult {
  final bool verified;
  final String phone;
  final String verificationToken;
  final String message;

  const VerifyOtpResult({
    required this.verified,
    required this.phone,
    required this.verificationToken,
    required this.message,
  });

  factory VerifyOtpResult.fromJson(Map<String, dynamic> json) {
    return VerifyOtpResult(
      verified: json['verified'] as bool? ?? false,
      phone: json['phone'] as String? ?? '',
      verificationToken: json['verification_token'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }
}
