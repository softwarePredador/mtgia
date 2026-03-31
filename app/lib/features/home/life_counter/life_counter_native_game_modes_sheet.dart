import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

enum LifeCounterGameModesAction {
  openPlanechase,
  editPlanechaseCards,
  closePlanechaseCardPool,
  closePlanechase,
  openArchenemy,
  editArchenemyCards,
  closeArchenemyCardPool,
  closeArchenemy,
  openBounty,
  editBountyCards,
  closeBountyCardPool,
  closeBounty,
  openSettings,
}

enum LifeCounterGameModeKind { planechase, archenemy, bounty }

enum LifeCounterGameModesEntryIntent { openMode, editCards }

class LifeCounterGameModesAvailability {
  const LifeCounterGameModesAvailability({
    required this.planechaseAvailable,
    required this.archenemyAvailable,
    required this.bountyAvailable,
    this.planechaseActive = false,
    this.planechaseCardPoolActive = false,
    this.archenemyActive = false,
    this.archenemyCardPoolActive = false,
    this.bountyActive = false,
    this.bountyCardPoolActive = false,
    this.activeModeCount = 0,
    this.maxActiveModes = 2,
  });

  final bool planechaseAvailable;
  final bool archenemyAvailable;
  final bool bountyAvailable;
  final bool planechaseActive;
  final bool planechaseCardPoolActive;
  final bool archenemyActive;
  final bool archenemyCardPoolActive;
  final bool bountyActive;
  final bool bountyCardPoolActive;
  final int activeModeCount;
  final int maxActiveModes;

  bool get maxActiveModesReached => activeModeCount >= maxActiveModes;

  List<String> get activeModeLabels {
    final labels = <String>[];
    if (planechaseActive) {
      labels.add('Planechase');
    }
    if (archenemyActive) {
      labels.add('Archenemy');
    }
    if (bountyActive) {
      labels.add('Bounty');
    }
    return labels;
  }
}

Future<LifeCounterGameModesAction?> showLifeCounterNativeGameModesSheet(
  BuildContext context, {
  required LifeCounterGameModesAvailability availability,
  LifeCounterGameModesAction? preferredAction,
  LifeCounterGameModesEntryIntent preferredIntent =
      LifeCounterGameModesEntryIntent.openMode,
}) {
  return showModalBottomSheet<LifeCounterGameModesAction>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder:
        (context) => _LifeCounterNativeGameModesSheet(
          availability: availability,
          preferredAction: preferredAction,
          preferredIntent: preferredIntent,
        ),
  );
}

class _LifeCounterNativeGameModesSheet extends StatelessWidget {
  const _LifeCounterNativeGameModesSheet({
    required this.availability,
    this.preferredAction,
    required this.preferredIntent,
  });

  final LifeCounterGameModesAvailability availability;
  final LifeCounterGameModesAction? preferredAction;
  final LifeCounterGameModesEntryIntent preferredIntent;

