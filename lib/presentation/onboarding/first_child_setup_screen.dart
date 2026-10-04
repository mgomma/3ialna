import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/local/age_safety_profile_service.dart';
import '../../domain/models/age_safety_profile.dart';
import '../../domain/models/child_profile.dart';
import '../../l10n/app_localizations.dart';
import '../parental_control/widgets/age_profile_preview.dart';

class FirstChildSetupScreen extends StatefulWidget {
  const FirstChildSetupScreen({super.key});

  @override
  State<FirstChildSetupScreen> createState() => _FirstChildSetupScreenState();
}

class _FirstChildSetupScreenState extends State<FirstChildSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  DateTime? _birthDate;
  ChildGender? _gender;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _chooseBirthDate() async {
    final DateTime today = DateTime.now();
    final DateTime? selected = await showDatePicker(
      context: context,
      firstDate: DateTime(today.year - 18, today.month, today.day),
      lastDate: today,
      initialDate: DateTime(today.year - 8, today.month, today.day),
    );
    if (selected != null && mounted) setState(() => _birthDate = selected);
  }

  Future<void> _save() async {
    final DateTime? birthDate = _birthDate;
    final ChildGender? gender = _gender;
    if (_nameController.text.trim().isEmpty || birthDate == null || gender == null) {
      return;
    }

    setState(() => _saving = true);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await AgeSafetyProfileService(prefs).addChild(
      name: _nameController.text.trim(),
      birthDate: birthDate,
      gender: gender,
      profileFollowsBirthDate: true,
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  String _genderLabel(AppLocalizations l10n, ChildGender gender) => switch (gender) {
    ChildGender.boy => l10n.boy,
    ChildGender.girl => l10n.girl,
    ChildGender.unspecified => l10n.unspecified,
  };

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final DateTime? birthDate = _birthDate;
    final AgeSafetyProfilePreset? preview = birthDate == null
        ? null
        : AgeSafetyProfilePreset.defaults[
            AgeSafetyProfileRecommendation.forBirthDate(birthDate)
          ];

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(l10n.firstChildSetupTitle),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Text(l10n.firstChildSetupIntro),
              const SizedBox(height: 20),
              TextField(
                key: const ValueKey<String>('first-child-name'),
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l10n.childName,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              ListTile(
                key: const ValueKey<String>('first-child-birth-date'),
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.birthDate),
                subtitle: Text(
                  birthDate == null
                      ? l10n.chooseBirthDate
                      : MaterialLocalizations.of(context)
                          .formatMediumDate(birthDate),
                ),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: _chooseBirthDate,
              ),
              DropdownButtonFormField<ChildGender>(
                key: const ValueKey<String>('first-child-gender'),
                initialValue: _gender,
                decoration: InputDecoration(
                  labelText: l10n.gender,
                  border: const OutlineInputBorder(),
                ),
                hint: Text(l10n.chooseGender),
                items: ChildGender.values
                    .map(
                      (ChildGender gender) => DropdownMenuItem<ChildGender>(
                        value: gender,
                        child: Text(_genderLabel(l10n, gender)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (ChildGender? value) => setState(() => _gender = value),
              ),
              if (preview != null) ...<Widget>[
                const SizedBox(height: 16),
                AgeProfilePreview(preset: preview),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                key: const ValueKey<String>('save-first-child-profile'),
                onPressed: !_saving &&
                        _nameController.text.trim().isNotEmpty &&
                        birthDate != null &&
                        _gender != null
                    ? _save
                    : null,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(l10n.saveChildProfile),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
