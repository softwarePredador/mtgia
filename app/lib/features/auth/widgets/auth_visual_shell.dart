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
          Positioned(
            top: -164,
            left: -96,
            right: -96,
            height: 468,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.42,
                child: Image.asset(
                  'assets/branding/home_hero.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
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
                      AppTheme.backgroundAbyss.withValues(alpha: 0.2),
                      AppTheme.backgroundAbyss.withValues(alpha: 0.8),
                      AppTheme.backgroundAbyss,
                    ],
                    stops: const [0, 0.34, 1],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: -92,
            right: -92,
            bottom: -188,
            height: 360,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.frost600.withValues(alpha: 0.14),
                      AppTheme.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (leading != null) ...[
                    Align(alignment: Alignment.centerLeft, child: leading!),
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
    this.logoSize = 104,
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
                color: AppTheme.brass400.withValues(alpha: 0.18),
                blurRadius: 28,
                spreadRadius: -6,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusLogoInner),
            child: Image.asset(
              'assets/branding/app_logo.png',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
        if (eyebrow != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            decoration: BoxDecoration(
              color: AppTheme.brass500.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              border: Border.all(
                color: AppTheme.brass400.withValues(alpha: 0.22),
              ),
            ),
            child: Text(
              eyebrow!,
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppTheme.brass400,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineLarge?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.15,
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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(AppTheme.radiusLogoInner),
        border: Border.all(color: AppTheme.brass400.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.backgroundAbyss.withValues(alpha: 0.56),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: AppTheme.brass700.withValues(alpha: 0.12),
            blurRadius: 24,
            spreadRadius: -10,
          ),
        ],
      ),
      child: child,
    );
  }
}
