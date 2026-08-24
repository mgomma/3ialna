import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/social_media_apps.dart';
import '../../data/local/age_safety_profile_service.dart';
import '../../data/local/child_usage_ledger_service.dart';
import '../../data/local/locale_controller.dart';
import '../../data/system/app_usage_service.dart';
import '../../domain/models/child_profile.dart';

enum _ReportRange { today, sevenDays, custom }

class ParentUsageReportScreen extends StatefulWidget {
  const ParentUsageReportScreen({super.key});

  @override
  State<ParentUsageReportScreen> createState() =>
      _ParentUsageReportScreenState();
}

class _ParentUsageReportScreenState extends State<ParentUsageReportScreen> {
  static const String _allChildren = '__all_children__';

  final ChildUsageLedgerService _usageLedger = const ChildUsageLedgerService();
  _ReportRange _range = _ReportRange.today;
  late DateTime _start;
  late DateTime _end;
  AppUsageSummary? _summary;
  List<ChildProfile> _children = <ChildProfile>[];
  String _selectedChildId = _allChildren;
  bool _loading = true;

  bool get _ar => LocaleController.instance.isArabic;

  ChildProfile? get _selectedChild {
    for (final ChildProfile child in _children) {
      if (child.id == _selectedChildId) return child;
    }
    return null;
  }

  String? get _selectedChildFilter =>
      _selectedChildId == _allChildren ? null : _selectedChildId;

  @override
  void initState() {
    super.initState();
    _setRange(_ReportRange.today, reload: false);
    _loadChildrenAndReport();
  }

  Future<void> _loadChildrenAndReport() async {
    final AgeSafetyProfileService profiles =
        AgeSafetyProfileService(await SharedPreferences.getInstance());
    final List<ChildProfile> children = profiles.loadChildren();
    if (!mounted) return;
    setState(() {
      _children = children;
      _selectedChildId = profiles.activeChild()?.id ?? _allChildren;
    });
    await _load();
  }

