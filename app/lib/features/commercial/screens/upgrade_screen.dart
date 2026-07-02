import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../models/manaloom_plan.dart';

class UpgradeScreen extends StatelessWidget {
  const UpgradeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upgrade Pro')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.of(context).padding.bottom,
        ),
        children: [
          Container(
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
                const Icon(Icons.workspace_premium, color: AppTheme.brass400),
                const SizedBox(height: 10),
                Text(
                  'ManaLoom Pro',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pro deixa a IA trabalhar na vida inteira do deck: geração, otimização por coleção, orçamento, relatório e pós-jogo.',
                  style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 16),
                ...ManaLoomPlan.pro.features.map(
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
          _CheckoutReadinessPanel(),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            key: const Key('upgrade-start-checkout-button'),
            onPressed: () => context.push('/checkout'),
            icon: const Icon(Icons.payment),
            label: const Text('Continuar para checkout'),
          ),
          TextButton(
            key: const Key('upgrade-open-legal-button'),
            onPressed: () => context.push('/legal'),
            child: const Text('Ver termos e privacidade'),
          ),
        ],
      ),
    );
  }
}

class _CheckoutReadinessPanel extends StatelessWidget {
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
              'Checkout interno habilita o Pro neste dispositivo para validar oferta e paywall. Para produção, conectar Stripe/Mercado Pago no backend.',
              style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
