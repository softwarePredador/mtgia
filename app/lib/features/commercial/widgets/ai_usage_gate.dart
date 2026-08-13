import 'package:flutter/material.dart';
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
  final hasQuota = ApiClient.hasAuthenticationToken
      ? await _checkAuthoritativeQuota(provider)
      : await provider.consumeAiAction(kind);
  if (hasQuota) {
    return true;
  }

  if (!context.mounted) return false;
  await showDialog<void>(
    context: context,
    builder: (_) => AiQuotaLimitDialog(kind: kind, provider: provider!),
  );
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

class AiQuotaLimitDialog extends StatelessWidget {
  const AiQuotaLimitDialog({
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
      key: const Key('ai-quota-limit-dialog'),
      title: Row(
        children: [
          const Icon(Icons.hourglass_bottom_rounded, color: AppTheme.brass400),
          const SizedBox(width: AppTheme.space10),
          Expanded(child: Text('${kind.label}: limite da beta atingido')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Você usou ${snapshot.used}/${snapshot.limit} ações de IA elegíveis na beta gratuita.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppTheme.space12),
          Text(
            'Não existe compra, upgrade ou paywall nesta fase. O teto é operacional e o saldo volta no próximo período UTC; a disponibilidade de cada recurso continua sendo confirmada pelo servidor.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          key: const Key('ai-beta-limit-dismiss-button'),
          onPressed: () => Navigator.pop(context),
          child: const Text('Entendi'),
        ),
      ],
    );
  }
}