  void _setRange(_ReportRange range, {bool reload = true}) {
    final DateTime now = DateTime.now();
    final DateTime endOfToday = DateTime(now.year, now.month, now.day, 23, 59,
        59, 999);
    setState(() {
      _range = range;
      if (range == _ReportRange.today) {
        _start = DateTime(now.year, now.month, now.day);
        _end = now;
      } else if (range == _ReportRange.sevenDays) {
        _start = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 6));
        _end = endOfToday;
      }
    });
    if (reload) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final ChildUsageLedgerAggregate aggregate =
        await _usageLedger.loadAggregate(
      childId: _selectedChildFilter,
      start: _start,
      end: _end,
    );
    if (!mounted) return;
    setState(() {
      _summary = AppUsageSummary(
        perAppMinutes: aggregate.appUsageMinutes,
        totalMinutes: aggregate.totalMinutes,
      );
      _loading = false;
    });
  }

  Future<void> _pickCustomRange() async {
    final DateTimeRange? selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _start, end: _end),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _range = _ReportRange.custom;
      _start = selected.start;
      _end = DateTime(selected.end.year, selected.end.month, selected.end.day,
          23, 59, 59, 999);
    });
    await _load();
  }

  String _duration(int totalMinutes) {
    final int hours = totalMinutes ~/ 60;
    final int minutes = totalMinutes % 60;
    if (hours == 0) return '$minutes ${_ar ? 'دقيقة' : 'min'}';
    return _ar ? '$hours س $minutes د' : '${hours}h ${minutes}m';
  }

  String _rangeLabel() {
    final MaterialLocalizations localizations =
        MaterialLocalizations.of(context);
    return '${localizations.formatMediumDate(_start)} — '
        '${localizations.formatMediumDate(_end)}';
  }

  String get _selectedChildLabel => _selectedChild == null
      ? (_ar ? 'كل الأطفال' : 'All children')
      : _selectedChild!.name;

  @override
  Widget build(BuildContext context) {
    final AppUsageSummary summary = _summary ??
        const AppUsageSummary(
          perAppMinutes: <String, int>{},
          totalMinutes: 0,
        );
    final List<MapEntry<String, int>> apps = summary.perAppMinutes.entries
        .toList(growable: false)
      ..sort((MapEntry<String, int> a, MapEntry<String, int> b) =>
          b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: Text(_ar ? 'تقرير الاستخدام للوالدين' : 'Parent usage report'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadChildrenAndReport,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text(
              _ar
                  ? 'يعرض التقرير الاستخدام المحلي المنسوب للطفل المحدد بعد اختياره على هذا الجهاز. لا يحدد Android الأشخاص تلقائيًا ولا يُرسل عيالنا هذا الإسناد.'
                  : 'This report shows locally attributed usage after a child is selected on this device. Android does not identify people automatically, and 3ialna does not send this attribution.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: const Key('parent-report-child-filter'),
              initialValue: _selectedChildId,
              decoration: InputDecoration(
                labelText: _ar ? 'تصفية حسب الطفل' : 'Filter by child',
                border: const OutlineInputBorder(),
              ),
              items: <DropdownMenuItem<String>>[
                DropdownMenuItem<String>(
                  value: _allChildren,
                  child: Text(_ar ? 'كل الأطفال' : 'All children'),
                ),
                ..._children.map(
                  (ChildProfile child) => DropdownMenuItem<String>(
                    value: child.id,
                    child: Text(child.name),
                  ),
                ),
              ],
              onChanged: (String? childId) {
                if (childId == null) return;
                setState(() => _selectedChildId = childId);
                _load();
              },
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                ChoiceChip(
                  label: Text(_ar ? 'اليوم' : 'Today'),
                  selected: _range == _ReportRange.today,
                  onSelected: (_) => _setRange(_ReportRange.today),
                ),
                ChoiceChip(
                  label: Text(_ar ? 'آخر 7 أيام' : 'Last 7 days'),
                  selected: _range == _ReportRange.sevenDays,
                  onSelected: (_) => _setRange(_ReportRange.sevenDays),
                ),
                ActionChip(
                  avatar: const Icon(Icons.date_range_outlined),
                  label: Text(_range == _ReportRange.custom
                      ? _rangeLabel()
                      : (_ar ? 'نطاق مخصص' : 'Custom range')),
                  onPressed: _pickCustomRange,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(_rangeLabel(),
                        style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 4),
                    Text(
                      _selectedChildLabel,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(_duration(summary.totalMinutes),
                        style: Theme.of(context).textTheme.displaySmall),
                    Text(
                      _selectedChild == null
                          ? (_ar
                              ? 'إجمالي الاستخدام المحلي المنسوب للأطفال'
                              : 'Total locally attributed child usage')
                          : (_ar
                              ? 'وقت الاستخدام المنسوب لهذا الطفل'
                              : 'Usage attributed to this child'),
                    ),
                    if (_selectedChild != null) ...<Widget>[
                      const SizedBox(height: 6),
                      Text(
                        _ar
                            ? 'الحد اليومي للملف: ${_selectedChild!.preset.dailyLimitMinutes} دقيقة'
                            : 'Profile daily limit: ${_selectedChild!.preset.dailyLimitMinutes} min',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(_ar ? 'التطبيقات المتتبعة' : 'Tracked apps',
                style: Theme.of(context).textTheme.titleLarge),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (apps.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Text(_ar
                    ? 'لا توجد بيانات منسوبة في هذا النطاق. اختر الطفل أولًا ثم استخدم الجهاز لتسجيل الاستهلاك محليًا.'
                    : 'No attributed usage is available for this range. Select a child first, then use the device so usage can be recorded locally.'),
              )
            else
              ...apps.map(
                (MapEntry<String, int> app) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.apps_outlined),
                    title: Text(socialMediaApps[app.key] ?? app.key),
                    trailing: Text(_duration(app.value),
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
