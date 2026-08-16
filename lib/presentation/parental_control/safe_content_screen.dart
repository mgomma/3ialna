import 'package:flutter/material.dart';

import '../../data/local/safe_content_policy_storage_service.dart';
import '../../domain/models/safe_content_policy.dart';

class SafeContentScreen extends StatefulWidget {
  const SafeContentScreen({super.key});

  @override
  State<SafeContentScreen> createState() => _SafeContentScreenState();
}

class _SafeContentScreenState extends State<SafeContentScreen> {
  final SafeContentPolicyStorageService _storage =
      SafeContentPolicyStorageService();
  final TextEditingController _blockedDomainController =
      TextEditingController();
  final TextEditingController _allowedDomainController =
      TextEditingController();

  SafeContentPolicy _policy = SafeContentPolicy.defaultPolicy;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPolicy();
  }

  @override
  void dispose() {
    _blockedDomainController.dispose();
    _allowedDomainController.dispose();
    super.dispose();
  }

  Future<void> _loadPolicy() async {
    final policy = await _storage.getPolicy();
    if (!mounted) return;
    setState(() {
      _policy = policy;
      _isLoading = false;
    });
  }

  Future<void> _savePolicy(SafeContentPolicy policy) async {
    setState(() {
      _policy = policy;
      _isSaving = true;
    });
    await _storage.savePolicy(policy);
    if (!mounted) return;
    setState(() {
      _isSaving = false;
    });
  }

  void _toggleCategory(SafeContentCategory category, bool enabled) {
    final categories = {..._policy.blockedCategories};
    if (enabled) {
      categories.add(category);
    } else {
      categories.remove(category);
    }
    _savePolicy(_policy.copyWith(blockedCategories: categories));
  }

  void _addDomain({required bool blocked}) {
    final controller = blocked
        ? _blockedDomainController
        : _allowedDomainController;
    final domain = SafeContentPolicy.normalizeDomain(controller.text);
    if (domain.isEmpty || !domain.contains('.')) return;

    final domains = blocked
        ? {..._policy.blockedDomains, domain}
        : {..._policy.allowedDomains, domain};
    controller.clear();
    _savePolicy(blocked
        ? _policy.copyWith(blockedDomains: domains)
        : _policy.copyWith(allowedDomains: domains));
  }

  void _removeDomain(String domain, {required bool blocked}) {
    final domains = <String>{
      ...(blocked ? _policy.blockedDomains : _policy.allowedDomains),
    };
    domains.remove(domain);
    _savePolicy(blocked
        ? _policy.copyWith(blockedDomains: domains)
        : _policy.copyWith(allowedDomains: domains));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Safe Content'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: SwitchListTile(
              title: const Text('Enable safe-content policy'),
              subtitle: const Text(
                'Apply the selected rules to supported 3ialna enforcement services.',
              ),
              value: _policy.enabled,
              onChanged: (value) => _savePolicy(_policy.copyWith(enabled: value)),
            ),
          ),
          const SizedBox(height: 12),
          Text('Content categories', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'These rules are transparent and parent-configurable. A future Android VPN or browser integration can enforce the same policy.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          ...SafeContentCategory.values.map(
            (category) => CheckboxListTile(
              title: Text(category.displayName),
              value: _policy.blockedCategories.contains(category),
              onChanged: _policy.enabled
                  ? (value) => _toggleCategory(category, value ?? false)
                  : null,
            ),
          ),
          SwitchListTile(
            title: const Text('Allow social media'),
            subtitle: const Text('Keep social-media domains available unless manually blocked.'),
            value: _policy.allowSocialMedia,
            onChanged: _policy.enabled
                ? (value) => _savePolicy(_policy.copyWith(allowSocialMedia: value))
                : null,
          ),
          const Divider(height: 32),
          _DomainEditor(
            title: 'Blocked domains',
            hintText: 'example.com',
            controller: _blockedDomainController,
            domains: _policy.blockedDomains,
            onAdd: () => _addDomain(blocked: true),
            onRemove: (domain) => _removeDomain(domain, blocked: true),
          ),
          const SizedBox(height: 24),
          _DomainEditor(
            title: 'Allowed domains',
            hintText: 'school.example',
            controller: _allowedDomainController,
            domains: _policy.allowedDomains,
            onAdd: () => _addDomain(blocked: false),
            onRemove: (domain) => _removeDomain(domain, blocked: false),
          ),
          const SizedBox(height: 24),
          Card(
            color: theme.colorScheme.surfaceContainerHighest,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Privacy note: this first policy layer stores only rule configuration. It does not read messages, photos, or page content. Android web enforcement requires a separate VPN/browser integration and explicit user permission.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DomainEditor extends StatelessWidget {
  final String title;
  final String hintText;
  final TextEditingController controller;
  final Set<String> domains;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  const _DomainEditor({
    required this.title,
    required this.hintText,
    required this.controller,
    required this.domains,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: 'Domain',
                  hintText: hintText,
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) => onAdd(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              tooltip: 'Add domain',
            ),
          ],
        ),
        if (domains.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: domains
                .map(
                  (domain) => InputChip(
                    label: Text(domain),
                    onDeleted: () => onRemove(domain),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}
