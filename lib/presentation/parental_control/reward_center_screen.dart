import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/local/age_safety_profile_service.dart';
import '../../data/local/reward_service.dart';
import '../../data/system/parent_voice_notification_service.dart';
import '../../domain/models/child_profile.dart';
import 'pin_auth_screen.dart';

class RewardCenterScreen extends StatefulWidget {
  const RewardCenterScreen({super.key});

  @override
  State<RewardCenterScreen> createState() => _RewardCenterScreenState();
}

class _RewardCenterScreenState extends State<RewardCenterScreen> {
  final RewardService _rewards = const RewardService();
  final ParentVoiceNotificationService _voice = ParentVoiceNotificationService();
  final TextEditingController _rewardController = TextEditingController();
  List<ChildProfile> _children = <ChildProfile>[];
  List<RewardOption> _rewardOptions = <RewardOption>[];
  List<ChildExtraTimeRequest> _requests = <ChildExtraTimeRequest>[];
  List<int> _requestDurations = <int>[5];
  final Map<String, FlexTokenBalance> _balances = <String, FlexTokenBalance>{};
  bool _loading = true;

  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _rewardController.dispose();
    _voice.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final AgeSafetyProfileService profiles = AgeSafetyProfileService(await SharedPreferences.getInstance());
    final List<ChildProfile> children = profiles.loadChildren();
    final List<RewardOption> rewards = await _rewards.loadRewards();
    final List<ChildExtraTimeRequest> requests = await _rewards.loadRequests();
    final List<int> requestDurations = await _rewards.loadRequestDurations();
    for (final ChildProfile child in children) {
      _balances[child.id] = await _rewards.loadTokens(child.id);
    }
    if (!mounted) return;
    setState(() {
      _children = children;
      _rewardOptions = rewards;
      _requests = requests;
      _requestDurations = requestDurations;
      _loading = false;
    });
  }

  Future<void> _addReward() async {
    final String title = _rewardController.text.trim();
    if (title.isEmpty) return;
    final RewardOption option = RewardOption(id: 'reward-${DateTime.now().microsecondsSinceEpoch}', title: title, enabled: true);
    await _rewards.saveRewards(<RewardOption>[..._rewardOptions, option]);
    _rewardController.clear();
    await _load();
  }

  Future<void> _issueToken(ChildProfile child) async {
    _balances[child.id] = await _rewards.issueToken(child.id);
    if (mounted) setState(() {});
  }

  Future<void> _approve(ChildExtraTimeRequest request) async {
    final bool? authenticated = await Navigator.of(context).push<bool>(MaterialPageRoute<bool>(builder: (BuildContext context) => PinAuthScreen(onAuthenticated: () => Navigator.of(context).pop(true))));
    if (authenticated != true) return;
    final ChildExtraTimeRequest? approved = await _rewards.approveRequest(request.id);
    if (approved == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_ar ? 'لا يوجد توكن متاح أو تمت معالجة الطلب.' : 'No token is available or this request was already processed.')));
      return;
    }
    if (approved.packageName.isNotEmpty) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        'flutter.snooze_until_${approved.packageName}',
        DateTime.now().add(Duration(minutes: approved.minutes)).millisecondsSinceEpoch,
      );
    }
    try {
      await _voice.playRecording();
    } catch (_) {
      // Approval remains successful if no parent celebration recording exists.
    }
    await _load();
  }

  Future<void> _toggleRequestDuration(int minutes) async {
    final List<int> selected = _requestDurations.contains(minutes)
        ? _requestDurations.where((int value) => value != minutes).toList()
        : <int>[..._requestDurations, minutes];
    final List<int> saved = await _rewards.saveRequestDurations(selected);
    if (mounted) setState(() => _requestDurations = saved);
  }

  Future<void> _reject(ChildExtraTimeRequest request) async {
    await _rewards.updateRequestStatus(request.id, 'rejected');
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_ar ? 'المكافآت والتوكنات' : 'Rewards and tokens')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                Text(_ar ? 'مكافآت غير رقمية' : 'Offline, non-screen rewards', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(_ar ? 'أضف مكافآت يحددها الوالد مثل اختيار قصة أو نشاط عائلي. لا تمنح المكافآت وقت شاشة تلقائيًا.' : 'Add parent-defined rewards such as choosing a story or family activity. Rewards never grant screen time automatically.'),
                const SizedBox(height: 12),
                Row(children: <Widget>[Expanded(child: TextField(controller: _rewardController, decoration: InputDecoration(labelText: _ar ? 'اسم المكافأة' : 'Reward name'))), const SizedBox(width: 8), IconButton(onPressed: _addReward, icon: const Icon(Icons.add_circle))]),
                for (final RewardOption reward in _rewardOptions) ListTile(leading: const Icon(Icons.card_giftcard_outlined), title: Text(reward.title)),
                const Divider(height: 32),
                Text(_ar ? 'توكنات المرونة' : 'Flex Tokens', style: Theme.of(context).textTheme.titleLarge),
                Text(_ar ? 'التوكن يمنح الوالد طريقة واضحة للموافقة على طلب وقت إضافي. يصدره الوالد ويُستهلك عند الموافقة.' : 'A token gives the parent a clear way to approve extra-time requests. The parent issues it and it is consumed on approval.'),
                for (final ChildProfile child in _children)
                  ListTile(
                    leading: const Icon(Icons.stars_outlined),
                    title: Text(child.name),
                    subtitle: Text(_ar ? 'المتاح: ${_balances[child.id]?.available ?? 0}' : 'Available: ${_balances[child.id]?.available ?? 0}'),
                    trailing: TextButton(onPressed: () => _issueToken(child), child: Text(_ar ? 'إصدار توكن' : 'Issue token')),
                  ),
                const Divider(height: 32),
                Text(_ar ? 'مدد طلب الوقت الإضافي' : 'Extra-time request durations', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(_ar ? 'اختر المدد التي يمكن للطفل طلبها. تبقى الخيارات محلية.' : 'Choose which durations a child can request. These options stay local.'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: <int>[5, 10, 15, 30].map((int minutes) => FilterChip(
                    label: Text(_ar ? '$minutes دقائق' : '$minutes min'),
                    selected: _requestDurations.contains(minutes),
                    onSelected: (_) => _toggleRequestDuration(minutes),
                  )).toList(),
                ),
                const Divider(height: 32),
                Text(_ar ? 'طلبات وقت إضافي (${_requests.where((ChildExtraTimeRequest item) => item.status == 'pending').length})' : 'Extra-time requests (${_requests.where((ChildExtraTimeRequest item) => item.status == 'pending').length})', style: Theme.of(context).textTheme.titleLarge),
                if (_requests.where((ChildExtraTimeRequest item) => item.status == 'pending').isEmpty) Text(_ar ? 'لا توجد طلبات معلقة.' : 'No pending requests.'),
                for (final ChildExtraTimeRequest request in _requests.where((ChildExtraTimeRequest item) => item.status == 'pending'))
                  Card(child: ListTile(title: Text(_ar ? 'طلب ${request.minutes} دقائق' : 'Request for ${request.minutes} minutes'), subtitle: Text(_ar ? 'يحتاج موافقة الوالد' : 'Needs parent approval'), trailing: Wrap(children: <Widget>[IconButton(onPressed: () => _reject(request), icon: const Icon(Icons.close)), IconButton(onPressed: () => _approve(request), icon: const Icon(Icons.check))]))),
                const SizedBox(height: 12),
                Text(_ar ? 'الحالة والطلبات والتسجيلات محفوظة محليًا على الجهاز.' : 'Balances, requests, and recordings stay local on this device.', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
    );
  }
}

