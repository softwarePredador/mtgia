import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'life_counter_session.dart';
import 'life_counter_tabletop_engine.dart';

Future<LifeCounterSession?> showLifeCounterNativeSetLifeSheet(
  BuildContext context, {
  required LifeCounterSession initialSession,
  required int initialTargetPlayerIndex,
}) {
  return showModalBottomSheet<LifeCounterSession>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return _LifeCounterNativeSetLifeSheet(
        initialSession: initialSession,
        initialTargetPlayerIndex: initialTargetPlayerIndex,
      );
    },
  );
}

class _LifeCounterNativeSetLifeSheet extends StatefulWidget {
  const _LifeCounterNativeSetLifeSheet({
    required this.initialSession,
    required this.initialTargetPlayerIndex,
  });

  final LifeCounterSession initialSession;
  final int initialTargetPlayerIndex;

  @override
  State<_LifeCounterNativeSetLifeSheet> createState() =>
      _LifeCounterNativeSetLifeSheetState();
}

class _LifeCounterNativeSetLifeSheetState
    extends State<_LifeCounterNativeSetLifeSheet> {
  late final int _targetPlayerIndex;
  late LifeCounterSession _draftSession;
  late String _buffer;

  @override
  void initState() {
    super.initState();
    _draftSession = widget.initialSession;
    _targetPlayerIndex = widget.initialTargetPlayerIndex.clamp(
      0,
      widget.initialSession.playerCount - 1,
    );
    _buffer = _draftSession.lives[_targetPlayerIndex].toString();
  }

  void _appendDigit(String digit) {
    setState(() {
      if (_buffer == '0') {
        _buffer = digit;
      } else if (_buffer.length < 3) {
        _buffer += digit;
      }
    });
  }

  void _clear() {
    setState(() {
      _buffer = '0';
    });
  }

  void _backspace() {
    setState(() {
      if (_buffer.length <= 1) {
        _buffer = '0';
      } else {
        _buffer = _buffer.substring(0, _buffer.length - 1);
      }
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      LifeCounterTabletopEngine.setLifeTotal(
        _draftSession,
        playerIndex: _targetPlayerIndex,
        life: int.tryParse(_buffer) ?? 0,
      ),
    );
  }

  void _applyQuickDelta(int delta) {
    setState(() {
      _draftSession = LifeCounterTabletopEngine.adjustLifeTotal(
        _draftSession,
        playerIndex: _targetPlayerIndex,
        delta: delta,
      );
      _buffer = _draftSession.lives[_targetPlayerIndex].toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayValue = _buffer.isEmpty ? '0' : _buffer;

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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Set Life',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: AppTheme.fontXxl,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Update Player ${_targetPlayerIndex + 1} directly from the ManaLoom-owned shell.',
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
                      Center(
                        child: Text(
                          'PLAYER ${_targetPlayerIndex + 1}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.28),
                            fontSize: AppTheme.fontSm,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        key: const Key('life-counter-native-set-life-display'),
                        height: 72,
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              displayValue,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 72,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -3,
                                height: 0.9,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _SetLifeQuickAdjustButton(
                            buttonKey: const Key(
                              'life-counter-native-set-life-adjust-minus-10',
                            ),
                            label: '-10',
                            onTap: () => _applyQuickDelta(-10),
                          ),
                          _SetLifeQuickAdjustButton(
                            buttonKey: const Key(
                              'life-counter-native-set-life-adjust-minus-5',
                            ),
                            label: '-5',
                            onTap: () => _applyQuickDelta(-5),
                          ),
                          _SetLifeQuickAdjustButton(
                            buttonKey: const Key(
                              'life-counter-native-set-life-adjust-plus-5',
                            ),
                            label: '+5',
                            onTap: () => _applyQuickDelta(5),
                          ),
                          _SetLifeQuickAdjustButton(
                            buttonKey: const Key(
                              'life-counter-native-set-life-adjust-plus-10',
                            ),
                            label: '+10',
                            onTap: () => _applyQuickDelta(10),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 250,
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 14,
                          runSpacing: 14,
                          children: [
                            for (final digit in const [
                              '1',
                              '2',
                              '3',
                              '4',
                              '5',
                              '6',
                              '7',
                              '8',
                              '9',
                            ])
                              _SetLifeKeypadButton(
                                buttonKey: Key(
                                  'life-counter-native-set-life-digit-$digit',
                                ),
                                label: digit,
                                onTap: () => _appendDigit(digit),
                              ),
                            _SetLifeKeypadButton(
                              buttonKey: const Key(
                                'life-counter-native-set-life-clear',
                              ),
                              label: 'C',
                              onTap: _clear,
                              destructive: true,
                            ),
                            _SetLifeKeypadButton(
                              buttonKey: const Key(
                                'life-counter-native-set-life-digit-0',
                              ),
                              label: '0',
                              onTap: () => _appendDigit('0'),
                            ),
                            _SetLifeKeypadButton(
                              buttonKey: const Key(
                                'life-counter-native-set-life-backspace',
                              ),
                              label: '<',
                              onTap: _backspace,
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
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        key: const Key('life-counter-native-set-life-apply'),
                        onPressed: _apply,
                        icon: const Icon(Icons.favorite_rounded),
                        label: const Text('Set Life'),
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

class _SetLifeQuickAdjustButton extends StatelessWidget {
  const _SetLifeQuickAdjustButton({
    required this.buttonKey,
    required this.label,
    required this.onTap,
  });

  final Key buttonKey;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      key: buttonKey,
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor:
            label.startsWith('-')
                ? const Color(0xFFFF7A9C)
                : AppTheme.textPrimary,
        side: BorderSide(
          color:
              label.startsWith('-')
                  ? const Color(0x66FF2C77)
                  : AppTheme.outlineMuted,
        ),
      ),
      child: Text(label),
    );
  }
}

class _SetLifeKeypadButton extends StatelessWidget {
  const _SetLifeKeypadButton({
    required this.buttonKey,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final Key buttonKey;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      height: 70,
      child: FilledButton.tonal(
        key: buttonKey,
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor:
              destructive
                  ? const Color(0x33FF2C77)
                  : AppTheme.surfaceElevated,
          foregroundColor:
              destructive ? const Color(0xFFFF5E9A) : AppTheme.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color:
                  destructive
                      ? const Color(0x66FF2C77)
                      : AppTheme.outlineMuted,
            ),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: AppTheme.fontXxl,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
