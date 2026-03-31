import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'life_counter_dice_engine.dart';
import 'life_counter_session.dart';
import 'life_counter_tabletop_engine.dart';

Future<LifeCounterSession?> showLifeCounterNativeDiceSheet(
  BuildContext context, {
  required LifeCounterSession initialSession,
  Random? random,
}) {
  return showModalBottomSheet<LifeCounterSession>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return _LifeCounterNativeDiceSheet(
        initialSession: initialSession,
        random: random ?? Random(),
      );
    },
  );
}

class _LifeCounterNativeDiceSheet extends StatefulWidget {
  const _LifeCounterNativeDiceSheet({
    required this.initialSession,
    required this.random,
  });

  final LifeCounterSession initialSession;
  final Random random;

  @override
  State<_LifeCounterNativeDiceSheet> createState() =>
      _LifeCounterNativeDiceSheetState();
}

class _LifeCounterNativeDiceSheetState extends State<_LifeCounterNativeDiceSheet> {
  late LifeCounterSession _draftSession;

  Set<int> get _highRollWinners =>
      LifeCounterDiceEngine.deriveHighRollWinners(_draftSession.lastHighRolls);

  bool get _hasPendingTieBreak => _highRollWinners.length > 1;
  bool get _hasAnyActivePlayers =>
      LifeCounterTabletopEngine.hasAnyActivePlayers(_draftSession);

  @override
  void initState() {
    super.initState();
    _draftSession = widget.initialSession;
  }

  void _applyAction(
    LifeCounterSession Function(
      LifeCounterSession session, {
      Random? random,
    })
    action,
  ) {
    setState(() {
      _draftSession = action(_draftSession, random: widget.random);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: FractionallySizedBox(
          heightFactor: 0.76,
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
                              'Dice Tools',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: AppTheme.fontXxl,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'ManaLoom owns the dice shell while the Lotus tabletop stays visually identical.',
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
                      _DiceSectionCard(
                        title: 'Quick Actions',
                        subtitle:
                            !_hasAnyActivePlayers
                                ? 'No active players remain on the table. Dice actions that choose a player stay unavailable.'
                                : _hasPendingTieBreak
                                ? 'The previous high roll ended in a tie. Running high roll again rerolls only tied players.'
                                : 'Run the same table tools without leaving the ManaLoom-owned shell.',
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            FilledButton.icon(
                              key: const Key(
                                'life-counter-native-dice-high-roll',
                              ),
                              onPressed:
                                  _hasAnyActivePlayers
                                      ? () => _applyAction(
                                        LifeCounterDiceEngine.runHighRoll,
                                      )
                                      : null,
                              icon: const Icon(Icons.emoji_events_rounded),
                              label: Text(
                                _hasPendingTieBreak ? 'Tiebreak' : 'High Roll',
                              ),
                            ),
                            OutlinedButton.icon(
                              key: const Key('life-counter-native-dice-d20'),
                              onPressed:
                                  () => _applyAction(
                                    LifeCounterDiceEngine.runTableD20,
                                  ),
                              icon: const Icon(Icons.casino_rounded),
                              label: const Text('D20'),
                            ),
                            OutlinedButton.icon(
                              key: const Key('life-counter-native-dice-coin'),
                              onPressed:
                                  () => _applyAction(
                                    LifeCounterDiceEngine.runCoinFlip,
                                  ),
                              icon: const Icon(Icons.toll_rounded),
                              label: const Text('Coin'),
                            ),
                            OutlinedButton.icon(
                              key: const Key(
                                'life-counter-native-dice-first-player',
                              ),
                              onPressed:
                                  _hasAnyActivePlayers
                                      ? () => _applyAction(
                                        LifeCounterDiceEngine.runFirstPlayerRoll,
                                      )
                                      : null,
                              icon: const Icon(Icons.flag_rounded),
                              label: const Text('Roll 1st'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _DiceSectionCard(
                        title: 'Current State',
                        subtitle:
                            'Preview of what will be pushed back into the live tabletop after applying.',
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _SummaryChip(
                              label: 'First Player',
                              value:
                                  _draftSession.firstPlayerIndex == null
                                      ? 'Unset'
                                      : 'Player ${_draftSession.firstPlayerIndex! + 1}',
                            ),
                            _SummaryChip(
                              label: 'Last Event',
                              value:
                                  _draftSession.lastTableEvent == null
                                      ? 'None'
                                      : _draftSession.lastTableEvent!,
                            ),
                          ],
                        ),
                      ),
                      if (_draftSession.lastHighRolls.whereType<int>().isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _DiceSectionCard(
                          title: 'High Roll Board',
                          subtitle:
                              _highRollWinners.length == 1
                                  ? 'Winning player is highlighted below.'
                                  : 'Tie detected. Running high roll again rerolls only tied players.',
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (
                                var index = 0;
                                index < _draftSession.playerCount;
                                index += 1
                              )
                                if (_draftSession.lastHighRolls[index] != null)
                                  _RollChip(
                                    label: 'P${index + 1}',
                                    value: _draftSession.lastHighRolls[index]!,
                                    highlighted: _highRollWinners.contains(index),
                                  ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppTheme.outlineMuted),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        key: const Key('life-counter-native-dice-apply'),
                        onPressed: () => Navigator.of(context).pop(_draftSession),
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Apply'),
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

class _DiceSectionCard extends StatelessWidget {
  const _DiceSectionCard({
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
            const SizedBox(height: 6),
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

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.backgroundAbyss,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.outlineMuted),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: AppTheme.fontXs,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: AppTheme.fontMd,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RollChip extends StatelessWidget {
  const _RollChip({
    required this.label,
    required this.value,
    required this.highlighted,
  });

  final String label;
  final int value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color:
            highlighted
                ? AppTheme.primarySoft.withValues(alpha: 0.18)
                : AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: highlighted ? AppTheme.primarySoft : AppTheme.outlineMuted,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: AppTheme.fontSm,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$value',
              style: TextStyle(
                color:
                    highlighted ? AppTheme.primarySoft : AppTheme.textPrimary,
                fontSize: AppTheme.fontLg,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
