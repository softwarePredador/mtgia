import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'life_counter_session.dart';
import 'life_counter_tabletop_engine.dart';

Future<LifeCounterSession?> showLifeCounterNativePlayerCounterSheet(
  BuildContext context, {
  required LifeCounterSession initialSession,
  required int initialTargetPlayerIndex,
  required String counterKey,
}) {
  return showModalBottomSheet<LifeCounterSession>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.transparent,
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
  late final TextEditingController _customCounterNameController;
  late LifeCounterSession _draftSession;
  late String _selectedCounterKey;
  String? _customCounterError;

  @override
  void initState() {
    super.initState();
    _targetPlayerIndex = widget.initialTargetPlayerIndex.clamp(
      0,
      widget.initialSession.playerCount - 1,
    );
    _draftSession = widget.initialSession;
    _selectedCounterKey = _resolveInitialCounterKey(
      widget.counterKey,
      _draftSession,
      _targetPlayerIndex,
    );
    _customCounterNameController = TextEditingController();
  }

  @override
  void dispose() {
    _customCounterNameController.dispose();
    super.dispose();
  }

  int get _currentValue => LifeCounterTabletopEngine.readCounterValue(
    _draftSession,
    playerIndex: _targetPlayerIndex,
    counterKey: _selectedCounterKey,
  );

  int get _step => _isTaxCounter(_selectedCounterKey) ? 2 : 1;

  List<String> get _availableCounterKeys => _buildAvailableCounterKeys(
    _draftSession,
    _targetPlayerIndex,
    selectedCounterKey: _selectedCounterKey,
  );

  void _changeValue(int delta) {
    setState(() {
      final nextValue = (_currentValue + delta).clamp(0, 999);
      _draftSession = LifeCounterTabletopEngine.writeCounterValue(
        _draftSession,
        playerIndex: _targetPlayerIndex,
        counterKey: _selectedCounterKey,
        value: nextValue,
      );
    });
  }

  void _selectCounter(String counterKey) {
    setState(() {
      _selectedCounterKey = counterKey;
      _customCounterError = null;
    });
  }

  void _addCustomCounter() {
    final normalizedKey = _normalizeCustomCounterKey(
      _customCounterNameController.text,
    );
    if (normalizedKey == null) {
      setState(() {
        _customCounterError = 'Informe um nome para o marcador personalizado.';
      });
      return;
    }

    setState(() {
      _customCounterError = null;
      _draftSession = LifeCounterTabletopEngine.ensureExtraCounterExists(
        _draftSession,
        playerIndex: _targetPlayerIndex,
        counterKey: normalizedKey,
      );
      _selectedCounterKey = normalizedKey;
      _customCounterNameController.clear();
    });
  }

  void _removeSelectedCustomCounter() {
    if (LifeCounterTabletopEngine.isKnownCounterKey(_selectedCounterKey)) {
      return;
    }

    setState(() {
      _draftSession = LifeCounterTabletopEngine.removeExtraCounter(
        _draftSession,
        playerIndex: _targetPlayerIndex,
        counterKey: _selectedCounterKey,
      );
      _selectedCounterKey = _resolveFallbackCounterKey(
        _draftSession,
        _targetPlayerIndex,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final counterLabel = _counterLabel(_selectedCounterKey);
    final playerLabel = 'Jogador ${_targetPlayerIndex + 1}';
    final isCustomCounter = !LifeCounterTabletopEngine.isKnownCounterKey(
      _selectedCounterKey,
    );
    final playerBoardSummary = LifeCounterTabletopEngine.playerBoardSummary(
      _draftSession,
      playerIndex: _targetPlayerIndex,
    );
    final criticalLabel = playerBoardSummary.criticalCounterLabel(
      _selectedCounterKey,
    );
    final playerStatusSummary = playerBoardSummary.statusSummary;

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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Marcadores do jogador',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: AppTheme.fontXxl,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: AppTheme.space6),
                            Text(
                              '$playerLabel · $counterLabel',
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
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.space20,
                      AppTheme.space20,
                      AppTheme.space20,
                      AppTheme.space20,
                    ),
                    child: ListView(
                      children: [
                        Text(
                          _counterDescription(_selectedCounterKey),
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: AppTheme.fontMd,
                            height: AppTheme.lineHeightComfortable,
                          ),
                        ),
                        const SizedBox(height: AppTheme.space18),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                            border: Border.all(color: AppTheme.outlineMuted),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppTheme.space16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Status atual do jogador',
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
                                    'life-counter-native-player-counter-status-label',
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
                                    'life-counter-native-player-counter-status-description',
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
                        const SizedBox(height: AppTheme.space20),
                        const Text(
                          'Marcadores disponíveis',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: AppTheme.fontLg,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppTheme.space10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _availableCounterKeys
                              .map(
                                (counterKey) => ChoiceChip(
                                  key: Key(
                                    'life-counter-native-player-counter-chip-$counterKey',
                                  ),
                                  label: Text(_counterLabel(counterKey)),
                                  selected: _selectedCounterKey == counterKey,
                                  onSelected: (_) => _selectCounter(counterKey),
                                ),
                              )
                              .toList(growable: false),
                        ),
                        const SizedBox(height: AppTheme.space20),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                            border: Border.all(color: AppTheme.outlineMuted),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppTheme.space16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Adicionar marcador personalizado',
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: AppTheme.fontLg,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.space6),
                                const Text(
                                  'Adicione marcadores para efeitos específicos da partida.',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: AppTheme.fontSm,
                                    height: AppTheme.lineHeightCompact,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.space14),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        key: const Key(
                                          'life-counter-native-player-counter-custom-name',
                                        ),
                                        controller:
                                            _customCounterNameController,
                                        textInputAction: TextInputAction.done,
                                        onSubmitted: (_) => _addCustomCounter(),
                                        decoration: InputDecoration(
                                          labelText: 'Nome do marcador',
                                          errorText: _customCounterError,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppTheme.space12),
                                    FilledButton.tonal(
                                      key: const Key(
                                        'life-counter-native-player-counter-custom-add',
                                      ),
                                      onPressed: _addCustomCounter,
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppTheme.space18,
                                          vertical: AppTheme.space18,
                                        ),
                                      ),
                                      child: const Text('Adicionar'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.space20),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                            border: Border.all(color: AppTheme.outlineMuted),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppTheme.space16),
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
                                if (criticalLabel != null)
                                  Container(
                                    key: const Key(
                                      'life-counter-native-player-counter-critical-badge',
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppTheme.space10,
                                      vertical: AppTheme.space6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.error.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.radiusPill,
                                      ),
                                      border: Border.all(
                                        color: AppTheme.error.withValues(
                                          alpha: 0.35,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      criticalLabel,
                                      style: const TextStyle(
                                        color: AppTheme.error,
                                        fontSize: AppTheme.fontXs,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                IconButton(
                                  key: const Key(
                                    'life-counter-native-player-counter-minus',
                                  ),
                                  tooltip: 'Diminuir valor',
                                  onPressed: () => _changeValue(-_step),
                                  icon: const Icon(
                                    Icons.remove_circle_outline_rounded,
                                  ),
                                  color: AppTheme.textSecondary,
                                ),
                                SizedBox(
                                  width: 56,
                                  child: Text(
                                    '$_currentValue',
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
                                  tooltip: 'Aumentar valor',
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
                        if (_isTaxCounter(_selectedCounterKey)) ...[
                          const SizedBox(height: AppTheme.space14),
                          const Text(
                            'A taxa de comandante aumenta de 2 em 2, como o custo adicional na mesa.',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: AppTheme.fontSm,
                              height: AppTheme.lineHeightCompact,
                            ),
                          ),
                        ],
                        if (isCustomCounter) ...[
                          const SizedBox(height: AppTheme.space14),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              key: const Key(
                                'life-counter-native-player-counter-custom-remove',
                              ),
                              onPressed: _removeSelectedCustomCounter,
                              icon: const Icon(Icons.delete_outline_rounded),
                              label: const Text(
                                'Remover marcador personalizado',
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
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
                            'life-counter-native-player-counter-apply',
                          ),
                          onPressed: () =>
                              Navigator.of(context).pop(_draftSession),
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
}

String _resolveInitialCounterKey(
  String requestedCounterKey,
  LifeCounterSession session,
  int playerIndex,
) {
  final availableKeys = _buildAvailableCounterKeys(
    session,
    playerIndex,
    selectedCounterKey: requestedCounterKey,
  );
  if (availableKeys.contains(requestedCounterKey)) {
    return requestedCounterKey;
  }
  return _resolveFallbackCounterKey(session, playerIndex);
}

String _resolveFallbackCounterKey(LifeCounterSession session, int playerIndex) {
  final keys = _buildAvailableCounterKeys(session, playerIndex);
  return keys.isEmpty ? 'poison' : keys.first;
}

List<String> _buildAvailableCounterKeys(
  LifeCounterSession session,
  int playerIndex, {
  String? selectedCounterKey,
}) {
  final keys = <String>['poison', 'energy', 'xp', 'tax-1'];
  if (session.partnerCommanders[playerIndex]) {
    keys.add('tax-2');
  }

  final extraKeys =
      session.resolvedPlayerExtraCounters[playerIndex].keys.toList()..sort();
  for (final extraKey in extraKeys) {
    if (!keys.contains(extraKey)) {
      keys.add(extraKey);
    }
  }

  if (selectedCounterKey != null && !keys.contains(selectedCounterKey)) {
    keys.add(selectedCounterKey);
  }

  return keys;
}

String? _normalizeCustomCounterKey(String raw) {
  final parts = raw
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) {
    return null;
  }
  return parts.join('-');
}

bool _isTaxCounter(String counterKey) =>
    counterKey == 'tax-1' || counterKey == 'tax-2';

String _counterLabel(String counterKey) {
  switch (counterKey) {
    case 'poison':
      return 'Veneno';
    case 'energy':
      return 'Energia';
    case 'xp':
      return 'Experiência';
    case 'tax-1':
      return 'Taxa de comandante 1';
    case 'tax-2':
      return 'Taxa de comandante 2';
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
      return 'Acompanhe os marcadores de veneno deste jogador.';
    case 'energy':
      return 'Acompanhe os marcadores de energia deste jogador.';
    case 'xp':
      return 'Acompanhe os marcadores de experiência deste jogador.';
    case 'tax-1':
    case 'tax-2':
      return 'A taxa de comandante aumenta em 2 após cada conjuração da zona de comando.';
    default:
      return 'Ajuste ou remova este marcador personalizado.';
  }
}
