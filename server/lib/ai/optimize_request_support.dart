import 'package:postgres/postgres.dart';

import '../color_identity.dart';
import '../logger.dart';
import 'optimize_runtime_support.dart';
import 'optimize_state_support.dart';

class OptimizeDeckContextData {
  final String deckFormat;
  final List<ResultRow> cardsResult;
  final int currentTotalBeforeMode;
  final int? maxTotalForFormat;
  final bool shouldAutoComplete;
  final String effectiveMode;
  final String deckSignature;
  final String cacheKey;
  final List<String> commanders;
  final List<String> otherCards;
  final List<Map<String, dynamic>> allCardData;
  final Set<String> deckColors;
  final Set<String> commanderColorIdentity;
  final int currentTotalCards;
  final Map<String, int> originalCountsById;
  final Map<String, dynamic> deckAnalysis;
  final DeckThemeProfileResult themeProfile;
  final DeckOptimizationStateResult deckState;
  final String effectiveOptimizeArchetype;

  const OptimizeDeckContextData({
    required this.deckFormat,
    required this.cardsResult,
    required this.currentTotalBeforeMode,
    required this.maxTotalForFormat,
    required this.shouldAutoComplete,
    required this.effectiveMode,
    required this.deckSignature,
    required this.cacheKey,
    required this.commanders,
    required this.otherCards,
    required this.allCardData,
    required this.deckColors,
    required this.commanderColorIdentity,
    required this.currentTotalCards,
    required this.originalCountsById,
    required this.deckAnalysis,
    required this.themeProfile,
    required this.deckState,
    required this.effectiveOptimizeArchetype,
  });
}

