import 'package:flutter/material.dart';

import '../../data/local/locale_controller.dart';

class FeatureWalkthroughScreen extends StatefulWidget {
  const FeatureWalkthroughScreen({
    super.key,
    required this.onCompleted,
  });

  final Future<void> Function() onCompleted;

  @override
  State<FeatureWalkthroughScreen> createState() =>
      _FeatureWalkthroughScreenState();
}

class _FeatureWalkthroughScreenState extends State<FeatureWalkthroughScreen> {
  final PageController _controller = PageController();
  int _page = 0;
  bool _finishing = false;

  bool get _ar => LocaleController.instance.isArabic;

  late final List<_WalkthroughPage> _pages = <_WalkthroughPage>[
    _WalkthroughPage(
      icon: Icons.family_restroom_outlined,
      color: Colors.teal,
      title: _ar ? 'عائلتك أولاً' : 'Your family, first',
      body: _ar
          ? 'أضف أطفالك، راجع تاريخ الميلاد، واختر إعدادات السلامة المناسبة. يتم اختيار الملف النشط بوضوح عند مشاركة الجهاز.'
          : 'Add children, review birth dates, and choose suitable safety settings. The active child is always clear when the device is shared.',
    ),
    _WalkthroughPage(
      icon: Icons.shield_outlined,
      color: Colors.indigo,
      title: _ar ? 'الحماية والحدود' : 'Protection and limits',
      body: _ar
          ? 'فعّل المراقبة بعد منح الوصول المطلوب. استخدم حدود الفئات، المواقع المسموحة والمحظورة، وأوقات النوم والصلاة القابلة للتعديل.'
          : 'Start monitoring after granting required access. Use category budgets, allowed and blocked sites, and editable sleep and prayer schedules.',
    ),
    _WalkthroughPage(
      icon: Icons.notifications_active_outlined,
      color: Colors.deepOrange,
      title: _ar ? 'تذكيرات بصوت الوالد' : 'Parent voice reminders',
      body: _ar
          ? 'سجّل تذكيرات للمهام أو الصلاة. يصل الإشعار بأمان، ثم يفتح التطبيق لتشغيل التسجيل المحلي؛ لا يتم التشغيل تلقائياً في الخلفية.'
          : 'Record task or prayer reminders. A safe notification opens the app to play the local recording; it does not autoplay in the background.',
    ),
    _WalkthroughPage(
      icon: Icons.bar_chart_outlined,
      color: Colors.purple,
      title: _ar ? 'تقارير وخصوصية' : 'Reports and privacy',
      body: _ar
          ? 'راجع الاستخدام حسب التاريخ. تبقى التسجيلات والبيانات الحساسة على الجهاز، وتحتاج أي مشاركة بالبريد إلى مراجعتك وموافقتك الصريحة.'
          : 'Review usage by date. Recordings and sensitive data stay on the device, and any email sharing requires your review and explicit consent.',
    ),
    _WalkthroughPage(
      icon: Icons.tune_outlined,
      color: Colors.blueGrey,
      title: _ar ? 'أنت المتحكم' : 'You stay in control',
      body: _ar
          ? 'يمكنك تعديل كل إعداد لاحقاً. من إعدادات الأطفال اطلب إضافة اختصار لوحة الإعدادات السريعة لتغيير الطفل النشط بشكل أسرع.'
          : 'Every setting remains editable. From Kids management, request the Quick Settings shortcut for faster active-child switching.',
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

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isLast = _page == _pages.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(_ar ? 'جولة تعريفية' : 'Feature tour'),
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
                        ? (_ar ? 'ابدأ استخدام عيالنا' : 'Start using 3ialna')
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
