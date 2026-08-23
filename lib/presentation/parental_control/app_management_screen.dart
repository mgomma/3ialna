import 'package:flutter/material.dart';
import '../../domain/models/app_info.dart';
import '../../data/system/app_list_service.dart';
import '../../data/local/parental_control_storage_service.dart';
import '../../data/system/app_usage_service.dart';
import '../../domain/models/managed_app_category.dart';
import '../widgets/app_card.dart';
import '../widgets/time_limit_selector.dart';

/// Screen for managing app blocking and time limits.
class AppManagementScreen extends StatefulWidget {
  const AppManagementScreen({super.key});

  @override
  State<AppManagementScreen> createState() => _AppManagementScreenState();
}

class _AppManagementScreenState extends State<AppManagementScreen> {
  final AppListService _appListService = AppListService();
  final ParentalControlStorageService _storage =
      ParentalControlStorageService();
  final AppUsageService _usageService = AppUsageService();

  List<AppInfo> _allApps = [];
  List<String> _blockedApps = [];
  Map<String, int> _timeLimits = {};
  Map<String, int> _currentUsage = {};
  Map<String, ManagedAppCategory> _categories = {};
  bool _isLoading = true;
  String _searchQuery = '';
  bool _showOnlyBlocked = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apps = await _appListService.getAllInstalledApps(
        includeSystemApps: false,
      );
      final blocked = await _storage.getBlockedApps();
      final limits = await _storage.getTimeLimits();
      final categories = await _storage.getAppCategories();

      // Get current usage for apps with limits
      final usageMap = <String, int>{};
      for (final packageName in limits.keys) {
        try {
          final usage = await _usageService.getTodayUsageForApp(packageName);
          usageMap[packageName] = usage;
        } catch (e) {
          usageMap[packageName] = 0;
        }
      }

      setState(() {
        _allApps = apps;
        _blockedApps = blocked;
        _timeLimits = limits;
        _currentUsage = usageMap;
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading apps: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  List<AppInfo> get _filteredApps {
    var apps = _allApps;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      apps = apps.where((app) {
        return app.appName
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            app.packageName.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Filter by blocked status
    if (_showOnlyBlocked) {
      apps = apps.where((app) => _blockedApps.contains(app.packageName)).toList();
    }

    return apps;
  }

  Future<void> _toggleBlock(AppInfo app) async {
    final isBlocked = _blockedApps.contains(app.packageName);
    if (isBlocked) {
      await _storage.unblockApp(app.packageName);
    } else {
      await _storage.blockApp(app.packageName);
    }
    await _loadData();
  }

  Future<void> _setTimeLimit(AppInfo app) async {
    final currentLimit = _timeLimits[app.packageName];
    showDialog(
      context: context,
      builder: (context) => TimeLimitSelector(
        initialMinutes: currentLimit,
        onTimeLimitSelected: (minutes) async {
          await _storage.setAppTimeLimit(app.packageName, minutes);
          await _loadData();
        },
      ),
    );
  }

  String _categoryLabel(ManagedAppCategory category) => switch (category) {
        ManagedAppCategory.socialMedia => 'Social media (shared budget)',
        ManagedAppCategory.games => 'Games (shared budget)',
        ManagedAppCategory.unassigned => 'Not assigned',
      };

  Future<void> _setCategory(AppInfo app) async {
    final ManagedAppCategory current = _categories[app.packageName] ?? ManagedAppCategory.unassigned;
    final ManagedAppCategory? chosen = await showModalBottomSheet<ManagedAppCategory>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: RadioGroup<ManagedAppCategory>(
          groupValue: current,
          onChanged: (ManagedAppCategory? value) => Navigator.pop(context, value),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ManagedAppCategory.values
                .map((ManagedAppCategory category) => RadioListTile<ManagedAppCategory>(
                      value: category,
                      title: Text(_categoryLabel(category)),
                    ))
                .toList(growable: false),
          ),
        ),
      ),
    );
    if (chosen == null) return;
    await _storage.setAppCategory(app.packageName, chosen);
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search apps...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    FilterChip(
                      label: const Text('Show Blocked Only'),
                      selected: _showOnlyBlocked,
                      onSelected: (selected) {
                        setState(() {
                          _showOnlyBlocked = selected;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          // App list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredApps.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.apps_outlined,
                              size: 64,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No apps found'
                                  : 'No apps to display',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredApps.length,
                        itemBuilder: (context, index) {
                          final app = _filteredApps[index];
                          final isBlocked = _blockedApps.contains(app.packageName);
                          final timeLimit = _timeLimits[app.packageName];
                          final usage = _currentUsage[app.packageName] ?? 0;
                          final category = _categories[app.packageName] ?? ManagedAppCategory.unassigned;

                          return AppCard(
                            appInfo: app,
                            isBlocked: isBlocked,
                            timeLimitMinutes: timeLimit,
                            currentUsageMinutes: timeLimit != null ? usage : null,
                            onToggleBlock: () => _toggleBlock(app),
                            onSetTimeLimit: () => _setTimeLimit(app),
                            categoryLabel: _categoryLabel(category),
                            onSetCategory: () => _setCategory(app),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
