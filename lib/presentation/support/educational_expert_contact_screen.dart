import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/local/age_safety_profile_service.dart';
import '../../data/local/locale_controller.dart';
import '../../data/local/settings_service.dart';
import '../../data/system/educational_expert_mailto.dart';
import '../../domain/models/child_profile.dart';
import '../../domain/validation/country_mobile_phone_validator.dart';
import '../parental_control/age_safety_profiles_screen.dart';

class EducationalExpertContactScreen extends StatefulWidget {
  const EducationalExpertContactScreen({
    super.key,
    this.childrenOverride,
  });

  /// Used by isolated UI tests; normal app navigation always loads local data.
  final List<ChildProfile>? childrenOverride;

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
  String _country = 'Saudi Arabia';
  bool _includeChildren = false;
  bool _loading = true;

  bool get _ar => LocaleController.instance.isArabic;

  /// `Child 1` is a local starter profile created for safeguards. It is not
  /// sufficiently parent-defined to include in an educational-expert request.
  List<ChildProfile> get _definedChildren => _children
      .where((ChildProfile child) {
        final String name = child.name.trim().toLowerCase();
        return name.isNotEmpty && name != 'child' && name != 'child 1';
      })
      .toList(growable: false);

  bool get _hasDefinedChild => _definedChildren.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final AgeSafetyProfileService service = AgeSafetyProfileService(preferences);
    final SettingsService settings = SettingsService(preferences);
    if (!mounted) return;
    setState(() {
      _children = widget.childrenOverride ?? service.loadChildren();
      _country = CountryMobilePhoneValidator.canonicalCountry(
        settings.selectedCountry,
      );
      _loading = false;
    });
  }

  String _childDetails() {
    if (!_hasDefinedChild) {
      return _ar ? 'لا توجد ملفات أطفال.' : 'No child profiles.';
    }
    return _definedChildren
        .map((ChildProfile child) => _ar
            ? '- ${child.name}: ${child.ageYears} سنة'
            : '- ${child.name}: ${child.ageYears} years')
        .join('\n');
  }

  CountryMobilePhoneValidation _validateMobileNumber(String value) =>
      CountryMobilePhoneValidator.validate(country: _country, input: value);

  String? _mobileValidationError(String? value) {
    final CountryMobilePhoneValidation validation =
        _validateMobileNumber(value ?? '');
    if (validation.isValid) return null;
    final String callingCode =
        CountryMobilePhoneValidator.callingCodeFor(_country);
    if (validation.error == 'missing') {
      return _ar ? 'أدخل رقم الجوال.' : 'Enter a mobile number.';
    }
    if (validation.error == 'countryCode') {
      return _ar
          ? 'استخدم رمز الدولة $callingCode أو رقم جوال محليًا للدولة المحددة.'
          : 'Use country code $callingCode or a local mobile number for the selected country.';
    }
    return _ar
        ? 'أدخل رقم جوال صحيحًا للدولة المحددة ($callingCode).'
        : 'Enter a valid mobile number for the selected country ($callingCode).';
  }

  Future<void> _openEmailDraft() async {
    if (!_hasDefinedChild) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_ar
              ? 'عرّف طفلًا واحدًا على الأقل قبل طلب التواصل مع الخبير.'
              : 'Define at least one child before requesting an expert.'),
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    final CountryMobilePhoneValidation phoneValidation =
        _validateMobileNumber(_phone.text);
    if (!phoneValidation.isValid) return;
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
        ? 'طلب تواصل مع خبير تربوي\n\nرقم الجوال: ${phoneValidation.e164}\n\nتفاصيل المساعدة المطلوبة:\n${_details.text.trim()}\n\nأسماء الأطفال وأعمارهم (بموافقة الوالد):\n${_childDetails()}'
        : 'Educational expert contact request\n\nMobile: ${phoneValidation.e164}\n\nRequested help:\n${_details.text.trim()}\n\nChildren’s names and ages (with parent consent):\n${_childDetails()}';
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

  Future<void> _openKidsManagement() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AgeSafetyProfilesScreen(
          openChildManagerOnStart: true,
        ),
      ),
    );
    if (!mounted) return;
    await _loadChildren();
  }

  Widget _buildChildRequirement() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.family_restroom_outlined, size: 56),
              const SizedBox(height: 18),
              Text(
                _ar
                    ? 'عرّف طفلًا واحدًا على الأقل أولًا'
                    : 'Define at least one child first',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _ar
                    ? 'تتضمن رسالة الخبير اسم الطفل وعمره فقط بعد موافقتك. أضف أو عدّل بيانات طفل من إدارة الأطفال ثم عُد إلى هذا الطلب.'
                    : 'The expert request can include a child’s name and age only with your consent. Add or edit a child in Kids Management, then return to this request.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                key: const Key('expert-contact-open-kids-management'),
                onPressed: _openKidsManagement,
                icon: const Icon(Icons.manage_accounts_outlined),
                label: Text(_ar ? 'فتح إدارة الأطفال' : 'Open Kids Management'),
              ),
            ],
          ),
        ),
      );

  @override
  void dispose() {
    _phone.dispose();
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String countryName = CountryMobilePhoneValidator.countryNameFor(
      _country,
      isArabic: _ar,
    );
    final String callingCode = CountryMobilePhoneValidator.callingCodeFor(
      _country,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _ar ? 'طلب تواصل مع خبير تربوى' : 'Request an educational expert',
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_hasDefinedChild
              ? _buildChildRequirement()
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
                          labelText: _ar
                              ? 'رقم الجوال للتواصل'
                              : 'Mobile number for contact',
                          helperText: _ar
                              ? 'الدولة المحددة: $countryName ($callingCode).'
                              : 'Selected country: $countryName ($callingCode).',
                          border: const OutlineInputBorder(),
                        ),
                        validator: _mobileValidationError,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _details,
                        minLines: 4,
                        maxLines: 8,
                        decoration: InputDecoration(
                          labelText: _ar
                              ? 'كيف يمكن للخبير مساعدتك؟'
                              : 'How can the expert help?',
                          border: const OutlineInputBorder(),
                        ),
                        validator: (String? value) =>
                            value == null || value.trim().isEmpty
                                ? (_ar
                                    ? 'أدخل تفاصيل الطلب.'
                                    : 'Enter request details.')
                                : null,
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                _ar
                                    ? 'سيظهر في مسودة البريد:'
                                    : 'The email draft will include:',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
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
                        title: Text(
                          _ar
                              ? 'أوافق على تضمين أسماء الأطفال وأعمارهم في هذه الرسالة إلى الخبير.'
                              : 'I agree to include children’s names and ages in this email to the expert.',
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        onPressed: _openEmailDraft,
                        icon: const Icon(Icons.email_outlined),
                        label: Text(
                          _ar
                              ? 'فتح مسودة البريد للمراجعة والإرسال'
                              : 'Open email draft to review and send',
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
