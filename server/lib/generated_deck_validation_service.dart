import 'package:postgres/postgres.dart';

import 'ai/cmc_safety.dart';
import 'basic_land_utils.dart' as basic_lands;
import 'card_validation_service.dart';
import 'color_identity.dart';
import 'deck_rules_service.dart';
import 'import_card_lookup_service.dart';

abstract class GeneratedDeckRepository {
  Future<Map<String, Map<String, dynamic>>> resolveCardNames(
    List<Map<String, dynamic>> parsedItems,
  );

  Future<Map<String, List<String>>> findSuggestions(List<String> names);

  Future<void> validateDeck({
    required String format,
    required List<Map<String, dynamic>> cards,
  });
}

class PostgresGeneratedDeckRepository implements GeneratedDeckRepository {
  PostgresGeneratedDeckRepository(this._pool, {String? preferredFormat})
    : _preferredFormat = preferredFormat?.trim().toLowerCase(),
      _cardValidationService = CardValidationService(_pool);

  final Pool _pool;
  final CardValidationService _cardValidationService;
  final String? _preferredFormat;

  @override
  Future<Map<String, List<String>>> findSuggestions(List<String> names) async {
    if (names.isEmpty) return const {};
    return _cardValidationService.findSuggestions(names);
  }

  @override
  Future<Map<String, Map<String, dynamic>>> resolveCardNames(
    List<Map<String, dynamic>> parsedItems,
  ) {
    return resolveImportCardNames(
      _pool,
      parsedItems,
      preferredFormat: _preferredFormat,
    );
  }

  @override
  Future<void> validateDeck({
    required String format,
    required List<Map<String, dynamic>> cards,
  }) async {
    await _pool.runTx(
      (session) => DeckRulesService(
        session,
      ).validateAndThrow(format: format, cards: cards, strict: true),
    );
  }
}

class GeneratedDeckValidationResult {
  const GeneratedDeckValidationResult({
    required this.generatedDeck,
    required this.errors,
    required this.invalidCards,
    required this.suggestions,
    required this.warnings,
    required this.totalSuggestedEntries,
    required this.totalSuggestedCards,
    required this.totalResolvedEntries,
    required this.totalResolvedCards,
  });

  final Map<String, dynamic> generatedDeck;
  final List<String> errors;
  final List<String> invalidCards;
  final Map<String, List<String>> suggestions;
  final List<String> warnings;
  final int totalSuggestedEntries;
  final int totalSuggestedCards;
  final int totalResolvedEntries;
  final int totalResolvedCards;

  bool get isValid => errors.isEmpty;

  Map<String, dynamic> qualityEvidenceSummary() {
    final repairWarnings = warnings
        .where(_isGeneratedDeckRepairWarning)
        .toList(growable: false);
    final cmcIntegrityWarnings = warnings
        .where(_isGeneratedDeckCmcIntegrityWarning)
        .toList(growable: false);
    final inputToResolvedCardDelta = totalSuggestedCards - totalResolvedCards;

    return {
      'has_quality_events':
          errors.isNotEmpty || invalidCards.isNotEmpty || warnings.isNotEmpty,
      'has_auto_repair': repairWarnings.isNotEmpty,
      'has_warnings': warnings.isNotEmpty,
      'has_removed_invalid_cards': invalidCards.isNotEmpty,
      'warning_count': warnings.length,
      'repair_warning_count': repairWarnings.length,
      'cmc_integrity_warning_count': cmcIntegrityWarnings.length,
      'validation_error_count': errors.length,
      'invalid_cards_removed_count': invalidCards.length,
      'input_to_resolved_card_delta': inputToResolvedCardDelta,
      if (repairWarnings.isNotEmpty)
        'repair_warning_sample': repairWarnings.take(5).toList(),
      if (warnings.isNotEmpty) 'warning_sample': warnings.take(5).toList(),
      if (invalidCards.isNotEmpty)
        'invalid_card_sample': invalidCards.take(12).toList(),
    };
  }

