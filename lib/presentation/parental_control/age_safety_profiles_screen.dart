import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/local/age_safety_profile_service.dart';
import '../../data/local/locale_controller.dart';
import '../../domain/models/age_safety_profile.dart';

class AgeSafetyProfilesScreen extends StatefulWidget {
  const AgeSafetyProfilesScreen({super.key});

  @override
  State<AgeSafetyProfilesScreen> createState() => _AgeSafetyProfilesScreenState();
}

class _AgeSafetyProfilesScreenState extends State<AgeSafetyProfilesScreen> {
  AgeSafetyProfileService? _service;
  AgeSafetyProfilePreset? _preset;
  bool _loading = true;

  bool get _ar => LocaleController.instance.isArabic;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final AgeSafetyProfileService service = AgeSafetyProfileService(prefs);
    setState(() {
      _service = service;
      _preset = service.load();
      _loading = false;
    });
  }

  Future<void> _select(AgeSafetyProfile profile) async {
    final AgeSafetyProfilePreset preset = await _service!.select(profile);
    setState(() => _preset = preset);
  }

  Future<void> _reset() async {
    final AgeSafetyProfilePreset preset = await _service!.reset();
    setState(() => _preset = preset);
  }

  Future<void> _save(AgeSafetyProfilePreset preset) async {
    await _service!.save(preset);
    setState(() => _preset = preset);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _preset == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final AgeSafetyProfilePreset preset = _preset!;
    return Scaffold(
      appBar: AppBar(
        title: Text(_ar ? 'إعدادات حسب العمر' : 'Age-based profiles'),
        actions: [
          IconButton(
            tooltip: _ar ? 'إرجاع الإعداد الافتراضي' : 'Reset to default',
            icon: const Icon(Icons.restart_alt),
            onPressed: _reset,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _ar ? 'اختر إعدادًا جاهزًا ثم عدّله حسب عائلتك.' : 'Choose a ready-made setup, then adjust it for your family.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          RadioGroup<AgeSafetyProfile>(
            groupValue: preset.profile,
            onChanged: (AgeSafetyProfile? value) {
              if (value != null) _select(value);
            },
            child: Column(
              children: AgeSafetyProfile.values.map((AgeSafetyProfile profile) {
                final AgeSafetyProfilePreset item = AgeSafetyProfilePreset.defaults[profile]!;
                return RadioListTile<AgeSafetyProfile>(
                  value: profile,
                  title: Text(_ar ? item.nameAr : item.nameEn),
                  subtitle: Text(_ar ? item.descriptionAr : item.descriptionEn),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 32),
          Text(_ar ? 'التخصيص' : 'Customize', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ListTile(
            title: Text(_ar ? 'الحد اليومي' : 'Daily limit'),
            subtitle: Text('${preset.dailyLimitMinutes} ${_ar ? 'دقيقة' : 'minutes'}'),
            trailing: SizedBox(
              width: 150,
              child: Slider(
                min: 15,
                max: 180,
                divisions: 11,
                value: preset.dailyLimitMinutes.toDouble().clamp(15, 180),
                onChanged: (double value) => _save(preset.copyWith(dailyLimitMinutes: value.round())),
              ),
            ),
          ),
          SwitchListTile(
            title: Text(_ar ? 'حظر المحتوى غير المناسب للعمر' : 'Block age-inappropriate content'),
            value: preset.blockMatureContent,
            onChanged: (bool value) => _save(preset.copyWith(blockMatureContent: value)),
          ),
          SwitchListTile(
            title: Text(_ar ? 'طلب موافقة الوالدين' : 'Require parent approval'),
            value: preset.requireParentApproval,
            onChanged: (bool value) => _save(preset.copyWith(requireParentApproval: value)),
          ),
          SwitchListTile(
            title: Text(_ar ? 'التنبيهات الصوتية' : 'Voice notifications'),
            subtitle: Text(_ar ? 'استخدم الرسالة الصوتية التي يسجلها الوالدان.' : 'Use the voice message recorded by a parent.'),
            value: preset.voiceNotifications,
            onChanged: (bool value) => _save(preset.copyWith(voiceNotifications: value)),
          ),
        ],
      ),
    );
  }
}
