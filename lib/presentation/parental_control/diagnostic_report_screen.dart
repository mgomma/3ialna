import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

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
                  FilledButton.icon(onPressed: _share, icon: const Icon(Icons.ios_share_outlined), label: Text(_isArabic ? 'مشاركة التقرير' : 'Share report')),
                ],
              ),
            ),
    );
  }
}
