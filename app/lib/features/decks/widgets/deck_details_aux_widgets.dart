import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_theme.dart';

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
      subtitle = 'Estimado: \$${total.toStringAsFixed(2)}';
      if (missing is num && missing > 0) {
        subtitle += ' • ${missing.toInt()} sem preço';
      }
      final ago = _formatUpdatedAt(updatedAt);
      if (ago.isNotEmpty) {
        subtitle += ' • $ago';
      }
    } else {
      subtitle = 'Calculando custo...';
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

class ManaCostRow extends StatelessWidget {
  final String? cost;

  const ManaCostRow({super.key, this.cost});

  @override
  Widget build(BuildContext context) {
    if (cost == null || cost!.isEmpty) return const SizedBox.shrink();

    final matches = RegExp(r'\{([^\}]+)\}').allMatches(cost!);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children:
          matches.map((m) {
            final symbol = m.group(1)!;
            return ManaSymbol(symbol: symbol);
          }).toList(),
    );
  }
}

class ManaSymbol extends StatelessWidget {
  final String symbol;

  const ManaSymbol({super.key, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final filename = symbol.replaceAll('/', '-');

    return Container(
      margin: const EdgeInsets.only(right: 2),
      width: 18,
      height: 18,
      child: SvgPicture.asset(
        'assets/symbols/$filename.svg',
        placeholderBuilder: (context) => FallbackManaSymbol(symbol: symbol),
      ),
    );
  }
}

class FallbackManaSymbol extends StatelessWidget {
  final String symbol;

  const FallbackManaSymbol({super.key, required this.symbol});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.textSecondary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        symbol,
        style: const TextStyle(fontSize: 8, color: AppTheme.backgroundAbyss),
      ),
    );
  }
}

class OracleTextWidget extends StatelessWidget {
  final String text;

  const OracleTextWidget(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'\{([^\}]+)\}');

    text.splitMapJoin(
      regex,
      onMatch: (Match m) {
        final symbol = m.group(1)!;
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.0),
              child: SizedBox(
                width: 16,
                height: 16,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: ManaSymbol(symbol: symbol),
                ),
              ),
            ),
          ),
        );
        return '';
      },
      onNonMatch: (String s) {
        spans.add(TextSpan(text: s));
        return '';
      },
    );

    return Text.rich(
      TextSpan(
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
        children: spans,
      ),
    );
  }
}

class ColorIdentityPips extends StatelessWidget {
  final List<String> colors;

  const ColorIdentityPips({super.key, required this.colors});

  static const _wubrgOrder = ['W', 'U', 'B', 'R', 'G'];

  @override
  Widget build(BuildContext context) {
    final sorted = List<String>.from(colors)..sort((a, b) {
      final ai = _wubrgOrder.indexOf(a);
      final bi = _wubrgOrder.indexOf(b);
      return (ai == -1 ? 99 : ai).compareTo(bi == -1 ? 99 : bi);
    });

    return Row(
      mainAxisSize: MainAxisSize.min,
      children:
          sorted.map((c) {
            return Padding(
              padding: const EdgeInsets.only(right: 3),
              child: SizedBox(
                width: 20,
                height: 20,
                child: SvgPicture.asset(
                  'assets/symbols/$c.svg',
                  placeholderBuilder: (_) => FallbackColorPip(letter: c),
                ),
              ),
            );
          }).toList(),
    );
  }
}

class FallbackColorPip extends StatelessWidget {
  final String letter;

  const FallbackColorPip({super.key, required this.letter});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: AppTheme.manaPipBackground(letter),
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.outlineMuted, width: 0.5),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppTheme.manaPipForeground(letter),
        ),
      ),
    );
  }
}
