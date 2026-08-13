import 'package:flutter/material.dart';

import '../../../core/branding/product_identity.dart';
import '../../../core/theme/app_theme.dart';
import '../models/commercial_launch_policy.dart';

class FreeBetaNotice extends StatelessWidget {
  const FreeBetaNotice({
    super.key,
    this.title = 'Beta controlada, gratuita e sem cobrança',
    this.description =
        'O ${ProductIdentity.displayName} confirma no servidor quais recursos estão liberados antes de apresentá-los ou executá-los. Estar na beta não abre automaticamente todas as funções.',
  });

  final String title;
  final String description;

  static const _capabilities = <(IconData, String)>[
    (Icons.money_off_csred_outlined, 'Sem preço ou assinatura'),
    (Icons.verified_user_outlined, 'Disponibilidade pelo servidor'),
    (Icons.rule_outlined, 'IA revisável quando liberada'),
    (Icons.speed_outlined, 'Teto operacional, não comercial'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTheme.space20),
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
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space10,
              vertical: AppTheme.space6,
            ),
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
                SizedBox(width: AppTheme.space7),
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
          const SizedBox(height: AppTheme.space16),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: AppTheme.space10),
          Text(
            description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppTheme.space18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final capability in _capabilities)
                _BetaCapability(icon: capability.$1, label: capability.$2),
            ],
          ),
          const SizedBox(height: AppTheme.space18),
          const Divider(color: AppTheme.outlineMuted, height: 1),
          const SizedBox(height: AppTheme.space14),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.verified_user_outlined,
                size: 20,
                color: AppTheme.frost400,
              ),
              SizedBox(width: AppTheme.space10),
              Expanded(
                child: Text(
                  'Não há assinatura, checkout, renovação, anúncio ou paywall nesta beta. Uma oferta futura exigirá outra decisão e será apresentada separadamente.',
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space11,
        vertical: AppTheme.space9,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.outlineMuted),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppTheme.frost400),
          const SizedBox(width: AppTheme.space8),
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
