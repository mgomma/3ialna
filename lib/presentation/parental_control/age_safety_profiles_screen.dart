import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/local/age_safety_profile_service.dart';
import '../../data/local/locale_controller.dart';
import '../../data/system/child_shortcut_service.dart';
import '../../domain/models/age_safety_profile.dart';
import '../../domain/models/child_profile.dart';

class AgeSafetyProfilesScreen extends StatefulWidget {
  const AgeSafetyProfilesScreen({super.key});

  @override
  State<AgeSafetyProfilesScreen> createState() => _AgeSafetyProfilesScreenState();
}

class _AgeSafetyProfilesScreenState extends State<AgeSafetyProfilesScreen> {
  AgeSafetyProfileService? _service;
  AgeSafetyProfilePreset? _preset;
  List<ChildProfile> _children = <ChildProfile>[];
  ChildProfile? _active;
  bool _loading = true;

  bool get _ar => LocaleController.instance.isArabic;
  String get _minuteLabel => _ar ? 'دقيقة' : 'minutes';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final AgeSafetyProfileService service = AgeSafetyProfileService(await SharedPreferences.getInstance());
    await service.ensureDefaultChild();
    if (!mounted) return;
    setState(() {
      _service = service;
      _children = service.loadChildren();
      _active = service.activeChild();
      _preset = service.load();
      _loading = false;
    });
    await ChildShortcutService.sync(service.loadChildren());
  }

  Future<void> _save(AgeSafetyProfilePreset preset) async {
    await _service!.save(preset);
    if (mounted) setState(() => _preset = preset);
  }

  Future<void> _setActive(String? childId) async {
    if (childId == null) return;
    await _service!.setActiveChild(childId);
    await _load();
  }

  String _gender(ChildGender gender) => _ar
      ? switch (gender) { ChildGender.boy => 'ولد', ChildGender.girl => 'بنت', ChildGender.unspecified => 'غير محدد' }
      : switch (gender) { ChildGender.boy => 'Boy', ChildGender.girl => 'Girl', ChildGender.unspecified => 'Not specified' };

  Future<void> _editChild({ChildProfile? child}) async {
    final TextEditingController name = TextEditingController(text: child?.name ?? '');
    DateTime birthDate = child?.birthDate ?? DateTime.now();
    ChildGender gender = child?.gender ?? ChildGender.unspecified;
    final ChildProfile? result = await showDialog<ChildProfile>(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) => AlertDialog(
          title: Text(child == null ? (_ar ? 'إضافة طفل' : 'Add child') : (_ar ? 'تعديل الطفل' : 'Edit child')),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
              TextField(controller: name, autofocus: true, decoration: InputDecoration(labelText: _ar ? 'اسم الطفل' : 'Child name')),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_ar ? 'تاريخ الميلاد' : 'Birth date'),
                subtitle: Text(MaterialLocalizations.of(context).formatMediumDate(birthDate)),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: () async {
                  final DateTime? selected = await showDatePicker(context: context, firstDate: DateTime(DateTime.now().year - 18), lastDate: DateTime.now(), initialDate: birthDate);
                  if (selected != null) setDialogState(() => birthDate = selected);
                },
              ),
              DropdownButtonFormField<ChildGender>(
                key: ValueKey<ChildGender>(gender),
                initialValue: gender,
                decoration: InputDecoration(labelText: _ar ? 'النوع' : 'Gender'),
                items: <DropdownMenuItem<ChildGender>>[
                  DropdownMenuItem(value: ChildGender.unspecified, child: Text(_ar ? 'غير محدد' : 'Not specified')),
                  DropdownMenuItem(value: ChildGender.boy, child: Text(_ar ? 'ولد' : 'Boy')),
                  DropdownMenuItem(value: ChildGender.girl, child: Text(_ar ? 'بنت' : 'Girl')),
                ],
                onChanged: (ChildGender? value) => setDialogState(() => gender = value ?? ChildGender.unspecified),
              ),
            ]),
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(_ar ? 'إلغاء' : 'Cancel')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, ChildProfile(id: child?.id ?? '', name: name.text, birthDate: birthDate, gender: gender, preset: child?.preset ?? AgeSafetyProfilePreset.defaults[AgeSafetyProfile.underFive]!)), child: Text(_ar ? 'حفظ' : 'Save')),
          ],
        ),
      ),
    );
    if (result == null) return;
    if (child == null) {
      await _service!.addChild(name: result.name, birthDate: result.birthDate, gender: result.gender);
    } else {
      await _service!.updateChild(result);
    }
    await _load();
  }

  Future<void> _manageChildren() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext sheetContext) => SafeArea(
        child: ListView(shrinkWrap: true, padding: const EdgeInsets.all(16), children: <Widget>[
          Row(children: <Widget>[Expanded(child: Text(_ar ? 'الأطفال على هذا الجهاز' : 'Children on this device', style: Theme.of(context).textTheme.titleLarge)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(sheetContext))]),
          ..._children.map((ChildProfile child) => ListTile(
            selected: child.id == _active?.id,
            leading: CircleAvatar(child: Text(child.name.isEmpty ? '?' : child.name.substring(0, 1).toUpperCase())),
            title: Text(child.name),
            subtitle: Text('${child.ageYears} ${_ar ? 'سنة' : 'years'} · ${_gender(child.gender)}'),
            onTap: () async { await _setActive(child.id); if (sheetContext.mounted) Navigator.pop(sheetContext); },
            trailing: Wrap(children: <Widget>[
              IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () async => _editChild(child: child)),
              if (_children.length > 1) IconButton(icon: const Icon(Icons.delete_outline), onPressed: () async { await _service!.removeChild(child.id); if (sheetContext.mounted) Navigator.pop(sheetContext); await _load(); }),
            ]),
          )),
          TextButton.icon(icon: const Icon(Icons.person_add_alt_1), label: Text(_ar ? 'إضافة طفل' : 'Add child'), onPressed: () async => _editChild()),
        ]),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _preset == null || _active == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final AgeSafetyProfilePreset preset = _preset!;
    return Scaffold(
      appBar: AppBar(title: Text(_ar ? 'الأطفال والإعدادات العمرية' : 'Children and age profiles'), actions: <Widget>[IconButton(tooltip: _ar ? 'إرجاع الإعداد الافتراضي' : 'Reset to default', icon: const Icon(Icons.restart_alt), onPressed: () async { await _service!.reset(); await _load(); })]),
      body: ListView(padding: const EdgeInsets.all(16), children: <Widget>[
        Text(_ar ? 'عرّف الأطفال الذين يستخدمون الجهاز واختر الطفل النشط. الإعدادات التالية تخص الطفل المختار فقط.' : 'Define the children who use this device and choose the active child. The settings below apply only to the selected child.'),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          key: ValueKey<String>(_active!.id),
          initialValue: _active!.id,
          decoration: InputDecoration(labelText: _ar ? 'الطفل المستخدم للجهاز الآن' : 'Child using this device now'),
          items: _children.map((ChildProfile child) => DropdownMenuItem<String>(value: child.id, child: Text(child.name))).toList(growable: false),
          onChanged: _setActive,
        ),
        Align(alignment: AlignmentDirectional.centerStart, child: TextButton.icon(icon: const Icon(Icons.manage_accounts_outlined), label: Text(_ar ? 'إدارة الأطفال' : 'Manage children'), onPressed: _manageChildren)),
        const Divider(height: 32),
        Text(_ar ? 'ملف ${_active!.name}' : '${_active!.name}\'s profile', style: Theme.of(context).textTheme.titleLarge),
        RadioGroup<AgeSafetyProfile>(
          groupValue: preset.profile,
          onChanged: (AgeSafetyProfile? profile) async { if (profile != null) { await _service!.select(profile); await _load(); } },
          child: Column(children: AgeSafetyProfile.values.map((AgeSafetyProfile profile) {
            final AgeSafetyProfilePreset item = AgeSafetyProfilePreset.defaults[profile]!;
            return RadioListTile<AgeSafetyProfile>(value: profile, title: Text(_ar ? item.nameAr : item.nameEn), subtitle: Text(_ar ? item.descriptionAr : item.descriptionEn));
          }).toList(growable: false)),
        ),
        const Divider(height: 32),
        Text(_ar ? 'ميزانيات الفئات اليومية' : 'Daily category budgets', style: Theme.of(context).textTheme.titleLarge),
        Text(_ar ? 'كل التطبيقات المصنفة ضمن نفس الفئة تستهلك من ميزانية واحدة. القيم قابلة للتعديل من الوالدين.' : 'Every app in the same category uses one shared budget. Parents can edit these values.'),
        _budgetTile(label: _ar ? 'وسائل التواصل الاجتماعي' : 'Social media', minutes: preset.socialMediaLimitMinutes, max: 180, onChanged: (int minutes) => _save(preset.copyWith(socialMediaLimitMinutes: minutes, dailyLimitMinutes: minutes + preset.gamesLimitMinutes))),
        _budgetTile(label: _ar ? 'الألعاب' : 'Games', minutes: preset.gamesLimitMinutes, max: 240, onChanged: (int minutes) => _save(preset.copyWith(gamesLimitMinutes: minutes, dailyLimitMinutes: minutes + preset.socialMediaLimitMinutes))),
        ListTile(title: Text(_ar ? 'المجموع' : 'Combined budget'), subtitle: Text('${preset.dailyLimitMinutes} $_minuteLabel')),
        SwitchListTile(title: Text(_ar ? 'حظر المحتوى غير المناسب للعمر' : 'Block age-inappropriate content'), value: preset.blockMatureContent, onChanged: (bool value) => _save(preset.copyWith(blockMatureContent: value))),
        SwitchListTile(title: Text(_ar ? 'طلب موافقة الوالدين' : 'Require parent approval'), value: preset.requireParentApproval, onChanged: (bool value) => _save(preset.copyWith(requireParentApproval: value))),
        SwitchListTile(title: Text(_ar ? 'التنبيهات الصوتية' : 'Voice notifications'), subtitle: Text(_ar ? 'استخدم الرسالة الصوتية التي يسجلها الوالدان.' : 'Use the voice message recorded by a parent.'), value: preset.voiceNotifications, onChanged: (bool value) => _save(preset.copyWith(voiceNotifications: value))),
      ]),
    );
  }

  Widget _budgetTile({required String label, required int minutes, required int max, required ValueChanged<int> onChanged}) {
    return ListTile(
      title: Text(label),
      subtitle: Text('$minutes $_minuteLabel'),
      trailing: SizedBox(width: 150, child: Slider(min: 0, max: max.toDouble(), divisions: max ~/ 15, value: minutes.toDouble(), onChanged: (double value) => onChanged(value.round()))),
    );
  }
}
