import 'package:flutter/material.dart';

import '../../data/local/locale_controller.dart';

class FeatureWalkthroughScreen extends StatefulWidget {
  const FeatureWalkthroughScreen({
    super.key,
    required this.onCompleted,
    this.onOpenProfileSetup,
  });

  final Future<void> Function() onCompleted;
  final Future<void> Function()? onOpenProfileSetup;

  @override
  State<FeatureWalkthroughScreen> createState() =>
      _FeatureWalkthroughScreenState();
}

class _FeatureWalkthroughScreenState extends State<FeatureWalkthroughScreen> {
  final PageController _controller = PageController();
  int _page = 0;
  bool _finishing = false;
  int _demoChildren = 1;
  String _demoActiveUser = 'Noor';
  bool _demoParentMode = false;

  bool get _ar => LocaleController.instance.isArabic;

  late final List<_WalkthroughPage> _pages = <_WalkthroughPage>[
    _WalkthroughPage(
      icon: Icons.family_restroom_outlined,
      color: Colors.teal,
      title: _ar ? 'عائلتك أولاً' : 'Your family, first',
      body: _ar
          ? 'يمكن لأسرة واحدة مشاركة جهاز واحد. لكل طفل ملف مستقل وحدود عمرية وسجل استخدام محلي خاص به.'
          : 'One family can share one device. Every child keeps a separate profile, age-based limits, and local usage history.',
    ),
    _WalkthroughPage(
      icon: Icons.person_add_alt_1_outlined,
      color: Colors.indigo,
      title: _ar ? 'أضف الأطفال' : 'Add the children',
      body: _ar
          ? 'أضف اسم الطفل وتاريخ ميلاده، ثم ابدأ بالملف العمري المقترح. يمكنك تعديل إعدادات كل طفل لاحقًا.'
          : 'Add a child’s name and birth date, then start with the recommended age profile. You can adjust every child’s settings later.',
    ),
    _WalkthroughPage(
      icon: Icons.switch_account_outlined,
      color: Colors.deepOrange,
      title: _ar
          ? 'اختر من يستخدم الجهاز الآن'
          : 'Choose who is using it now',
      body: _ar
          ? 'عند تسليم الجهاز، اختر الطفل النشط. تبدأ ميزانية ذلك الطفل وحدها ويظل سجل كل طفل منفصلًا.'
          : 'When handing over the device, choose the active child. Only that child’s budget applies and each history remains separate.',
    ),
    _WalkthroughPage(
      icon: Icons.admin_panel_settings_outlined,
      color: Colors.purple,
      title: _ar ? 'وضع الوالد محمي' : 'Parent mode is protected',
      body: _ar
          ? 'عند استلام الوالد للجهاز، يتطلب الوضع غير المقيد رمز PIN أو البصمة. لا تُخلط استخدامات الوالد بسجل الأطفال.'
          : 'When a parent takes the device back, unrestricted mode requires PIN or biometrics. Parent activity is not mixed into child history.',
    ),
    _WalkthroughPage(
      icon: Icons.tune_outlined,
      color: Colors.blueGrey,
      title: _ar
          ? 'ابدأ إعداد الجهاز المشترك'
          : 'Set up your shared device',
      body: _ar
          ? 'افتح إدارة الأطفال الآن لإضافة العائلة وتحديد الطفل النشط. تظل كل الحدود والسجلات قابلة للمراجعة والتعديل من الوالد.'
          : 'Open Kids Management now to add your family and select the active child. Parents can review and adjust all limits and histories later.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    await widget.onCompleted();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _openProfileSetup() async {
    if (_finishing || widget.onOpenProfileSetup == null) return;
    setState(() => _finishing = true);
    await widget.onOpenProfileSetup!();
    if (!mounted) return;
    await widget.onCompleted();
    if (mounted) Navigator.of(context).pop();
  }

  Widget _interactivePreview() {
    if (_page == 1) {
      return Column(
        children: <Widget>[
          Text(
            _ar
                ? 'ملفات في هذا المثال: $_demoChildren'
                : 'Profiles in this example: $_demoChildren',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            key: const Key('walkthrough-add-child'),
            onPressed: () => setState(() => _demoChildren = 2),
            icon: const Icon(Icons.add),
            label: Text(_ar ? 'أضف طفلًا آخر' : 'Add another child'),
          ),
        ],
      );
    }
    if (_page == 2) {
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        children: <Widget>[
          ChoiceChip(
            label: const Text('Noor'),
            selected: _demoActiveUser == 'Noor',
            onSelected: (_) => setState(() => _demoActiveUser = 'Noor'),
          ),
          ChoiceChip(
            key: const Key('walkthrough-switch-child'),
            label: const Text('Maha'),
            selected: _demoActiveUser == 'Maha',
            onSelected: (_) => setState(() => _demoActiveUser = 'Maha'),
          ),
        ],
      );
    }
    if (_page == 3) {
      return FilledButton.icon(
        key: const Key('walkthrough-parent-mode'),
        onPressed: () => setState(() => _demoParentMode = true),
        icon: Icon(_demoParentMode ? Icons.verified_user : Icons.lock_outline),
        label: Text(_demoParentMode
            ? (_ar ? 'تم التحقق في المثال' : 'Verified in this example')
            : (_ar ? 'مثال: تحقق برمز PIN' : 'Example: verify with PIN')),
      );
    }
    if (_page == _pages.length - 1 && widget.onOpenProfileSetup != null) {
      return OutlinedButton.icon(
        key: const Key('walkthrough-open-kids-management'),
        onPressed: _finishing ? null : _openProfileSetup,
        icon: const Icon(Icons.manage_accounts_outlined),
        label: Text(_ar ? 'افتح إدارة الأطفال الآن' : 'Open Kids Management now'),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isLast = _page == _pages.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(_ar ? 'دليل الجهاز المشترك' : 'Shared-device guide'),
        actions: <Widget>[
          TextButton(
            onPressed: _finishing ? null : _finish,
            child: Text(_ar ? 'تخطي' : 'Skip'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (int value) => setState(() => _page = value),
                itemBuilder: (BuildContext context, int index) {
                  final _WalkthroughPage page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(28),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            CircleAvatar(
                              radius: 52,
                              backgroundColor: page.color.withValues(alpha: 0.14),
                              child: Icon(page.icon, size: 62, color: page.color),
                            ),
                            const SizedBox(height: 32),
                            Text(
                              page.title,
                              style: Theme.of(context).textTheme.headlineSmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              page.body,
                              style: Theme.of(context).textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            _interactivePreview(),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(
                _pages.length,
                (int index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: index == _page ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: index == _page ? colors.primary : colors.outlineVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _finishing
                      ? null
                      : () async {
                          if (isLast) {
                            await _finish();
                          } else {
                            await _controller.nextPage(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOut,
                            );
                          }
                        },
                  icon: Icon(isLast ? Icons.check : Icons.arrow_forward),
                  label: Text(
                    isLast
                        ? (_ar ? 'إنهاء الدليل' : 'Finish guide')
                        : (_ar ? 'التالي' : 'Next'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalkthroughPage {
  const _WalkthroughPage({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;
}
