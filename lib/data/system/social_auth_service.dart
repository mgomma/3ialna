import 'dart:io';

import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
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

  Future<SocialAuthProfile?> signInWithFacebook() async {
    final LoginResult loginResult = await FacebookAuth.instance.login(
      permissions: <String>['email', 'public_profile'],
    );

    if (loginResult.status != LoginStatus.success) {
      return null;
    }

    final Map<String, dynamic> userData = await FacebookAuth.instance.getUserData(
      fields: 'id,email,first_name,last_name,name',
    );

    final String fullName = (userData['name'] as String? ?? '').trim();
    final List<String> parts = fullName.split(' ').where((String e) => e.isNotEmpty).toList();

    final String firstName = (userData['first_name'] as String?) ?? (parts.isNotEmpty ? parts.first : 'User');
    final String lastName = (userData['last_name'] as String?) ?? (parts.length > 1 ? parts.sublist(1).join(' ') : '');

    return SocialAuthProfile(
      provider: 'facebook',
      providerUserId: (userData['id'] as String?) ?? '',
      email: (userData['email'] as String?) ?? '',
      firstName: firstName,
      lastName: lastName,
      accessToken: loginResult.accessToken?.tokenString,
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
