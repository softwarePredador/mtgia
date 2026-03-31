import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

enum LifeCounterQuickAction {
  settings,
  history,
  cardSearch,
  turnTracker,
  gameTimer,
  dice,
  tableState,
  dayNight,
}

Future<LifeCounterQuickAction?> showLifeCounterNativeQuickActionsSheet(
  BuildContext context,
) {
  return showModalBottomSheet<LifeCounterQuickAction>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _LifeCounterNativeQuickActionsSheet(),
  );
}

class _LifeCounterNativeQuickActionsSheet extends StatelessWidget {
  const _LifeCounterNativeQuickActionsSheet();

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
                            'Quick Actions',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: AppTheme.fontXxl,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Open ManaLoom-owned tools without relying on Lotus overlays.',
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
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      color: AppTheme.textSecondary,
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppTheme.outlineMuted),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: const [
                    _QuickActionButton(
                      keyName: 'settings',
                      action: LifeCounterQuickAction.settings,
                      label: 'Settings',
                      icon: Icons.settings_outlined,
                    ),
                    _QuickActionButton(
                      keyName: 'history',
                      action: LifeCounterQuickAction.history,
                      label: 'History',
                      icon: Icons.history_rounded,
                    ),
                    _QuickActionButton(
                      keyName: 'card-search',
                      action: LifeCounterQuickAction.cardSearch,
                      label: 'Card Search',
                      icon: Icons.search_rounded,
                    ),
                    _QuickActionButton(
                      keyName: 'turn-tracker',
                      action: LifeCounterQuickAction.turnTracker,
                      label: 'Turn Tracker',
                      icon: Icons.route_rounded,
                    ),
                    _QuickActionButton(
                      keyName: 'game-timer',
                      action: LifeCounterQuickAction.gameTimer,
                      label: 'Game Timer',
                      icon: Icons.timer_outlined,
                    ),
                    _QuickActionButton(
                      keyName: 'dice',
                      action: LifeCounterQuickAction.dice,
                      label: 'Dice',
                      icon: Icons.casino_rounded,
                    ),
                    _QuickActionButton(
                      keyName: 'table-state',
                      action: LifeCounterQuickAction.tableState,
                      label: 'Table State',
                      icon: Icons.emoji_events_outlined,
                    ),
                    _QuickActionButton(
                      keyName: 'day-night',
                      action: LifeCounterQuickAction.dayNight,
                      label: 'Day / Night',
                      icon: Icons.nightlight_round,
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

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.keyName,
    required this.action,
    required this.label,
    required this.icon,
  });

  final String keyName;
  final LifeCounterQuickAction action;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      key: Key('life-counter-native-quick-actions-$keyName'),
      onPressed: () => Navigator.of(context).pop(action),
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
