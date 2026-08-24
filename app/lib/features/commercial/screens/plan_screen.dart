import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/config/release_capabilities.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/responsive_page_frame.dart';
import '../models/commercial_launch_policy.dart';
import '../providers/commercial_provider.dart';
import '../widgets/ai_usage_meter.dart';
import '../widgets/free_beta_notice.dart';

class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CommercialProvider>();
    final releaseCapabilities = context.watch<ReleaseCapabilitiesProvider?>();
    final aiAvailable =
        (releaseCapabilities?.isAllowed(
              ReleaseCapability.aiAnalyzeOptimizeAdvisory,
            ) ??
            false) ||
        (releaseCapabilities?.isAllowed(ReleaseCapability.aiGenerateRebuild) ??
            false);
    if (!provider.isLoaded) {
      provider.load();
    }

    return Scaffold(
      appBar: AppBar(title: const Text(CommercialLaunchPolicy.betaLabel)),
      body: LayoutBuilder(
        builder: (context, viewport) {
          final horizontalGutter =
              viewport.maxWidth < AppTheme.breakpointCompact ? 16.0 : 24.0;
          return ListView(
            padding: EdgeInsets.only(
              top: AppTheme.space16,
              bottom: AppTheme.space16 + MediaQuery.of(context).padding.bottom,
            ),
            children: [
              ResponsivePageFrame(
                key: const Key('plans-responsive-frame'),
                maxWidth: AppTheme.contentMaxWidth,
                padding: EdgeInsets.symmetric(horizontal: horizontalGutter),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppTheme.readingMaxWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (aiAvailable) ...[
                          const AiUsageMeter(),
                          const SizedBox(height: AppTheme.space16),
                        ],
                        const FreeBetaNotice(
                          key: Key('beta-free-access-panel'),
                        ),
                        if (provider.isRemoteSynced ||
                            provider.lastRemoteError != null) ...[
                          const SizedBox(height: AppTheme.space16),
                          _RemotePlanStatusPanel(provider: provider),
                        ],
                        const SizedBox(height: AppTheme.space16),
                        const _LegalShortcutPanel(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RemotePlanStatusPanel extends StatelessWidget {
  const _RemotePlanStatusPanel({required this.provider});

  final CommercialProvider provider;

  @override
  Widget build(BuildContext context) {
    final synced = provider.isRemoteSynced;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTheme.space14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: synced ? AppTheme.success : AppTheme.warning),
      ),
      child: Row(
        children: [
          Icon(
            synced ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
            color: synced ? AppTheme.success : AppTheme.warning,
          ),
          const SizedBox(width: AppTheme.space10),
          Expanded(
            child: Text(
              synced
                  ? 'Teto operacional sincronizado com o servidor.'
                  : provider.lastRemoteError ??
                        'Não foi possível confirmar o teto operacional agora.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalShortcutPanel extends StatelessWidget {
  const _LegalShortcutPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTheme.space14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.outlineMuted),
      ),
      child: Row(
        children: [
          const Icon(Icons.policy_outlined, color: AppTheme.frost400),
          const SizedBox(width: AppTheme.space10),
          Expanded(
            child: Text(
              'Consulte como tratamos privacidade, conteúdo e sugestões de IA durante a beta.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
                height: 1.35,
              ),
            ),
          ),
          TextButton(
            key: const Key('plans-open-legal-button'),
            onPressed: () => context.push('/legal'),
            child: const Text('Legal'),
          ),
        ],
      ),
    );
  }
}
