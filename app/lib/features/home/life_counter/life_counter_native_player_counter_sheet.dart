import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'life_counter_session.dart';

Future<LifeCounterSession?> showLifeCounterNativePlayerCounterSheet(
  BuildContext context, {
  required LifeCounterSession initialSession,
  required int initialTargetPlayerIndex,
  required String counterKey,
}) {
  return showModalBottomSheet<LifeCounterSession>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return _LifeCounterNativePlayerCounterSheet(
        initialSession: initialSession,
        initialTargetPlayerIndex: initialTargetPlayerIndex,
        counterKey: counterKey,
      );
    },
  );
}

class _LifeCounterNativePlayerCounterSheet extends StatefulWidget {
  const _LifeCounterNativePlayerCounterSheet({
    required this.initialSession,
    required this.initialTargetPlayerIndex,
    required this.counterKey,
  });

  final LifeCounterSession initialSession;
  final int initialTargetPlayerIndex;
  final String counterKey;

  @override
  State<_LifeCounterNativePlayerCounterSheet> createState() =>
      _LifeCounterNativePlayerCounterSheetState();
}

class _LifeCounterNativePlayerCounterSheetState
    extends State<_LifeCounterNativePlayerCounterSheet> {
  late final int _targetPlayerIndex;
  late int _value;

  @override
  void initState() {
    super.initState();
    _targetPlayerIndex = widget.initialTargetPlayerIndex.clamp(
      0,
      widget.initialSession.playerCount - 1,
    );
    _value = _readCounterValue(
      widget.initialSession,
      _targetPlayerIndex,
      widget.counterKey,
    );
  }

  int get _step => _isTaxCounter(widget.counterKey) ? 2 : 1;

  void _changeValue(int delta) {
    setState(() {
      _value = (_value + delta).clamp(0, 999);
    });
  }

  LifeCounterSession _buildUpdatedSession() {
    return _writeCounterValue(
      widget.initialSession,
      playerIndex: _targetPlayerIndex,
      counterKey: widget.counterKey,
      value: _value,
    );
  }

  @override
  Widget build(BuildContext context) {
    final counterLabel = _counterLabel(widget.counterKey);
    final playerLabel = 'Player ${_targetPlayerIndex + 1}';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: FractionallySizedBox(
          heightFactor: 0.6,
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
                              'Player Counter',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: AppTheme.fontXxl,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$playerLabel · $counterLabel',
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
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _counterDescription(widget.counterKey),
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: AppTheme.fontMd,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                            border: Border.all(color: AppTheme.outlineMuted),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    counterLabel,
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: AppTheme.fontLg,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  key: const Key(
                                    'life-counter-native-player-counter-minus',
                                  ),
                                  onPressed: () => _changeValue(-_step),
                                  icon: const Icon(
                                    Icons.remove_circle_outline_rounded,
                                  ),
                                  color: AppTheme.textSecondary,
                                ),
                                SizedBox(
                                  width: 56,
                                  child: Text(
                                    '$_value',
                                    key: const Key(
                                      'life-counter-native-player-counter-value',
                                    ),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: AppTheme.fontXxl,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  key: const Key(
                                    'life-counter-native-player-counter-plus',
                                  ),
                                  onPressed: () => _changeValue(_step),
                                  icon: const Icon(
                                    Icons.add_circle_outline_rounded,
                                  ),
                                  color: AppTheme.textPrimary,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_isTaxCounter(widget.counterKey)) ...[
                          const SizedBox(height: 14),
                          const Text(
                            'Commander tax moves in steps of 2 to match the tabletop mana tax.',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: AppTheme.fontSm,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ],
                    ),
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
                            'life-counter-native-player-counter-apply',
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

int _readCounterValue(
  LifeCounterSession session,
  int playerIndex,
  String counterKey,
) {
  switch (counterKey) {
    case 'poison':
      return session.poison[playerIndex];
    case 'energy':
      return session.energy[playerIndex];
    case 'xp':
      return session.experience[playerIndex];
    case 'tax-1':
      return session
              .resolvedCommanderCastDetails[playerIndex]
              .commanderOneCasts *
          2;
    case 'tax-2':
      return session
              .resolvedCommanderCastDetails[playerIndex]
              .commanderTwoCasts *
          2;
    default:
      return session.resolvedPlayerExtraCounters[playerIndex][counterKey] ?? 0;
  }
}

LifeCounterSession _writeCounterValue(
  LifeCounterSession session, {
  required int playerIndex,
  required String counterKey,
  required int value,
}) {
  switch (counterKey) {
    case 'poison':
      final poison = List<int>.from(session.poison);
      poison[playerIndex] = value;
      return session.copyWith(poison: poison);
    case 'energy':
      final energy = List<int>.from(session.energy);
      energy[playerIndex] = value;
      return session.copyWith(energy: energy);
    case 'xp':
      final experience = List<int>.from(session.experience);
      experience[playerIndex] = value;
      return session.copyWith(experience: experience);
    case 'tax-1':
    case 'tax-2':
      final details = List<LifeCounterCommanderCastDetail>.from(
        session.resolvedCommanderCastDetails,
      );
      final current = details[playerIndex];
      final casts = (value ~/ 2).clamp(0, 999);
      details[playerIndex] =
          counterKey == 'tax-1'
              ? LifeCounterCommanderCastDetail(
                commanderOneCasts: casts,
                commanderTwoCasts: current.commanderTwoCasts,
              )
              : LifeCounterCommanderCastDetail(
                commanderOneCasts: current.commanderOneCasts,
                commanderTwoCasts: casts,
              );
      final commanderCasts = details
          .map((entry) => entry.totalCasts)
          .toList(growable: false);
      return session.copyWith(
        commanderCasts: commanderCasts,
        commanderCastDetails: details,
      );
    default:
      final extraCounters = session.resolvedPlayerExtraCounters
          .map((entry) => <String, int>{...entry})
          .toList(growable: false);
      if (value <= 0) {
        extraCounters[playerIndex].remove(counterKey);
      } else {
        extraCounters[playerIndex][counterKey] = value;
      }
      return session.copyWith(playerExtraCounters: extraCounters);
  }
}

bool _isTaxCounter(String counterKey) =>
    counterKey == 'tax-1' || counterKey == 'tax-2';

String _counterLabel(String counterKey) {
  switch (counterKey) {
    case 'poison':
      return 'Poison';
    case 'energy':
      return 'Energy';
    case 'xp':
      return 'Experience';
    case 'tax-1':
      return 'Commander Tax 1';
    case 'tax-2':
      return 'Commander Tax 2';
    case 'rad':
      return 'Rad';
    default:
      return counterKey
          .replaceAll('-', ' ')
          .split(' ')
          .where((part) => part.isNotEmpty)
          .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
          .join(' ');
  }
}

String _counterDescription(String counterKey) {
  switch (counterKey) {
    case 'poison':
      return 'Adjust poison counters without leaving the ManaLoom-owned shell.';
    case 'energy':
      return 'Adjust energy counters while keeping the tabletop layout intact.';
    case 'xp':
      return 'Adjust experience counters from the same player card flow.';
    case 'tax-1':
    case 'tax-2':
      return 'Commander tax stays mapped to the partner-specific commander cast count.';
    default:
      return 'Adjust this player-specific counter while the Lotus tabletop remains visually identical.';
  }
}
