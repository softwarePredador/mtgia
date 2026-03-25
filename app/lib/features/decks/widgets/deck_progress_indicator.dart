import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/deck_details.dart';

/// Enum para representar o status de completude do deck
enum DeckStatus {
  incomplete, // Faltam cartas
  complete, // Número correto de cartas
  invalid, // Problema de validação (sem comandante, identidade, etc)
  unknown, // Formato sem limite definido
}

/// Widget que mostra o progresso e status do deck
class DeckProgressIndicator extends StatelessWidget {
  final DeckDetails deck;
  final int totalCards;
  final int? maxCards;
  final bool hasCommander;
  final VoidCallback? onTap;
  final String? semanticBadgeLabel;
  final Color? semanticBadgeColor;
  final IconData? semanticBadgeIcon;
  final VoidCallback? onSemanticBadgeTap;

  const DeckProgressIndicator({
    super.key,
    required this.deck,
    required this.totalCards,
    required this.maxCards,
    required this.hasCommander,
    this.onTap,
    this.semanticBadgeLabel,
    this.semanticBadgeColor,
    this.semanticBadgeIcon,
    this.onSemanticBadgeTap,
  });

  DeckStatus get status {
    final format = deck.format.toLowerCase();
    final isCommanderFormat = format == 'commander' || format == 'brawl';

    if (maxCards == null) return DeckStatus.unknown;

    // Valida se tem comandante em formatos que exigem
    if (isCommanderFormat && !hasCommander) {
      return DeckStatus.invalid;
    }

    if (totalCards < maxCards!) {
      return DeckStatus.incomplete;
    }

    if (totalCards == maxCards) {
      return DeckStatus.complete;
    }

    // Mais cartas que o permitido
    return DeckStatus.invalid;
  }

  Color _getStatusColor(BuildContext context) {
    final theme = Theme.of(context);
    switch (status) {
      case DeckStatus.complete:
        return AppTheme.success;
      case DeckStatus.incomplete:
        return theme.colorScheme.primary;
      case DeckStatus.invalid:
        return theme.colorScheme.error;
      case DeckStatus.unknown:
        return theme.colorScheme.outline;
    }
  }

  IconData _getStatusIcon() {
    switch (status) {
      case DeckStatus.complete:
        return Icons.check_circle;
      case DeckStatus.incomplete:
        return Icons.pending;
      case DeckStatus.invalid:
        return Icons.error;
      case DeckStatus.unknown:
        return Icons.help_outline;
    }
  }

  String _getStatusText() {
    final format = deck.format.toLowerCase();
    final isCommanderFormat = format == 'commander' || format == 'brawl';

    switch (status) {
      case DeckStatus.complete:
        return 'Deck completo!';
      case DeckStatus.incomplete:
        final missing = maxCards! - totalCards;
        return 'Faltam $missing carta${missing > 1 ? 's' : ''}';
      case DeckStatus.invalid:
        if (isCommanderFormat && !hasCommander) {
          return 'Selecione um comandante';
        }
        if (totalCards > maxCards!) {
          final excess = totalCards - maxCards!;
          return 'Excede em $excess carta${excess > 1 ? 's' : ''}';
        }
        return 'Deck inválido';
      case DeckStatus.unknown:
        return '$totalCards cartas';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getStatusColor(context);
    final progress =
        maxCards != null ? (totalCards / maxCards!).clamp(0.0, 1.0) : 0.0;
    final toneSurface = AppTheme.surfaceElevated.withValues(alpha: 0.95);
    final toneBorder = color.withValues(
      alpha: status == DeckStatus.invalid ? 0.32 : 0.2,
    );
    final headlineColor =
        status == DeckStatus.invalid ? AppTheme.textPrimary : color;
    final supportingColor =
        status == DeckStatus.invalid
            ? theme.colorScheme.error.withValues(alpha: 0.86)
            : AppTheme.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: toneSurface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: toneBorder, width: 0.9),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Icon(_getStatusIcon(), color: color, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        maxCards != null
                            ? '$totalCards / $maxCards cartas'
                            : '$totalCards cartas',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: headlineColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getStatusText(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: supportingColor,
                          fontWeight:
                              status == DeckStatus.invalid
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (semanticBadgeLabel != null &&
                    semanticBadgeLabel!.trim().isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _StatusBadge(
                    label: semanticBadgeLabel!,
                    color: semanticBadgeColor ?? color,
                    icon: semanticBadgeIcon,
                    onTap: onSemanticBadgeTap,
                  ),
                ],
                if (status == DeckStatus.complete)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.success,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: const Text(
                      'Pronto',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: AppTheme.fontSm,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (maxCards != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppTheme.outlineMuted.withValues(
                    alpha: 0.65,
                  ),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final VoidCallback? onTap;

  const _StatusBadge({
    required this.label,
    required this.color,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: AppTheme.fontSm,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return child;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: child,
    );
  }
}

/// Widget compacto para exibição em cards/listas
class DeckProgressChip extends StatelessWidget {
  final int totalCards;
  final int? maxCards;
  final bool hasCommander;
  final String format;

  const DeckProgressChip({
    super.key,
    required this.totalCards,
    required this.maxCards,
    required this.hasCommander,
    required this.format,
  });

  DeckStatus get status {
    final fmt = format.toLowerCase();
    final isCommanderFormat = fmt == 'commander' || fmt == 'brawl';

    if (maxCards == null) return DeckStatus.unknown;

    if (isCommanderFormat && !hasCommander) {
      return DeckStatus.invalid;
    }

    if (totalCards < maxCards!) {
      return DeckStatus.incomplete;
    }

    if (totalCards == maxCards) {
      return DeckStatus.complete;
    }

    return DeckStatus.invalid;
  }

  Color _getColor() {
    switch (status) {
      case DeckStatus.complete:
        return AppTheme.success;
      case DeckStatus.incomplete:
        return AppTheme.primarySoft;
      case DeckStatus.invalid:
        return AppTheme.error;
      case DeckStatus.unknown:
        return AppTheme.disabled;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        maxCards != null ? '$totalCards/$maxCards' : '$totalCards',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: AppTheme.fontSm,
        ),
      ),
    );
  }
}
