import 'package:flutter_test/flutter_test.dart';

import 'package:mu_super_app/domain/models/safe_content_policy.dart';
import 'package:mu_super_app/domain/services/safe_content_filter.dart';

SafeContentPolicy defaultSafePolicy() => SafeContentPolicy.defaultPolicy;

void main() {
  group('SafeContentPolicy', () {
    test('normalizes URLs and subdomains to a canonical domain', () {
      expect(
        SafeContentPolicy.normalizeDomain('https://WWW.Example.com/path?q=1'),
        'example.com',
      );
      expect(
        SafeContentPolicy.normalizeDomain(' child.example.com '),
        'child.example.com',
      );
    });

    test('round-trips policy data and normalizes custom domains', () {
      final original = SafeContentPolicy(
        enabled: true,
        blockedCategories: const {
          SafeContentCategory.adult,
          SafeContentCategory.social,
        },
        blockedDomains: const {'https://Blocked.Example/path'},
        allowedDomains: const {'www.school.example'},
        allowSocialMedia: false,
      );

      final restored = SafeContentPolicy.fromMap(original.toMap());

      expect(restored, original.copyWith(
        blockedDomains: const {'blocked.example'},
        allowedDomains: const {'school.example'},
      ));
    });
  });

  group('SafeContentFilter', () {
    final filter = SafeContentFilter();

    test('blocks an explicitly blocked domain and its subdomains', () {
      final policy = defaultSafePolicy().copyWith(
        blockedDomains: const {'example.com'},
      );

      final result = filter.evaluate('https://child.example.com/path', policy);

      expect(result.isBlocked, isTrue);
      expect(result.reason, contains('explicitly blocked'));
    });

    test('explicit allowlist takes precedence over a category rule', () {
      final policy = defaultSafePolicy().copyWith(
        blockedCategories: const {SafeContentCategory.social},
        allowSocialMedia: false,
        allowedDomains: const {'instagram.com'},
      );

      final result = filter.evaluate('https://www.instagram.com', policy);

      expect(result.isBlocked, isFalse);
      expect(result.reason, contains('explicitly allowed'));
    });

    test('blocks known gambling domains when gambling is enabled', () {
      final policy = defaultSafePolicy();

      final result = filter.evaluate('bet365.com', policy);

      expect(result.isBlocked, isTrue);
      expect(result.category, SafeContentCategory.gambling);
    });

    test('allows social media when the parent explicitly permits it', () {
      final policy = defaultSafePolicy().copyWith(
        blockedCategories: const {SafeContentCategory.social},
        allowSocialMedia: true,
      );

      final result = filter.evaluate('tiktok.com', policy);

      expect(result.isBlocked, isFalse);
    });

    test('fails open for an unknown domain while preserving the policy decision', () {
      final result = filter.evaluate('https://school.example', defaultSafePolicy());

      expect(result.isBlocked, isFalse);
      expect(result.normalizedDomain, 'school.example');
    });
  });
}
