import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/local/shareable_profile_pack_service.dart';

class ProfilePackScreen extends StatefulWidget {
  const ProfilePackScreen({super.key});

  @override
  State<ProfilePackScreen> createState() => _ProfilePackScreenState();
}

class _ProfilePackScreenState extends State<ProfilePackScreen> {
  bool _busy = false;

  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';

  Future<void> _exportPack() async {
    final TextEditingController profile = TextEditingController(text: _ar ? 'إعداد عائلتي' : 'My family setup');
    final TextEditingController creator = TextEditingController();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(_ar ? 'تصدير إعداد قابل للمشاركة' : 'Export a shareable setup'),
        content: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          Text(_ar ? 'اكتب اسم الإعداد واسم صاحبه. لا يتضمن التصدير أسماء الأطفال أو تواريخ ميلادهم أو جنسهم أو رمز الوالد أو الاستخدام أو التسجيلات.' : 'Name the setup and its creator. Export never includes child names, dates of birth, gender, the parent PIN, usage, or recordings.'),
          const SizedBox(height: 12),
          TextField(controller: profile, maxLength: 80, decoration: InputDecoration(labelText: _ar ? 'اسم الإعداد' : 'Setup name')),
          TextField(controller: creator, maxLength: 80, decoration: InputDecoration(labelText: _ar ? 'اسم المُنشئ' : 'Creator name')),
        ]),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(_ar ? 'إلغاء' : 'Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(_ar ? 'تصدير' : 'Export')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      final String pack = await (await ShareableProfilePackService.create()).export(profileName: profile.text, creatorName: creator.text);
      await Share.share(pack, subject: '${profile.text.trim()} — 3ialna');
      _show(_ar ? 'تم فتح المشاركة. أرسل النص كما هو ليتم استيراده.' : 'Sharing opened. Send the text unchanged so it can be imported.');
    } on FormatException catch (error) {
      _show(error.message, error: true);
    } catch (_) {
      _show(_ar ? 'تعذر تصدير الإعداد.' : 'Could not export the setup.', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importPack() async {
    final TextEditingController pack = TextEditingController();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(_ar ? 'استيراد إعداد مشترك' : 'Import a shared setup'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: TextField(
            controller: pack,
            minLines: 7,
            maxLines: 12,
            decoration: InputDecoration(hintText: _ar ? 'الصق نص إعداد 3ialna هنا' : 'Paste a 3ialna setup here'),
          ),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(_ar ? 'إلغاء' : 'Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(_ar ? 'استيراد واستبدال إعداد الطفل النشط' : 'Import to the active child')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      final ShareableProfilePack imported = await (await ShareableProfilePackService.create()).importText(pack.text);
      _show(_ar ? 'تم استيراد «${imported.profileName}» من ${imported.creatorName} للطفل النشط.' : 'Imported “${imported.profileName}” by ${imported.creatorName} to the active child.');
    } on FormatException catch (error) {
      _show(error.message, error: true);
    } catch (_) {
      _show(_ar ? 'تعذر استيراد الإعداد. تأكد من لصق النص الكامل.' : 'Could not import the setup. Paste the complete text.', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _show(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: error ? Theme.of(context).colorScheme.error : null));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_ar ? 'إعدادات قابلة للمشاركة' : 'Shareable setups')),
      body: ListView(padding: const EdgeInsets.all(20), children: <Widget>[
        Text(_ar ? 'شارك القواعد، لا بيانات الأطفال' : 'Share rules, not child data', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 10),
        Text(_ar ? 'تنقل الحزمة إعداد العمر، النوم، الصلاة، الحدود اليومية، قواعد التطبيقات، والتصنيفات والجدول. لا تُنشئ طفلاً جديداً عند الاستيراد؛ بل تطبق على الطفل النشط فقط.' : 'A pack carries age, sleep, prayer, daily-limit, app-rule, category, and schedule settings. Import does not create a child; it applies only to the active child.'),
        const SizedBox(height: 24),
        Card(child: ListTile(leading: const Icon(Icons.ios_share), title: Text(_ar ? 'تصدير ومشاركة' : 'Export and share'), subtitle: Text(_ar ? 'أضف اسم الإعداد واسمك ثم شارك النص من هاتفك.' : 'Add a setup name and your name, then use your device share sheet.'), onTap: _busy ? null : _exportPack)),
        Card(child: ListTile(leading: const Icon(Icons.download_for_offline_outlined), title: Text(_ar ? 'استيراد إعداد' : 'Import a setup'), subtitle: Text(_ar ? 'الصق النص الذي تلقيته، ثم وافق على استبدال إعداد الطفل النشط.' : 'Paste the received text and approve applying it to the active child.'), onTap: _busy ? null : _importPack)),
        if (_busy) const Padding(padding: EdgeInsets.only(top: 20), child: Center(child: CircularProgressIndicator())),
      ]),
    );
  }
}