  Map<String, dynamic> validationSummary() {
    return {
      'is_valid': isValid,
      'errors': errors,
      'invalid_cards': invalidCards,
      'suggestions': suggestions,
      'warnings': warnings,
      'quality_evidence': qualityEvidenceSummary(),
    };
  }
}

bool _isGeneratedDeckRepairWarning(String warning) {
  final normalized = warning.toLowerCase();
  return normalized.contains('auto-reparo') ||
      normalized.contains('descartad') ||
      normalized.contains('foram removidas') ||
      normalized.contains('foi removida') ||
      normalized.contains('foram removidos') ||
      normalized.contains('foi removido');
}

bool _isGeneratedDeckCmcIntegrityWarning(String warning) {
  return warning.toLowerCase().contains('integridade cmc');
}

class GeneratedDeckValidationService {
  GeneratedDeckValidationService(this._repository);

  final GeneratedDeckRepository _repository;

  Future<GeneratedDeckValidationResult> validate({
    required String format,
    required List<Map<String, dynamic>> cards,
    String? commanderName,
  }) async {
    final normalizedFormat = _normalizeFormat(format);
    final requiresCommander =
        normalizedFormat == 'commander' || normalizedFormat == 'brawl';

    final sanitizedCards = <Map<String, dynamic>>[];
    final warnings = <String>[];
    final unsupportedSections = unsupportedDeckSectionLabels(cards);
    if (unsupportedSections.isNotEmpty) {
      return GeneratedDeckValidationResult(
        generatedDeck: const {'cards': <Map<String, dynamic>>[]},
        errors: [unsupportedDeckSectionsMessage(unsupportedSections)],
        invalidCards: const [],
        suggestions: const {},
        warnings: const [],
        totalSuggestedEntries: cards.length,
        totalSuggestedCards: _sumRawCardQuantities(cards),
        totalResolvedEntries: 0,
        totalResolvedCards: 0,
      );
    }

    for (final rawCard in cards) {
      final rawName = rawCard['name']?.toString() ?? '';
      final name = CardValidationService.sanitizeCardName(rawName);
      if (name.isEmpty) {
        warnings.add('Uma entrada sem nome foi descartada.');
        continue;
      }

      final rawQuantity = rawCard['quantity'];
      final quantity =
          rawQuantity is int
              ? rawQuantity
              : int.tryParse(rawQuantity?.toString() ?? '') ?? 1;

      if (quantity <= 0) {
        warnings.add('A carta "$name" foi descartada por quantidade invalida.');
        continue;
      }

      sanitizedCards.add({'name': name, 'quantity': quantity});
    }

    final sanitizedCommander =
        commanderName == null
            ? null
            : CardValidationService.sanitizeCardName(commanderName);

    final seenLookupNames = <String>{};
    final parsedItems = <Map<String, dynamic>>[];
    void addLookupName(String? name) {
      final normalizedName = name?.trim();
      if (normalizedName == null || normalizedName.isEmpty) return;
      if (!seenLookupNames.add(normalizedName.toLowerCase())) return;
      parsedItems.add({'name': normalizedName});
    }

    for (final card in sanitizedCards) {
      addLookupName(card['name'] as String?);
    }
    addLookupName(sanitizedCommander);

    final foundCardsMap = await _repository.resolveCardNames(parsedItems);

    final invalidCards = <String>[];
    final resolvedCards = <Map<String, dynamic>>[];

    for (final card in sanitizedCards) {
      final name = card['name'] as String;
      final lookupKey = _lookupKey(name, foundCardsMap);
      final resolved = foundCardsMap[lookupKey];

      if (resolved == null) {
        invalidCards.add(name);
        continue;
      }

      resolvedCards.add({
        'card_id': resolved['id'],
        'name': resolved['name'],
        'type_line': resolved['type_line'],
        'color_identity': resolved['color_identity'],
        'colors': resolved['colors'],
        'oracle_text': resolved['oracle_text'],
        'mana_cost': resolved['mana_cost'],
        'cmc': resolved['cmc'],
        'quantity': card['quantity'],
        'is_commander': false,
      });
    }

    Map<String, dynamic>? resolvedCommander;
    if (sanitizedCommander != null && sanitizedCommander.isNotEmpty) {
      final commanderKey = _lookupKey(sanitizedCommander, foundCardsMap);
      final commanderCard = foundCardsMap[commanderKey];
      if (commanderCard == null) {
        invalidCards.add(sanitizedCommander);
      } else {
        resolvedCommander = {
          'card_id': commanderCard['id'],
          'name': commanderCard['name'],
          'type_line': commanderCard['type_line'],
          'color_identity': commanderCard['color_identity'],
          'colors': commanderCard['colors'],
          'oracle_text': commanderCard['oracle_text'],
          'mana_cost': commanderCard['mana_cost'],
          'cmc': commanderCard['cmc'],
          'quantity': 1,
          'is_commander': true,
        };
      }
    }

    if (resolvedCommander != null) {
      final commanderCardId = resolvedCommander['card_id'] as String;
      resolvedCards.removeWhere((card) => card['card_id'] == commanderCardId);
    }

    var consolidatedCards = _consolidateResolvedCards([
      ...resolvedCards,
      if (resolvedCommander != null) resolvedCommander,
    ]);

    if (!requiresCommander && consolidatedCards.isNotEmpty) {
      consolidatedCards = await _tryAutoRepairConstructed(
        format: normalizedFormat,
        cards: consolidatedCards,
        warnings: warnings,
      );
    }

    _appendCmcIntegrityWarnings(consolidatedCards, warnings);

    final errors = <String>[];
    if (requiresCommander && resolvedCommander == null) {
      errors.add(
        'Deck $normalizedFormat precisa de um comandante válido no campo "commander".',
      );
    }

    if (invalidCards.isNotEmpty) {
      warnings.add(
        '${invalidCards.length} carta(s) sugerida(s) não foram encontradas e foram removidas.',
      );
    }

    if (consolidatedCards.isEmpty) {
      errors.add('Nenhuma carta válida restou após a resolução dos nomes.');
    } else {
      try {
        await _repository.validateDeck(
          format: normalizedFormat,
          cards: consolidatedCards,
        );
      } on DeckRulesException catch (e) {
        final repaired = await _tryAutoRepairCommanderOrBrawl(
          format: normalizedFormat,
          cards: consolidatedCards,
          commander: resolvedCommander,
          warnings: warnings,
        );

        if (repaired != null) {
          consolidatedCards = repaired;
          try {
            await _repository.validateDeck(
              format: normalizedFormat,
              cards: consolidatedCards,
            );
          } on DeckRulesException catch (e2) {
            errors.add(e2.message);
          } catch (e2) {
            errors.add(e2.toString());
          }
        } else if (!requiresCommander) {
          final constructedRepair = await _tryAutoRepairConstructedAfterFailure(
            format: normalizedFormat,
            cards: consolidatedCards,
            failure: e,
            warnings: warnings,
          );
          if (constructedRepair != null) {
            consolidatedCards = constructedRepair;
            try {
              await _repository.validateDeck(
                format: normalizedFormat,
                cards: consolidatedCards,
              );
            } on DeckRulesException catch (e2) {
              errors.add(e2.message);
            } catch (e2) {
              errors.add(e2.toString());
            }
          } else {
            errors.add(e.message);
          }
        } else {
          errors.add(e.message);
        }
      } catch (e) {
        errors.add(e.toString());
      }
    }

    final uniqueInvalidCards = invalidCards.toSet().toList();
    const maxSuggestionLookups = 12;
    final suggestionCandidates =
        uniqueInvalidCards.take(maxSuggestionLookups).toList();

    if (uniqueInvalidCards.length > suggestionCandidates.length) {
      warnings.add(
        'Sugestões limitadas a $maxSuggestionLookups cartas inválidas para evitar lentidão.',
      );
    }

    final suggestions =
        suggestionCandidates.isEmpty
            ? const <String, List<String>>{}
            : await _repository.findSuggestions(suggestionCandidates);

    final generatedDeck = <String, dynamic>{
      if (resolvedCommander != null)
        'commander': {'name': resolvedCommander['name']},
      'cards': [
        for (final card in consolidatedCards)
          if (card['is_commander'] != true)
            {'name': card['name'], 'quantity': card['quantity']},
      ],
    };

    return GeneratedDeckValidationResult(
      generatedDeck: generatedDeck,
      errors: errors,
      invalidCards: invalidCards,
      suggestions: suggestions,
      warnings: warnings,
      totalSuggestedEntries: sanitizedCards.length,
      totalSuggestedCards: sanitizedCards.fold<int>(
        0,
        (sum, card) => sum + (card['quantity'] as int),
      ),
      totalResolvedEntries: resolvedCards.length,
      totalResolvedCards: resolvedCards.fold<int>(
        0,
        (sum, card) => sum + (card['quantity'] as int),
      ),
    );
  }

