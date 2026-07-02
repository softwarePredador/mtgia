import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';

class PlatformUnavailableScreen extends StatelessWidget {
  const PlatformUnavailableScreen({
    super.key,
    required this.title,
    required this.message,
    this.details,
    this.fallbackRoutePath = '/home',
    this.primaryActionLabel = 'Voltar ao inicio',
  });

  final String title;
  final String message;
  final String? details;
  final String fallbackRoutePath;
  final String primaryActionLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundAbyss,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundAbyss,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      border: Border.all(color: AppTheme.outlineMuted),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: const Icon(
                      Icons.web_asset_off_rounded,
                      color: AppTheme.brass400,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.45,
                      letterSpacing: 0,
                    ),
                  ),
                  if (details != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      details!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textHint,
                        height: 1.45,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => context.go(fallbackRoutePath),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: Text(primaryActionLabel),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
