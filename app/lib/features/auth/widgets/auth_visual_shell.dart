import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class AuthVisualShell extends StatelessWidget {
  const AuthVisualShell({
    super.key,
    required this.child,
    this.leading,
    this.maxWidth = 460,
  });

  final Widget child;
  final Widget? leading;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundAbyss,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(gradient: AppTheme.scaffoldGradient),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.34,
                child: Image.asset(
                  'assets/branding/home_hero.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  filterQuality: FilterQuality.high,
                  excludeFromSemantics: true,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.backgroundAbyss.withValues(alpha: 0.38),
                      AppTheme.backgroundAbyss.withValues(alpha: 0.76),
                      AppTheme.backgroundAbyss.withValues(alpha: 0.94),
                    ],
                    stops: const [0, 0.58, 1],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const padding = EdgeInsets.fromLTRB(20, 18, 20, 32);
                return SingleChildScrollView(
                  padding: padding,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (constraints.maxHeight - padding.vertical)
                          .clamp(0, double.infinity),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (leading != null) ...[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: leading!,
                          ),
                          const SizedBox(height: 8),
                        ],
                        Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: maxWidth),
                            child: child,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.eyebrow,
    this.logoSize = 88,
  });

  final String title;
  final String subtitle;
  final String? eyebrow;
  final double logoSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          width: logoSize,
          height: logoSize,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLogoOuter),
            border: Border.all(
              color: AppTheme.brass400.withValues(alpha: 0.32),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.brass400.withValues(alpha: 0.14),
                blurRadius: 22,
                spreadRadius: -8,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusLogoInner),
            child: Image.asset(
              'assets/branding/app_logo.png',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              semanticLabel: 'Logo do ManaLoom',
            ),
          ),
        ),
        if (eyebrow != null) ...[
          const SizedBox(height: 14),
          Text(
            eyebrow!,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppTheme.brass400,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppTheme.textSecondary,
            height: AppTheme.lineHeightCompact,
          ),
        ),
      ],
    );
  }
}

class AuthFormSurface extends StatelessWidget {
  const AuthFormSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.brass400.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.backgroundAbyss.withValues(alpha: 0.46),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}
