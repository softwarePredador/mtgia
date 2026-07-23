import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'life_counter_session.dart';
import 'life_counter_tabletop_engine.dart';
import 'life_counter_turn_tracker_engine.dart';

Future<LifeCounterSession?> showLifeCounterNativeTurnTrackerSheet(
  BuildContext context, {
  required LifeCounterSession initialSession,
}) {
  return showModalBottomSheet<LifeCounterSession>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.transparent,
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
    _draftSession =
        LifeCounterTurnTrackerEngine.sanitizeTrackerPointersForActivePlayers(
          widget.initialSession,
        );
    _startingPlayerIndex =
        _draftSession.firstPlayerIndex ??
        LifeCounterTabletopEngine.firstActivePlayerIndex(_draftSession);
    _autoHighRoll = _draftSession.turnTrackerAutoHighRoll;
    _turnTimerActive = _draftSession.turnTimerActive;
  }

  bool get _isTrackerActive => _draftSession.turnTrackerActive;
  bool get _hasAnyActivePlayers =>
      LifeCounterTabletopEngine.hasAnyActivePlayers(_draftSession);

  @override
  Widget build(BuildContext context) {
    final currentPlayerLabel = _draftSession.currentTurnPlayerIndex != null
        ? _playerLabel(_draftSession.currentTurnPlayerIndex!)
        : 'Nenhum jogador ativo';
    final startingPlayerLabel = _hasAnyActivePlayers
        ? _playerLabel(_startingPlayerIndex)
        : 'Nenhum jogador ativo';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.space12,
          AppTheme.space12,
          AppTheme.space12,
          AppTheme.space12,
        ),
        child: FractionallySizedBox(
          heightFactor: 0.78,
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
                              'Controle de turnos',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: AppTheme.fontXxl,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: AppTheme.space6),
                            Text(
                              'Escolha quem começa e acompanhe a ordem dos turnos.',
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
                      _SummaryCard(
                        isTrackerActive: _isTrackerActive,
                        currentTurn: _draftSession.currentTurnNumber,
                        currentPlayerLabel: currentPlayerLabel,
                        startingPlayerLabel: startingPlayerLabel,
                        turnTimerActive: _turnTimerActive,
                        turnTimerSeconds: _draftSession.turnTimerSeconds,
                      ),
                      const SizedBox(height: AppTheme.space18),
                      _SectionCard(
                        title: 'Jogador inicial',
                        subtitle:
                            'Escolha quem começa. Jogadores eliminados ficam indisponíveis.',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List<Widget>.generate(_draftSession.playerCount, (
                            index,
                          ) {
                            final isAlive =
                                LifeCounterTabletopEngine.isPlayerActiveOnTable(
                                  _draftSession,
                                  playerIndex: index,
                                );
                            return ChoiceChip(
                              key: Key(
                                'life-counter-native-turn-tracker-player-$index',
                              ),
                              label: Text(_playerLabel(index)),
                              selected: _startingPlayerIndex == index,
                              onSelected: isAlive
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
                      const SizedBox(height: AppTheme.space18),
                      _SectionCard(
                        title: 'Opções do controle',
                        subtitle:
                            'Defina como os turnos começam e aparecem na mesa.',
                        child: Column(
                          children: [
                            SwitchListTile.adaptive(
                              key: const Key(
                                'life-counter-native-turn-tracker-auto-high-roll',
                              ),
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                'Maior rolagem automática',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: const Text(
                                'Role automaticamente para escolher quem começa.',
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
                              key: const Key(
                                'life-counter-native-turn-tracker-turn-timer',
                              ),
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                'Cronômetro do turno',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: const Text(
                                'Mostre o cronômetro de cada turno na mesa.',
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
                      const SizedBox(height: AppTheme.space18),
                      _SectionCard(
                        title: 'Ações',
                        subtitle: _isTrackerActive
                            ? 'Avance ou volte turnos, ou encerre o controle.'
                            : 'Inicie o controle a partir do jogador selecionado.',
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            if (!_isTrackerActive)
                              FilledButton.icon(
                                key: const Key(
                                  'life-counter-native-turn-tracker-start',
                                ),
                                onPressed: _hasAnyActivePlayers
                                    ? () {
                                        setState(() {
                                          _draftSession =
                                              LifeCounterTurnTrackerEngine.startGame(
                                                _draftSession,
                                                startingPlayerIndex:
                                                    _startingPlayerIndex,
                                                autoHighRoll: _autoHighRoll,
                                                turnTimerActive:
                                                    _turnTimerActive,
                                              );
                                        });
                                      }
                                    : null,
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: const Text('Iniciar partida'),
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
                                label: const Text('Voltar'),
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
                                label: const Text('Avançar'),
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
                                label: const Text('Encerrar'),
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

  String _playerLabel(int index) => 'Jogador ${index + 1}';
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
      title: 'Estado do turno',
      subtitle: isTrackerActive
          ? 'Confira o turno atual antes de aplicar as mudanças.'
          : 'O controle de turnos está parado.',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _SummaryChip(
            label: 'Status',
            value: isTrackerActive ? 'Ativo' : 'Inativo',
          ),
          _SummaryChip(label: 'Turno', value: '$currentTurn'),
          _SummaryChip(label: 'Atual', value: currentPlayerLabel),
          _SummaryChip(label: 'Começa', value: startingPlayerLabel),
          _SummaryChip(
            label: 'Cronômetro',
            value: turnTimerActive
                ? _formatDuration(turnTimerSeconds)
                : 'Desligado',
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
    return Material(
      color: AppTheme.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: const BorderSide(color: AppTheme.outlineMuted),
      ),
      clipBehavior: Clip.antiAlias,
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
