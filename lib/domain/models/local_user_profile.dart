class LocalUserProfile {
  const LocalUserProfile({
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.country,
    required this.language,
    this.accessToken,
    this.refreshToken,
    this.childDeviceId,
    this.deviceToken,
    this.authProvider,
    this.providerUserId,
    this.isRegistered = false,
  });

  final String email;
  final String firstName;
  final String lastName;
  final String phone;
  final String country;
  final String language;
  final String? accessToken;
  final String? refreshToken;
  final String? childDeviceId;
  final String? deviceToken;
  final String? authProvider;
  final String? providerUserId;
  final bool isRegistered;

  LocalUserProfile copyWith({
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    String? country,
    String? language,
    String? accessToken,
    String? refreshToken,
    String? childDeviceId,
    String? deviceToken,
    String? authProvider,
    String? providerUserId,
    bool? isRegistered,
  }) {
    return LocalUserProfile(
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      country: country ?? this.country,
      language: language ?? this.language,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      childDeviceId: childDeviceId ?? this.childDeviceId,
      deviceToken: deviceToken ?? this.deviceToken,
      authProvider: authProvider ?? this.authProvider,
      providerUserId: providerUserId ?? this.providerUserId,
      isRegistered: isRegistered ?? this.isRegistered,
    );
  }

  factory LocalUserProfile.fromMap(Map<String, dynamic> map) {
    return LocalUserProfile(
      email: map['email'] as String? ?? '',
      firstName: map['firstName'] as String? ?? '',
      lastName: map['lastName'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      country: map['country'] as String? ?? '',
      language: map['language'] as String? ?? 'ar',
      accessToken: map['accessToken'] as String?,
      refreshToken: map['refreshToken'] as String?,
      childDeviceId: map['childDeviceId'] as String?,
      deviceToken: map['deviceToken'] as String?,
      authProvider: map['authProvider'] as String?,
      providerUserId: map['providerUserId'] as String?,
      isRegistered: map['isRegistered'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'country': country,
      'language': language,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'childDeviceId': childDeviceId,
      'deviceToken': deviceToken,
      'authProvider': authProvider,
      'providerUserId': providerUserId,
      'isRegistered': isRegistered,
    };
  }
}
