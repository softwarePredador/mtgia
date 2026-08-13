import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/branding/product_identity.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/responsive_page_frame.dart';
import '../models/commercial_launch_policy.dart';
import '../widgets/free_beta_notice.dart';

/// Compatibility destination for old `/upgrade` links.
///
/// There is no upgrade offer in the controlled free beta. The route stays
/// harmless while older links and installed clients age out.
class UpgradeScreen extends StatelessWidget {
  const UpgradeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(CommercialLaunchPolicy.betaLabel)),
      body: LayoutBuilder(
        builder: (context, viewport) {
          final isCompact = viewport.maxWidth < AppTheme.breakpointCompact;
          final horizontalGutter = isCompact ? 16.0 : 24.0;
          return ListView(
            padding: EdgeInsets.only(
              top: AppTheme.space16,
              bottom: AppTheme.space16 + MediaQuery.of(context).padding.bottom,
            ),
            children: [
              ResponsivePageFrame(
                key: const Key('upgrade-responsive-frame'),
                maxWidth: AppTheme.readingMaxWidth,
                padding: EdgeInsets.symmetric(horizontal: horizontalGutter),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const FreeBetaNotice(
                      key: Key('upgrade-beta-notice'),
                      title: 'Não há upgrade nesta fase',
                      description:
                          'A beta controlada do ${ProductIdentity.displayName} tem uma única oferta gratuita. O servidor libera cada recurso separadamente quando as validações necessárias estiverem concluídas.',
                    ),
                    const SizedBox(height: AppTheme.space16),
                    if (isCompact)
                      _buildBetaAction(context)
                    else
                      Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(
                          width: 280,
                          child: _buildBetaAction(context),
                        ),
                      ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        key: const Key('upgrade-open-legal-button'),
                        onPressed: () => context.push('/legal'),
                        child: const Text('Ver termos e privacidade'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBetaAction(BuildContext context) {
    return ElevatedButton.icon(
      key: const Key('upgrade-back-to-beta-button'),
      onPressed: () => context.go('/plans'),
      icon: const Icon(Icons.insights_outlined),
      label: const Text('Ver uso e regras da beta'),
    );
  }
}