  int _sumRawCardQuantities(List<Map<String, dynamic>> cards) {
    return cards.fold<int>(0, (sum, card) {
      final raw = card['quantity'];
      final quantity =
          raw is int ? raw : int.tryParse(raw?.toString() ?? '') ?? 1;
      return quantity > 0 ? sum + quantity : sum;
    });
  }

  Future<List<Map<String, dynamic>>?> _tryAutoRepairCommanderOrBrawl({
    required String format,
    required List<Map<String, dynamic>> cards,
    required Map<String, dynamic>? commander,
    required List<String> warnings,
  }) async {
    final normalized = format.trim().toLowerCase();
    if (normalized != 'commander' && normalized != 'brawl') return null;
    if (commander == null) return null;

    Iterable<String> toStrings(dynamic raw) {
      if (raw == null) return const <String>[];
      if (raw is Iterable) return raw.map((e) => e.toString());
      return [raw.toString()];
    }

    Set<String> identityOf(Map<String, dynamic> card) {
      final oracleText = card['oracle_text'];
      return resolveCardColorIdentity(
        colorIdentity:
            card['color_identity'] == null
                ? null
                : toStrings(card['color_identity']),
        colors: toStrings(card['colors']),
        oracleText: oracleText == null ? null : oracleText.toString(),
        manaCost: card['mana_cost']?.toString(),
      );
    }

    final commanderColors = identityOf(commander);

    final targetNonCommander = normalized == 'brawl' ? 59 : 99;

    final repaired = <Map<String, dynamic>>[
      {...commander, 'quantity': 1, 'is_commander': true},
    ];

    var removedOffColor = 0;
    var reducedExtraCopies = 0;

    for (final card in cards) {
      if (card['is_commander'] == true) continue;

      final qtyRaw = card['quantity'];
      final qty =
          qtyRaw is int ? qtyRaw : int.tryParse(qtyRaw?.toString() ?? '') ?? 1;
      if (qty <= 0) continue;

      final typeLineRaw = (card['type_line'] ?? '').toString();
      final typeLine = typeLineRaw.toLowerCase();
      final hasTypeLine = typeLineRaw.trim().isNotEmpty;

      final name = (card['name'] ?? '').toString();
      final isBasicLand = basic_lands.isBasicLandCard(
        name: name,
        typeLine: typeLine,
      );

      final cardColors = identityOf(card);

      final within = isWithinCommanderIdentity(
        cardIdentity: cardColors,
        commanderIdentity: commanderColors,
      );
      if (!within) {
        removedOffColor += qty;
        continue;
      }

      var finalQty = qty;
      if (hasTypeLine && !isBasicLand && finalQty > 1) {
        reducedExtraCopies += (finalQty - 1);
        finalQty = 1;
      }

      repaired.add({...card, 'quantity': finalQty, 'is_commander': false});
    }

    var consolidated = _consolidateResolvedCards(repaired);

    if (removedOffColor > 0) {
      warnings.add(
        'Auto-reparo: removidas $removedOffColor carta(s) fora da identidade de cor do comandante.',
      );
    }
    if (reducedExtraCopies > 0) {
      warnings.add(
        'Auto-reparo: removidas $reducedExtraCopies cópia(s) extras em cartas não-básicas (singleton).',
      );
    }

    int currentNonCommander = 0;
    for (final card in consolidated) {
      if (card['is_commander'] == true) continue;
      currentNonCommander += (card['quantity'] as int?) ?? 1;
    }

    if (currentNonCommander < targetNonCommander) {
      var toAdd = targetNonCommander - currentNonCommander;
      final colorToBasic = <String, String>{
        'W': 'Plains',
        'U': 'Island',
        'B': 'Swamp',
        'R': 'Mountain',
        'G': 'Forest',
      };

      final basicNames = <String>[];
      for (final color in ['W', 'U', 'B', 'R', 'G']) {
        if (commanderColors.contains(color)) {
          basicNames.add(colorToBasic[color]!);
        }
      }
      if (basicNames.isEmpty) {
        basicNames.add('Wastes');
      }

      final lookupItems = [
        for (final name in basicNames) {'name': name},
      ];
      final resolvedBasics = await _repository.resolveCardNames(lookupItems);

      final resolvedBasicCards = <Map<String, dynamic>>[];
      final per = (toAdd / basicNames.length).floor();
      var remaining = toAdd;

      for (var i = 0; i < basicNames.length; i++) {
        final name = basicNames[i];
        final key = name.toLowerCase();
        final resolved = resolvedBasics[key];
        if (resolved == null) continue;

        var qty = i == basicNames.length - 1 ? remaining : per;
        if (qty <= 0) continue;
        remaining -= qty;

        resolvedBasicCards.add({
          'card_id': resolved['id'],
          'name': resolved['name'],
          'type_line': resolved['type_line'],
          'color_identity': resolved['color_identity'],
          'colors': resolved['colors'],
          'oracle_text': resolved['oracle_text'],
          'mana_cost': resolved['mana_cost'],
          'cmc': resolved['cmc'],
          'quantity': qty,
          'is_commander': false,
        });
      }

      if (resolvedBasicCards.isNotEmpty) {
        consolidated = _consolidateResolvedCards([
          ...consolidated,
          ...resolvedBasicCards,
        ]);
        warnings.add(
          'Auto-reparo: completado com terrenos básicos para fechar o tamanho do deck.',
        );
      }
    }

    // If we still overflow, trim basic lands first.
    currentNonCommander = 0;
    for (final card in consolidated) {
      if (card['is_commander'] == true) continue;
      currentNonCommander += (card['quantity'] as int?) ?? 1;
    }

    var overflow = currentNonCommander - targetNonCommander;
    if (overflow > 0) {
      for (final card in consolidated) {
        if (overflow <= 0) break;
        if (card['is_commander'] == true) continue;
        final typeLine = (card['type_line'] ?? '').toString().toLowerCase();
        final name = (card['name'] ?? '').toString();
        final isBasicLand = basic_lands.isBasicLandCard(
          name: name,
          typeLine: typeLine,
        );
        if (!isBasicLand) continue;

        final qty = (card['quantity'] as int?) ?? 1;
        if (qty <= 0) continue;

        final remove = qty >= overflow ? overflow : qty;
        card['quantity'] = qty - remove;
        overflow -= remove;
      }

      consolidated =
          consolidated.where((c) => (c['quantity'] as int? ?? 0) > 0).toList();
      warnings.add(
        'Auto-reparo: removidos terrenos básicos excedentes para fechar o tamanho do deck.',
      );
    }

    return consolidated;
  }

