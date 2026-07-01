import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../binder/providers/binder_provider.dart';
import '../models/trade_match_summary.dart';

class CommunityTradeGrowthPanel extends StatelessWidget {
  const CommunityTradeGrowthPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final binderProvider = context.watch<BinderProvider?>();
    final stats = binderProvider?.stats;
    final summary =
        stats == null ? null : TradeMatchSummary.fromBinderStats(stats);

    return Container(
      key: const Key('community-trade-growth-panel'),
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.brass400.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.hub_outlined, color: AppTheme.brass400),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Rede de decks e trocas',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            summary?.primaryInsight ??
                'Publique decks, abra fichários e use want list para encontrar cartas faltantes.',
            style: const TextStyle(color: AppTheme.textSecondary, height: 1.35),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ActionChipButton(
                label: 'Fichário',
                icon: Icons.collections_bookmark_outlined,
                onTap: () => context.push('/collection?tab=0'),
              ),
              _ActionChipButton(
                label: 'Want list',
                icon: Icons.checklist_outlined,
                onTap: () => context.push('/collection?tab=0'),
              ),
              _ActionChipButton(
                label: 'Trades',
                icon: Icons.swap_horiz_rounded,
                onTap: () => context.push('/trades'),
              ),
              _ActionChipButton(
                label: 'Buscar jogadores',
                icon: Icons.person_search,
                onTap: () => context.push('/community/search-users'),
              ),
            ],
          ),
          if (summary != null) ...[
            const SizedBox(height: 12),
            _TradeMatchMetrics(summary: summary),
          ],
        ],
      ),
    );
  }
}

class _TradeMatchMetrics extends StatelessWidget {
  const _TradeMatchMetrics({required this.summary});

  final TradeMatchSummary summary;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _MetricPill(label: 'faltantes', value: '${summary.missingCards}'),
        _MetricPill(label: 'want list', value: '${summary.wishlistCards}'),
        _MetricPill(label: 'para troca', value: '${summary.cardsForTrade}'),
        _MetricPill(label: 'duplicadas', value: '${summary.duplicateCopies}'),
      ],
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.backgroundAbyss.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Text(
        '$value $label',
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: AppTheme.fontSm,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ActionChipButton extends StatelessWidget {
  const _ActionChipButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 17),
      label: Text(label),
      onPressed: onTap,
    );
  }
}
