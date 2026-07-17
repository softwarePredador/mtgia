import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/commercial_launch_policy.dart';

class FreeBetaNotice extends StatelessWidget {
  const FreeBetaNotice({
    super.key,
    this.title = 'Tudo o que está disponível agora, sem cobrança',
    this.description =
        'Use o ManaLoom para preparar decks, organizar sua coleção e acompanhar partidas enquanto refinamos a experiência com a comunidade.',
  });

  final String title;
  final String description;

  static const _capabilities = <(IconData, String)>[
    (Icons.auto_awesome_outlined, 'Decks e IA com revisão'),
    (Icons.style_outlined, 'Coleção e fichário'),
    (Icons.people_alt_outlined, 'Trocas e comunidade'),
    (Icons.favorite_border_rounded, 'Life Counter e pós-jogo'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.brass400.withValues(alpha: 0.42)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            key: const Key('free-beta-status-badge'),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.brass400.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              border: Border.all(
                color: AppTheme.brass400.withValues(alpha: 0.5),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.explore_outlined,
                  size: 17,
                  color: AppTheme.brass400,
                ),
                SizedBox(width: 7),
                Text(
                  CommercialLaunchPolicy.betaLabel,
                  style: TextStyle(
                    color: AppTheme.brass400,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final capability in _capabilities)
                _BetaCapability(icon: capability.$1, label: capability.$2),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: AppTheme.outlineMuted, height: 1),
          const SizedBox(height: 14),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.verified_user_outlined,
                size: 20,
                color: AppTheme.frost400,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Não há assinatura, checkout ou cobrança nesta beta. Qualquer oferta futura será apresentada separadamente e exigirá confirmação explícita.',
                  style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BetaCapability extends StatelessWidget {
  const _BetaCapability({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.outlineMuted),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppTheme.frost400),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