  Future<List<Map<String, dynamic>>> _tryAutoRepairConstructed({
    required String format,
    required List<Map<String, dynamic>> cards,
    required List<String> warnings,
  }) async {
    var repaired = <Map<String, dynamic>>[];
    var reducedExtraCopies = 0;

    for (final card in cards) {
      if (card['is_commander'] == true) continue;

      final copy = Map<String, dynamic>.from(card)..['is_commander'] = false;
      final qtyRaw = copy['quantity'];
      var quantity =
          qtyRaw is int ? qtyRaw : int.tryParse(qtyRaw?.toString() ?? '') ?? 1;
      if (quantity <= 0) continue;

      if (!_isBasicLandCard(copy) && quantity > 4) {
        reducedExtraCopies += quantity - 4;
        quantity = 4;
      }

      copy['quantity'] = quantity;
      repaired.add(copy);
    }

    repaired = _consolidateResolvedCards(repaired);

    if (reducedExtraCopies > 0) {
      warnings.add(
        'Auto-reparo: reduzidas $reducedExtraCopies copia(s) extras em cartas nao-basicas para respeitar o limite do formato $format.',
      );
    }

    repaired = await _fillConstructedDeckToMinimum(
      cards: repaired,
      minTotal: 60,
      warnings: warnings,
    );

    return repaired;
  }

