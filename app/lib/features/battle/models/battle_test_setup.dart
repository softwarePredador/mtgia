enum BattleTestObjective {
  general('general', 'Plano geral'),
  commander('commander', 'Comandante'),
  manaCurve('mana_curve', 'Mana e curva'),
  interaction('interaction', 'Interação'),
  combo('combo', 'Combo'),
  focusCards('focus_cards', 'Cartas de foco');

  const BattleTestObjective(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

enum BattleSeriesSize {
  single(1, '1 tentativa'),
  three(3, 'Série de 3'),
  five(5, 'Série de 5'),
  ten(10, 'Série de 10');

  const BattleSeriesSize(this.count, this.label);

  final int count;
  final String label;

  bool get isSeries => count > 1;
}

enum BattleTestLaunchMode { automatic, interactive }

class BattleTestSetup {
  BattleTestSetup({
    required this.opponentDeckId,
    this.objective = BattleTestObjective.general,
    this.seriesSize = BattleSeriesSize.single,
    this.launchMode = BattleTestLaunchMode.automatic,
    List<String> focusCards = const <String>[],
  }) : focusCards = _normalizeFocusCards(focusCards);

  final String opponentDeckId;
  final BattleTestObjective objective;
  final BattleSeriesSize seriesSize;
  final BattleTestLaunchMode launchMode;
  final List<String> focusCards;

  /// Only the single-attempt engine contract is serialized here. A series is
  /// coordinated by the client as independent canonical jobs, each with its
  /// own seed and idempotency key.
  Map<String, dynamic> toRequestJson() => {
    'opponent_deck_id': opponentDeckId.trim(),
    'test_objective': objective.apiValue,
    if (focusCards.isNotEmpty) 'focus_cards': focusCards,
  };
}

class BattlePreflight {
  const BattlePreflight({
    required this.status,
    required this.cardCount,
    required this.commanderCount,
    required this.validationState,
    required this.availableOpponentCount,
    required this.engineCoverage,
    required this.blockers,
    this.unsupportedCardNames = const <String>[],
    this.mode = 'simulation',
    this.selectedEngine,
    this.deckSnapshotHash,
    this.deckRevision,
  });

  final String status;
  final int cardCount;
  final int commanderCount;
  final String validationState;
  final int availableOpponentCount;
  final Map<String, String> engineCoverage;
  final List<String> blockers;
  final List<String> unsupportedCardNames;
  final String mode;
  final String? selectedEngine;
  final String? deckSnapshotHash;
  final String? deckRevision;

  bool get canStart => status == 'ready' && blockers.isEmpty;
  bool get canStartInteractive =>
      canStart && mode == 'interactive' && selectedEngine == 'xmage';

  factory BattlePreflight.fromJson(
    Map<String, dynamic> json, {
    String requestedMode = 'simulation',
  }) {
    final coverage = json['engine_coverage'];
    final blockerValues = json['blockers'];
    final unsupportedValues = json['unsupported_cards'];
    return BattlePreflight(
      status: _optionalText(json['status']) ?? 'unknown',
      cardCount: _readInt(json['card_count']) ?? 0,
      commanderCount: _readInt(json['commander_count']) ?? 0,
      validationState: _optionalText(json['validation_state']) ?? 'unknown',
      availableOpponentCount: _readInt(json['available_opponent_count']) ?? 0,
      engineCoverage: coverage is Map
          ? coverage.map(
              (key, value) =>
                  MapEntry(key.toString(), _optionalText(value) ?? 'unknown'),
            )
          : const <String, String>{},
      blockers: blockerValues is List
          ? blockerValues
                .map(_optionalText)
                .whereType<String>()
                .toList(growable: false)
          : const <String>[],
      unsupportedCardNames: _unsupportedCardNames(unsupportedValues),
      mode: _optionalText(json['mode']) ?? requestedMode,
      selectedEngine: _optionalText(json['selected_engine']),
      deckSnapshotHash: _optionalText(json['deck_snapshot_hash']),
      deckRevision: _optionalText(json['deck_revision']),
    );
  }
}

List<String> _unsupportedCardNames(Object? values) {
  if (values is! List) return const <String>[];
  final names = <String>[];
  final seen = <String>{};
  for (final value in values) {
    if (value is! Map) continue;
    final name = _optionalText(value['name']);
    if (name == null || !seen.add(name.toLowerCase())) continue;
    names.add(name);
  }
  return List<String>.unmodifiable(names);
}

List<String> _normalizeFocusCards(List<String> values) {
  final normalized = <String>[];
  final seen = <String>{};
  for (final value in values) {
    final card = value.trim();
    if (card.isEmpty) continue;
    final key = card.toLowerCase();
    if (!seen.add(key)) continue;
    normalized.add(card);
    if (normalized.length == 3) break;
  }
  return List<String>.unmodifiable(normalized);
}

String? _optionalText(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

int? _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
