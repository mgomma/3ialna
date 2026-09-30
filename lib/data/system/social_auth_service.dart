import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../domain/models/social_auth_profile.dart';

class SocialAuthService {
  SocialAuthService({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: <String>['email']);

  final GoogleSignIn _googleSignIn;

  Future<SocialAuthProfile?> signInWithGoogle() async {
    final GoogleSignInAccount? account = await _googleSignIn.signIn();
    if (account == null) {
      return null;
    }
    final GoogleSignInAuthentication auth = await account.authentication;

    final List<String> parts = account.displayName?.trim().split(' ') ?? <String>[];
    final String firstName = parts.isNotEmpty ? parts.first : 'User';
    final String lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    return SocialAuthProfile(
      provider: 'google',
      providerUserId: account.id,
      email: account.email,
      firstName: firstName,
      lastName: lastName,
      accessToken: auth.accessToken,
      idToken: auth.idToken,
    );
  }

  Future<SocialAuthProfile?> signInWithApple() async {
    if (!Platform.isIOS) {
      return null;
    }

    final AuthorizationCredentialAppleID credential =
        await SignInWithApple.getAppleIDCredential(
      scopes: <AppleIDAuthorizationScopes>[
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final String firstName = credential.givenName?.trim().isNotEmpty == true
        ? credential.givenName!.trim()
        : 'User';
    final String lastName = credential.familyName?.trim() ?? '';

    return SocialAuthProfile(
      provider: 'apple',
      providerUserId: credential.userIdentifier ?? '',
      email: credential.email ?? '',
      firstName: firstName,
      lastName: lastName,
      idToken: credential.identityToken,
      authorizationCode: credential.authorizationCode,
    );
  }
}
