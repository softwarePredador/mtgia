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
    final summary = stats == null
        ? null
        : TradeMatchSummary.fromBinderStats(stats);
    final subtitle = summary == null
        ? 'Encontre jogadores para completar sua lista.'
        : '${summary.missingCards} faltantes • '
              '${summary.cardsForTrade} para troca';

    return Material(
      key: const Key('community-trade-growth-panel'),
      color: AppTheme.transparent,
      child: InkWell(
        onTap: () => context.push('/trades'),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          margin: const EdgeInsets.fromLTRB(
            AppTheme.space14,
            AppTheme.space12,
            AppTheme.space14,
            AppTheme.space4,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space12,
            vertical: AppTheme.space10,
          ),
          decoration: BoxDecoration(
            color: AppTheme.surfaceSlate.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.outlineMuted),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.hub_outlined,
                color: AppTheme.brass400,
                size: 22,
              ),
              const SizedBox(width: AppTheme.space10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rede de decks e trocas',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: AppTheme.fontSm,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.space8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
