import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../platform/page_reload.dart';
import '../theme/app_theme.dart';

/// "Nova versão disponível" strip on top of the whole app (BT-REL-002, D-13).
///
/// It shows while the backend runs a different release than this artifact.
/// The capabilities this build did not ship stay denied either way; "Agora
/// não" only hides the strip for this session. It is not a SnackBar, dialog
/// or route, so it never covers the screen or steals focus.
class ReleaseUpdateBannerHost extends StatefulWidget {
  const ReleaseUpdateBannerHost({
    super.key,
    required this.updateAvailable,
    required this.child,
    this.canReload,
    this.onReload,
  });

  final ValueListenable<bool> updateAvailable;
  final Widget child;

  /// Overrides for tests; default to the platform's page reload.
  final bool? canReload;
  final VoidCallback? onReload;

  @override
  State<ReleaseUpdateBannerHost> createState() =>
      _ReleaseUpdateBannerHostState();
}

class _ReleaseUpdateBannerHostState extends State<ReleaseUpdateBannerHost> {
  var _dismissed = false;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.updateAvailable,
      builder: (context, updateAvailable, child) {
        if (!updateAvailable || _dismissed) return child!;
        return Column(
          children: [
            _ReleaseUpdateBanner(
              canReload: widget.canReload ?? canReloadPage,
              onReload: widget.onReload ?? reloadPage,
              onDismiss: () => setState(() => _dismissed = true),
            ),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: child!,
              ),
            ),
          ],
        );
      },
      child: widget.child,
    );
  }
}

class _ReleaseUpdateBanner extends StatelessWidget {
  const _ReleaseUpdateBanner({
    required this.canReload,
    required this.onReload,
    required this.onDismiss,
  });

  final bool canReload;
  final VoidCallback onReload;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = canReload
        ? 'Recarregue a página para usar a versão nova.'
        : 'Instale a versão nova do app, disponível em brewtact.com.';
    return Material(
      key: const Key('release-update-banner'),
      color: AppTheme.surfaceElevated,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.space16,
            AppTheme.space8,
            AppTheme.space8,
            AppTheme.space8,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.system_update_alt_rounded,
                color: AppTheme.brass400,
                size: 20,
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Nova versão disponível. ',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: message),
                      ],
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textPrimary,
                      height: AppTheme.lineHeightCompact,
                    ),
                  ),
                ),
              ),
              if (canReload)
                TextButton(
                  key: const Key('release-update-reload'),
                  onPressed: onReload,
                  child: const Text('Recarregar'),
                ),
              TextButton(
                key: const Key('release-update-dismiss'),
                onPressed: onDismiss,
                child: const Text('Agora não'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
