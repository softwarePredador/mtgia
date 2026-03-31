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

  int get _currentValue =>
      LifeCounterTabletopEngine.readCounterValue(
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
        _customCounterError = 'Enter a custom counter name to continue.';
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
    final playerLabel = 'Player ${_targetPlayerIndex + 1}';
    final isCustomCounter =
        !LifeCounterTabletopEngine.isKnownCounterKey(_selectedCounterKey);

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
                    child: ListView(
                      children: [
                        Text(
                          _counterDescription(_selectedCounterKey),
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: AppTheme.fontMd,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Available counters',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: AppTheme.fontLg,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Add custom counter',
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: AppTheme.fontLg,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Create custom counters here so this flow no longer depends on Lotus-only chips.',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: AppTheme.fontSm,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 14),
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
                                          labelText: 'Custom counter name',
                                          errorText: _customCounterError,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    FilledButton.tonal(
                                      key: const Key(
                                        'life-counter-native-player-counter-custom-add',
                                      ),
                                      onPressed: _addCustomCounter,
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 18,
                                        ),
                                      ),
                                      child: const Text('Add'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
                        if (isCustomCounter) ...[
                          const SizedBox(height: 14),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              key: const Key(
                                'life-counter-native-player-counter-custom-remove',
                              ),
                              onPressed: _removeSelectedCustomCounter,
                              icon: const Icon(Icons.delete_outline_rounded),
                              label: const Text('Remove custom counter'),
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
                              () => Navigator.of(context).pop(_draftSession),
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

String _resolveFallbackCounterKey(
  LifeCounterSession session,
  int playerIndex,
) {
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

  final extraKeys = session.resolvedPlayerExtraCounters[playerIndex].keys.toList()
    ..sort();
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
      return 'Adjust or remove this player-specific counter while the Lotus tabletop remains visually identical.';
  }
}
