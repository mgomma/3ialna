import 'package:flutter/material.dart';

class ProtectionStatusCard extends StatelessWidget {
  final bool policyEnabled;
  final bool vpnPermissionGranted;
  final bool vpnRunning;
  final bool isAndroid;
  final bool isArabic;
  final VoidCallback? onEnablePolicy;
  final VoidCallback? onGrantPermission;
  final VoidCallback? onStart;
  final VoidCallback? onStop;
  final VoidCallback? onRetry;
  final String? errorMessage;

  const ProtectionStatusCard({
    super.key,
    required this.policyEnabled,
    required this.vpnPermissionGranted,
    required this.vpnRunning,
    required this.isAndroid,
    required this.isArabic,
    this.onEnablePolicy,
    this.onGrantPermission,
    this.onStart,
    this.onStop,
    this.onRetry,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final state = _state;
    final theme = Theme.of(context);
    final color = switch (state) {
      _ProtectionState.protected => Colors.green,
      _ProtectionState.policyDisabled => theme.colorScheme.outline,
      _ProtectionState.permissionRequired => Colors.orange,
      _ProtectionState.stopped => Colors.orange,
      _ProtectionState.unsupported => theme.colorScheme.outline,
      _ProtectionState.error => theme.colorScheme.error,
    };

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.14),
                    foregroundColor: color,
                    child: Icon(_icon),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _title,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(_description, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  if (state == _ProtectionState.protected)
                    Switch(value: true, onChanged: (_) => onStop?.call())
                ],
              ),
              if (state != _ProtectionState.protected) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _primaryAction,
                    icon: Icon(_primaryIcon),
                    label: Text(_primaryLabel),
                  ),
                ),
              ],
              if (errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  errorMessage!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  _ProtectionState get _state {
    if (!isAndroid) return _ProtectionState.unsupported;
    if (errorMessage != null) return _ProtectionState.error;
    if (!policyEnabled) return _ProtectionState.policyDisabled;
    if (!vpnPermissionGranted) return _ProtectionState.permissionRequired;
    if (!vpnRunning) return _ProtectionState.stopped;
    return _ProtectionState.protected;
  }

  IconData get _icon {
    switch (_state) {
      case _ProtectionState.protected:
        return Icons.verified_user;
      case _ProtectionState.policyDisabled:
        return Icons.shield_outlined;
      case _ProtectionState.permissionRequired:
        return Icons.vpn_key_outlined;
      case _ProtectionState.stopped:
        return Icons.vpn_lock;
      case _ProtectionState.unsupported:
        return Icons.info_outline;
      case _ProtectionState.error:
        return Icons.error_outline;
    }
  }

  String get _title {
    if (!isArabic) {
      switch (_state) {
        case _ProtectionState.protected: return 'Protection is active';
        case _ProtectionState.policyDisabled: return 'Safe-content policy is off';
        case _ProtectionState.permissionRequired: return 'VPN permission required';
        case _ProtectionState.stopped: return 'Protection is disconnected';
        case _ProtectionState.unsupported: return 'Not available on this device';
        case _ProtectionState.error: return 'Protection could not start';
      }
    }
    switch (_state) {
      case _ProtectionState.protected: return 'الحماية مفعّلة';
      case _ProtectionState.policyDisabled: return 'سياسة المحتوى الآمن متوقفة';
      case _ProtectionState.permissionRequired: return 'يلزم السماح باتصال VPN';
      case _ProtectionState.stopped: return 'الحماية غير متصلة';
      case _ProtectionState.unsupported: return 'غير متاح على هذا الجهاز';
      case _ProtectionState.error: return 'تعذر تشغيل الحماية';
    }
  }

  String get _description {
    if (!isArabic) {
      switch (_state) {
        case _ProtectionState.protected: return 'Domain filtering is active for supported DNS traffic.';
        case _ProtectionState.policyDisabled: return 'Enable the safe-content policy before starting device filtering.';
        case _ProtectionState.permissionRequired: return '3ialna needs Android VPN permission to apply domain rules.';
        case _ProtectionState.stopped: return 'The policy is enabled, but device filtering is stopped.';
        case _ProtectionState.unsupported: return 'VPN filtering is currently available on Android only.';
        case _ProtectionState.error: return 'Check VPN permission and try again.';
      }
    }
    switch (_state) {
      case _ProtectionState.protected: return 'يعمل فلتر النطاقات على حركة DNS المدعومة.';
      case _ProtectionState.policyDisabled: return 'فعّل السياسة أولاً لتطبيق قواعد النطاقات على الجهاز.';
      case _ProtectionState.permissionRequired: return 'يحتاج 3ialna إلى إذن VPN لتطبيق قواعد النطاقات.';
      case _ProtectionState.stopped: return 'السياسة مفعّلة، لكن فلتر الجهاز متوقف.';
      case _ProtectionState.unsupported: return 'فلترة VPN متاحة حالياً على Android فقط.';
      case _ProtectionState.error: return 'تحقق من إذن VPN ثم حاول مرة أخرى.';
    }
  }

  String get _primaryLabel {
    if (!isArabic) {
      switch (_state) {
        case _ProtectionState.policyDisabled: return 'Enable policy';
        case _ProtectionState.permissionRequired: return 'Grant permission';
        case _ProtectionState.stopped: return 'Start protection';
        case _ProtectionState.error: return 'Retry';
        case _ProtectionState.protected: return 'Stop protection';
        case _ProtectionState.unsupported: return 'Learn more';
      }
    }
    switch (_state) {
      case _ProtectionState.policyDisabled: return 'تفعيل السياسة';
      case _ProtectionState.permissionRequired: return 'منح الإذن';
      case _ProtectionState.stopped: return 'تشغيل الحماية';
      case _ProtectionState.error: return 'إعادة المحاولة';
      case _ProtectionState.protected: return 'إيقاف الحماية';
      case _ProtectionState.unsupported: return 'معرفة المزيد';
    }
  }

  IconData get _primaryIcon {
    switch (_state) {
      case _ProtectionState.permissionRequired: return Icons.vpn_key;
      case _ProtectionState.stopped: return Icons.play_arrow;
      case _ProtectionState.policyDisabled: return Icons.shield;
      case _ProtectionState.error: return Icons.refresh;
      case _ProtectionState.protected: return Icons.stop;
      case _ProtectionState.unsupported: return Icons.info_outline;
    }
  }

  VoidCallback? get _primaryAction {
    switch (_state) {
      case _ProtectionState.policyDisabled: return onEnablePolicy;
      case _ProtectionState.permissionRequired: return onGrantPermission;
      case _ProtectionState.stopped: return onStart;
      case _ProtectionState.error: return onRetry;
      case _ProtectionState.protected: return onStop;
      case _ProtectionState.unsupported: return null;
    }
  }
}

enum _ProtectionState { protected, policyDisabled, permissionRequired, stopped, unsupported, error }
