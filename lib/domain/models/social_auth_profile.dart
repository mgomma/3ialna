class SocialAuthProfile {
  const SocialAuthProfile({
    required this.provider,
    required this.providerUserId,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.accessToken,
    this.idToken,
    this.authorizationCode,
  });

  final String provider;
  final String providerUserId;
  final String email;
  final String firstName;
  final String lastName;
  final String? accessToken;
  final String? idToken;
  final String? authorizationCode;
}
