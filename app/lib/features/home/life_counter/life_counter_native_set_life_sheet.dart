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
    backgroundColor: AppTheme.transparent,
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
    final previewSession = LifeCounterTabletopEngine.setLifeTotal(
      _draftSession,
      playerIndex: _targetPlayerIndex,
      life: int.tryParse(displayValue) ?? 0,
    );
    final playerStatusSummary = LifeCounterTabletopEngine.playerBoardSummary(
      previewSession,
      playerIndex: _targetPlayerIndex,
    ).statusSummary;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.space12,
          AppTheme.space12,
          AppTheme.space12,
          AppTheme.space12,
        ),
        child: FractionallySizedBox(
          heightFactor: 0.84,
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Definir vida',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: AppTheme.fontXxl,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: AppTheme.space6),
                            Text(
                              'Informe o novo total de vida do Jogador ${_targetPlayerIndex + 1}.',
                              style: const TextStyle(
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.space20,
                    AppTheme.space16,
                    AppTheme.space20,
                    AppTheme.space14,
                  ),
                  child: Column(
                    children: [
                      Center(
                        child: Text(
                          'JOGADOR ${_targetPlayerIndex + 1}',
                          style: TextStyle(
                            color: AppTheme.textSecondary.withValues(
                              alpha: 0.76,
                            ),
                            fontSize: AppTheme.fontSm,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.space8),
                      DecoratedBox(
                        key: const Key('life-counter-native-set-life-display'),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusLg,
                          ),
                          border: Border.all(
                            color: AppTheme.mythicGold.withValues(alpha: 0.32),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.surfaceElevated,
                              AppTheme.backgroundAbyss.withValues(alpha: 0.96),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.mythicGold.withValues(
                                alpha: 0.12,
                              ),
                              blurRadius: 22,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: SizedBox(
                          height: 94,
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.space18,
                                ),
                                child: Text(
                                  displayValue,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize:
                                        AppTheme.fontLifeCounterInputValue,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0,
                                    height: AppTheme.space1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.space20,
                      AppTheme.space0,
                      AppTheme.space20,
                      AppTheme.space12,
                    ),
                    children: [
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
                      const SizedBox(height: AppTheme.space14),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                          border: Border.all(color: AppTheme.outlineMuted),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.space14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Prévia do status',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: AppTheme.fontLg,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: AppTheme.space8),
                              Text(
                                playerStatusSummary.label,
                                key: const Key(
                                  'life-counter-native-set-life-status-label',
                                ),
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: AppTheme.fontLg,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: AppTheme.space6),
                              Text(
                                playerStatusSummary.description,
                                key: const Key(
                                  'life-counter-native-set-life-status-description',
                                ),
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: AppTheme.fontSm,
                                  height: AppTheme.lineHeightCompact,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.space14),
                      SizedBox(
                        width: 250,
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          runSpacing: 12,
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
                              label: 'DEL',
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
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.space20,
                    AppTheme.space14,
                    AppTheme.space20,
                    AppTheme.space18,
                  ),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        key: const Key('life-counter-native-set-life-apply'),
                        onPressed: _apply,
                        icon: const Icon(Icons.favorite_rounded),
                        label: const Text('Definir vida'),
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
        foregroundColor: label.startsWith('-')
            ? AppTheme.lifeCounterSetLifeDanger
            : AppTheme.textPrimary,
        side: BorderSide(
          color: label.startsWith('-')
              ? AppTheme.lifeCounterPinkSoft
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
    final semanticLabel = destructive
        ? 'Limpar valor'
        : label == 'DEL'
        ? 'Apagar último dígito'
        : 'Adicionar dígito $label';
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Tooltip(
        message: semanticLabel,
        child: SizedBox(
          width: 64,
          height: 64,
          child: FilledButton.tonal(
            key: buttonKey,
            onPressed: onTap,
            style: FilledButton.styleFrom(
              minimumSize: Size.zero,
              padding: EdgeInsets.zero,
              backgroundColor: destructive
                  ? AppTheme.lifeCounterPinkSubtle
                  : AppTheme.surfaceElevated,
              foregroundColor: destructive
                  ? AppTheme.lifeCounterPinkText
                  : AppTheme.textPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                side: BorderSide(
                  color: destructive
                      ? AppTheme.lifeCounterPinkSoft
                      : AppTheme.outlineMuted,
                ),
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                softWrap: false,
                style: TextStyle(
                  fontSize: label == 'DEL' ? AppTheme.fontXs : AppTheme.fontXxl,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