  Future<List<Map<String, dynamic>>?> _tryAutoRepairConstructedAfterFailure({
    required String format,
    required List<Map<String, dynamic>> cards,
    required DeckRulesException failure,
    required List<String> warnings,
  }) async {
    final offendingName = failure.cardName?.trim().toLowerCase();
    if (offendingName == null || offendingName.isEmpty) return null;

    var changed = false;
    final repaired = <Map<String, dynamic>>[];

    for (final card in cards) {
      final cardName = (card['name'] ?? '').toString().trim().toLowerCase();
      final copy = Map<String, dynamic>.from(card);
      if (cardName != offendingName) {
        repaired.add(copy);
        continue;
      }

      changed = true;
      if (failure.message.contains('excede o limite')) {
        copy['quantity'] = _isBasicLandCard(copy) ? copy['quantity'] : 4;
        repaired.add(copy);
      } else if (failure.message.contains('RESTRITA')) {
        copy['quantity'] = 1;
        repaired.add(copy);
      }
    }

    if (!changed) return null;

    warnings.add(
      'Auto-reparo: ajustada/removida a carta "${failure.cardName}" apos falha de legalidade do formato $format.',
    );

    return _fillConstructedDeckToMinimum(
      cards: _consolidateResolvedCards(repaired),
      minTotal: 60,
      warnings: warnings,
    );
  }

