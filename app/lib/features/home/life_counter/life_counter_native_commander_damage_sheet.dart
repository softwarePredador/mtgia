import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'life_counter_session.dart';
import 'life_counter_tabletop_engine.dart';

Future<LifeCounterSession?> showLifeCounterNativeCommanderDamageSheet(
  BuildContext context, {
  required LifeCounterSession initialSession,
  required int initialTargetPlayerIndex,
}) {
  return showModalBottomSheet<LifeCounterSession>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return _LifeCounterNativeCommanderDamageSheet(
        initialSession: initialSession,
        initialTargetPlayerIndex: initialTargetPlayerIndex,
      );
    },
  );
}

class _LifeCounterNativeCommanderDamageSheet extends StatefulWidget {
  const _LifeCounterNativeCommanderDamageSheet({
    required this.initialSession,
    required this.initialTargetPlayerIndex,
  });

  final LifeCounterSession initialSession;
  final int initialTargetPlayerIndex;

  @override
  State<_LifeCounterNativeCommanderDamageSheet> createState() =>
      _LifeCounterNativeCommanderDamageSheetState();
}

class _LifeCounterNativeCommanderDamageSheetState
    extends State<_LifeCounterNativeCommanderDamageSheet> {
  late int _targetPlayerIndex;
  late LifeCounterSession _draftSession;

  @override
  void initState() {
    super.initState();
    _targetPlayerIndex = widget.initialTargetPlayerIndex.clamp(
      0,
      widget.initialSession.playerCount - 1,
    );
    _draftSession = widget.initialSession;
  }

  String _playerLabel(int index) => 'Player ${index + 1}';

  void _updateCommanderDamage({
    required int sourceIndex,
    required bool secondCommander,
    required int delta,
  }) {
    setState(() {
      _draftSession = LifeCounterTabletopEngine.adjustCommanderDamageFromSource(
        _draftSession,
        targetPlayerIndex: _targetPlayerIndex,
        sourcePlayerIndex: sourceIndex,
        secondCommander: secondCommander,
        delta: delta,
      );
    });
  }

  LifeCounterSession _buildUpdatedSession() => _draftSession;

  @override
  Widget build(BuildContext context) {
    final playerBoardSummary = LifeCounterTabletopEngine.playerBoardSummary(
      _draftSession,
      playerIndex: _targetPlayerIndex,
      playerLabelBuilder: _playerLabel,
    );
    final lethalSources = LifeCounterTabletopEngine.commanderDamageLethalSources(
      _draftSession,
      targetPlayerIndex: _targetPlayerIndex,
    );
    final lethalSummary = playerBoardSummary.commanderDamageLethalSummary;
    final playerStatusSummary = playerBoardSummary.statusSummary;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: FractionallySizedBox(
          heightFactor: 0.82,
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Commander Damage',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: AppTheme.fontXxl,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'ManaLoom owns this shell while the Lotus tabletop stays visually identical.',
                              style: const TextStyle(
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
                            'Choose which player is receiving commander damage.',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List<Widget>.generate(
                            widget.initialSession.playerCount,
                            (index) => ChoiceChip(
                              key: Key(
                                'life-counter-native-commander-damage-target-$index',
                              ),
                              label: Text(_playerLabel(index)),
                              selected: _targetPlayerIndex == index,
                              onSelected:
                                  (_) => setState(
                                    () => _targetPlayerIndex = index,
                                  ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (lethalSources.isNotEmpty) ...[
                        _SectionCard(
                          title: 'Lethal Summary',
                          subtitle: lethalSummary ?? '',
                          child: const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 18),
                      ],
                      _SectionCard(
                        title: 'Target Status',
                        subtitle:
                            'The ManaLoom tabletop engine evaluates the target status before you apply the change.',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              playerStatusSummary.label,
                              key: const Key(
                                'life-counter-native-commander-damage-status-label',
                              ),
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: AppTheme.fontLg,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              playerStatusSummary.description,
                              key: const Key(
                                'life-counter-native-commander-damage-status-description',
                              ),
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: AppTheme.fontSm,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _SectionCard(
                        title: 'Damage By Source',
                        subtitle:
                            'Each source keeps the split between commander one and commander two when partner commander is enabled.',
                        child: Column(
                          children: [
                            for (
                              var sourceIndex = 0;
                              sourceIndex < widget.initialSession.playerCount;
                              sourceIndex += 1
                            )
                              if (sourceIndex != _targetPlayerIndex)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _CommanderDamageSourceCard(
                                    sourceIndex: sourceIndex,
                                    sourceLabel: _playerLabel(sourceIndex),
                                    detail:
                                        _draftSession
                                            .resolvedCommanderDamageDetails[_targetPlayerIndex][sourceIndex],
                                    hasPartnerCommander:
                                        widget
                                            .initialSession
                                            .partnerCommanders[sourceIndex],
                                    isLethal: LifeCounterTabletopEngine
                                        .isCommanderDamageSourceLethal(
                                          _draftSession,
                                          targetPlayerIndex:
                                              _targetPlayerIndex,
                                          sourcePlayerIndex: sourceIndex,
                                        ),
                                    onCommanderOneIncrement:
                                        () => _updateCommanderDamage(
                                          sourceIndex: sourceIndex,
                                          secondCommander: false,
                                          delta: 1,
                                        ),
                                    onCommanderOneDecrement:
                                        () => _updateCommanderDamage(
                                          sourceIndex: sourceIndex,
                                          secondCommander: false,
                                          delta: -1,
                                        ),
                                    onCommanderTwoIncrement:
                                        () => _updateCommanderDamage(
                                          sourceIndex: sourceIndex,
                                          secondCommander: true,
                                          delta: 1,
                                        ),
                                    onCommanderTwoDecrement:
                                        () => _updateCommanderDamage(
                                          sourceIndex: sourceIndex,
                                          secondCommander: true,
                                          delta: -1,
                                        ),
                                  ),
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
                            'life-counter-native-commander-damage-apply',
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

class _CommanderDamageSourceCard extends StatelessWidget {
  const _CommanderDamageSourceCard({
    required this.sourceIndex,
    required this.sourceLabel,
    required this.detail,
    required this.hasPartnerCommander,
    required this.isLethal,
    required this.onCommanderOneIncrement,
    required this.onCommanderOneDecrement,
    required this.onCommanderTwoIncrement,
    required this.onCommanderTwoDecrement,
  });

  final int sourceIndex;
  final String sourceLabel;
  final LifeCounterCommanderDamageDetail detail;
  final bool hasPartnerCommander;
  final bool isLethal;
  final VoidCallback onCommanderOneIncrement;
  final VoidCallback onCommanderOneDecrement;
  final VoidCallback onCommanderTwoIncrement;
  final VoidCallback onCommanderTwoDecrement;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color:
            isLethal
                ? AppTheme.error.withValues(alpha: 0.1)
                : AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color:
              isLethal
                  ? AppTheme.error.withValues(alpha: 0.35)
                  : AppTheme.outlineMuted,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    sourceLabel,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: AppTheme.fontLg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  'Total ${detail.totalDamage}',
                  style: TextStyle(
                    color: isLethal ? AppTheme.error : AppTheme.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _CommanderDamageStepper(
              label: hasPartnerCommander ? 'Commander 1' : 'Commander',
              value: detail.commanderOneDamage,
              decrementKey: Key(
                'life-counter-native-commander-damage-minus-$sourceIndex-c1',
              ),
              incrementKey: Key(
                'life-counter-native-commander-damage-plus-$sourceIndex-c1',
              ),
              valueKey: Key(
                'life-counter-native-commander-damage-value-$sourceIndex-c1',
              ),
              onIncrement: onCommanderOneIncrement,
              onDecrement: onCommanderOneDecrement,
            ),
            if (hasPartnerCommander) ...[
              const SizedBox(height: 10),
              _CommanderDamageStepper(
                label: 'Commander 2',
                value: detail.commanderTwoDamage,
                decrementKey: Key(
                  'life-counter-native-commander-damage-minus-$sourceIndex-c2',
                ),
                incrementKey: Key(
                  'life-counter-native-commander-damage-plus-$sourceIndex-c2',
                ),
                valueKey: Key(
                  'life-counter-native-commander-damage-value-$sourceIndex-c2',
                ),
                onIncrement: onCommanderTwoIncrement,
                onDecrement: onCommanderTwoDecrement,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CommanderDamageStepper extends StatelessWidget {
  const _CommanderDamageStepper({
    required this.label,
    required this.value,
    required this.decrementKey,
    required this.incrementKey,
    required this.valueKey,
    required this.onIncrement,
    required this.onDecrement,
  });

  final String label;
  final int value;
  final Key decrementKey;
  final Key incrementKey;
  final Key valueKey;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        IconButton(
          key: decrementKey,
          onPressed: onDecrement,
          icon: const Icon(Icons.remove_circle_outline_rounded),
          color: AppTheme.textSecondary,
        ),
        Container(
          key: valueKey,
          width: 46,
          alignment: Alignment.center,
          child: Text(
            '$value',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: AppTheme.fontLg,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        IconButton(
          key: incrementKey,
          onPressed: onIncrement,
          icon: const Icon(Icons.add_circle_outline_rounded),
          color: AppTheme.textPrimary,
        ),
      ],
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
