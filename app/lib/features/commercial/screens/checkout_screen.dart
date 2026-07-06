import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/commercial_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isProcessing = false;
  String? _statusMessage;
  bool _requiresExternalPayment = false;

  Future<void> _confirm() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = null;
      _requiresExternalPayment = false;
    });
    final result = await context.read<CommercialProvider>().startProCheckout();
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _statusMessage = result.message;
      _requiresExternalPayment = result.requiresExternalPayment;
    });
    if (!result.activated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor:
              result.requiresExternalPayment
                  ? AppTheme.warning
                  : AppTheme.error,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Plano Pro ativado.'),
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
                const _CheckoutLine(
                  label: 'Uso de IA',
                  value: '2.500 ações/mês',
                ),
                const _CheckoutLine(label: 'Status', value: 'Checkout backend'),
                const SizedBox(height: 12),
                const Text(
                  'Este fluxo chama o backend para ativar o Pro somente quando o checkout interno ou provedor de pagamento estiver configurado.',
                  style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
          if (_statusMessage != null) ...[
            const SizedBox(height: 12),
            _CheckoutStatusPanel(
              message: _statusMessage!,
              requiresExternalPayment: _requiresExternalPayment,
            ),
          ],
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

class _CheckoutStatusPanel extends StatelessWidget {
  const _CheckoutStatusPanel({
    required this.message,
    required this.requiresExternalPayment,
  });

  final String message;
  final bool requiresExternalPayment;

  @override
  Widget build(BuildContext context) {
    final color = requiresExternalPayment ? AppTheme.warning : AppTheme.error;
    return Container(
      key: const Key('checkout-status-panel'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            requiresExternalPayment
                ? Icons.payments_outlined
                : Icons.error_outline,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
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