Future<OptimizeDeckContextData> loadOptimizeDeckContext({
  required Pool pool,
  required String deckId,
  required String targetArchetype,
  required String requestMode,
  required int? bracket,
  required bool keepTheme,
}) async {
  final deckResult = await pool.execute(
    Sql.named('SELECT name, format FROM decks WHERE id = @id'),
    parameters: {'id': deckId},
  );

  if (deckResult.isEmpty) {
    throw const OptimizeDeckContextException('DECK_NOT_FOUND');
  }

  final deckRow = deckResult[0];
  final deckFormatRaw = deckRow[1] as String?;
  final deckFormat = (deckFormatRaw ?? '').toLowerCase().trim();
  if (deckFormat.isEmpty) {
    throw const OptimizeDeckContextException('DECK_FORMAT_MISSING');
  }

  final cardsResult = await pool.execute(
    Sql.named('''
      SELECT c.name, dc.is_commander, dc.quantity, c.type_line, c.mana_cost, c.colors,
             COALESCE(
               (SELECT SUM(
                 CASE 
                   WHEN m[1] ~ '^[0-9]+\$' THEN m[1]::int
                   WHEN m[1] IN ('W','U','B','R','G','C') THEN 1
                   WHEN m[1] = 'X' THEN 0
                   ELSE 1
                 END
               ) FROM regexp_matches(c.mana_cost, '\\{([^}]+)\\}', 'g') AS m(m)),
               0
             ) as cmc,
             c.oracle_text,
             c.color_identity,
             c.id::text
      FROM deck_cards dc 
      JOIN cards c ON c.id = dc.card_id 
      WHERE dc.deck_id = @id
    '''),
    parameters: {'id': deckId},
  );

  final currentTotalBeforeMode = cardsResult.fold<int>(
    0,
    (sum, row) => sum + ((row[2] as int?) ?? 1),
  );
  final maxTotalForFormat =
      deckFormat == 'commander' ? 100 : (deckFormat == 'brawl' ? 60 : null);
  final shouldAutoComplete =
      maxTotalForFormat != null && currentTotalBeforeMode < maxTotalForFormat;
  final effectiveMode =
      requestMode == 'complete' || shouldAutoComplete ? 'complete' : 'optimize';

  final deckSignature = buildOptimizeDeckSignature(cardsResult);
  final cacheKey = buildOptimizeCacheKey(
    deckId: deckId,
    archetype: targetArchetype,
    mode: effectiveMode,
    bracket: bracket,
    keepTheme: keepTheme,
    deckSignature: deckSignature,
  );

  final commanders = <String>[];
  final otherCards = <String>[];
  final allCardData = <Map<String, dynamic>>[];
  final deckColors = <String>{};
  final commanderColorIdentity = <String>{};
  var currentTotalCards = 0;
  final originalCountsById = <String, int>{};

  for (final row in cardsResult) {
    final name = row[0] as String;
    final isCmdr = row[1] as bool;
    final quantity = (row[2] as int?) ?? 1;
    final typeLine = (row[3] as String?) ?? '';
    final manaCost = (row[4] as String?) ?? '';
    final colors = (row[5] as List?)?.cast<String>() ?? [];
    final cmc = (row[6] as num?)?.toDouble() ?? 0.0;
    final oracleText = (row[7] as String?) ?? '';
    final colorIdentity = (row[8] as List?)?.cast<String>() ?? const <String>[];
    final cardId = row[9] as String;

    currentTotalCards += quantity;
    originalCountsById[cardId] = (originalCountsById[cardId] ?? 0) + quantity;
    deckColors.addAll(colors);

    final cardData = {
      'name': name,
      'type_line': typeLine,
      'mana_cost': manaCost,
      'colors': colors,
      'color_identity': colorIdentity,
      'cmc': cmc,
      'is_commander': isCmdr,
      'oracle_text': oracleText,
      'quantity': quantity,
      'card_id': cardId,
    };
    allCardData.add(cardData);

    if (isCmdr) {
      commanders.add(name);
      commanderColorIdentity.addAll(
        normalizeColorIdentity(
          colorIdentity.isNotEmpty ? colorIdentity : colors,
        ),
      );
    } else {
      final cleanText = oracleText.replaceAll('\n', ' ').trim();
      final truncatedText = cleanText.length > 150
          ? '${cleanText.substring(0, 147)}...'
          : cleanText;

      if (truncatedText.isNotEmpty) {
        otherCards.add('$name (Type: $typeLine, Text: $truncatedText)');
      } else {
        otherCards.add('$name (Type: $typeLine)');
      }
    }
  }

  if (commanderColorIdentity.isEmpty) {
    final inferredFromDeck = normalizeColorIdentity(deckColors.toList());
    if (inferredFromDeck.isNotEmpty) {
      commanderColorIdentity.addAll(inferredFromDeck);
    } else {
      commanderColorIdentity.addAll(const {'W', 'U', 'B', 'R', 'G'});
    }

    final reason = commanders.isNotEmpty
        ? 'commander sem color_identity detectável'
        : 'deck sem is_commander marcado';
    Log.w(
      'Color identity fallback aplicado ($reason) para evitar complete degradado. '
      'commanders=${commanders.join(' | ')} '
      'identity=${commanderColorIdentity.join(',')}',
    );
  }

  final analyzer = DeckArchetypeAnalyzerCore(allCardData, deckColors.toList());
  final deckAnalysis = analyzer.generateAnalysis();
  final themeProfile = await detectThemeProfile(
    allCardData,
    commanders: commanders,
    pool: pool,
  );
  final deckState = assessDeckOptimizationStateCore(
    cards: allCardData,
    deckAnalysis: deckAnalysis,
    deckFormat: deckFormat,
    currentTotalCards: currentTotalCards,
    commanderColorIdentity: commanderColorIdentity,
  );
  final effectiveOptimizeArchetype = resolveOptimizeArchetype(
    requestedArchetype: targetArchetype,
    detectedArchetype: deckAnalysis['detected_archetype']?.toString(),
  );

  return OptimizeDeckContextData(
    deckFormat: deckFormat,
    cardsResult: cardsResult,
    currentTotalBeforeMode: currentTotalBeforeMode,
    maxTotalForFormat: maxTotalForFormat,
    shouldAutoComplete: shouldAutoComplete,
    effectiveMode: effectiveMode,
    deckSignature: deckSignature,
    cacheKey: cacheKey,
    commanders: commanders,
    otherCards: otherCards,
    allCardData: allCardData,
    deckColors: deckColors,
    commanderColorIdentity: commanderColorIdentity,
    currentTotalCards: currentTotalCards,
    originalCountsById: originalCountsById,
    deckAnalysis: deckAnalysis,
    themeProfile: themeProfile,
    deckState: deckState,
    effectiveOptimizeArchetype: effectiveOptimizeArchetype,
  );
}

class OptimizeDeckContextException implements Exception {
  final String code;

  const OptimizeDeckContextException(this.code);
}
