import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_state_panel.dart';
import '../../../core/widgets/responsive_page_frame.dart';
import '../models/commercial_launch_policy.dart';

/// Compatibility destination for old `/checkout` links.
///
/// No payment action, external URL, provider call or activation path exists in
/// the controlled free beta.
class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

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
                key: const Key('checkout-responsive-frame'),
                maxWidth: AppTheme.readingMaxWidth,
                padding: EdgeInsets.symmetric(horizontal: horizontalGutter),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AppStatePanel(
                      key: Key('checkout-beta-notice'),
                      title: 'Checkout não está disponível',
                      message: CommercialLaunchPolicy.betaCheckoutMessage,
                      icon: Icons.money_off_csred_outlined,
                      accent: AppTheme.brass400,
                      status: AppStateStatus.unavailable,
                    ),
                    const SizedBox(height: AppTheme.space16),
                    if (isCompact)
                      _buildBackButton(context)
                    else
                      Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(
                          width: 220,
                          child: _buildBackButton(context),
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

  Widget _buildBackButton(BuildContext context) {
    return ElevatedButton.icon(
      key: const Key('checkout-back-to-beta-button'),
      onPressed: () => context.go('/plans'),
      icon: const Icon(Icons.arrow_back_rounded),
      label: const Text('Voltar à beta'),
    );
  }
}
