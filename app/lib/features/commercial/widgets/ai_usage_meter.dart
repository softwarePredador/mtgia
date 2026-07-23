import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../models/commercial_launch_policy.dart';
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
    final planLabel = CommercialLaunchPolicy.isFreeBeta && !snapshot.plan.isPro
        ? CommercialLaunchPolicy.betaLabel
        : snapshot.plan.tier.label;
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
                  'Uso de IA · $planLabel',
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
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: snapshot.ratio,
              backgroundColor: AppTheme.backgroundAbyss.withValues(alpha: 0.55),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: AppTheme.space8),
          Text(
            '${snapshot.remaining} de ${snapshot.limit} ações restantes em ${snapshot.periodKey}.',
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
