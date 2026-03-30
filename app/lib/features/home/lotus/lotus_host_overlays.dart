import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class LotusLoadingOverlay extends StatelessWidget {
  const LotusLoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppTheme.heroGradient,
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _LotusShellBadge(),
                SizedBox(height: 24),
                SizedBox(
                  width: 34,
                  height: 34,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    color: AppTheme.primarySoft,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'ManaLoom',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: AppTheme.fontXxl,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Preparing the life counter',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: AppTheme.fontLg,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LotusErrorOverlay extends StatelessWidget {
  const LotusErrorOverlay({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: AppTheme.backgroundAbyss,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(color: AppTheme.outlineMuted),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 28,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _LotusShellBadge(),
                      const SizedBox(height: 18),
                      const Text(
                        'Life counter unavailable',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: AppTheme.fontXxl,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        message,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: AppTheme.fontLg,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: onRetry,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.manaViolet,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMd,
                              ),
                            ),
                          ),
                          child: const Text('Retry'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LotusShellBadge extends StatelessWidget {
  const _LotusShellBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.outlineMuted),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          'ManaLoom shell',
          style: TextStyle(
            color: AppTheme.primarySoft,
            fontSize: AppTheme.fontSm,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
