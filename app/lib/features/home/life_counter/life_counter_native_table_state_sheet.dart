import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'life_counter_session.dart';

Future<LifeCounterSession?> showLifeCounterNativeTableStateSheet(
  BuildContext context, {
  required LifeCounterSession initialSession,
}) {
  return showModalBottomSheet<LifeCounterSession>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return _LifeCounterNativeTableStateSheet(
        initialSession: initialSession,
      );
    },
  );
}

class _LifeCounterNativeTableStateSheet extends StatefulWidget {
  const _LifeCounterNativeTableStateSheet({required this.initialSession});

  final LifeCounterSession initialSession;

  @override
  State<_LifeCounterNativeTableStateSheet> createState() =>
      _LifeCounterNativeTableStateSheetState();
}

class _LifeCounterNativeTableStateSheetState
    extends State<_LifeCounterNativeTableStateSheet> {
  late int _stormCount;
  late int? _monarchPlayer;
  late int? _initiativePlayer;

  @override
  void initState() {
    super.initState();
    _stormCount = widget.initialSession.stormCount.clamp(0, 999);
    _monarchPlayer = widget.initialSession.monarchPlayer;
    _initiativePlayer = widget.initialSession.initiativePlayer;
  }

  void _changeStorm(int delta) {
    setState(() {
      _stormCount = (_stormCount + delta).clamp(0, 999);
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      widget.initialSession.copyWith(
        stormCount: _stormCount,
        monarchPlayer: _monarchPlayer,
        clearMonarchPlayer: _monarchPlayer == null,
        initiativePlayer: _initiativePlayer,
        clearInitiativePlayer: _initiativePlayer == null,
      ),
    );
  }

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
                              'Table State',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: AppTheme.fontXxl,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'ManaLoom owns monarch, initiative and storm without changing the Lotus tabletop layout.',
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
                      _TableStateCard(
                        title: 'Monarch',
                        subtitle:
                            'Choose who currently holds the monarch token, or clear it.',
                        child: _TokenAssignmentSection(
                          keyPrefix: 'life-counter-native-table-state-monarch',
                          selectedPlayer: _monarchPlayer,
                          playerCount: widget.initialSession.playerCount,
                          onPlayerSelected:
                              (playerIndex) =>
                                  setState(() => _monarchPlayer = playerIndex),
                          onCleared:
                              () => setState(() => _monarchPlayer = null),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _TableStateCard(
                        title: 'Initiative',
                        subtitle:
                            'Choose who currently holds the initiative, or clear it.',
                        child: _TokenAssignmentSection(
                          keyPrefix:
                              'life-counter-native-table-state-initiative',
                          selectedPlayer: _initiativePlayer,
                          playerCount: widget.initialSession.playerCount,
                          onPlayerSelected:
                              (playerIndex) => setState(
                                () => _initiativePlayer = playerIndex,
                              ),
                          onCleared:
                              () => setState(() => _initiativePlayer = null),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _TableStateCard(
                        title: 'Storm',
                        subtitle:
                            'Track the current storm count in our canonical runtime state.',
                        child: Row(
                          children: [
                            _StormButton(
                              buttonKey: const Key(
                                'life-counter-native-table-state-storm-minus',
                              ),
                              icon: Icons.remove_rounded,
                              onPressed: () => _changeStorm(-1),
                            ),
                            Expanded(
                              child: Center(
                                child: Column(
                                  children: [
                                    const Text(
                                      'Storm Count',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: AppTheme.fontSm,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '$_stormCount',
                                      key: const Key(
                                        'life-counter-native-table-state-storm-value',
                                      ),
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 42,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            _StormButton(
                              buttonKey: const Key(
                                'life-counter-native-table-state-storm-plus',
                              ),
                              icon: Icons.add_rounded,
                              onPressed: () => _changeStorm(1),
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
                            'life-counter-native-table-state-apply',
                          ),
                          onPressed: _apply,
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

class _TableStateCard extends StatelessWidget {
  const _TableStateCard({
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

class _TokenAssignmentSection extends StatelessWidget {
  const _TokenAssignmentSection({
    required this.keyPrefix,
    required this.selectedPlayer,
    required this.playerCount,
    required this.onPlayerSelected,
    required this.onCleared,
  });

  final String keyPrefix;
  final int? selectedPlayer;
  final int playerCount;
  final ValueChanged<int> onPlayerSelected;
  final VoidCallback onCleared;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List<Widget>.generate(
            playerCount,
            (index) => ChoiceChip(
              key: Key('$keyPrefix-player-$index'),
              label: Text('Player ${index + 1}'),
              selected: selectedPlayer == index,
              onSelected: (_) => onPlayerSelected(index),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          key: Key('$keyPrefix-clear'),
          onPressed: onCleared,
          icon: const Icon(Icons.remove_circle_outline_rounded),
          label: const Text('Clear'),
        ),
      ],
    );
  }
}

class _StormButton extends StatelessWidget {
  const _StormButton({
    required this.buttonKey,
    required this.icon,
    required this.onPressed,
  });

  final Key buttonKey;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: FilledButton.tonal(
        key: buttonKey,
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.surfaceElevated,
          foregroundColor: AppTheme.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppTheme.outlineMuted),
          ),
        ),
        child: Icon(icon),
      ),
    );
  }
}
