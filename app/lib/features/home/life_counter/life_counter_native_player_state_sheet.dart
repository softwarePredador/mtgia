import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'life_counter_dice_engine.dart';
import 'life_counter_native_commander_damage_sheet.dart';
import 'life_counter_native_player_appearance_sheet.dart';
import 'life_counter_native_player_counter_sheet.dart';
import 'life_counter_native_set_life_sheet.dart';
import 'life_counter_session.dart';
import 'life_counter_tabletop_engine.dart';

Future<LifeCounterSession?> showLifeCounterNativePlayerStateSheet(
  BuildContext context, {
  required LifeCounterSession initialSession,
  required int initialTargetPlayerIndex,
}) {
  return showModalBottomSheet<LifeCounterSession>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return _LifeCounterNativePlayerStateSheet(
        initialSession: initialSession,
        initialTargetPlayerIndex: initialTargetPlayerIndex,
      );
    },
  );
}

class _LifeCounterNativePlayerStateSheet extends StatefulWidget {
  const _LifeCounterNativePlayerStateSheet({
    required this.initialSession,
    required this.initialTargetPlayerIndex,
  });

  final LifeCounterSession initialSession;
  final int initialTargetPlayerIndex;

  @override
  State<_LifeCounterNativePlayerStateSheet> createState() =>
      _LifeCounterNativePlayerStateSheetState();
}

