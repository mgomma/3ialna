import '../models/safe_content_policy.dart';

enum SafeContentDecision { allow, block }

class SafeContentCheck {
  final SafeContentDecision decision;
  final SafeContentCategory? category;
  final String normalizedDomain;
  final String reason;

  const SafeContentCheck({
    required this.decision,
    required this.normalizedDomain,
    required this.reason,
    this.category,
  });

  bool get isBlocked => decision == SafeContentDecision.block;
}

/// Deterministic policy evaluator for domains.
///
/// This service is deliberately platform-neutral. Android VPN/browser
/// enforcement can call it later without duplicating policy rules. It does
/// not inspect page content or claim to replace a web reputation provider.
class SafeContentFilter {
  static const Map<SafeContentCategory, Set<String>> _knownDomains = {
    SafeContentCategory.social: {
      'facebook.com',
      'instagram.com',
      'snapchat.com',
      'tiktok.com',
      'x.com',
      'twitter.com',
    },
    SafeContentCategory.gambling: {
      'bet365.com',
      'betway.com',
      'draftkings.com',
    },
    SafeContentCategory.adult: {
      'pornhub.com',
      'xvideos.com',
      'xhamster.com',
    },
    SafeContentCategory.violence: {
      'example-violence.invalid',
    },
  };

  SafeContentCheck evaluate(String urlOrDomain, SafeContentPolicy policy) {
    final domain = SafeContentPolicy.normalizeDomain(urlOrDomain);
    if (domain.isEmpty) {
      return const SafeContentCheck(
        decision: SafeContentDecision.allow,
        normalizedDomain: '',
        reason: 'The domain could not be normalized.',
      );
    }

    if (!policy.enabled) {
      return SafeContentCheck(
        decision: SafeContentDecision.allow,
        normalizedDomain: domain,
        reason: 'Safe-content policy is disabled.',
      );
    }

    if (_matchesDomain(domain, policy.allowedDomains)) {
      return SafeContentCheck(
        decision: SafeContentDecision.allow,
        normalizedDomain: domain,
        reason: 'Domain is explicitly allowed by the parent.',
      );
    }

    if (_matchesDomain(domain, policy.blockedDomains)) {
      return SafeContentCheck(
        decision: SafeContentDecision.block,
        normalizedDomain: domain,
        reason: 'Domain is explicitly blocked by the parent.',
      );
    }

    for (final category in policy.blockedCategories) {
      if (category == SafeContentCategory.social && policy.allowSocialMedia) {
        continue;
      }
      final domains = _knownDomains[category] ?? const <String>{};
      if (_matchesDomain(domain, domains)) {
        return SafeContentCheck(
          decision: SafeContentDecision.block,
          normalizedDomain: domain,
          category: category,
          reason: '${category.displayName} is blocked by the active policy.',
        );
      }
    }

    return SafeContentCheck(
      decision: SafeContentDecision.allow,
      normalizedDomain: domain,
      reason: 'No active rule matched this domain.',
    );
  }

  bool _matchesDomain(String domain, Iterable<String> candidates) {
    return candidates.any((candidate) {
      final normalized = SafeContentPolicy.normalizeDomain(candidate);
      return domain == normalized || domain.endsWith('.$normalized');
    });
  }
}
