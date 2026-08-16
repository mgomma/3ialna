import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/local/safe_content_policy_storage_service.dart';
import '../../data/system/safe_content_vpn_service.dart';
import '../../domain/models/safe_content_policy.dart';
import 'widgets/domain_rules_tabs.dart';
import 'widgets/protection_status_card.dart';

class SafeContentScreen extends StatefulWidget {
  const SafeContentScreen({super.key});

  @override
  State<SafeContentScreen> createState() => _SafeContentScreenState();
}

class _SafeContentScreenState extends State<SafeContentScreen> {
  final SafeContentPolicyStorageService _storage =
      SafeContentPolicyStorageService();
  final SafeContentVpnService _vpnService = SafeContentVpnService();

  SafeContentPolicy _policy = SafeContentPolicy.defaultPolicy;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _vpnPermissionGranted = false;
  bool _vpnRunning = false;
  String? _vpnError;

  bool get _isArabic => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _loadPolicy();
  }

  Future<void> _loadPolicy() async {
    final policy = await _storage.getPolicy();
    await _refreshVpnStatus(showError: false);
    if (!mounted) return;
    setState(() {
      _policy = policy;
      _isLoading = false;
    });
  }

  Future<void> _refreshVpnStatus({bool showError = true}) async {
    if (!Platform.isAndroid) return;
    try {
      final permissionGranted = await _vpnService.isPermissionGranted();
      final running = await _vpnService.isRunning();
      if (!mounted) return;
      setState(() {
        _vpnPermissionGranted = permissionGranted;
        _vpnRunning = running;
        _vpnError = null;
      });
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() {
        _vpnError = error.message ?? error.code;
      });
      if (showError) _showMessage(_vpnError!);
    }
  }

  Future<void> _savePolicy(SafeContentPolicy policy) async {
    setState(() {
      _policy = policy;
      _isSaving = true;
    });
    await _storage.savePolicy(policy);
    if (!mounted) return;
    setState(() => _isSaving = false);
  }

  Future<void> _enablePolicy() => _savePolicy(_policy.copyWith(enabled: true));

  Future<void> _grantVpnPermission() async {
    if (!Platform.isAndroid) return;
    try {
      final granted = await _vpnService.requestPermission();
      if (!granted) {
        _showMessage(_isArabic
            ? 'وافق على إذن VPN ثم اضغط تشغيل الحماية مرة أخرى.'
            : 'Approve VPN permission, then start protection again.');
        return;
      }
      await _refreshVpnStatus();
    } on PlatformException catch (error) {
      _handleVpnError(error);
    }
  }

  Future<void> _startVpn() async {
    if (!Platform.isAndroid || !_policy.enabled) return;
    try {
      if (!await _vpnService.isPermissionGranted()) {
        await _grantVpnPermission();
        if (!await _vpnService.isPermissionGranted()) return;
      }
      await _vpnService.start();
      await _refreshVpnStatus();
    } on PlatformException catch (error) {
      _handleVpnError(error);
    }
  }

  Future<void> _stopVpn() async {
    if (!Platform.isAndroid) return;
    try {
      await _vpnService.stop();
      await _refreshVpnStatus();
    } on PlatformException catch (error) {
      _handleVpnError(error);
    }
  }

  void _handleVpnError(PlatformException error) {
    if (!mounted) return;
    setState(() => _vpnError = error.message ?? error.code);
    _showMessage(_isArabic
        ? 'تعذر تشغيل الحماية. تحقق من إذن VPN ثم حاول مرة أخرى.'
        : 'Protection could not start. Check VPN permission and try again.');
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _toggleCategory(SafeContentCategory category, bool enabled) {
    final categories = {..._policy.blockedCategories};
    if (enabled) {
      categories.add(category);
    } else {
      categories.remove(category);
    }
    _savePolicy(_policy.copyWith(blockedCategories: categories));
  }

  void _addBlocked(String domain) {
    _savePolicy(_policy.copyWith(
      blockedDomains: {..._policy.blockedDomains, domain},
    ));
  }

  void _addAllowed(String domain) {
    _savePolicy(_policy.copyWith(
      allowedDomains: {..._policy.allowedDomains, domain},
    ));
  }

  void _removeBlocked(String domain) {
    _savePolicy(_policy.copyWith(
      blockedDomains: {..._policy.blockedDomains}..remove(domain),
    ));
  }

  void _removeAllowed(String domain) {
    _savePolicy(_policy.copyWith(
      allowedDomains: {..._policy.allowedDomains}..remove(domain),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isArabic ? 'المحتوى الآمن' : 'Safe Content'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Directionality(
        textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ProtectionStatusCard(
              policyEnabled: _policy.enabled,
              vpnPermissionGranted: _vpnPermissionGranted,
              vpnRunning: _vpnRunning,
              isAndroid: Platform.isAndroid,
              isArabic: _isArabic,
              errorMessage: _vpnError,
              onEnablePolicy: _enablePolicy,
              onGrantPermission: _grantVpnPermission,
              onStart: _startVpn,
              onStop: _stopVpn,
              onRetry: _refreshVpnStatus,
            ),
            const SizedBox(height: 16),
            Card(
              child: SwitchListTile(
                title: Text(_isArabic
                    ? 'تفعيل سياسة المحتوى الآمن'
                    : 'Enable safe-content policy'),
                subtitle: Text(_isArabic
                    ? 'تُطبّق الفئات وقواعد النطاقات على خدمات 3ialna المدعومة.'
                    : 'Apply categories and domain rules to supported 3ialna services.'),
                value: _policy.enabled,
                onChanged: (value) =>
                    _savePolicy(_policy.copyWith(enabled: value)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isArabic ? 'فئات الحماية' : 'Protection categories',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              _isArabic
                  ? 'اختر الفئات التي تريد حظرها. يمكنك إضافة استثناءات من خلال قواعد النطاقات.'
                  : 'Choose the categories to block. You can add exceptions through domain rules.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            ...SafeContentCategory.values.map(
              (category) => CheckboxListTile(
                title: Text(_arabicCategory(category)),
                subtitle: _isArabic ? Text(category.displayName) : null,
                value: _policy.blockedCategories.contains(category),
                onChanged: _policy.enabled
                    ? (value) => _toggleCategory(category, value ?? false)
                    : null,
              ),
            ),
            SwitchListTile(
              title: Text(_isArabic ? 'السماح بوسائل التواصل' : 'Allow social media'),
              subtitle: Text(_isArabic
                  ? 'اترك وسائل التواصل متاحة ما لم تضفها يدوياً إلى قائمة الحظر.'
                  : 'Keep social media available unless you add it to the blocked list.'),
              value: _policy.allowSocialMedia,
              onChanged: _policy.enabled
                  ? (value) =>
                      _savePolicy(_policy.copyWith(allowSocialMedia: value))
                  : null,
            ),
            const Divider(height: 32),
            DomainRulesTabs(
              blockedDomains: _policy.blockedDomains,
              allowedDomains: _policy.allowedDomains,
              isArabic: _isArabic,
              onAddBlocked: _addBlocked,
              onAddAllowed: _addAllowed,
              onRemoveBlocked: _removeBlocked,
              onRemoveAllowed: _removeAllowed,
            ),
            const SizedBox(height: 24),
            Card(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_isArabic
                    ? 'ملاحظة الخصوصية: تحفظ الحماية إعدادات القواعد فقط ولا تقرأ الرسائل أو الصور أو محتوى الصفحات. قد لا تغطي عناوين IP المباشرة أو DNS المشفر الذي يتجاوز محلل النظام.'
                    : 'Privacy note: filtering stores rule configuration only and does not read messages, photos, or page content. It may not cover direct IP access or encrypted DNS that bypasses the system resolver.'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _arabicCategory(SafeContentCategory category) {
    if (!_isArabic) return category.displayName;
    switch (category) {
      case SafeContentCategory.adult:
        return 'المحتوى للبالغين';
      case SafeContentCategory.gambling:
        return 'المقامرة';
      case SafeContentCategory.violence:
        return 'العنف';
      case SafeContentCategory.social:
        return 'وسائل التواصل الاجتماعي';
    }
  }
}
