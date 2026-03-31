import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

Future<void> showLifeCounterNativeGameModesSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _LifeCounterNativeGameModesSheet(),
  );
}

class _LifeCounterNativeGameModesSheet extends StatelessWidget {
  const _LifeCounterNativeGameModesSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.backgroundAbyss,
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Game Modes',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: AppTheme.fontXxl,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'ManaLoom now owns the shell for these modes. Gameplay runtime still stays in the Lotus bundle for now.',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: AppTheme.fontMd,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      key: const Key('life-counter-native-game-modes-close'),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      color: AppTheme.textSecondary,
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppTheme.outlineMuted),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  children: [
                    _GameModeStatusCard(
                      title: 'Planechase',
                      icon: Icons.public_rounded,
                      summary:
                          'The planar deck and die still run inside Lotus. ManaLoom owns the surrounding shell and roadmap.',
                    ),
                    SizedBox(height: 10),
                    _GameModeStatusCard(
                      title: 'Archenemy',
                      icon: Icons.shield_moon_outlined,
                      summary:
                          'Scheme runtime remains embedded for now while the migration contract is prepared.',
                    ),
                    SizedBox(height: 10),
                    _GameModeStatusCard(
                      title: 'Bounty',
                      icon: Icons.workspace_premium_outlined,
                      summary:
                          'Bounty gameplay still depends on Lotus, but the ownership decision now lives in ManaLoom.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameModeStatusCard extends StatelessWidget {
  const _GameModeStatusCard({
    required this.title,
    required this.icon,
    required this.summary,
  });

  final String title;
  final IconData icon;
  final String summary;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.outlineMuted),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.textPrimary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: AppTheme.fontLg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundAbyss,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppTheme.outlineMuted),
                  ),
                  child: const Text(
                    'Lotus runtime',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: AppTheme.fontSm,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              summary,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: AppTheme.fontMd,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
