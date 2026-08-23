import 'package:flutter/material.dart';

import '../../data/system/safe_content_ios_service.dart';
import '../../data/system/ios_screen_time_safeguard_service.dart';

class IosAuthorizationOnboardingScreen extends StatefulWidget {
  const IosAuthorizationOnboardingScreen({super.key});

  @override
  State<IosAuthorizationOnboardingScreen> createState() => _IosAuthorizationOnboardingScreenState();
}

class _IosAuthorizationOnboardingScreenState extends State<IosAuthorizationOnboardingScreen> {
  final SafeContentIosService _service = SafeContentIosService();
  final IosScreenTimeSafeguardService _safeguards = IosScreenTimeSafeguardService();
  bool _loading = true;
  bool _authorized = false;
  bool _networkConfigured = false;
  bool _safeguardSelectionConfigured = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final authorized = await _service.isAuthorizationGranted();
      final running = await _service.isWebProtectionRunning();
      final selectionConfigured = authorized && await _safeguards.isSelectionConfigured();
      if (!mounted) return;
      setState(() {
        _authorized = authorized;
        _networkConfigured = running;
        _safeguardSelectionConfigured = selectionConfigured;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'تعذر التحقق من حالة الحماية';
      });
    }
  }

  Future<void> _requestAuthorization() async {
    setState(() => _loading = true);
    try {
      final authorized = await _service.requestAuthorization();
      if (!mounted) return;
      setState(() {
        _authorized = authorized;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'تعذر الحصول على إذن الرقابة. تحقق من إعدادات Screen Time أو حاول مرة أخرى.';
      });
    }
  }

  Future<void> _requestNetworkPermission() async {
    setState(() => _loading = true);
    try {
      await _service.requestNetworkPermission();
      await _service.startWebProtection();
      await _refresh();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'تعذر إعداد حماية DNS. تحتاج هذه الخطوة إلى Network Extension معتمدة من Apple.';
      });
    }
  }

  Future<void> _selectSafeguardApps() async {
    setState(() => _loading = true);
    try {
      await _safeguards.selectAppsAndCategories();
      await _refresh();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'تعذر حفظ التطبيقات والفئات التي تريد حمايتها.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _authorized && _networkConfigured;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('حماية رقمية مناسبة لعائلتك')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              active ? 'الحماية مفعّلة' : (_authorized ? 'تم منح إذن الرقابة' : 'لم تكتمل الحماية بعد'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              active
                  ? 'تم منح الإذن، وتعمل طبقة الحماية المحددة على الجهاز.'
                  : (_authorized
                      ? 'إذن Screen Time متاح، لكن حماية الويب تحتاج إلى Network Extension مفعّلة.'
                      : 'يحتاج 3ialna إلى إذن الرقابة حتى يطبق القيود التي تختارها أنت.'),
            ),
            const SizedBox(height: 24),
            _StepRow(
              number: '١',
              title: 'لماذا نحتاج الإذن؟',
              detail: 'لا نقرأ الرسائل أو الصور، ولا نعرض محتوى الصفحات داخل لوحة الوالد.',
              completed: _authorized,
            ),
            _StepRow(
              number: '٢',
              title: 'منح إذن الرقابة',
              detail: 'سيظهر طلب من Apple. اختر السماح لتطبيق سياسة العائلة.',
              completed: _authorized,
            ),
            _StepRow(
              number: '٣',
              title: 'اختيار التطبيقات والفئات للحماية',
              detail: 'تستخدم قيود النوم والصلاة شاشة Apple لحماية التطبيقات أو الفئات التي تختارها أنت.',
              completed: _safeguardSelectionConfigured,
            ),
            _StepRow(
              number: '٤',
              title: 'حماية النطاقات',
              detail: 'طبّق سياسة النطاقات المحظورة والمسموح بها على مسار الويب المدعوم.',
              completed: _networkConfigured,
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 24),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (!_authorized)
              FilledButton(onPressed: _requestAuthorization, child: const Text('منح الإذن'))
            else if (!_safeguardSelectionConfigured)
              FilledButton(onPressed: _selectSafeguardApps, child: const Text('اختيار التطبيقات والفئات'))
            else if (!_networkConfigured)
              FilledButton(onPressed: _requestNetworkPermission, child: const Text('إعداد حماية الويب'))
            else
              OutlinedButton(onPressed: _refresh, child: const Text('مراجعة السياسة')),
            TextButton(onPressed: () => Navigator.of(context).maybePop(), child: const Text('لاحقاً')),
          ],
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.number, required this.title, required this.detail, required this.completed});

  final String number;
  final String title;
  final String detail;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(child: Text(completed ? '✓' : number)),
      title: Text(title),
      subtitle: Text(detail),
    );
  }
}
