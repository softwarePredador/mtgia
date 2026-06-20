import 'package:postgres/postgres.dart';

import 'basic_land_utils.dart' as basic_lands;
import 'card_identity_support.dart';
import 'commander_eligibility.dart';
import 'commander_pairing.dart' as commander_pairing;
import 'color_identity.dart';
import 'deck_section_support.dart';

String normalizePhysicalCardCopyName(String name) {
  return commander_pairing.normalizePhysicalCardCopyName(name);
}

class DeckRulesService {
  DeckRulesService(this._session);

  final Session _session;

  Future<void> validateAndThrow({
    required String format,
    required List<Map<String, dynamic>>
        cards, // {card_id, quantity, is_commander}
    bool strict = false,
  }) async {
    final normalizedFormat = format.toLowerCase();
    validateNoUnsupportedDeckSections(cards: cards);
    validateCommanderSlotAllowedForFormat(
      format: normalizedFormat,
      cards: cards,
    );

    final cardIds = cards.map((c) => c['card_id']).whereType<String>().toList();
    if (cardIds.isEmpty) return;

    final cardsData = await _loadCardsData(cardIds);
    final legalities = await _loadLegalities(cardIds, normalizedFormat);

    // Regras gerais: limite de cópias por carta física.
    // Isso cobre múltiplas edições e nomes MDFC/split representados por face.
    final copiesByName = <String, _CopyCounter>{};
    for (final item in cards) {
      final cardId = item['card_id'] as String?;
      if (cardId == null || cardId.isEmpty) continue;

      final quantity = item['quantity'] as int? ?? 1;
      final isCommander = item['is_commander'] as bool? ?? false;

      final info = cardsData[cardId];
      if (info == null) continue;

      // Commander é validado separadamente (quantidade=1).
      if (isCommander) continue;

      final typeLine = info.typeLine.toLowerCase();
      final isBasicLand = _isBasicLandTypeLine(typeLine);
      if (isBasicLand) continue;

      final key = info.physicalCopyKey;
      final existing = copiesByName[key];
      if (existing == null) {
        copiesByName[key] = _CopyCounter(info.name.trim(), quantity);
      } else {
        existing.quantity += quantity;
        existing.sourceNames.add(info.name.trim());
      }
    }

    final limit = isCommanderStyleFormat(normalizedFormat) ? 1 : 4;
    for (final entry in copiesByName.entries) {
      final value = entry.value;
      final name = value.displayName;
      final qty = value.quantity;
      if (qty > limit) {
        final hasMultipleNames = value.sourceNames.length > 1;
        final sourceNames = value.sourceNames.join('" / "');
        throw DeckRulesException(
          hasMultipleNames
              ? 'Regra violada: "$sourceNames" contam como a mesma carta física e excedem o limite de $limit cópia(s) para o formato $normalizedFormat.'
              : 'Regra violada: "$name" excede o limite de $limit cópia(s) para o formato $normalizedFormat.',
          cardName: name,
        );
      }
    }

    // Regras gerais (limite de cópias + banlist/restrita)
    for (final item in cards) {
      final cardId = item['card_id'] as String?;
      final quantity = item['quantity'] as int? ?? 1;
      final isCommander = item['is_commander'] as bool? ?? false;

      if (cardId == null || cardId.isEmpty) {
        throw DeckRulesException('Carta sem card_id.');
      }
      if (quantity <= 0) {
        throw DeckRulesException('Quantidade inválida para card_id=$cardId.');
      }

      final info = cardsData[cardId];
      if (info == null) {
        throw DeckRulesException('Carta não encontrada (card_id=$cardId).');
      }

      final typeLine = info.typeLine.toLowerCase();
      final isBasicLand = _isBasicLandTypeLine(typeLine);

      final limit = isCommanderStyleFormat(normalizedFormat) ? 1 : 4;

      // Commanders são validados separadamente pela regra quantity == 1
      // Aqui só validamos cartas normais
      if (!isBasicLand && !isCommander && quantity > limit) {
        throw DeckRulesException(
          'Regra violada: "${info.name}" excede o limite de $limit cópia(s) para o formato $normalizedFormat.',
          cardName: info.name,
        );
      }

      if (isCommander && quantity != 1) {
        throw DeckRulesException(
            'Regra violada: comandante deve ter quantidade 1 ("${info.name}").',
            cardName: info.name);
      }

      final status = legalities[cardId];
      if (status == null) continue;
      if (status == 'banned') {
        throw DeckRulesException(
            'Regra violada: "${info.name}" é BANIDA no formato $normalizedFormat.',
            cardName: info.name);
      }
      if (status == 'not_legal') {
        throw DeckRulesException(
            'Regra violada: "${info.name}" não é válida no formato $normalizedFormat.',
            cardName: info.name);
      }
      if (status == 'restricted' && quantity > 1) {
        throw DeckRulesException(
            'Regra violada: "${info.name}" é RESTRITA no formato $normalizedFormat (máx. 1).',
            cardName: info.name);
      }
    }

    // Regras específicas de Commander/Brawl (MVP para o fluxo que você descreveu)
    if (isCommanderStyleFormat(normalizedFormat)) {
      await _validateCommanderStyle(
        format: normalizedFormat,
        cards: cards,
        cardsData: cardsData,
        strict: strict,
      );
    } else {
      // Formatos não-Commander (Standard, Modern, Pioneer, Legacy, Vintage, Pauper...)
      // Mínimo de 60 cartas no main deck
      final total =
          cards.fold<int>(0, (sum, c) => sum + ((c['quantity'] as int?) ?? 1));
      const minDeckSize = 60;
      if (strict && total < minDeckSize) {
        throw DeckRulesException(
            'Regra violada: deck $normalizedFormat precisa de pelo menos $minDeckSize cartas (atual: $total).');
      }
    }
  }

