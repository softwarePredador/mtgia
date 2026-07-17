import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/responsive_page_frame.dart';
import '../models/commercial_launch_policy.dart';
import '../models/manaloom_plan.dart';
import '../widgets/free_beta_notice.dart';

class UpgradeScreen extends StatelessWidget {
  const UpgradeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (CommercialLaunchPolicy.isFreeBeta) {
      return const _FreeBetaUpgradeScreen();
    }

    final proPlan = ManaLoomPlan.pro;
    return Scaffold(
      appBar: AppBar(title: const Text('Upgrade Pro')),
      body: LayoutBuilder(
        builder: (context, viewport) {
          final isCompact = viewport.maxWidth < AppTheme.breakpointCompact;
          final horizontalGutter = isCompact ? 16.0 : 24.0;
          return ListView(
            padding: EdgeInsets.only(
              top: 16,
              bottom: 16 + MediaQuery.of(context).padding.bottom,
            ),
            children: [
              ResponsivePageFrame(
                key: const Key('upgrade-responsive-frame'),
                maxWidth: AppTheme.readingMaxWidth,
                padding: EdgeInsets.symmetric(horizontal: horizontalGutter),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      key: const Key('upgrade-pro-summary'),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceSlate,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(
                          color: AppTheme.brass400.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.workspace_premium,
                            color: AppTheme.brass400,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'ManaLoom Pro',
                            style: Theme.of(
                              context,
                            ).textTheme.headlineSmall?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Pro aumenta o limite mensal de IA de 120 para 2.500 ações. Coleção, fichário, trocas, comunidade e pós-jogo continuam disponíveis no Free.',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            proPlan.priceLabel,
                            key: const Key('upgrade-pro-price'),
                            style: Theme.of(
                              context,
                            ).textTheme.headlineSmall?.copyWith(
                              color: AppTheme.brass400,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            proPlan.billingTerms.recurrenceLabel,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...proPlan.features.map(
                            (feature) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    size: 18,
                                    color: AppTheme.success,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(feature)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const _CheckoutReadinessPanel(),
                    const SizedBox(height: 12),
                    _BillingTermsPanel(terms: proPlan.billingTerms),
                    const SizedBox(height: 16),
                    if (isCompact)
                      SizedBox(
                        width: double.infinity,
                        child: _buildCheckoutButton(context),
                      )
                    else
                      Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(
                          width: 260,
                          child: _buildCheckoutButton(context),
                        ),
                      ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        key: const Key('upgrade-open-legal-button'),
                        onPressed: () => context.push('/legal'),
                        child: const Text('Ver termos e privacidade'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCheckoutButton(BuildContext context) {
    return ElevatedButton.icon(
      key: const Key('upgrade-start-checkout-button'),
      onPressed: () => context.push('/checkout'),
      icon: const Icon(Icons.payment),
      label: const Text('Continuar para checkout'),
    );
  }
}

class _FreeBetaUpgradeScreen extends StatelessWidget {
  const _FreeBetaUpgradeScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(CommercialLaunchPolicy.betaLabel)),
      body: LayoutBuilder(
        builder: (context, viewport) {
          final isCompact = viewport.maxWidth < AppTheme.breakpointCompact;
          final horizontalGutter = isCompact ? 16.0 : 24.0;
          return ListView(
            padding: EdgeInsets.only(
              top: 16,
              bottom: 16 + MediaQuery.of(context).padding.bottom,
            ),
            children: [
              ResponsivePageFrame(
                key: const Key('upgrade-responsive-frame'),
                maxWidth: AppTheme.readingMaxWidth,
                padding: EdgeInsets.symmetric(horizontal: horizontalGutter),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const FreeBetaNotice(
                      key: Key('upgrade-beta-notice'),
                      title: 'Você já está na versão disponível',
                      description:
                          'Não é necessário fazer upgrade para acessar os recursos liberados nesta fase do ManaLoom.',
                    ),
                    const SizedBox(height: 16),
                    if (isCompact)
                      _buildBetaAction(context)
                    else
                      Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(
                          width: 280,
                          child: _buildBetaAction(context),
                        ),
                      ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        key: const Key('upgrade-open-legal-button'),
                        onPressed: () => context.push('/legal'),
                        child: const Text('Ver termos e privacidade'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBetaAction(BuildContext context) {
    return ElevatedButton.icon(
      key: const Key('upgrade-back-to-beta-button'),
      onPressed: () => context.go('/plans'),
      icon: const Icon(Icons.insights_outlined),
      label: const Text('Ver uso e recursos da beta'),
    );
  }
}

class _CheckoutReadinessPanel extends StatelessWidget {
  const _CheckoutReadinessPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.outlineMuted),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.receipt_long_outlined, color: AppTheme.frost400),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'A assinatura é concluída em um ambiente de pagamento seguro. O plano só é ativado após a confirmação do pagamento.',
              style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _BillingTermsPanel extends StatelessWidget {
  const _BillingTermsPanel({required this.terms});

  final ManaLoomBillingTerms terms;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('upgrade-billing-terms'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.outlineMuted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cobrança e condições',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          _DisclosureLine(
            icon: Icons.autorenew_rounded,
            text: terms.renewalDisclosure,
          ),
          _DisclosureLine(
            icon: Icons.event_busy_outlined,
            text: terms.cancellationDisclosure,
          ),
          _DisclosureLine(
            icon: Icons.currency_exchange_outlined,
            text: terms.refundDisclosure,
          ),
          _DisclosureLine(
            icon: Icons.verified_user_outlined,
            text: terms.checkoutGuardrail,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _DisclosureLine extends StatelessWidget {
  const _DisclosureLine({
    required this.icon,
    required this.text,
    this.isLast = false,
  });

  final IconData icon;
  final String text;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.frost400),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
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
