import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'manaloom_theme_motif.dart';

enum AppStateStatus {
  information,
  firstUse,
  noResults,
  error,
  offline,
  unavailable,
  loading,
}

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
    final eyebrow = switch (status) {
      AppStateStatus.firstUse => 'PRIMEIRO PASSO',
      AppStateStatus.noResults => 'SEM RESULTADOS',
      AppStateStatus.error => 'AÇÃO INTERROMPIDA',
      AppStateStatus.offline => 'SEM CONEXÃO',
      AppStateStatus.unavailable => 'INDISPONÍVEL',
      AppStateStatus.loading => 'PREPARANDO',
      AppStateStatus.information => 'PRÓXIMO PASSO',
    };
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
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1080),
                      child: LayoutBuilder(
                        builder: (context, contentConstraints) {
                          final horizontal = contentConstraints.maxWidth >= 620;
                          final spacious = contentConstraints.maxWidth >= 900;
                          final visual = _StateVisual(
                            accent: accent,
                            status: status,
                            icon: icon,
                            iconWidget: iconWidget,
                            prominent: spacious,
                          );
                          final copy = _StateCopy(
                            eyebrow: eyebrow,
                            title: title,
                            message: message,
                            accent: accent,
                            actionLabel: actionLabel,
                            onAction: onAction,
                            actionKey: actionKey,
                            textAlign: horizontal
                                ? TextAlign.start
                                : TextAlign.center,
                            crossAxisAlignment: horizontal
                                ? CrossAxisAlignment.start
                                : CrossAxisAlignment.center,
                            theme: theme,
                            prominent: spacious,
                          );

                          return Container(
                            key: spacious
                                ? const Key('app-state-wide-workbench')
                                : const Key('app-state-compact-workbench'),
                            padding: EdgeInsets.symmetric(
                              horizontal: spacious
                                  ? AppTheme.space40
                                  : horizontal
                                  ? AppTheme.space24
                                  : AppTheme.space8,
                              vertical: spacious
                                  ? AppTheme.space32
                                  : AppTheme.space24,
                            ),
                            decoration: BoxDecoration(
                              border: Border.symmetric(
                                horizontal: BorderSide(
                                  color: accent.withValues(alpha: 0.26),
                                  width: AppTheme.strokeHairline,
                                ),
                              ),
                            ),
                            child: spacious
                                ? Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        key: const Key('app-state-visual-rail'),
                                        width: 240,
                                        child: Center(child: visual),
                                      ),
                                      Container(
                                        width: AppTheme.strokeHairline,
                                        height: 168,
                                        color: accent.withValues(alpha: 0.22),
                                      ),
                                      const SizedBox(width: AppTheme.space40),
                                      Expanded(
                                        child: Align(
                                          key: const Key(
                                            'app-state-copy-workspace',
                                          ),
                                          alignment: Alignment.centerLeft,
                                          child: ConstrainedBox(
                                            constraints: const BoxConstraints(
                                              maxWidth: 620,
                                            ),
                                            child: copy,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : horizontal
                                ? Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      visual,
                                      const SizedBox(width: AppTheme.space28),
                                      Expanded(child: copy),
                                    ],
                                  )
                                : Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      visual,
                                      const SizedBox(height: AppTheme.space18),
                                      copy,
                                    ],
                                  ),
                          );
                        },
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

class _StateVisual extends StatelessWidget {
  const _StateVisual({
    required this.accent,
    required this.status,
    required this.icon,
    required this.iconWidget,
    required this.prominent,
  });

  final Color accent;
  final AppStateStatus status;
  final IconData? icon;
  final Widget? iconWidget;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final canvasSize = prominent ? 168.0 : 104.0;
    final orbitSize = prominent ? 142.0 : 88.0;
    return ExcludeSemantics(
      child: SizedBox(
        width: canvasSize,
        height: canvasSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: orbitSize,
              height: orbitSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.08),
                border: Border.all(
                  color: accent.withValues(alpha: 0.30),
                  width: AppTheme.strokeHairline,
                ),
              ),
            ),
            Positioned(
              left: prominent ? 4 : 3,
              top: prominent ? 24 : 18,
              child: Container(
                width: prominent ? 34 : 22,
                height: prominent ? 48 : 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.24),
                    width: AppTheme.strokeHairline,
                  ),
                ),
              ),
            ),
            Positioned(
              right: prominent ? 3 : 2,
              bottom: prominent ? 22 : 16,
              child: Container(
                width: prominent ? 38 : 24,
                height: prominent ? 54 : 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.22),
                    width: AppTheme.strokeHairline,
                  ),
                ),
              ),
            ),
            if (status == AppStateStatus.loading)
              SizedBox(
                width: prominent ? 44 : 32,
                height: prominent ? 44 : 32,
                child: CircularProgressIndicator(
                  color: accent,
                  strokeWidth: 2.4,
                ),
              )
            else
              IconTheme(
                data: IconThemeData(color: accent, size: prominent ? 46 : 34),
                child: iconWidget ?? Icon(icon),
              ),
          ],
        ),
      ),
    );
  }
}

class _StateCopy extends StatelessWidget {
  const _StateCopy({
    required this.eyebrow,
    required this.title,
    required this.message,
    required this.accent,
    required this.actionLabel,
    required this.onAction,
    required this.actionKey,
    required this.textAlign,
    required this.crossAxisAlignment,
    required this.theme,
    required this.prominent,
  });

  final String eyebrow;
  final String title;
  final String? message;
  final Color accent;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Key? actionKey;
  final TextAlign textAlign;
  final CrossAxisAlignment crossAxisAlignment;
  final ThemeData theme;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        ExcludeSemantics(
          child: Text(
            eyebrow,
            textAlign: textAlign,
            style: theme.textTheme.labelSmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.space6),
        ExcludeSemantics(
          child: Text(
            title,
            textAlign: textAlign,
            style:
                (prominent
                        ? theme.textTheme.headlineSmall
                        : theme.textTheme.titleLarge)
                    ?.copyWith(
                      color: AppTheme.textPrimary,
                      fontFamily: AppTheme.displayFontFamily,
                      fontWeight: FontWeight.w800,
                      height: 1.08,
                    ),
          ),
        ),
        if (message != null && message!.trim().isNotEmpty) ...[
          const SizedBox(height: AppTheme.space8),
          ExcludeSemantics(
            child: Text(
              message!,
              textAlign: textAlign,
              style:
                  (prominent
                          ? theme.textTheme.bodyLarge
                          : theme.textTheme.bodyMedium)
                      ?.copyWith(color: AppTheme.textSecondary, height: 1.42),
            ),
          ),
        ],
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: AppTheme.space18),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 180),
            child: FilledButton(
              key: actionKey,
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.brass500,
                foregroundColor: AppTheme.backgroundAbyss,
              ),
              child: Text(actionLabel!),
            ),
          ),
        ],
      ],
    );
  }
}
