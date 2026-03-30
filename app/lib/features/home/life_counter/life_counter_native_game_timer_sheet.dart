import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'life_counter_game_timer_engine.dart';
import 'life_counter_game_timer_state.dart';

Future<LifeCounterGameTimerState?> showLifeCounterNativeGameTimerSheet(
  BuildContext context, {
  required LifeCounterGameTimerState initialState,
  DateTime Function()? nowProvider,
}) {
  return showModalBottomSheet<LifeCounterGameTimerState>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return _LifeCounterNativeGameTimerSheet(
        initialState: initialState,
        nowProvider: nowProvider ?? DateTime.now,
      );
    },
  );
}

class _LifeCounterNativeGameTimerSheet extends StatefulWidget {
  const _LifeCounterNativeGameTimerSheet({
    required this.initialState,
    required this.nowProvider,
  });

  final LifeCounterGameTimerState initialState;
  final DateTime Function() nowProvider;

  @override
  State<_LifeCounterNativeGameTimerSheet> createState() =>
      _LifeCounterNativeGameTimerSheetState();
}

class _LifeCounterNativeGameTimerSheetState
    extends State<_LifeCounterNativeGameTimerSheet> {
  late LifeCounterGameTimerState _draftState;

  bool get _isActive => _draftState.isActive;
  bool get _isPaused => _draftState.isPaused;

  int get _nowEpochMs => widget.nowProvider().millisecondsSinceEpoch;

  @override
  void initState() {
    super.initState();
    _draftState = widget.initialState;
  }

  @override
  Widget build(BuildContext context) {
    final elapsedSeconds = LifeCounterGameTimerEngine.elapsedSecondsAt(
      _draftState,
      nowEpochMs: _nowEpochMs,
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: FractionallySizedBox(
          heightFactor: 0.68,
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
                              'Game Timer',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: AppTheme.fontXxl,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'ManaLoom owns the timer shell while the Lotus tabletop stays visually identical.',
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
                        title: 'Current Timer State',
                        subtitle:
                            'Preview of the timer state that will be pushed back into the tabletop.',
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _SummaryChip(
                              label: 'Status',
                              value:
                                  !_isActive
                                      ? 'Idle'
                                      : (_isPaused ? 'Paused' : 'Running'),
                            ),
                            _SummaryChip(
                              label: 'Elapsed',
                              value: _formatDuration(elapsedSeconds),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _SectionCard(
                        title: 'Actions',
                        subtitle:
                            _isActive
                                ? 'Pause, resume or reset the table timer before applying it back to Lotus.'
                                : 'Start a new game timer from zero.',
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            if (!_isActive)
                              FilledButton.icon(
                                key: const Key(
                                  'life-counter-native-game-timer-start',
                                ),
                                onPressed: () {
                                  setState(() {
                                    _draftState =
                                        LifeCounterGameTimerEngine.start(
                                          nowEpochMs: _nowEpochMs,
                                        );
                                  });
                                },
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: const Text('Start'),
                              ),
                            if (_isActive && !_isPaused)
                              OutlinedButton.icon(
                                key: const Key(
                                  'life-counter-native-game-timer-pause',
                                ),
                                onPressed: () {
                                  setState(() {
                                    _draftState =
                                        LifeCounterGameTimerEngine.pause(
                                          _draftState,
                                          nowEpochMs: _nowEpochMs,
                                        );
                                  });
                                },
                                icon: const Icon(Icons.pause_rounded),
                                label: const Text('Pause'),
                              ),
                            if (_isActive && _isPaused)
                              FilledButton.icon(
                                key: const Key(
                                  'life-counter-native-game-timer-resume',
                                ),
                                onPressed: () {
                                  setState(() {
                                    _draftState =
                                        LifeCounterGameTimerEngine.resume(
                                          _draftState,
                                          nowEpochMs: _nowEpochMs,
                                        );
                                  });
                                },
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: const Text('Resume'),
                              ),
                            if (_isActive)
                              OutlinedButton.icon(
                                key: const Key(
                                  'life-counter-native-game-timer-reset',
                                ),
                                onPressed: () {
                                  setState(() {
                                    _draftState =
                                        LifeCounterGameTimerEngine.reset();
                                  });
                                },
                                icon: const Icon(Icons.restart_alt_rounded),
                                label: const Text('Reset'),
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
                            'life-counter-native-game-timer-apply',
                          ),
                          onPressed:
                              () => Navigator.of(context).pop(_draftState),
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

  static String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    final paddedMinutes =
        hours > 0 ? minutes.toString().padLeft(2, '0') : minutes.toString();
    final paddedSeconds = seconds.toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$paddedMinutes:$paddedSeconds';
    }
    return '$paddedMinutes:$paddedSeconds';
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