  Future<List<Map<String, dynamic>>> _fillConstructedDeckToMinimum({
    required List<Map<String, dynamic>> cards,
    required int minTotal,
    required List<String> warnings,
  }) async {
    final currentTotal = cards.fold<int>(
      0,
      (sum, card) => sum + ((card['quantity'] as int?) ?? 1),
    );
    if (currentTotal >= minTotal) return cards;

    final toAdd = minTotal - currentTotal;
    final basicNames = _basicLandNamesForConstructedDeck(cards);
    final resolvedBasics = await _repository.resolveCardNames([
      for (final name in basicNames) {'name': name},
    ]);

    final quantitiesByName = <String, int>{};
    for (var i = 0; i < toAdd; i++) {
      final name = basicNames[i % basicNames.length];
      quantitiesByName[name] = (quantitiesByName[name] ?? 0) + 1;
    }

    final additions = <Map<String, dynamic>>[];
    for (final entry in quantitiesByName.entries) {
      final resolved = resolvedBasics[_lookupKey(entry.key, resolvedBasics)];
      if (resolved == null) continue;
      additions.add({
        'card_id': resolved['id'],
        'name': resolved['name'],
        'type_line': resolved['type_line'],
        'color_identity': resolved['color_identity'],
        'colors': resolved['colors'],
        'oracle_text': resolved['oracle_text'],
        'mana_cost': resolved['mana_cost'],
        'cmc': resolved['cmc'],
        'quantity': entry.value,
        'is_commander': false,
      });
    }

    if (additions.isEmpty) return cards;

    warnings.add(
      'Auto-reparo: adicionados $toAdd terreno(s) basico(s) para atingir o minimo de $minTotal cartas.',
    );

    return _consolidateResolvedCards([...cards, ...additions]);
  }

