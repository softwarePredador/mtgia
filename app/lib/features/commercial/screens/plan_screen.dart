import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../models/manaloom_plan.dart';
import '../providers/commercial_provider.dart';
import '../widgets/ai_usage_meter.dart';

class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CommercialProvider>();
    if (!provider.isLoaded) {
      provider.load();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Planos')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.of(context).padding.bottom,
        ),
        children: [
          const AiUsageMeter(),
          const SizedBox(height: 16),
          _PlanComparisonCard(
            plan: ManaLoomPlan.free,
            active: provider.tier == ManaLoomPlanTier.free,
            onAction:
                provider.isRemoteSynced
                    ? null
                    : () => provider.setPlan(ManaLoomPlanTier.free),
          ),
          const SizedBox(height: 12),
          _PlanComparisonCard(
            plan: ManaLoomPlan.pro,
            active: provider.tier == ManaLoomPlanTier.pro,
            featured: true,
            onAction: () => context.push('/upgrade'),
          ),
          const SizedBox(height: 16),
          if (provider.isRemoteSynced || provider.lastRemoteError != null) ...[
            _RemotePlanStatusPanel(provider: provider),
            const SizedBox(height: 16),
          ],
          _LegalShortcutPanel(),
        ],
      ),
    );
  }
}

class _PlanComparisonCard extends StatelessWidget {
  const _PlanComparisonCard({
    required this.plan,
    required this.active,
    required this.onAction,
    this.featured = false,
  });

  final ManaLoomPlan plan;
  final bool active;
  final bool featured;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final accent = featured ? AppTheme.brass400 : AppTheme.frost400;
    final theme = Theme.of(context);
    return Container(
      key: Key('plan-card-${plan.tier.id}'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: active ? AppTheme.success : accent.withValues(alpha: 0.32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.tier.label,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (active)
                const Chip(
                  label: Text('Atual'),
                  avatar: Icon(Icons.check_circle, size: 16),
                )
              else
                Text(
                  plan.priceLabel,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            plan.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          ...plan.features.map(
            (feature) => _PlanLine(icon: Icons.check, text: feature),
          ),
          const SizedBox(height: 8),
          ...plan.limits.map(
            (limit) =>
                _PlanLine(icon: Icons.info_outline, text: limit, muted: true),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child:
                featured
                    ? ElevatedButton(
                      key: const Key('plan-pro-upgrade-button'),
                      onPressed: active ? null : onAction,
                      child: Text(active ? 'Pro ativo' : 'Fazer upgrade'),
                    )
                    : OutlinedButton(
                      onPressed: active ? null : onAction,
                      child: Text(active ? 'Free ativo' : 'Usar Free'),
                    ),
          ),
        ],
      ),
    );
  }
}

class _RemotePlanStatusPanel extends StatelessWidget {
  const _RemotePlanStatusPanel({required this.provider});

  final CommercialProvider provider;

  @override
  Widget build(BuildContext context) {
    final synced = provider.isRemoteSynced;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: synced ? AppTheme.success : AppTheme.warning),
      ),
      child: Row(
        children: [
          Icon(
            synced ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
            color: synced ? AppTheme.success : AppTheme.warning,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              synced
                  ? 'Plano sincronizado com o backend. O limite exibido é o que bloqueia os endpoints de IA.'
                  : provider.lastRemoteError ?? 'Plano remoto indisponível.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanLine extends StatelessWidget {
  const _PlanLine({required this.icon, required this.text, this.muted = false});

  final IconData icon;
  final String text;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 17,
            color: muted ? AppTheme.textSecondary : AppTheme.success,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: muted ? AppTheme.textSecondary : AppTheme.textPrimary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalShortcutPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.outlineMuted),
      ),
      child: Row(
        children: [
          const Icon(Icons.policy_outlined, color: AppTheme.frost400),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Termos, privacidade, IP e disclaimer ficam disponíveis antes do upgrade.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
                height: 1.35,
              ),
            ),
          ),
          TextButton(
            key: const Key('plans-open-legal-button'),
            onPressed: () => context.push('/legal'),
            child: const Text('Legal'),
          ),
        ],
      ),
    );
  }
}
