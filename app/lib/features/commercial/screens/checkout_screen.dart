import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/commercial_provider.dart';

typedef CommercialCheckoutStarter = Future<CommercialCheckoutResult> Function();
typedef ExternalCheckoutLauncher = Future<bool> Function(Uri uri);

Future<bool> launchExternalCheckout(Uri uri) => launchUrl(
  uri,
  mode: LaunchMode.externalApplication,
  webOnlyWindowName: '_blank',
);

Uri? secureExternalCheckoutUri(String? value) {
  final uri = Uri.tryParse(value?.trim() ?? '');
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
  return uri;
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    this.startCheckout,
    this.externalCheckoutLauncher = launchExternalCheckout,
  });

  final CommercialCheckoutStarter? startCheckout;
  final ExternalCheckoutLauncher externalCheckoutLauncher;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isProcessing = false;
  bool _isOpeningCheckout = false;
  String? _statusMessage;
  bool _requiresExternalPayment = false;
  Uri? _checkoutUri;

  Future<void> _confirm() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = null;
      _requiresExternalPayment = false;
      _checkoutUri = null;
    });
    final result =
        await (widget.startCheckout?.call() ??
            context.read<CommercialProvider>().startProCheckout());
    if (!mounted) return;
    final checkoutUri = secureExternalCheckoutUri(result.checkoutUrl);
    setState(() {
      _isProcessing = false;
      _statusMessage =
          result.requiresExternalPayment &&
                  result.checkoutUrl != null &&
                  checkoutUri == null
              ? 'O link de pagamento recebido não é seguro. Tente novamente.'
              : result.message;
      _requiresExternalPayment = result.requiresExternalPayment;
      _checkoutUri = checkoutUri;
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

  Future<void> _openExternalCheckout() async {
    final uri = _checkoutUri;
    if (uri == null || _isOpeningCheckout) return;

    setState(() => _isOpeningCheckout = true);
    var launched = false;
    try {
      launched = await widget.externalCheckoutLauncher(uri);
    } catch (_) {
      launched = false;
    }
    if (!mounted) return;
    setState(() => _isOpeningCheckout = false);

    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir o pagamento. Tente novamente.'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
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
                const _CheckoutLine(label: 'Status', value: 'Pagamento seguro'),
                const SizedBox(height: 12),
                const Text(
                  'Seu plano será ativado após a confirmação do pagamento.',
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
              checkoutUri: _checkoutUri,
              isOpeningCheckout: _isOpeningCheckout,
              onOpenCheckout: _openExternalCheckout,
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
            label: Text(_isProcessing ? 'Processando...' : 'Continuar'),
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
    required this.checkoutUri,
    required this.isOpeningCheckout,
    required this.onOpenCheckout,
  });

  final String message;
  final bool requiresExternalPayment;
  final Uri? checkoutUri;
  final bool isOpeningCheckout;
  final VoidCallback onOpenCheckout;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
          if (checkoutUri != null) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('checkout-open-payment-button'),
              onPressed: isOpeningCheckout ? null : onOpenCheckout,
              icon:
                  isOpeningCheckout
                      ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.open_in_new_rounded),
              label: Text(
                isOpeningCheckout
                    ? 'Abrindo pagamento...'
                    : 'Continuar para pagamento',
              ),
            ),
          ],
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
