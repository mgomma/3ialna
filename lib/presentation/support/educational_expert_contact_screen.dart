import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/local/age_safety_profile_service.dart';
import '../../data/local/locale_controller.dart';
import '../../data/system/educational_expert_mailto.dart';
import '../../domain/models/child_profile.dart';

class EducationalExpertContactScreen extends StatefulWidget {
  const EducationalExpertContactScreen({super.key});

  @override
  State<EducationalExpertContactScreen> createState() =>
      _EducationalExpertContactScreenState();
}

class _EducationalExpertContactScreenState
    extends State<EducationalExpertContactScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _details = TextEditingController(
    text:
        'أرغب في التواصل مع خبير تربوي لمساعدتي في إعدادات عيالنا. أحتاج المساعدة في: ',
  );
  List<ChildProfile> _children = <ChildProfile>[];
  bool _includeChildren = false;
  bool _loading = true;

  bool get _ar => LocaleController.instance.isArabic;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    final AgeSafetyProfileService service =
        AgeSafetyProfileService(await SharedPreferences.getInstance());
    await service.ensureDefaultChild();
    if (!mounted) return;
    setState(() {
      _children = service.loadChildren();
      _loading = false;
    });
  }

  String _childDetails() {
    if (_children.isEmpty) return _ar ? 'لا توجد ملفات أطفال.' : 'No child profiles.';
    return _children
        .map((ChildProfile child) => _ar
            ? '- ${child.name}: ${child.ageYears} سنة'
            : '- ${child.name}: ${child.ageYears} years')
        .join('\n');
  }

  Future<void> _openEmailDraft() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_includeChildren) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_ar
              ? 'يرجى تأكيد موافقتك قبل تضمين أسماء الأطفال وأعمارهم في البريد.'
              : 'Confirm consent before including children’s names and ages in the email.'),
        ),
      );
      return;
    }

    final String body = _ar
        ? 'طلب تواصل مع خبير تربوي\n\nرقم الجوال: ${_phone.text.trim()}\n\nتفاصيل المساعدة المطلوبة:\n${_details.text.trim()}\n\nأسماء الأطفال وأعمارهم (بموافقة الوالد):\n${_childDetails()}'
        : 'Educational expert contact request\n\nMobile: ${_phone.text.trim()}\n\nRequested help:\n${_details.text.trim()}\n\nChildren’s names and ages (with parent consent):\n${_childDetails()}';
    final Uri email = buildEducationalExpertMailto(
      subject: 'طلب تواصل مع خبير تربوى',
      body: body,
    );
    final bool opened =
        await launchUrl(email, mode: LaunchMode.externalApplication);
    if (!mounted || opened) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_ar
            ? 'تعذر فتح تطبيق البريد. أرسل طلبك إلى 3ialna.app@gmail.com.'
            : 'Could not open an email app. Send your request to 3ialna.app@gmail.com.'),
      ),
    );
  }

  @override
  void dispose() {
    _phone.dispose();
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_ar ? 'طلب تواصل مع خبير تربوى' : 'Request an educational expert'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  Text(
                    _ar
                        ? 'املأ البيانات المطلوبة. سيُفتح تطبيق البريد لتراجع الرسالة ثم ترسلها بنفسك؛ لا تُرسل عيالنا هذه البيانات تلقائيًا.'
                        : 'Fill in the required details. Your email app will open so you can review and send the message yourself; 3ialna does not send this data automatically.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: _ar ? 'رقم الجوال للتواصل' : 'Mobile number for contact',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (String? value) => value == null || value.trim().length < 5
                        ? (_ar ? 'أدخل رقم جوال صحيحًا.' : 'Enter a valid mobile number.')
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _details,
                    minLines: 4,
                    maxLines: 8,
                    decoration: InputDecoration(
                      labelText: _ar ? 'كيف يمكن للخبير مساعدتك؟' : 'How can the expert help?',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (String? value) => value == null || value.trim().isEmpty
                        ? (_ar ? 'أدخل تفاصيل الطلب.' : 'Enter request details.')
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(_ar ? 'سيظهر في مسودة البريد:' : 'The email draft will include:',
                              style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 8),
                          Text(_childDetails()),
                        ],
                      ),
                    ),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _includeChildren,
                    onChanged: (bool? value) =>
                        setState(() => _includeChildren = value ?? false),
                    title: Text(_ar
                        ? 'أوافق على تضمين أسماء الأطفال وأعمارهم في هذه الرسالة إلى الخبير.'
                        : 'I agree to include children’s names and ages in this email to the expert.'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: _openEmailDraft,
                    icon: const Icon(Icons.email_outlined),
                    label: Text(_ar
                        ? 'فتح مسودة البريد للمراجعة والإرسال'
                        : 'Open email draft to review and send'),
                  ),
                ],
              ),
            ),
    );
  }
}
