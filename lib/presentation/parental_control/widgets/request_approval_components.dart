import 'package:flutter/material.dart';

import '../../../data/local/reward_service.dart';
import '../../../l10n/app_localizations.dart';

class ChildRequestDurationDialog {
  const ChildRequestDurationDialog._();

  static Future<int?> show(BuildContext context, List<int> durations) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return showDialog<int>(
      context: context,
      builder: (BuildContext dialogContext) => SimpleDialog(
        title: Text(l10n.requestExtraTime),
        children: durations
            .map(
              (int minutes) => SimpleDialogOption(
                onPressed: () => Navigator.of(dialogContext).pop(minutes),
                child: Text(l10n.durationMinutes(minutes)),
              ),
            )
            .toList(),
      ),
    );
  }
}

class ChildRequestPendingBanner extends StatelessWidget {
  const ChildRequestPendingBanner({super.key, required this.pending, required this.onRequest});

  final bool pending;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    if (pending) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.hourglass_top),
        label: Text(l10n.requestPending),
      );
    }
    return OutlinedButton.icon(
      onPressed: onRequest,
      icon: const Icon(Icons.more_time),
      label: Text(l10n.requestExtraTime),
    );
  }
}

class PendingRequestBadge extends StatelessWidget {
  const PendingRequestBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n.pendingRequestCount(count),
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '$count',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onError,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class PendingRequestCard extends StatelessWidget {
  const PendingRequestCard({
    super.key,
    required this.request,
    required this.childName,
    required this.tokenAvailable,
    required this.onApprove,
    required this.onDecline,
  });

  final ChildExtraTimeRequest request;
  final String childName;
  final int tokenAvailable;
  final VoidCallback onApprove;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Card(
      child: ListTile(
        title: Text(l10n.requestForChild(childName)),
        subtitle: Text('${l10n.durationMinutes(request.minutes)} · ${l10n.tokensAvailable(tokenAvailable)}'),
        leading: const Icon(Icons.more_time),
        trailing: Wrap(
          spacing: 2,
          children: <Widget>[
            IconButton(
              tooltip: l10n.decline,
              onPressed: onDecline,
              icon: const Icon(Icons.close),
            ),
            IconButton(
              tooltip: l10n.approve,
              onPressed: tokenAvailable > 0 ? onApprove : null,
              icon: const Icon(Icons.check),
            ),
          ],
        ),
      ),
    );
  }
}

class ApprovalDecisionSheet extends StatelessWidget {
  const ApprovalDecisionSheet({
    super.key,
    required this.request,
    required this.childName,
    required this.tokenAvailable,
    required this.onApprove,
    required this.onDecline,
  });

  final ChildExtraTimeRequest request;
  final String childName;
  final int tokenAvailable;
  final VoidCallback onApprove;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.lock_outline),
                const SizedBox(width: 8),
                Expanded(child: Text(l10n.reviewExtraTimeRequest, style: Theme.of(context).textTheme.titleLarge)),
              ],
            ),
            const SizedBox(height: 16),
            Text(l10n.requestForChild(childName), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('${l10n.durationMinutes(request.minutes)} · ${l10n.tokensAvailable(tokenAvailable)}'),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                Expanded(child: OutlinedButton(onPressed: onDecline, child: Text(l10n.decline))),
                const SizedBox(width: 12),
                Expanded(child: FilledButton(onPressed: tokenAvailable > 0 ? onApprove : null, child: Text(l10n.approve))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
