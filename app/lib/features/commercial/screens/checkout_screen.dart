import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../models/manaloom_plan.dart';
import '../providers/commercial_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isProcessing = false;

  Future<void> _confirm() async {
    setState(() => _isProcessing = true);
    await context.read<CommercialProvider>().setPlan(ManaLoomPlanTier.pro);
    if (!mounted) return;
    setState(() => _isProcessing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Plano Pro ativado para este ambiente.'),
        backgroundColor: AppTheme.success,
      ),
    );
    context.go('/plans');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.of(context).padding.bottom,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceSlate,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: AppTheme.brass400.withValues(alpha: 0.34),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumo do pedido',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                const _CheckoutLine(label: 'Plano', value: 'ManaLoom Pro'),
                const _CheckoutLine(label: 'Uso de IA', value: '200 ações/mês'),
                const _CheckoutLine(
                  label: 'Status',
                  value: 'Checkout interno MVP',
                ),
                const SizedBox(height: 12),
                const Text(
                  'Este fluxo valida produto, paywall e upgrade. A cobrança real deve ser feita por integração de pagamento no backend antes de produção.',
                  style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            key: const Key('checkout-confirm-button'),
            onPressed: _isProcessing ? null : _confirm,
            icon:
                _isProcessing
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.lock_open),
            label: Text(_isProcessing ? 'Processando...' : 'Ativar Pro'),
          ),
          TextButton(
            onPressed: _isProcessing ? null : () => context.go('/plans'),
            child: const Text('Voltar aos planos'),
          ),
        ],
      ),
    );
  }
}

class _CheckoutLine extends StatelessWidget {
  const _CheckoutLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
