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
    backgroundColor: AppTheme.transparent,
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

class _LifeCounterNativeDiceSheetState
    extends State<_LifeCounterNativeDiceSheet> {
  late LifeCounterSession _draftSession;

  Set<int> get _highRollWinners =>
      LifeCounterDiceEngine.deriveHighRollWinners(
        _draftSession.lastHighRolls,
      ).where((playerIndex) {
        return LifeCounterTabletopEngine.isPlayerActiveOnTable(
          _draftSession,
          playerIndex: playerIndex,
        );
      }).toSet();

  bool get _hasPendingTieBreak => _highRollWinners.length > 1;
  bool get _hasAnyActivePlayers =>
      LifeCounterTabletopEngine.hasAnyActivePlayers(_draftSession);

  @override
  void initState() {
    super.initState();
    _draftSession = widget.initialSession;
  }

  void _applyAction(
    LifeCounterSession Function(LifeCounterSession session, {Random? random})
    action,
  ) {
    setState(() {
      _draftSession = action(_draftSession, random: widget.random);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      key: const Key('life-counter-native-dice-sheet'),
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
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ferramentas de dados',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: AppTheme.fontXxl,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Role dados, jogue uma moeda ou escolha quem começa.',
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
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                    children: [
                      _DiceSectionCard(
                        title: 'Ações rápidas',
                        subtitle:
                            !_hasAnyActivePlayers
                                ? 'Não há jogadores ativos na mesa. Ações que escolhem um jogador ficam indisponíveis.'
                                : _hasPendingTieBreak
                                ? 'A maior rolagem terminou empatada. Role novamente apenas para os jogadores empatados.'
                                : 'Escolha uma ação rápida para a mesa.',
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
                                _hasPendingTieBreak
                                    ? 'Desempatar'
                                    : 'Maior rolagem',
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
                              label: const Text('Moeda'),
                            ),
                            OutlinedButton.icon(
                              key: const Key(
                                'life-counter-native-dice-first-player',
                              ),
                              onPressed:
                                  _hasAnyActivePlayers
                                      ? () => _applyAction(
                                        LifeCounterDiceEngine
                                            .runFirstPlayerRoll,
                                      )
                                      : null,
                              icon: const Icon(Icons.flag_rounded),
                              label: const Text('Sortear 1º'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _DiceSectionCard(
                        title: 'Estado atual',
                        subtitle:
                            'Confira o resultado mais recente antes de aplicar.',
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _SummaryChip(
                              label: 'Primeiro jogador',
                              value:
                                  _draftSession.firstPlayerIndex == null
                                      ? 'Não definido'
                                      : 'Jogador ${_draftSession.firstPlayerIndex! + 1}',
                            ),
                            _SummaryChip(
                              label: 'Último evento',
                              value:
                                  _draftSession.lastTableEvent == null
                                      ? 'Nenhum'
                                      : _draftSession.lastTableEvent!,
                            ),
                          ],
                        ),
                      ),
                      if (_draftSession.lastHighRolls
                          .whereType<int>()
                          .isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _DiceSectionCard(
                          title: 'Quadro da maior rolagem',
                          subtitle:
                              _highRollWinners.length == 1
                                  ? 'O jogador vencedor está destacado abaixo.'
                                  : 'Empate detectado. Role novamente apenas para os jogadores empatados.',
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
                                    highlighted: _highRollWinners.contains(
                                      index,
                                    ),
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
                        child: const Text('Cancelar'),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        key: const Key('life-counter-native-dice-apply'),
                        onPressed:
                            () => Navigator.of(context).pop(_draftSession),
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Aplicar'),
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
                height: AppTheme.lineHeightCompact,
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
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
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
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
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