  Future<void> _validateCommanderStyle({
    required String format,
    required List<Map<String, dynamic>> cards,
    required Map<String, _CardData> cardsData,
    required bool strict,
  }) async {
    final commanders =
        cards.where((c) => (c['is_commander'] as bool?) ?? false).toList();

    if (commanders.isEmpty) {
      if (strict) {
        throw DeckRulesException(
            'Regra violada: deck $format precisa de 1 comandante selecionado.');
      }
      final total =
          cards.fold<int>(0, (sum, c) => sum + ((c['quantity'] as int?) ?? 1));
      final maxTotal = format == 'commander' ? 100 : 60;
      if (total > maxTotal) {
        throw DeckRulesException(
            'Regra violada: deck $format não pode exceder $maxTotal cartas (atual: $total).');
      }
      return;
    }

    // Validar quantidade de comandantes (1 ou 2 com Partner/Background)
    if (commanders.length > 2) {
      throw DeckRulesException(
        'Regra violada: deck $format suporta no máximo 2 comandantes (com Partner ou Background).',
      );
    }

    if (commanders.length == 2) {
      // Validar regras de Partner/Background
      final cmd1Id = commanders[0]['card_id'] as String?;
      final cmd2Id = commanders[1]['card_id'] as String?;
      if (cmd1Id == null || cmd2Id == null) {
        throw DeckRulesException('Regra violada: comandante sem card_id.');
      }
      final cmd1 = cardsData[cmd1Id];
      final cmd2 = cardsData[cmd2Id];
      if (cmd1 == null || cmd2 == null) {
        throw DeckRulesException('Regra violada: comandante não encontrado.');
      }

      if (!_validatePartnerPairing(cmd1, cmd2)) {
        throw DeckRulesException(
          'Regra violada: "${cmd1.name}" e "${cmd2.name}" não podem ser comandantes juntos. '
          'Precisam ter "Partner", "Partner with [nome]" ou um ter "Choose a Background" e o outro ser Background.',
          cardName: cmd1.name,
        );
      }
    }

    if (commanders.length == 1) {
      final commanderId = commanders.first['card_id'] as String?;
      if (commanderId == null || commanderId.isEmpty) {
        throw DeckRulesException('Regra violada: comandante sem card_id.');
      }
      final commanderInfo = cardsData[commanderId];
      if (commanderInfo == null) {
        throw DeckRulesException('Regra violada: comandante não encontrado.');
      }

      if (!_isCommanderEligible(commanderInfo, format: format)) {
        throw DeckRulesException(
          'Regra violada: "${commanderInfo.name}" não pode ser comandante (precisa ser criatura lendária, Vehicle/Spacecraft lendário com poder/resistência, ou dizer "can be your commander").',
          cardName: commanderInfo.name,
        );
      }
    }

    // Calcular identidade de cor combinada de todos os comandantes
    final commanderIdentitySet = <String>{};
    final commanderIdentityKeys = <String>{};
    for (final cmd in commanders) {
      final cmdId = cmd['card_id'] as String?;
      if (cmdId == null) continue;
      final info = cardsData[cmdId];
      if (info == null) continue;

      if (!_isCommanderEligible(info, format: format) && !_isBackground(info)) {
        throw DeckRulesException(
          'Regra violada: "${info.name}" não pode ser comandante.',
          cardName: info.name,
        );
      }

      commanderIdentityKeys.add(info.physicalCopyKey);
      commanderIdentitySet.addAll(_resolvedIdentity(info));
    }

    for (final item in cards) {
      final cardId = item['card_id'] as String?;
      if (cardId == null) continue;
      final info = cardsData[cardId];
      if (info == null) continue;
      final isCommander = item['is_commander'] as bool? ?? false;

      if (!isCommander &&
          commanderIdentityKeys.contains(info.physicalCopyKey)) {
        throw DeckRulesException(
          'Regra violada: "${info.name}" já está selecionada como comandante e não pode entrar no deck principal.',
          cardName: info.name,
        );
      }

      for (final c in _resolvedIdentity(info)) {
        if (!commanderIdentitySet.contains(c.toUpperCase())) {
          throw DeckRulesException(
            'Regra violada: "${info.name}" tem identidade de cor fora do(s) comandante(s).',
            cardName: info.name,
          );
        }
      }
    }

    final total =
        cards.fold<int>(0, (sum, c) => sum + ((c['quantity'] as int?) ?? 1));
    final maxTotal = format == 'commander' ? 100 : 60;
    if (strict && total != maxTotal) {
      throw DeckRulesException(
          'Regra violada: deck $format deve ter exatamente $maxTotal cartas (atual: $total).');
    }
    if (total > maxTotal) {
      throw DeckRulesException(
          'Regra violada: deck $format não pode exceder $maxTotal cartas (atual: $total).');
    }
  }