  static List<String> _basicLandNamesForConstructedDeck(
    List<Map<String, dynamic>> cards,
  ) {
    final colorOrder = ['W', 'U', 'B', 'R', 'G'];
    final demand = {for (final color in colorOrder) color: 0};

    for (final card in cards) {
      if (_isBasicLandCard(card)) continue;

      final identity = _identityOf(card);
      for (final color in identity) {
        if (demand.containsKey(color)) {
          demand[color] = demand[color]! + ((card['quantity'] as int?) ?? 1);
        }
      }

      final manaCost = (card['mana_cost'] ?? '').toString();
      for (final color in colorOrder) {
        final symbolCount =
            RegExp(
              '\\{${color.toLowerCase()}\\}',
              caseSensitive: false,
            ).allMatches(manaCost).length;
        if (symbolCount > 0) {
          demand[color] =
              demand[color]! +
              (symbolCount * ((card['quantity'] as int?) ?? 1));
        }
      }
    }

    final selectedColors = demand.entries
        .where((entry) => entry.value > 0)
        .map((entry) => entry.key)
        .toList(growable: false);

    final colorToBasic = <String, String>{
      'W': 'Plains',
      'U': 'Island',
      'B': 'Swamp',
      'R': 'Mountain',
      'G': 'Forest',
    };

    final names = [for (final color in selectedColors) colorToBasic[color]!];
    return names.isEmpty ? const ['Wastes'] : names;
  }

  static bool _isBasicLandCard(Map<String, dynamic> card) {
    final typeLine = (card['type_line'] ?? '').toString();
    final name = (card['name'] ?? '').toString();
    return basic_lands.isBasicLandCard(name: name, typeLine: typeLine);
  }

  static Set<String> _identityOf(Map<String, dynamic> card) {
    Iterable<String> toStrings(dynamic raw) {
      if (raw == null) return const <String>[];
      if (raw is Iterable) return raw.map((e) => e.toString());
      return [raw.toString()];
    }

    final oracleText = card['oracle_text'];
    return resolveCardColorIdentity(
      colorIdentity:
          card['color_identity'] == null
              ? null
              : toStrings(card['color_identity']),
      colors: toStrings(card['colors']),
      oracleText: oracleText == null ? null : oracleText.toString(),
      manaCost: card['mana_cost']?.toString(),
    );
  }

  static List<Map<String, dynamic>> _consolidateResolvedCards(
    List<Map<String, dynamic>> cards,
  ) {
    final byId = <String, Map<String, dynamic>>{};

    for (final card in cards) {
      final cardId = card['card_id'] as String;
      final existing = byId[cardId];
      if (existing == null) {
        byId[cardId] = Map<String, dynamic>.from(card);
        continue;
      }

      existing['quantity'] =
          (existing['quantity'] as int) + (card['quantity'] as int);
      if (card['is_commander'] == true) {
        existing['is_commander'] = true;
      }
    }

    return byId.values.toList();
  }

  static void _appendCmcIntegrityWarnings(
    List<Map<String, dynamic>> cards,
    List<String> warnings,
  ) {
    final suspiciousNames = <String>[];
    for (final card in cards) {
      if (!hasSuspiciousNonLandCmc(card)) continue;
      final name = (card['name'] ?? '').toString().trim();
      suspiciousNames.add(name.isEmpty ? 'card_id=${card['card_id']}' : name);
    }

    if (suspiciousNames.isEmpty) return;

    const maxNames = 8;
    final shown = suspiciousNames.take(maxNames).join(', ');
    final hidden =
        suspiciousNames.length > maxNames
            ? suspiciousNames.length - maxNames
            : 0;
    warnings.add(
      hidden > 0
          ? 'Integridade CMC: ${suspiciousNames.length} carta(s) não-terreno têm CMC ausente/zerado suspeito contra mana_cost; exemplos: $shown; +$hidden.'
          : 'Integridade CMC: ${suspiciousNames.length} carta(s) não-terreno têm CMC ausente/zerado suspeito contra mana_cost: $shown.',
    );
  }

  static String _lookupKey(
    String name,
    Map<String, Map<String, dynamic>> foundCardsMap,
  ) {
    final originalKey = name.toLowerCase();
    final cleanedKey = cleanImportLookupKey(originalKey);
    return foundCardsMap.containsKey(originalKey) ? originalKey : cleanedKey;
  }

  static String _normalizeFormat(String format) {
    final normalized = format.trim().toLowerCase();
    if (normalized == 'edh') return 'commander';
    return normalized;
  }
}
