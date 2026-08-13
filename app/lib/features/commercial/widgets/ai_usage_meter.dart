import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../models/manaloom_plan.dart';
import '../providers/commercial_provider.dart';

class AiUsageMeter extends StatelessWidget {
  const AiUsageMeter({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CommercialProvider?>();
    if (provider == null) return const SizedBox.shrink();
    if (!provider.isLoaded) {
      provider.load();
    }
    final snapshot = provider.usageSnapshot;
    final accent = snapshot.isExhausted
        ? AppTheme.error
        : snapshot.isNearLimit
        ? AppTheme.warning
        : AppTheme.brass400;

    return Container(
      key: const Key('ai-usage-meter'),
      padding: EdgeInsets.all(compact ? AppTheme.space12 : AppTheme.space16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: accent, size: 19),
              const SizedBox(width: AppTheme.space8),
              Expanded(
                child: Text(
                  'Ações de IA · ${snapshot.plan.tier.label}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                key: const Key('ai-usage-open-plans-button'),
                onPressed: () => context.push('/plans'),
                child: const Text('Detalhes'),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ações usadas',
                  key: const Key('ai-usage-used-label'),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${(snapshot.ratio * 100).round()}%',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space6),
          Semantics(
            label: 'Ações de inteligência artificial usadas',
            value: '${snapshot.used} de ${snapshot.limit}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              child: LinearProgressIndicator(
                key: const Key('ai-usage-progress'),
                minHeight: 8,
                value: snapshot.ratio,
                backgroundColor: AppTheme.backgroundAbyss.withValues(
                  alpha: 0.55,
                ),
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.space8),
          Text(
            '${snapshot.used} de ${snapshot.limit} usadas · '
            '${snapshot.remaining} disponíveis em ${snapshot.periodKey}.',
            key: const Key('ai-usage-remaining-label'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
