import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../models/manaloom_plan.dart';
import '../providers/commercial_provider.dart';

Future<bool> reserveAiActionOrShowPaywall(
  BuildContext context, {
  required AiUsageKind kind,
}) async {
  CommercialProvider? provider;
  try {
    provider = context.read<CommercialProvider>();
  } on ProviderNotFoundException {
    return true;
  }

  await provider.load();
  final hasQuota =
      ApiClient.hasAuthenticationToken
          ? await _checkAuthoritativeQuota(provider)
          : await provider.consumeAiAction(kind);
  if (hasQuota) {
    return true;
  }

  if (!context.mounted) return false;
  final openUpgrade = await showDialog<bool>(
    context: context,
    builder: (_) => AiPaywallDialog(kind: kind, provider: provider!),
  );
  if (openUpgrade == true && context.mounted) {
    context.push('/upgrade');
  }
  return false;
}

Future<bool> _checkAuthoritativeQuota(CommercialProvider provider) async {
  await provider.refreshFromServer();
  // The API middleware is the final authority. A transient plan-read failure
  // must not create a second, divergent quota counter in the app.
  return !provider.isRemoteSynced || provider.canUseAi;
}

Future<void> refreshAiUsageAfterAction(BuildContext context) async {
  if (!ApiClient.hasAuthenticationToken || !context.mounted) return;

  CommercialProvider? provider;
  try {
    provider = context.read<CommercialProvider>();
  } on ProviderNotFoundException {
    return;
  }
  await provider.refreshFromServer();
}

class AiPaywallDialog extends StatelessWidget {
  const AiPaywallDialog({
    super.key,
    required this.kind,
    required this.provider,
  });

  final AiUsageKind kind;
  final CommercialProvider provider;

  @override
  Widget build(BuildContext context) {
    final snapshot = provider.usageSnapshot;
    final theme = Theme.of(context);
    return AlertDialog(
      key: const Key('ai-paywall-dialog'),
      title: Row(
        children: [
          const Icon(Icons.lock_outline, color: AppTheme.brass400),
          const SizedBox(width: 10),
          Expanded(child: Text('${kind.label} precisa do Pro')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Você usou ${snapshot.used}/${snapshot.limit} ações de IA no plano ${snapshot.plan.tier.label}.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No Pro, o ManaLoom libera mais uso mensal, otimização por coleção/orçamento, relatório antes/depois e acompanhamento pós-jogo.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Agora não'),
        ),
        ElevatedButton(
          key: const Key('ai-paywall-upgrade-button'),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Ver upgrade'),
        ),
      ],
    );
  }
}
