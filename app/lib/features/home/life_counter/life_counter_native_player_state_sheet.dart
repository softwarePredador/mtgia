import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'life_counter_session.dart';

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
  late int _targetPlayerIndex;
  late bool _partnerCommander;
  late LifeCounterPlayerSpecialState _specialState;

  @override
  void initState() {
    super.initState();
    _targetPlayerIndex = widget.initialTargetPlayerIndex.clamp(
      0,
      widget.initialSession.playerCount - 1,
    );
    _syncFromTarget();
  }

  void _syncFromTarget() {
    _partnerCommander =
        widget.initialSession.partnerCommanders[_targetPlayerIndex];
    _specialState =
        widget.initialSession.playerSpecialStates[_targetPlayerIndex];
  }

  void _changeTarget(int playerIndex) {
    setState(() {
      _targetPlayerIndex = playerIndex;
      _syncFromTarget();
    });
  }

  LifeCounterSession _buildUpdatedSession() {
    final partnerCommanders = List<bool>.from(
      widget.initialSession.partnerCommanders,
    );
    final playerSpecialStates = List<LifeCounterPlayerSpecialState>.from(
      widget.initialSession.playerSpecialStates,
    );

    partnerCommanders[_targetPlayerIndex] = _partnerCommander;
    playerSpecialStates[_targetPlayerIndex] = _specialState;

    return widget.initialSession.copyWith(
      partnerCommanders: partnerCommanders,
      playerSpecialStates: playerSpecialStates,
    );
  }

  @override
  Widget build(BuildContext context) {
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
                                      label: Text(_specialStateLabel(entry)),
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
                              _specialStateDescription(_specialState),
                              key: const Key(
                                'life-counter-native-player-state-description',
                              ),
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                height: 1.4,
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

String _specialStateLabel(LifeCounterPlayerSpecialState state) {
  switch (state) {
    case LifeCounterPlayerSpecialState.none:
      return 'Active player';
    case LifeCounterPlayerSpecialState.deckedOut:
      return 'Decked out';
    case LifeCounterPlayerSpecialState.answerLeft:
      return 'Left the table';
  }
}

String _specialStateDescription(LifeCounterPlayerSpecialState state) {
  switch (state) {
    case LifeCounterPlayerSpecialState.none:
      return 'This player is still active in the game.';
    case LifeCounterPlayerSpecialState.deckedOut:
      return 'Track that the player lost by drawing from an empty library.';
    case LifeCounterPlayerSpecialState.answerLeft:
      return 'Track that the player left or conceded outside of life loss.';
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