class _LifeCounterNativePlayerStateSheetState
    extends State<_LifeCounterNativePlayerStateSheet> {
  static final Random _runtimeRandom = Random();

  late int _targetPlayerIndex;
  late LifeCounterSession _draftSession;
  late bool _partnerCommander;
  late LifeCounterPlayerSpecialState _specialState;

  @override
  void initState() {
    super.initState();
    _draftSession = widget.initialSession;
    _targetPlayerIndex = widget.initialTargetPlayerIndex.clamp(
      0,
      widget.initialSession.playerCount - 1,
    );
    _syncFromTarget();
  }

  void _syncFromTarget() {
    _partnerCommander = _draftSession.partnerCommanders[_targetPlayerIndex];
    _specialState = _draftSession.playerSpecialStates[_targetPlayerIndex];
  }

  void _changeTarget(int playerIndex) {
    setState(() {
      _targetPlayerIndex = playerIndex;
      _syncFromTarget();
    });
  }

  LifeCounterSession _buildUpdatedSession() {
    var updatedSession = LifeCounterTabletopEngine.setPartnerCommander(
      _draftSession,
      playerIndex: _targetPlayerIndex,
      enabled: _partnerCommander,
    );
    updatedSession = LifeCounterTabletopEngine.setPlayerSpecialState(
      updatedSession,
      playerIndex: _targetPlayerIndex,
      state: _specialState,
    );
    return updatedSession;
  }

  Future<void> _openManageCounters() async {
    final updatedSession = await showLifeCounterNativePlayerCounterSheet(
      context,
      initialSession: _buildUpdatedSession(),
      initialTargetPlayerIndex: _targetPlayerIndex,
      counterKey: 'poison',
    );
    if (!mounted || updatedSession == null) {
      return;
    }

    setState(() {
      _draftSession = updatedSession;
      _syncFromTarget();
    });
  }

  Future<void> _openManageCommanderDamage() async {
    final updatedSession = await showLifeCounterNativeCommanderDamageSheet(
      context,
      initialSession: _buildUpdatedSession(),
      initialTargetPlayerIndex: _targetPlayerIndex,
    );
    if (!mounted || updatedSession == null) {
      return;
    }

    setState(() {
      _draftSession = updatedSession;
      _syncFromTarget();
    });
  }

  Future<void> _openManageAppearance() async {
    final updatedSession = await showLifeCounterNativePlayerAppearanceSheet(
      context,
      initialSession: _buildUpdatedSession(),
      initialTargetPlayerIndex: _targetPlayerIndex,
    );
    if (!mounted || updatedSession == null) {
      return;
    }

    setState(() {
      _draftSession = updatedSession;
      _syncFromTarget();
    });
  }

  Future<void> _openSetLife() async {
    final updatedSession = await showLifeCounterNativeSetLifeSheet(
      context,
      initialSession: _buildUpdatedSession(),
      initialTargetPlayerIndex: _targetPlayerIndex,
    );
    if (!mounted || updatedSession == null) {
      return;
    }

    setState(() {
      _draftSession = updatedSession;
      _syncFromTarget();
    });
  }

  void _rollPlayerD20() {
    setState(() {
      _draftSession = LifeCounterDiceEngine.runPlayerD20(
        _buildUpdatedSession(),
        _targetPlayerIndex,
        random: _runtimeRandom,
      );
      _syncFromTarget();
    });
  }

  void _markPlayerKnockedOut() {
    setState(() {
      _draftSession = LifeCounterTabletopEngine.markPlayerKnockedOut(
        _buildUpdatedSession(),
        playerIndex: _targetPlayerIndex,
      );
      _syncFromTarget();
    });
  }

  void _markPlayerDeckedOut() {
    setState(() {
      _draftSession = LifeCounterTabletopEngine.markPlayerDeckedOut(
        _buildUpdatedSession(),
        playerIndex: _targetPlayerIndex,
      );
      _syncFromTarget();
    });
  }

  void _markPlayerAnswerLeft() {
    setState(() {
      _draftSession = LifeCounterTabletopEngine.markPlayerAnswerLeft(
        _buildUpdatedSession(),
        playerIndex: _targetPlayerIndex,
      );
      _syncFromTarget();
    });
  }

  void _revivePlayer() {
    setState(() {
      _draftSession = LifeCounterTabletopEngine.revivePlayer(
        _buildUpdatedSession(),
        playerIndex: _targetPlayerIndex,
      );
      _syncFromTarget();
    });
  }

  @override
  Widget build(BuildContext context) {
    final playerStatusSummary = LifeCounterTabletopEngine.playerBoardSummary(
      _draftSession,
      playerIndex: _targetPlayerIndex,
    ).statusSummary;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: FractionallySizedBox(
          heightFactor: 0.74,
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
                              'Player State',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: AppTheme.fontXxl,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'ManaLoom owns partner commander and special player states while the tabletop stays visually identical.',
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
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                    children: [
                      _SectionCard(
                        title: 'Target Player',
                        subtitle:
                            'Choose which player receives the state changes.',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List<Widget>.generate(
                            widget.initialSession.playerCount,
                            (index) => ChoiceChip(
                              key: Key(
                                'life-counter-native-player-state-target-$index',
                              ),
                              label: Text('Player ${index + 1}'),
                              selected: _targetPlayerIndex == index,
                              onSelected: (_) => _changeTarget(index),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _SectionCard(
                        title: 'Current Status',
                        subtitle:
                            'Use the canonical tabletop engine to understand why this player is active, lethal or out of the game.',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              playerStatusSummary.label,
                              key: const Key(
                                'life-counter-native-player-state-status-label',
                              ),
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: AppTheme.fontLg,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              playerStatusSummary.description,
                              key: const Key(
                                'life-counter-native-player-state-status-description',
                              ),
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _SectionCard(
                        title: 'Commander Setup',
                        subtitle:
                            'Keep partner commander under our canonical player contract.',
                        child: SwitchListTile.adaptive(
                          key: const Key(
                            'life-counter-native-player-state-partner-toggle',
                          ),
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Partner commander',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: const Text(
                            'Enable split commander tax and split commander damage for this player.',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                          value: _partnerCommander,
                          onChanged:
                              (value) =>
                                  setState(() => _partnerCommander = value),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _SectionCard(
                        title: 'Player Tools',
                        subtitle:
                            'Open ManaLoom-owned player tools without depending on Lotus-only chips and gestures.',
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            FilledButton.tonalIcon(
                              key: const Key(
                                'life-counter-native-player-state-set-life',
                              ),
                              onPressed: _openSetLife,
                              icon: const Icon(Icons.favorite_rounded),
                              label: const Text('Set Life'),
                            ),
                            FilledButton.tonalIcon(
                              key: const Key(
                                'life-counter-native-player-state-manage-counters',
                              ),
                              onPressed: _openManageCounters,
                              icon: const Icon(Icons.tune_rounded),
                              label: const Text('Manage Counters'),
                            ),
                            FilledButton.tonalIcon(
                              key: const Key(
                                'life-counter-native-player-state-manage-commander-damage',
                              ),
                              onPressed: _openManageCommanderDamage,
                              icon: const Icon(Icons.shield_outlined),
                              label: const Text('Commander Damage'),
                            ),
                            FilledButton.tonalIcon(
                              key: const Key(
                                'life-counter-native-player-state-manage-appearance',
                              ),
                              onPressed: _openManageAppearance,
                              icon: const Icon(Icons.palette_outlined),
                              label: const Text('Player Appearance'),
                            ),
                            FilledButton.tonalIcon(
                              key: const Key(
                                'life-counter-native-player-state-roll-d20',
                              ),
                              onPressed: _rollPlayerD20,
                              icon: const Icon(Icons.casino_rounded),
                              label: const Text('Roll D20'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _SectionCard(
                        title: 'Special State',
                        subtitle:
                            'Preserve the defeat reason separately from the Lotus alive flag.',
                        child: Column(
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: LifeCounterPlayerSpecialState.values
                                  .map(
                                    (entry) => ChoiceChip(
                                      key: Key(
                                        'life-counter-native-player-state-${entry.name}',
                                      ),
                                      label: Text(
                                        LifeCounterTabletopEngine
                                            .playerSpecialStateLabel(entry),
                                      ),
                                      selected: _specialState == entry,
                                      onSelected:
                                          (_) => setState(
                                            () => _specialState = entry,
                                          ),
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              LifeCounterTabletopEngine
                                  .playerSpecialStateDescription(
                                    _specialState,
                                  ),
                              key: const Key(
                                'life-counter-native-player-state-description',
                              ),
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                FilledButton.tonalIcon(
                                  key: const Key(
                                    'life-counter-native-player-state-knockout',
                                  ),
                                  onPressed: _markPlayerKnockedOut,
                                  icon: const Icon(Icons.heart_broken_rounded),
                                  label: const Text('Knock Out'),
                                ),
                                FilledButton.tonalIcon(
                                  key: const Key(
                                    'life-counter-native-player-state-decked-out',
                                  ),
                                  onPressed: _markPlayerDeckedOut,
                                  icon: const Icon(Icons.menu_book_rounded),
                                  label: const Text('Decked Out'),
                                ),
                                FilledButton.tonalIcon(
                                  key: const Key(
                                    'life-counter-native-player-state-left-table',
                                  ),
                                  onPressed: _markPlayerAnswerLeft,
                                  icon: const Icon(Icons.exit_to_app_rounded),
                                  label: const Text('Left Table'),
                                ),
                                FilledButton.tonalIcon(
                                  key: const Key(
                                    'life-counter-native-player-state-revive',
                                  ),
                                  onPressed: _revivePlayer,
                                  icon: const Icon(Icons.restart_alt_rounded),
                                  label: const Text('Revive'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppTheme.outlineMuted),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textSecondary,
                            side: const BorderSide(
                              color: AppTheme.outlineMuted,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          key: const Key(
                            'life-counter-native-player-state-apply',
                          ),
                          onPressed:
                              () => Navigator.of(
                                context,
                              ).pop(_buildUpdatedSession()),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.manaViolet,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Apply'),
                        ),
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

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
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: AppTheme.fontLg,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: AppTheme.fontSm,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}