  bool _isCommanderEligible(_CardData card, {required String format}) {
    // Nota: Background enchantments NÃO são elegíveis como comandante solo.
    // Eles só podem ser usados como comandante quando PAREADOS com uma criatura
    // que tenha "Choose a Background" (2 comandantes).
    // O par é validado por _validateCommanderStyle → _validatePartnerPairing.
    // No loop de 2 comandantes, o Background é aceito via guarda _isBackground(info)
    // na condição: `if (!_isCommanderEligible(info) && !_isBackground(info))`.
    return isCommanderEligibleCard(
      typeLine: card.typeLine,
      oracleText: card.oracleText,
      power: card.power,
      toughness: card.toughness,
      format: format,
    );
  }

  /// Verifica se a carta é um Background (encantamento lendário com subtipo Background)
  bool _isBackground(_CardData card) {
    return commander_pairing
        .isBackgroundCommanderPairCard(card.toCommanderPairingCard());
  }

  /// Valida se dois comandantes podem ser usados juntos
  bool _validatePartnerPairing(_CardData cmd1, _CardData cmd2) {
    return commander_pairing.areCommanderPairingCompatible(
      cmd1.toCommanderPairingCard(),
      cmd2.toCommanderPairingCard(),
    );
  }

  /// Retorna `true` para terrenos básicos (incluindo Snow-Covered variants).
  ///
  /// Tipo de linha das variações:
  ///   - Normais:       "Basic Land — Plains/Island/Swamp/Mountain/Forest"
  ///   - Snow-Covered:  "Basic Snow Land — Plains/Island/Swamp/Mountain/Forest"
  ///   - Wastes:        "Basic Land" (sem subtipo)
  static bool _isBasicLandTypeLine(String typeLineLower) {
    return basic_lands.isBasicLandTypeLine(typeLineLower);
  }

  Future<Map<String, _CardData>> _loadCardsData(List<String> cardIds) async {
    final hasIdentityColumns = await hasCardIdentityColumns(_session);
    final identitySelect = hasIdentityColumns
        ? 'oracle_id::text AS oracle_id'
        : 'NULL::text AS oracle_id';
    final result = await _session.execute(
      Sql.named('''
        SELECT id::text, name, type_line, oracle_text, colors, color_identity, mana_cost, cmc, power, toughness, $identitySelect
        FROM cards
        WHERE id = ANY(@ids)
      '''),
      parameters: {'ids': cardIds},
    );

    final map = <String, _CardData>{};
    for (final row in result) {
      final id = row[0] as String;
      final name = row[1] as String;
      final typeLine = row[2] as String? ?? '';
      final oracleText = row[3] as String?;
      final colors = (row[4] as List?)?.map((e) => e.toString()).toList() ??
          const <String>[];
      final colorIdentity =
          (row[5] as List?)?.map((e) => e.toString()).toList() ??
              const <String>[];
      final manaCost = row[6] as String?;
      final cmc = parseDeckRulesCmcValue(row[7]);
      final power = row[8] as String?;
      final toughness = row[9] as String?;
      final oracleId = nonEmptyCardIdentityString(row[10]);

      map[id] = _CardData(
        id: id,
        oracleId: oracleId,
        name: name,
        typeLine: typeLine,
        oracleText: oracleText,
        colors: colors,
        colorIdentity: colorIdentity,
        manaCost: manaCost,
        cmc: cmc,
        power: power,
        toughness: toughness,
      );
    }

    return map;
  }

  Future<Map<String, String>> _loadLegalities(
      List<String> cardIds, String format) async {
    final result = await _session.execute(
      Sql.named('''
        SELECT card_id::text, status
        FROM card_legalities
        WHERE card_id = ANY(@ids) AND format = @format
      '''),
      parameters: {'ids': cardIds, 'format': format},
    );

    return {
      for (final row in result)
        row[0] as String: (row[1] as String).toLowerCase()
    };
  }