  @override
  Widget build(BuildContext context) {
    final activeModeLabels = availability.activeModeLabels;
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
          child: SingleChildScrollView(
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
                              'ManaLoom owns the shell here. The actual gameplay runtime still stays embedded in Lotus for now.',
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    children: [
                      if (availability.maxActiveModesReached) ...[
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                            border: Border.all(color: AppTheme.warning),
                          ),
                          child: Text(
                            activeModeLabels.isEmpty
                                ? 'Two game modes are already active. Close one before starting another mode or opening another card pool editor.'
                                : '${activeModeLabels.join(' and ')} ${activeModeLabels.length == 1 ? 'is' : 'are'} already active. Close one before starting another mode or opening another card pool editor.',
                            key: const Key(
                              'life-counter-native-game-modes-limit-warning',
                            ),
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: AppTheme.fontMd,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                      _GameModeStatusCard(
                        keyName: 'planechase',
                        modeKind: LifeCounterGameModeKind.planechase,
                        title: 'Planechase',
                        icon: Icons.public_rounded,
                        summary:
                            'The planar deck and die still run inside Lotus. ManaLoom now owns the launch shell for this mode.',
                        available: availability.planechaseAvailable,
                        active: availability.planechaseActive,
                        preferred: preferredAction ==
                            LifeCounterGameModesAction.openPlanechase ||
                            preferredAction ==
                                LifeCounterGameModesAction.editPlanechaseCards ||
                            preferredAction ==
                                LifeCounterGameModesAction.closePlanechaseCardPool ||
                            preferredAction ==
                                LifeCounterGameModesAction.closePlanechase,
                        preferredIntent: preferredIntent,
                        activeModeCount: availability.activeModeCount,
                        maxActiveModes: availability.maxActiveModes,
                        activeModeLabels: activeModeLabels,
                        cardPoolActive: availability.planechaseCardPoolActive,
                        openAction: LifeCounterGameModesAction.openPlanechase,
                        editAction:
                            LifeCounterGameModesAction.editPlanechaseCards,
                        closeCardPoolAction:
                            LifeCounterGameModesAction.closePlanechaseCardPool,
                        closeAction:
                            LifeCounterGameModesAction.closePlanechase,
                      ),
                      const SizedBox(height: 10),
                      _GameModeStatusCard(
                        keyName: 'archenemy',
                        modeKind: LifeCounterGameModeKind.archenemy,
                        title: 'Archenemy',
                        icon: Icons.shield_moon_outlined,
                        summary:
                            'Scheme runtime remains embedded for now while the migration contract is prepared.',
                        available: availability.archenemyAvailable,
                        active: availability.archenemyActive,
                        preferred: preferredAction ==
                            LifeCounterGameModesAction.openArchenemy ||
                            preferredAction ==
                                LifeCounterGameModesAction.editArchenemyCards ||
                            preferredAction ==
                                LifeCounterGameModesAction.closeArchenemyCardPool ||
                            preferredAction ==
                                LifeCounterGameModesAction.closeArchenemy,
                        preferredIntent: preferredIntent,
                        activeModeCount: availability.activeModeCount,
                        maxActiveModes: availability.maxActiveModes,
                        activeModeLabels: activeModeLabels,
                        cardPoolActive: availability.archenemyCardPoolActive,
                        openAction: LifeCounterGameModesAction.openArchenemy,
                        editAction:
                            LifeCounterGameModesAction.editArchenemyCards,
                        closeCardPoolAction:
                            LifeCounterGameModesAction.closeArchenemyCardPool,
                        closeAction:
                            LifeCounterGameModesAction.closeArchenemy,
                      ),
                      const SizedBox(height: 10),
                      _GameModeStatusCard(
                        keyName: 'bounty',
                        modeKind: LifeCounterGameModeKind.bounty,
                        title: 'Bounty',
                        icon: Icons.workspace_premium_outlined,
                        summary:
                            'Bounty gameplay still depends on Lotus, but ManaLoom now owns the mode entry shell.',
                        available: availability.bountyAvailable,
                        active: availability.bountyActive,
                        preferred:
                            preferredAction == LifeCounterGameModesAction.openBounty ||
                            preferredAction ==
                                LifeCounterGameModesAction.editBountyCards ||
                            preferredAction ==
                                LifeCounterGameModesAction.closeBountyCardPool ||
                            preferredAction ==
                                LifeCounterGameModesAction.closeBounty,
                        preferredIntent: preferredIntent,
                        activeModeCount: availability.activeModeCount,
                        maxActiveModes: availability.maxActiveModes,
                        activeModeLabels: activeModeLabels,
                        cardPoolActive: availability.bountyCardPoolActive,
                        openAction: LifeCounterGameModesAction.openBounty,
                        editAction: LifeCounterGameModesAction.editBountyCards,
                        closeCardPoolAction:
                            LifeCounterGameModesAction.closeBountyCardPool,
                        closeAction: LifeCounterGameModesAction.closeBounty,
                      ),
                    ],
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

class _GameModeStatusCard extends StatelessWidget {
  const _GameModeStatusCard({
    required this.keyName,
    required this.modeKind,
    required this.title,
    required this.icon,
    required this.summary,
    required this.available,
    required this.active,
    required this.cardPoolActive,
    required this.preferred,
    required this.preferredIntent,
    required this.activeModeCount,
    required this.maxActiveModes,
    required this.activeModeLabels,
    required this.openAction,
    required this.editAction,
    required this.closeCardPoolAction,
    required this.closeAction,
  });

  final String keyName;
  final LifeCounterGameModeKind modeKind;
  final String title;
  final IconData icon;
  final String summary;
  final bool available;
  final bool active;
  final bool cardPoolActive;
  final bool preferred;
  final LifeCounterGameModesEntryIntent preferredIntent;
  final int activeModeCount;
  final int maxActiveModes;
  final List<String> activeModeLabels;
  final LifeCounterGameModesAction openAction;
  final LifeCounterGameModesAction editAction;
  final LifeCounterGameModesAction closeCardPoolAction;
  final LifeCounterGameModesAction closeAction;

  @override
  Widget build(BuildContext context) {
    final blockedByActiveModeLimit =
        available && !active && activeModeCount >= maxActiveModes;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: preferred ? AppTheme.primarySoft : AppTheme.outlineMuted,
          width: preferred ? 1.5 : 1,
        ),
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
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _GameModeBadge(label: available ? 'Available' : 'Unavailable'),
                if (active)
                  const _GameModeBadge(
                    label: 'Active Now',
                    foregroundColor: AppTheme.backgroundAbyss,
                    backgroundColor: AppTheme.success,
                  ),
                if (cardPoolActive)
                  const _GameModeBadge(
                    label: 'Card Pool Open',
                    foregroundColor: AppTheme.backgroundAbyss,
                    backgroundColor: AppTheme.warning,
                  ),
                if (preferred)
                  const _GameModeBadge(
                    label: 'Selected Surface',
                    foregroundColor: AppTheme.backgroundAbyss,
                    backgroundColor: AppTheme.primarySoft,
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
            if (active) ...[
              const SizedBox(height: 10),
              const Text(
                'An embedded overlay for this mode is already open in the current game.',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: AppTheme.fontSm,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
            if (cardPoolActive) ...[
              const SizedBox(height: 10),
              const Text(
                'The embedded card pool editor for this mode is already open in the current game.',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: AppTheme.fontSm,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
            if (blockedByActiveModeLimit) ...[
              const SizedBox(height: 10),
              Text(
                activeModeLabels.isEmpty
                    ? 'Lotus only allows $maxActiveModes active game modes at once. Close one active mode before starting $title or opening its card pool editor.'
                    : 'Lotus only allows $maxActiveModes active game modes at once. ${activeModeLabels.join(' and ')} ${activeModeLabels.length == 1 ? 'is' : 'are'} already active, so close one of them before starting $title or opening its card pool editor.',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: AppTheme.fontSm,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
            if (preferred &&
                preferredIntent == LifeCounterGameModesEntryIntent.editCards) ...[
              const SizedBox(height: 10),
              Text(
                'Continuing will hand off to the embedded $title card pool editor while ManaLoom keeps ownership of the entry shell.',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: AppTheme.fontSm,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              key: Key('life-counter-native-game-modes-$keyName-open'),
              onPressed:
                  available && !blockedByActiveModeLimit
                      ? () => Navigator.of(context).pop(
                        preferredIntent == LifeCounterGameModesEntryIntent.editCards
                            ? editAction
                            : openAction,
                      )
                      : null,
              icon: const Icon(Icons.launch_rounded),
              label: Text(
                !available
                    ? 'Not Available Right Now'
                    : blockedByActiveModeLimit
                    ? 'Close One Active Mode First'
                    : cardPoolActive
                    ? 'Return To Embedded Card Pool'
                    : preferred
                    ? preferredIntent == LifeCounterGameModesEntryIntent.editCards
                        ? 'Continue To Embedded Card Pool'
                        : 'Continue With $title'
                    : active
                    ? 'Return To Embedded Mode'
                    : 'Open Embedded Mode',
              ),
            ),
            if (available &&
                !blockedByActiveModeLimit &&
                preferredIntent == LifeCounterGameModesEntryIntent.openMode) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: Key('life-counter-native-game-modes-$keyName-edit-cards'),
                  onPressed: () => Navigator.of(context).pop(editAction),
                  icon: const Icon(Icons.style_outlined),
                  label: const Text('Edit Card Pool'),
                ),
              ),
            ],
            if (cardPoolActive) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: Key(
                    'life-counter-native-game-modes-$keyName-close-card-pool',
                  ),
                  onPressed: () => Navigator.of(context).pop(closeCardPoolAction),
                  icon: const Icon(Icons.close_fullscreen_rounded),
                  label: const Text('Close Embedded Card Pool'),
                ),
              ),
            ],
            if (active) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: Key('life-counter-native-game-modes-$keyName-close-overlay'),
                  onPressed: () => Navigator.of(context).pop(closeAction),
                  icon: const Icon(Icons.close_fullscreen_rounded),
                  label: const Text('Close Embedded Overlay'),
                ),
              ),
            ],
            if (!available) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: Key('life-counter-native-game-modes-$keyName-settings'),
                  onPressed:
                      () => Navigator.of(
                        context,
                      ).pop(LifeCounterGameModesAction.openSettings),
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text('Open Settings'),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: Key('life-counter-native-game-modes-$keyName-info'),
                onPressed: () => _showGameModeInfoSheet(context, modeKind),
                icon: const Icon(Icons.info_outline_rounded),
                label: const Text('How It Works'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameModeBadge extends StatelessWidget {
  const _GameModeBadge({
    required this.label,
    this.foregroundColor = AppTheme.textSecondary,
    this.backgroundColor = AppTheme.backgroundAbyss,
  });

  final String label;
  final Color foregroundColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.outlineMuted),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontSize: AppTheme.fontSm,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

Future<void> _showGameModeInfoSheet(
  BuildContext context,
  LifeCounterGameModeKind modeKind,
) {
  final info = _gameModeInfo(modeKind);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder:
        (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.backgroundAbyss,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                border: Border.all(color: AppTheme.outlineMuted),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              info.title,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: AppTheme.fontXxl,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            key: Key(
                              'life-counter-native-game-modes-${info.keyName}-info-close',
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded),
                            color: AppTheme.textSecondary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        info.summary,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: AppTheme.fontMd,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Quick Rules',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: AppTheme.fontLg,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final bullet in info.rules) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 7),
                              child: Icon(
                                Icons.circle,
                                size: 6,
                                color: AppTheme.primarySoft,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                bullet,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: AppTheme.fontMd,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        info.tip,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: AppTheme.fontSm,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
  );
}

({String keyName, String title, String summary, List<String> rules, String tip})
_gameModeInfo(LifeCounterGameModeKind modeKind) {
  switch (modeKind) {
    case LifeCounterGameModeKind.planechase:
      return (
        keyName: 'planechase',
        title: 'Planechase',
        summary:
            'A shared planar deck changes the battlefield for everyone. The mode still runs inside Lotus, but ManaLoom now owns the help surface.',
        rules: <String>[
          'During your turn, you may roll the planar die whenever you could cast a sorcery.',
          'Your first roll each turn is free. Every extra roll costs one mana more than the previous roll.',
          'Planeswalk on the planeswalker symbol, trigger chaos on the chaos symbol, and blank faces do nothing.',
        ],
        tip: 'Tip: long-press the Planechase button to roll the planar die instantly.',
      );
    case LifeCounterGameModeKind.archenemy:
      return (
        keyName: 'archenemy',
        title: 'Archenemy',
        summary:
            'The scheme deck powers up one player against the table. ManaLoom now owns the help surface while the scheme runtime stays embedded.',
        rules: <String>[
          'At the start of the archenemy turn, set a scheme in motion.',
          'Ongoing schemes stay in play until abandoned or completed.',
          'When a scheme is finished, the next one comes from the shared scheme deck.',
        ],
        tip: 'Tip: keep an eye on ongoing schemes because they stack pressure across turns.',
      );
    case LifeCounterGameModeKind.bounty:
      return (
        keyName: 'bounty',
        title: 'Bounty',
        summary:
            'A shared bounty deck gives the table rotating objectives and rewards. ManaLoom now owns the help surface for this mode.',
        rules: <String>[
          'Starting on turn 3, reveal a bounty card with a condition to complete.',
          'If a player completes the bounty, they claim the reward and a new one appears on the next turn.',
          'If no one claims it, the reward level escalates up to level 4.',
        ],
        tip: 'Tip: Bounty rewards snowball quickly, so unanswered objectives become table-wide pressure.',
      );
  }
}
