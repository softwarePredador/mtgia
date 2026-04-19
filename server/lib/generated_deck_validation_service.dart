import 'package:postgres/postgres.dart';

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
  PostgresGeneratedDeckRepository(this._pool)
      : _cardValidationService = CardValidationService(_pool);

  final Pool _pool;
  final CardValidationService _cardValidationService;

  @override
  Future<Map<String, List<String>>> findSuggestions(List<String> names) async {
    if (names.isEmpty) return const {};
    return _cardValidationService.findSuggestions(names);
  }

  @override
  Future<Map<String, Map<String, dynamic>>> resolveCardNames(
    List<Map<String, dynamic>> parsedItems,
  ) {
    return resolveImportCardNames(_pool, parsedItems);
  }

  @override
  Future<void> validateDeck({
    required String format,
    required List<Map<String, dynamic>> cards,
  }) async {
    await _pool.runTx(
      (session) => DeckRulesService(session).validateAndThrow(
        format: format,
        cards: cards,
        strict: true,
      ),
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

  Map<String, dynamic> validationSummary() {
    return {
      'is_valid': isValid,
      'errors': errors,
      'invalid_cards': invalidCards,
      'suggestions': suggestions,
      'warnings': warnings,
    };
  }
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

    for (final rawCard in cards) {
      final rawName = rawCard['name']?.toString() ?? '';
      final name = CardValidationService.sanitizeCardName(rawName);
      if (name.isEmpty) {
        warnings.add('Uma entrada sem nome foi descartada.');
        continue;
      }

      final rawQuantity = rawCard['quantity'];
      final quantity = rawQuantity is int
          ? rawQuantity
          : int.tryParse(rawQuantity?.toString() ?? '') ?? 1;

      if (quantity <= 0) {
        warnings.add('A carta "$name" foi descartada por quantidade invalida.');
        continue;
      }

      sanitizedCards.add({
        'name': name,
        'quantity': quantity,
      });
    }

    final sanitizedCommander = commanderName == null
        ? null
        : CardValidationService.sanitizeCardName(commanderName);

    final parsedItems = [
      for (final card in sanitizedCards) {'name': card['name']},
      if (sanitizedCommander != null && sanitizedCommander.isNotEmpty)
        {'name': sanitizedCommander},
    ];

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
          'quantity': 1,
          'is_commander': true,
        };
      }
    }

    if (resolvedCommander != null) {
      final commanderCardId = resolvedCommander['card_id'] as String;
      resolvedCards.removeWhere(
        (card) => card['card_id'] == commanderCardId,
      );
    }

    var consolidatedCards = _consolidateResolvedCards([
      ...resolvedCards,
      if (resolvedCommander != null) resolvedCommander,
    ]);

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

    final suggestions = suggestionCandidates.isEmpty
        ? const <String, List<String>>{}
        : await _repository.findSuggestions(suggestionCandidates);

    final generatedDeck = <String, dynamic>{
      if (resolvedCommander != null)
        'commander': {'name': resolvedCommander['name']},
      'cards': [
        for (final card in consolidatedCards)
          if (card['is_commander'] != true)
            {
              'name': card['name'],
              'quantity': card['quantity'],
            },
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
        colorIdentity: toStrings(card['color_identity']),
        colors: toStrings(card['colors']),
        oracleText: oracleText == null ? null : oracleText.toString(),
      );
    }

    final commanderColors = identityOf(commander);

    final targetNonCommander = normalized == 'brawl' ? 59 : 99;

    final repaired = <Map<String, dynamic>>[
      {
        ...commander,
        'quantity': 1,
        'is_commander': true,
      },
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

      final nameLower = (card['name'] ?? '').toString().trim().toLowerCase();
      final isBasicLandByName = nameLower == 'plains' ||
          nameLower == 'island' ||
          nameLower == 'swamp' ||
          nameLower == 'mountain' ||
          nameLower == 'forest' ||
          nameLower == 'wastes' ||
          nameLower.startsWith('snow-covered plains') ||
          nameLower.startsWith('snow-covered island') ||
          nameLower.startsWith('snow-covered swamp') ||
          nameLower.startsWith('snow-covered mountain') ||
          nameLower.startsWith('snow-covered forest');

      final isBasicLand = typeLine.contains('basic land') || isBasicLandByName;

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

      repaired.add({
        ...card,
        'quantity': finalQty,
        'is_commander': false,
      });
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
        for (final name in basicNames) {'name': name}
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
        final nameLower = (card['name'] ?? '').toString().trim().toLowerCase();
        final isBasicLandByName = nameLower == 'plains' ||
            nameLower == 'island' ||
            nameLower == 'swamp' ||
            nameLower == 'mountain' ||
            nameLower == 'forest' ||
            nameLower == 'wastes' ||
            nameLower.startsWith('snow-covered plains') ||
            nameLower.startsWith('snow-covered island') ||
            nameLower.startsWith('snow-covered swamp') ||
            nameLower.startsWith('snow-covered mountain') ||
            nameLower.startsWith('snow-covered forest');
        final isBasicLand =
            typeLine.contains('basic land') || isBasicLandByName;
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