  Set<String> _resolvedIdentity(_CardData card) {
    return resolveCardColorIdentity(
      colorIdentity: card.colorIdentity,
      colors: card.colors,
      oracleText: card.oracleText,
      manaCost: card.manaCost,
    );
  }
}

void validateCommanderSlotAllowedForFormat({
  required String format,
  required List<Map<String, dynamic>> cards,
}) {
  if (isCommanderStyleFormat(format)) return;
  final hasCommanderSlot =
      cards.any((card) => card['is_commander'] as bool? ?? false);
  if (!hasCommanderSlot) return;
  throw DeckRulesException(
    'Regra violada: is_commander só é permitido em Commander/Brawl.',
  );
}

List<String> unsupportedDeckSectionLabels(
  Iterable<Map<String, dynamic>> cards,
) {
  final labels = <String>[];
  for (final card in cards) {
    final label = unsupportedDeckSectionLabel(card);
    if (label == null) continue;
    labels.add(label);
  }
  return labels;
}

List<String> unsupportedRawDeckSectionLabels(Object? rawList) {
  if (rawList is! List) return const [];
  final labels = <String>[];
  for (final item in rawList) {
    if (item is! Map) continue;
    final card = <String, dynamic>{
      for (final entry in item.entries) entry.key.toString(): entry.value,
    };
    final label = unsupportedDeckSectionLabel(card);
    if (label != null) labels.add(label);
  }
  return labels;
}

String? unsupportedDeckSectionLabel(Map<String, dynamic> card) {
  const booleanFields = {
    'sideboard': 'sideboard',
    'is_sideboard': 'sideboard',
    'wishboard': 'wishboard',
    'is_wishboard': 'wishboard',
    'maybeboard': 'maybeboard',
    'is_maybeboard': 'maybeboard',
    'outside_game': 'outside-game',
    'is_outside_game': 'outside-game',
  };

  for (final entry in booleanFields.entries) {
    final raw = card[entry.key];
    if (raw == true || raw?.toString().trim().toLowerCase() == 'true') {
      return entry.value;
    }
  }

  const sectionFields = {
    'zone',
    'board',
    'board_type',
    'section',
    'deck_section',
    'list_section',
    'list_type',
  };

  for (final key in sectionFields) {
    final raw = card[key];
    if (raw == null) continue;
    if (isUnsupportedDeckSectionValue(raw)) {
      return raw.toString().trim();
    }
  }

  return null;
}

void validateNoUnsupportedDeckSections({
  required Iterable<Map<String, dynamic>> cards,
}) {
  final labels = unsupportedDeckSectionLabels(cards);
  if (labels.isEmpty) return;
  throw DeckRulesException(unsupportedDeckSectionsMessage(labels));
}

String unsupportedDeckSectionsMessage(Iterable<String> labels) {
  final uniqueLabels = labels
      .map((label) => label.trim())
      .where((label) => label.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
  final suffix = uniqueLabels.isEmpty ? '' : ' (${uniqueLabels.join(', ')}).';
  return 'Regra violada: ManaLoom ainda não suporta sideboard, wishboard, maybeboard ou cartas "outside the game" em decks salvos$suffix '
      'Importe apenas o deck principal e marque comandante pelo campo/tag de comandante.';
}

class DeckRulesException implements Exception {
  DeckRulesException(this.message, {this.cardName});
  final String message;
  final String? cardName;
  @override
  String toString() => message;
}

double? parseDeckRulesCmcValue(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

class _CopyCounter {
  _CopyCounter(String displayName, this.quantity)
      : displayName = displayName,
        sourceNames = {displayName};

  final String displayName;
  int quantity;
  final Set<String> sourceNames;
}

class _CardData {
  const _CardData({
    required this.id,
    required this.oracleId,
    required this.name,
    required this.typeLine,
    required this.oracleText,
    required this.colors,
    required this.colorIdentity,
    required this.manaCost,
    required this.cmc,
    required this.power,
    required this.toughness,
  });

  final String id;
  final String? oracleId;
  final String name;
  final String typeLine;
  final String? oracleText;
  final List<String> colors;
  final List<String> colorIdentity;
  final String? manaCost;
  final double? cmc;
  final String? power;
  final String? toughness;

  String get physicalCopyKey {
    final canonicalId = nonEmptyCardIdentityString(oracleId);
    if (canonicalId != null) return 'oracle:$canonicalId';
    return 'name:${normalizePhysicalCardCopyName(name)}';
  }

  commander_pairing.CommanderPairingCard toCommanderPairingCard() {
    return commander_pairing.CommanderPairingCard(
      name: name,
      typeLine: typeLine,
      oracleText: oracleText,
    );
  }
}
