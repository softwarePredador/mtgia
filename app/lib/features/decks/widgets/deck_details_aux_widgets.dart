import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
export '../../../core/widgets/mana_symbols.dart';

class DeckPricingRow extends StatelessWidget {
  final Map<String, dynamic>? pricing;
  final bool isLoading;
  final VoidCallback onForceRefresh;
  final VoidCallback? onShowDetails;

  const DeckPricingRow({
    super.key,
    required this.pricing,
    required this.isLoading,
    required this.onForceRefresh,
    this.onShowDetails,
  });

  String _formatUpdatedAt(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final local = dt.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inHours < 1) return 'há ${diff.inMinutes}min';
    if (diff.inDays < 1) return 'há ${diff.inHours}h';
    if (diff.inDays == 1) return 'ontem';
    if (diff.inDays < 7) return 'há ${diff.inDays}d';
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = pricing?['estimated_total_usd'];
    final missing = pricing?['missing_price_cards'];
    final updatedAt = pricing?['pricing_updated_at']?.toString();

    String subtitle;
    if (isLoading && total == null) {
      subtitle = 'Calculando...';
    } else if (total is num) {
      subtitle =
          'Estimado: ${CurrencyFormatter.format(total, currencyCode: pricing?['currency']?.toString() ?? 'USD')}';
      if (missing is num && missing > 0) {
        subtitle += ' • ${missing.toInt()} sem preço';
      }
      final ago = _formatUpdatedAt(updatedAt);
      if (ago.isNotEmpty) {
        subtitle += ' • $ago';
      }
    } else {
      subtitle = 'Atualize quando quiser calcular o custo';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.35),
          width: AppTheme.strokeThin,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.attach_money),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Custo', style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(subtitle, style: theme.textTheme.bodySmall),
                if (isLoading) ...[
                  const SizedBox(height: 8),
                  const LinearProgressIndicator(),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (onShowDetails != null && total is num)
            TextButton(
              onPressed: isLoading ? null : onShowDetails,
              child: const Text('Detalhes'),
            ),
          IconButton(
            tooltip: 'Atualizar preços',
            onPressed: isLoading ? null : onForceRefresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}
