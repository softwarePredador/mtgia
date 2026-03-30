import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'life_counter_session.dart';
import 'life_counter_turn_tracker_engine.dart';

Future<LifeCounterSession?> showLifeCounterNativeTurnTrackerSheet(
  BuildContext context, {
  required LifeCounterSession initialSession,
}) {
  return showModalBottomSheet<LifeCounterSession>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return _LifeCounterNativeTurnTrackerSheet(initialSession: initialSession);
    },
  );
}

class _LifeCounterNativeTurnTrackerSheet extends StatefulWidget {
  const _LifeCounterNativeTurnTrackerSheet({required this.initialSession});

  final LifeCounterSession initialSession;

  @override
  State<_LifeCounterNativeTurnTrackerSheet> createState() =>
      _LifeCounterNativeTurnTrackerSheetState();
}

class _LifeCounterNativeTurnTrackerSheetState
    extends State<_LifeCounterNativeTurnTrackerSheet> {
  late LifeCounterSession _draftSession;
  late int _startingPlayerIndex;
  late bool _autoHighRoll;
  late bool _turnTimerActive;

  @override
  void initState() {
    super.initState();
    _draftSession = widget.initialSession;
    _startingPlayerIndex =
        widget.initialSession.firstPlayerIndex ?? _firstAlivePlayerIndex();
    _autoHighRoll = widget.initialSession.turnTrackerAutoHighRoll;
    _turnTimerActive = widget.initialSession.turnTimerActive;
  }

  bool get _isTrackerActive => _draftSession.turnTrackerActive;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: FractionallySizedBox(
          heightFactor: 0.78,
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
                              'Turn Tracker',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: AppTheme.fontXxl,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'ManaLoom owns the turn tracker shell while the Lotus tabletop stays visually identical.',
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
                      _SummaryCard(
                        isTrackerActive: _isTrackerActive,
                        currentTurn: _draftSession.currentTurnNumber,
                        currentPlayerLabel: _playerLabel(
                          _draftSession.currentTurnPlayerIndex ??
                              _startingPlayerIndex,
                        ),
                        startingPlayerLabel: _playerLabel(_startingPlayerIndex),
                        turnTimerActive: _turnTimerActive,
                        turnTimerSeconds: _draftSession.turnTimerSeconds,
                      ),
                      const SizedBox(height: 18),
                      _SectionCard(
                        title: 'Starting Player',
                        subtitle:
                            'Choose who starts. Dead players stay unavailable.',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List<
                            Widget
                          >.generate(_draftSession.playerCount, (index) {
                            final isAlive = _isAlive(index);
                            return ChoiceChip(
                              key: Key(
                                'life-counter-native-turn-tracker-player-$index',
                              ),
                              label: Text(_playerLabel(index)),
                              selected: _startingPlayerIndex == index,
                              onSelected:
                                  isAlive
                                      ? (_) => setState(() {
                                        _startingPlayerIndex = index;
                                        if (_isTrackerActive) {
                                          _draftSession =
                                              LifeCounterTurnTrackerEngine.setStartingPlayer(
                                                _draftSession.copyWith(
                                                  turnTrackerAutoHighRoll:
                                                      _autoHighRoll,
                                                  turnTimerActive:
                                                      _turnTimerActive,
                                                ),
                                                playerIndex: index,
                                              );
                                        }
                                      })
                                      : null,
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _SectionCard(
                        title: 'Tracker Options',
                        subtitle:
                            'These values are applied when the tabletop is reloaded.',
                        child: Column(
                          children: [
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                'Auto high roll',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: const Text(
                                'Keep Lotus parity for tables that auto-pick a starting player.',
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                              value: _autoHighRoll,
                              onChanged: (value) {
                                setState(() {
                                  _autoHighRoll = value;
                                  _draftSession = _draftSession.copyWith(
                                    turnTrackerAutoHighRoll: value,
                                  );
                                });
                              },
                            ),
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                'Turn timer',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: const Text(
                                'Show the per-turn timer on the tabletop surface.',
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                              value: _turnTimerActive,
                              onChanged: (value) {
                                setState(() {
                                  _turnTimerActive = value;
                                  _draftSession =
                                      LifeCounterTurnTrackerEngine.setTurnTimerActive(
                                        _draftSession,
                                        isActive: value,
                                      ).copyWith(
                                        turnTrackerAutoHighRoll: _autoHighRoll,
                                      );
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _SectionCard(
                        title: 'Actions',
                        subtitle:
                            _isTrackerActive
                                ? 'Advance or rewind the draft state before applying it back to the tabletop.'
                                : 'Start a tracked game from the selected player.',
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            if (!_isTrackerActive)
                              FilledButton.icon(
                                key: const Key(
                                  'life-counter-native-turn-tracker-start',
                                ),
                                onPressed: () {
                                  setState(() {
                                    _draftSession =
                                        LifeCounterTurnTrackerEngine.startGame(
                                          _draftSession,
                                          startingPlayerIndex:
                                              _startingPlayerIndex,
                                          autoHighRoll: _autoHighRoll,
                                          turnTimerActive: _turnTimerActive,
                                        );
                                  });
                                },
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: const Text('Start Game'),
                              ),
                            if (_isTrackerActive) ...[
                              OutlinedButton.icon(
                                key: const Key(
                                  'life-counter-native-turn-tracker-previous',
                                ),
                                onPressed: () {
                                  setState(() {
                                    _draftSession =
                                        LifeCounterTurnTrackerEngine.previousTurn(
                                          _draftSession,
                                        );
                                    _startingPlayerIndex =
                                        _draftSession.firstPlayerIndex ??
                                        _startingPlayerIndex;
                                  });
                                },
                                icon: const Icon(Icons.undo_rounded),
                                label: const Text('Back'),
                              ),
                              FilledButton.icon(
                                key: const Key(
                                  'life-counter-native-turn-tracker-next',
                                ),
                                onPressed: () {
                                  setState(() {
                                    _draftSession =
                                        LifeCounterTurnTrackerEngine.nextTurn(
                                          _draftSession,
                                        );
                                  });
                                },
                                icon: const Icon(Icons.redo_rounded),
                                label: const Text('Next'),
                              ),
                              OutlinedButton.icon(
                                key: const Key(
                                  'life-counter-native-turn-tracker-stop',
                                ),
                                onPressed: () {
                                  setState(() {
                                    _draftSession =
                                        LifeCounterTurnTrackerEngine.stopGame(
                                          _draftSession,
                                        ).copyWith(
                                          turnTrackerAutoHighRoll:
                                              _autoHighRoll,
                                          turnTimerActive: _turnTimerActive,
                                        );
                                  });
                                },
                                icon: const Icon(Icons.stop_rounded),
                                label: const Text('Stop'),
                              ),
                            ],
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
                            'life-counter-native-turn-tracker-apply',
                          ),
                          onPressed: () {
                            Navigator.of(context).pop(
                              _draftSession.copyWith(
                                turnTrackerAutoHighRoll: _autoHighRoll,
                                turnTimerActive: _turnTimerActive,
                              ),
                            );
                          },
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

  int _firstAlivePlayerIndex() {
    for (var index = 0; index < widget.initialSession.playerCount; index += 1) {
      if (_isAlive(index)) {
        return index;
      }
    }
    return 0;
  }

  bool _isAlive(int index) {
    return widget.initialSession.playerSpecialStates[index] ==
        LifeCounterPlayerSpecialState.none;
  }

  String _playerLabel(int index) => 'Player ${index + 1}';
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.isTrackerActive,
    required this.currentTurn,
    required this.currentPlayerLabel,
    required this.startingPlayerLabel,
    required this.turnTimerActive,
    required this.turnTimerSeconds,
  });

  final bool isTrackerActive;
  final int currentTurn;
  final String currentPlayerLabel;
  final String startingPlayerLabel;
  final bool turnTimerActive;
  final int turnTimerSeconds;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Current Draft State',
      subtitle:
          isTrackerActive
              ? 'Preview of what will be pushed back into the embedded tabletop.'
              : 'Tracker is currently stopped.',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _SummaryChip(
            label: 'Status',
            value: isTrackerActive ? 'Active' : 'Idle',
          ),
          _SummaryChip(label: 'Turn', value: '$currentTurn'),
          _SummaryChip(label: 'Current', value: currentPlayerLabel),
          _SummaryChip(label: 'Starts', value: startingPlayerLabel),
          _SummaryChip(
            label: 'Timer',
            value: turnTimerActive ? _formatDuration(turnTimerSeconds) : 'Off',
          ),
        ],
      ),
    );
  }

  static String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final paddedSeconds = seconds.toString().padLeft(2, '0');
    return '$minutes:$paddedSeconds';
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
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
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
                fontSize: AppTheme.fontSm,
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
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.primarySoft,
                fontSize: AppTheme.fontLg,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
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
