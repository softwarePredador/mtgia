import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class LotusLoadingOverlay extends StatelessWidget {
  const LotusLoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: DecoratedBox(
        key: Key('lotus-loading-overlay'),
        decoration: BoxDecoration(gradient: AppTheme.heroGradient),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppTheme.space28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _LotusShellBadge(),
                SizedBox(height: AppTheme.space24),
                SizedBox(
                  width: AppTheme.space34,
                  height: AppTheme.space34,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    color: AppTheme.primarySoft,
                  ),
                ),
                SizedBox(height: AppTheme.space20),
                Text(
                  'ManaLoom',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: AppTheme.fontXxl,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(height: AppTheme.space8),
                Text(
                  'Preparando o contador de vida',
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
        key: const Key('lotus-error-overlay'),
        color: AppTheme.backgroundAbyss,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.space24),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(color: AppTheme.outlineMuted),
                  boxShadow: const [
                    BoxShadow(
                      color: AppTheme.overlayBlack40,
                      blurRadius: 28,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.space20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _LotusShellBadge(),
                      const SizedBox(height: AppTheme.space18),
                      const Text(
                        'Contador de vida indisponível',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: AppTheme.fontXxl,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppTheme.space10),
                      Text(
                        _localizedHostMessage(message),
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: AppTheme.fontLg,
                          height: AppTheme.lineHeightComfortable,
                        ),
                      ),
                      const SizedBox(height: AppTheme.space18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          key: const Key('lotus-error-retry-button'),
                          onPressed: onRetry,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.brass500,
                            foregroundColor: AppTheme.backgroundAbyss,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppTheme.space14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMd,
                              ),
                            ),
                          ),
                          child: const Text('Tentar novamente'),
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
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(color: AppTheme.outlineMuted),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.space12,
          vertical: AppTheme.space7,
        ),
        child: Text(
          'Interface ManaLoom',
          style: TextStyle(
            color: AppTheme.primarySoft,
            fontSize: AppTheme.fontSm,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

String _localizedHostMessage(String message) {
  final normalized = message.trim();
  if (normalized.startsWith('O ManaLoom ')) {
    return normalized;
  }
  return switch (normalized) {
    'ManaLoom could not open the embedded life counter. Check the local bundle and try again.' =>
      'O ManaLoom não conseguiu abrir o contador de vida. Tente novamente.',
    'ManaLoom could not safely restore the life counter state. Try loading it again.' =>
      'O ManaLoom não conseguiu restaurar o estado da partida com segurança. Tente carregar novamente.',
    'ManaLoom could not open the Life Counter in this browser. Reload the page and try again.' =>
      'O ManaLoom não conseguiu abrir o contador de vida neste navegador. Recarregue a página e tente novamente.',
    _ =>
      'Não foi possível carregar o contador de vida. Tente novamente em instantes.',
  };
}
