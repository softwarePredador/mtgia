import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../models/commercial_launch_policy.dart';
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
  if (CommercialLaunchPolicy.paidCheckoutEnabled &&
      openUpgrade == true &&
      context.mounted) {
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
    final isFreeBeta = CommercialLaunchPolicy.isFreeBeta;
    return AlertDialog(
      key: const Key('ai-paywall-dialog'),
      title: Row(
        children: [
          Icon(
            isFreeBeta ? Icons.hourglass_bottom_rounded : Icons.lock_outline,
            color: AppTheme.brass400,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isFreeBeta
                  ? '${kind.label}: limite da beta atingido'
                  : '${kind.label} precisa do Pro',
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Você usou ${snapshot.used}/${snapshot.limit} ações de IA ${isFreeBeta ? 'na beta gratuita' : 'no plano ${snapshot.plan.tier.label}'}.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isFreeBeta
                ? 'Compras e upgrades não estão disponíveis nesta fase. Seu acesso volta quando o próximo período de uso começar.'
                : 'No Pro, o ManaLoom libera mais uso mensal, otimização por coleção/orçamento, relatório antes/depois e acompanhamento pós-jogo.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
      actions: [
        if (isFreeBeta)
          ElevatedButton(
            key: const Key('ai-beta-limit-dismiss-button'),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Entendi'),
          )
        else ...[
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
      ],
    );
  }
}
