import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'manaloom_theme_motif.dart';

enum AppStateStatus { information, loading }

class AppStatePanel extends StatelessWidget {
  final IconData? icon;
  final Widget? iconWidget;
  final String title;
  final String? message;
  final Color accent;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Key? actionKey;
  final AppStateStatus status;
  final ManaLoomMotifVariant motif;

  const AppStatePanel({
    super.key,
    this.icon,
    this.iconWidget,
    required this.title,
    required this.accent,
    this.message,
    this.actionLabel,
    this.onAction,
    this.actionKey,
    this.status = AppStateStatus.information,
    this.motif = ManaLoomMotifVariant.cardWeave,
  }) : assert(
         (icon == null) != (iconWidget == null),
         'Provide exactly one of icon or iconWidget.',
       );

  const AppStatePanel.loading({
    super.key,
    required this.title,
    required this.accent,
    this.message,
    this.motif = ManaLoomMotifVariant.cardWeave,
  }) : icon = Icons.hourglass_empty_rounded,
       iconWidget = null,
       actionLabel = null,
       onAction = null,
       actionKey = null,
       status = AppStateStatus.loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusLabel = <String>[
      if (status == AppStateStatus.loading) 'Carregando',
      title.trim(),
      if (message != null && message!.trim().isNotEmpty) message!.trim(),
    ].join('. ');

    return Semantics(
      container: true,
      liveRegion: true,
      label: statusLabel,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final minHeight = constraints.hasBoundedHeight
              ? constraints.maxHeight
              : 0.0;

          return ManaLoomThemeMotif(
            variant: motif,
            intensity: status == AppStateStatus.loading ? 0.42 : 0.72,
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minHeight),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.space24),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 420),
                      padding: const EdgeInsets.all(AppTheme.space18),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceSlate.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(
                          color: AppTheme.outlineMuted.withValues(alpha: 0.62),
                          width: AppTheme.strokeHairline,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMd,
                              ),
                            ),
                            child: ExcludeSemantics(
                              child: status == AppStateStatus.loading
                                  ? Padding(
                                      padding: const EdgeInsets.all(
                                        AppTheme.space13,
                                      ),
                                      child: CircularProgressIndicator(
                                        color: accent,
                                        strokeWidth: 2.4,
                                      ),
                                    )
                                  : IconTheme(
                                      data: IconThemeData(
                                        color: accent,
                                        size: 26,
                                      ),
                                      child: iconWidget ?? Icon(icon),
                                    ),
                            ),
                          ),
                          const SizedBox(height: AppTheme.space14),
                          ExcludeSemantics(
                            child: Text(
                              title,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (message != null &&
                              message!.trim().isNotEmpty) ...[
                            const SizedBox(height: AppTheme.space8),
                            ExcludeSemantics(
                              child: Text(
                                message!,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                  height: 1.36,
                                ),
                              ),
                            ),
                          ],
                          if (actionLabel != null && onAction != null) ...[
                            const SizedBox(height: AppTheme.space16),
                            ElevatedButton(
                              key: actionKey,
                              onPressed: onAction,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.brass500,
                                foregroundColor: AppTheme.backgroundAbyss,
                              ),
                              child: Text(actionLabel!),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
