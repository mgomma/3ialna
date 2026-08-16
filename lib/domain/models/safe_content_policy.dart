import 'package:flutter/foundation.dart';

enum SafeContentCategory {
  adult,
  gambling,
  violence,
  social,
}

extension SafeContentCategoryLabel on SafeContentCategory {
  String get storageKey => name;

  String get displayName {
    switch (this) {
      case SafeContentCategory.adult:
        return 'Adult content';
      case SafeContentCategory.gambling:
        return 'Gambling';
      case SafeContentCategory.violence:
        return 'Violence';
      case SafeContentCategory.social:
        return 'Social media';
    }
  }
}

@immutable
class SafeContentPolicy {
  static const SafeContentPolicy defaultPolicy = SafeContentPolicy(
    enabled: true,
    blockedCategories: {
      SafeContentCategory.adult,
      SafeContentCategory.gambling,
    },
    blockedDomains: <String>{},
    allowedDomains: <String>{},
    allowSocialMedia: true,
  );

  final bool enabled;
  final Set<SafeContentCategory> blockedCategories;
  final Set<String> blockedDomains;
  final Set<String> allowedDomains;
  final bool allowSocialMedia;

  const SafeContentPolicy({
    required this.enabled,
    required this.blockedCategories,
    required this.blockedDomains,
    required this.allowedDomains,
    required this.allowSocialMedia,
  });

  SafeContentPolicy copyWith({
    bool? enabled,
    Set<SafeContentCategory>? blockedCategories,
    Set<String>? blockedDomains,
    Set<String>? allowedDomains,
    bool? allowSocialMedia,
  }) {
    return SafeContentPolicy(
      enabled: enabled ?? this.enabled,
      blockedCategories: blockedCategories ?? this.blockedCategories,
      blockedDomains: blockedDomains ?? this.blockedDomains,
      allowedDomains: allowedDomains ?? this.allowedDomains,
      allowSocialMedia: allowSocialMedia ?? this.allowSocialMedia,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'blockedCategories': blockedCategories.map((item) => item.storageKey).toList()..sort(),
      'blockedDomains': blockedDomains.toList()..sort(),
      'allowedDomains': allowedDomains.toList()..sort(),
      'allowSocialMedia': allowSocialMedia,
    };
  }

  factory SafeContentPolicy.fromMap(Map<String, dynamic> map) {
    final rawCategories = map['blockedCategories'];
    final categories = <SafeContentCategory>{};
    if (rawCategories is List) {
      for (final raw in rawCategories) {
        final value = raw.toString();
        for (final category in SafeContentCategory.values) {
          if (category.storageKey == value) categories.add(category);
        }
      }
    }

    Set<String> readDomains(Object? value) {
      if (value is! List) return <String>{};
      return value
          .map((item) => normalizeDomain(item.toString()))
          .where((item) => item.isNotEmpty)
          .toSet();
    }

    return SafeContentPolicy(
      enabled: map['enabled'] is bool ? map['enabled'] as bool : true,
      blockedCategories: categories,
      blockedDomains: readDomains(map['blockedDomains']),
      allowedDomains: readDomains(map['allowedDomains']),
      allowSocialMedia: map['allowSocialMedia'] is bool
          ? map['allowSocialMedia'] as bool
          : true,
    );
  }

  static String normalizeDomain(String value) {
    var domain = value.trim().toLowerCase();
    domain = domain.replaceFirst(RegExp(r'^https?://'), '');
    domain = domain.split('/').first;
    domain = domain.split('?').first;
    domain = domain.split('#').first;
    if (domain.startsWith('www.')) domain = domain.substring(4);
    return domain;
  }

  @override
  bool operator ==(Object other) {
    return other is SafeContentPolicy &&
        other.enabled == enabled &&
        other.allowSocialMedia == allowSocialMedia &&
        setEquals(other.blockedCategories, blockedCategories) &&
        setEquals(other.blockedDomains, blockedDomains) &&
        setEquals(other.allowedDomains, allowedDomains);
  }

  @override
  int get hashCode => Object.hash(
        enabled,
        allowSocialMedia,
        Object.hashAll(blockedCategories),
        Object.hashAll(blockedDomains),
        Object.hashAll(allowedDomains),
      );
}
