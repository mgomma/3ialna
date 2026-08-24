import 'package:flutter/material.dart';

import '../../../domain/models/safe_content_policy.dart';

class DomainRulesTabs extends StatefulWidget {
  final Set<String> blockedDomains;
  final Set<String> allowedDomains;
  final bool isArabic;
  final ValueChanged<String> onAddBlocked;
  final ValueChanged<String> onAddAllowed;
  final ValueChanged<String> onRemoveBlocked;
  final ValueChanged<String> onRemoveAllowed;

  const DomainRulesTabs({
    super.key,
    required this.blockedDomains,
    required this.allowedDomains,
    required this.isArabic,
    required this.onAddBlocked,
    required this.onAddAllowed,
    required this.onRemoveBlocked,
    required this.onRemoveAllowed,
  });

  @override
  State<DomainRulesTabs> createState() => _DomainRulesTabsState();
}

class _DomainRulesTabsState extends State<DomainRulesTabs>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Directionality(
      textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isArabic ? 'قواعد النطاقات' : 'Domain rules',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            widget.isArabic
                ? 'تأخذ النطاقات المسموح بها أولوية على قواعد الحظر.'
                : 'Allowed domains take precedence over blocked rules.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: widget.isArabic ? 'البحث في النطاقات' : 'Search domains',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      onPressed: _searchController.clear,
                      icon: const Icon(Icons.clear),
                      tooltip: widget.isArabic ? 'مسح البحث' : 'Clear search',
                    ),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: _tabLabel('blocked', widget.blockedDomains.length)),
              Tab(text: _tabLabel('allowed', widget.allowedDomains.length)),
            ],
          ),
          SizedBox(
            height: 300,
            child: TabBarView(
              controller: _tabController,
              children: [
                _DomainList(
                  domains: _filtered(widget.blockedDomains),
                  isArabic: widget.isArabic,
                  emptyText: widget.isArabic
                      ? 'لا توجد نطاقات محظورة مخصّصة. يمكنك استخدام فئات الحماية أو إضافة نطاق يدوي.'
                      : 'No custom blocked domains. Use categories or add a domain manually.',
                  addLabel: widget.isArabic ? 'إضافة نطاق' : 'Add domain',
                  onAdd: () => _showAddDialog(blocked: true),
                  onRemove: widget.onRemoveBlocked,
                ),
                _DomainList(
                  domains: _filtered(widget.allowedDomains),
                  isArabic: widget.isArabic,
                  emptyText: widget.isArabic
                      ? 'لا توجد استثناءات. ستظل قواعد الفئات مطبّقة على النطاقات غير المستثناة.'
                      : 'No exceptions. Category rules remain active for non-allowed domains.',
                  addLabel: widget.isArabic ? 'إضافة استثناء' : 'Add exception',
                  onAdd: () => _showAddDialog(blocked: false),
                  onRemove: widget.onRemoveAllowed,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _tabLabel(String kind, int count) {
    final label = widget.isArabic
        ? (kind == 'blocked' ? 'المحظورة' : 'المسموح بها')
        : (kind == 'blocked' ? 'Blocked' : 'Allowed');
    return '$label ($count)';
  }

  Set<String> _filtered(Set<String> domains) {
    if (_query.isEmpty) return domains;
    return domains.where((domain) => domain.contains(_query)).toSet();
  }

  Future<void> _showAddDialog({required bool blocked}) async {
    String input = '';
    final value = await showDialog<String>(
      context: context,
      builder: (context) => Directionality(
        textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          title: Text(widget.isArabic ? 'إضافة نطاق' : 'Add domain'),
          content: TextField(
            autofocus: true,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: widget.isArabic ? 'النطاق أو الرابط' : 'Domain or URL',
              hintText: 'example.com',
              helperText: widget.isArabic
                  ? 'سيتم تطبيق القاعدة على النطاق وجميع النطاقات الفرعية.'
                  : 'The rule applies to the domain and its subdomains.',
              border: const OutlineInputBorder(),
            ),
            onChanged: (String value) => input = value,
            onSubmitted: (_) => Navigator.of(context).pop(input),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(widget.isArabic ? 'إلغاء' : 'Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(input),
              child: Text(blocked
                  ? (widget.isArabic ? 'حظر هذا النطاق' : 'Block domain')
                  : (widget.isArabic ? 'السماح بهذا النطاق' : 'Allow domain')),
            ),
          ],
        ),
      ),
    );
    if (!mounted || value == null) return;

    final domain = SafeContentPolicy.normalizeDomain(value);
    if (domain.isEmpty || !domain.contains('.')) {
      _showError(widget.isArabic
          ? 'أدخل نطاقاً صحيحاً مثل example.com.'
          : 'Enter a valid domain such as example.com.');
      return;
    }
    final existing = blocked ? widget.blockedDomains : widget.allowedDomains;
    if (existing.contains(domain)) {
      _showError(widget.isArabic
          ? 'هذا النطاق موجود بالفعل.'
          : 'This domain already exists.');
      return;
    }
    if (blocked) {
      widget.onAddBlocked(domain);
    } else {
      widget.onAddAllowed(domain);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _DomainList extends StatelessWidget {
  final Set<String> domains;
  final bool isArabic;
  final String emptyText;
  final String addLabel;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  const _DomainList({
    required this.domains,
    required this.isArabic,
    required this.emptyText,
    required this.addLabel,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (domains.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.language_outlined, size: 40),
              const SizedBox(height: 8),
              Text(emptyText, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: Text(addLabel),
              ),
            ],
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: domains
          .map(
            (domain) => ListTile(
              leading: const Icon(Icons.public),
              title: Text(domain, textDirection: TextDirection.ltr),
              trailing: IconButton(
                onPressed: () => onRemove(domain),
                icon: const Icon(Icons.delete_outline),
                tooltip: isArabic ? 'حذف القاعدة' : 'Remove rule',
              ),
            ),
          )
          .toList(),
    );
  }
}
