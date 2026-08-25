import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/system/error_report_service.dart';

/// Parent-controlled export of the sanitized, local diagnostic ring buffer.
class DiagnosticReportScreen extends StatefulWidget {
  const DiagnosticReportScreen({super.key});

  @override
  State<DiagnosticReportScreen> createState() => _DiagnosticReportScreenState();
}

class _DiagnosticReportScreenState extends State<DiagnosticReportScreen> {
  String? _report;
  bool _loading = true;

  bool get _isArabic => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final String report = await ErrorReportService.buildShareText();
    if (!mounted) return;
    setState(() {
      _report = report;
      _loading = false;
    });
  }

  Future<void> _sendByEmail() async {
    if (_report == null) return;
    try {
      final Uri email = await ErrorReportService.buildEmailUri();
      if (!await launchUrl(email, mode: LaunchMode.externalApplication) && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isArabic ? 'تعذر فتح تطبيق البريد.' : 'Could not open the email app.')));
      }
    } catch (error, stackTrace) {
      ErrorReportService.recordHandled(source: 'diagnostic_share', error: error, stackTrace: stackTrace);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isArabic ? 'تعذر تجهيز تقرير الأعطال.' : 'Could not prepare the diagnostic report.')));
    }
  }

  Future<void> _share() async {
    if (_report == null) return;
    try {
      await Share.share(_report!, subject: '3ialna diagnostic report');
    } catch (error, stackTrace) {
      ErrorReportService.recordHandled(source: 'diagnostic_share', error: error, stackTrace: stackTrace);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isArabic ? 'تعذر فتح المشاركة.' : 'Could not open sharing.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isArabic ? 'تقرير الأعطال' : 'Diagnostic report')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    _isArabic
                        ? 'راجع التقرير ثم اختر تطبيق المشاركة لإرساله إلى الدعم. لا يتضمن أسماء الأطفال أو تواريخ ميلادهم أو PIN أو التسجيلات أو الاستخدام أو قواعد التطبيقات.'
                        : 'Review the report, then choose a sharing app to send it to support. It excludes child names, birth dates, PINs, recordings, usage, and app rules.',
                  ),
                  const SizedBox(height: 12),
                  Expanded(child: DecoratedBox(decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.outline), borderRadius: BorderRadius.circular(12)), child: SingleChildScrollView(padding: const EdgeInsets.all(12), child: SelectableText(_report ?? '')))),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: <Widget>[
                      FilledButton.icon(onPressed: _sendByEmail, icon: const Icon(Icons.email_outlined), label: Text(_isArabic ? 'إرسال بالبريد' : 'Send by email')),
                      OutlinedButton.icon(onPressed: _share, icon: const Icon(Icons.ios_share_outlined), label: Text(_isArabic ? 'مشاركة التقرير' : 'Share report')),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
