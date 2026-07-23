import 'dart:async';

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
    backgroundColor: AppTheme.transparent,
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
  Timer? _ticker;

  bool get _isActive => _draftState.isActive;
  bool get _isPaused => _draftState.isPaused;

  int get _nowEpochMs => widget.nowProvider().millisecondsSinceEpoch;

  @override
  void initState() {
    super.initState();
    _draftState = widget.initialState;
    _syncTicker();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _syncTicker() {
    _ticker?.cancel();
    _ticker = null;
    if (!_isActive || _isPaused) {
      return;
    }

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _updateDraftState(LifeCounterGameTimerState nextState) {
    setState(() {
      _draftState = nextState;
      _syncTicker();
    });
  }

  @override
  Widget build(BuildContext context) {
    final elapsedSeconds = LifeCounterGameTimerEngine.elapsedSecondsAt(
      _draftState,
      nowEpochMs: _nowEpochMs,
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.space12,
          AppTheme.space12,
          AppTheme.space12,
          AppTheme.space12,
        ),
        child: FractionallySizedBox(
          heightFactor: 0.76,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.backgroundAbyss,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppTheme.outlineMuted),
              boxShadow: const [
                BoxShadow(
                  color: AppTheme.overlayBlack40,
                  blurRadius: 28,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.space20,
                    AppTheme.space18,
                    AppTheme.space20,
                    AppTheme.space8,
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cronômetro da partida',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: AppTheme.fontXxl,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: AppTheme.space6),
                            Text(
                              'Acompanhe a duração da partida e gerencie as pausas na mesa.',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: AppTheme.fontMd,
                                height: AppTheme.lineHeightCompact,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: AppTheme.textSecondary,
                        tooltip: 'Fechar',
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppTheme.outlineMuted),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.space20,
                      AppTheme.space18,
                      AppTheme.space20,
                      AppTheme.space12,
                    ),
                    children: [
                      _SectionCard(
                        title: 'Ações',
                        subtitle: _isActive
                            ? 'Pause, retome ou reinicie o cronômetro quando necessário.'
                            : 'Inicie um novo cronômetro a partir de zero.',
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
                                  _updateDraftState(
                                    LifeCounterGameTimerEngine.start(
                                      nowEpochMs: _nowEpochMs,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: const Text('Iniciar'),
                              ),
                            if (_isActive && !_isPaused)
                              OutlinedButton.icon(
                                key: const Key(
                                  'life-counter-native-game-timer-pause',
                                ),
                                onPressed: () {
                                  _updateDraftState(
                                    LifeCounterGameTimerEngine.pause(
                                      _draftState,
                                      nowEpochMs: _nowEpochMs,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.pause_rounded),
                                label: const Text('Pausar'),
                              ),
                            if (_isActive && _isPaused)
                              FilledButton.icon(
                                key: const Key(
                                  'life-counter-native-game-timer-resume',
                                ),
                                onPressed: () {
                                  _updateDraftState(
                                    LifeCounterGameTimerEngine.resume(
                                      _draftState,
                                      nowEpochMs: _nowEpochMs,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: const Text('Retomar'),
                              ),
                            if (_isActive)
                              OutlinedButton.icon(
                                key: const Key(
                                  'life-counter-native-game-timer-reset',
                                ),
                                onPressed: () {
                                  _updateDraftState(
                                    LifeCounterGameTimerEngine.reset(),
                                  );
                                },
                                icon: const Icon(Icons.restart_alt_rounded),
                                label: const Text('Reiniciar'),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.space18),
                      _SectionCard(
                        title: 'Cronômetro',
                        subtitle:
                            'Confira o tempo decorrido e o estado do cronômetro.',
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _SummaryChip(
                              label: 'Status',
                              value: !_isActive
                                  ? 'Inativo'
                                  : (_isPaused ? 'Pausado' : 'Em andamento'),
                            ),
                            _SummaryChip(
                              label: 'Tempo decorrido',
                              value: _formatDuration(elapsedSeconds),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppTheme.outlineMuted),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.space20,
                    AppTheme.space14,
                    AppTheme.space20,
                    AppTheme.space18,
                  ),
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
                            padding: const EdgeInsets.symmetric(
                              vertical: AppTheme.space14,
                            ),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: AppTheme.space12),
                      Expanded(
                        child: FilledButton(
                          key: const Key(
                            'life-counter-native-game-timer-apply',
                          ),
                          onPressed: () =>
                              Navigator.of(context).pop(_draftState),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.brass500,
                            foregroundColor: AppTheme.backgroundAbyss,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppTheme.space14,
                            ),
                          ),
                          child: const Text('Aplicar'),
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

    final paddedMinutes = hours > 0
        ? minutes.toString().padLeft(2, '0')
        : minutes.toString();
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space12,
          vertical: AppTheme.space10,
        ),
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
            const SizedBox(height: AppTheme.space4),
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
        padding: const EdgeInsets.fromLTRB(
          AppTheme.space14,
          AppTheme.space14,
          AppTheme.space14,
          AppTheme.space14,
        ),
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
            const SizedBox(height: AppTheme.space8),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: AppTheme.fontSm,
                height: AppTheme.lineHeightCompact,
              ),
            ),
            const SizedBox(height: AppTheme.space14),
            child,
          ],
        ),
      ),
    );
  }
}
