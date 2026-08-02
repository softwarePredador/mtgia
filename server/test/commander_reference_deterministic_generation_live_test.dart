@Tags(['live', 'live_backend'])
library;

import 'dart:convert';
import 'dart:io' show Platform;

import 'package:postgres/postgres.dart';
import 'package:server/ai/commander_reference_card_stats_support.dart';
import 'package:server/ai/commander_reference_deck_corpus_support.dart';
import 'package:server/ai/commander_reference_generate_fallback_support.dart';
import 'package:server/ai/commander_reference_profile_support.dart';
import 'package:server/ai/generate_bracket_support.dart';
import 'package:server/ai/generate_reference_structural_repair_support.dart';
import 'package:server/ai/generate_structural_quality_support.dart';
import 'package:server/generated_deck_validation_service.dart';
import 'package:test/test.dart';

void main() {
  final liveRequested =
      Platform.environment['RUN_LOREHOLD_DETERMINISTIC_GENERATION_LIVE'] == '1';
  final hasDatabaseEnvironment = const [
    'DB_HOST',
    'DB_PORT',
    'DB_NAME',
    'DB_USER',
  ].every((key) => (Platform.environment[key] ?? '').trim().isNotEmpty);
  final skipReason =
      !liveRequested
          ? 'Teste live requer RUN_LOREHOLD_DETERMINISTIC_GENERATION_LIVE=1.'
          : !hasDatabaseEnvironment
          ? 'Teste live requer DB_HOST, DB_PORT, DB_NAME e DB_USER.'
          : null;

  Pool openPool() => Pool.withEndpoints([
    Endpoint(
      host: Platform.environment['DB_HOST']!,
      port: int.parse(Platform.environment['DB_PORT']!),
      database: Platform.environment['DB_NAME']!,
      username: Platform.environment['DB_USER']!,
      password: Platform.environment['DB_PASS'] ?? '',
    ),
  ], settings: const PoolSettings(sslMode: SslMode.disable));

  test(
    'Lorehold deterministic B2 output is legal, structural and on-theme',
    () async {
      final pool = openPool();
      try {
        const commanderName = 'Lorehold, the Historian';
        const prompt =
            'Commander Boros Bracket 2 com Lorehold, the Historian. '
            'Tema Miracle Big Spells, sem Game Changers, fast mana explosiva '
            'ou combos infinitos.';
        final profile = await loadUsableCommanderReferenceProfile(
          pool: pool,
          commanderName: commanderName,
        );
        expect(profile, isNotNull);
        final statsLoad = await loadUsableCommanderReferenceCardStats(
          pool: pool,
          commanderName: commanderName,
        );
        final corpus = await loadCommanderReferenceDeckCorpusGuidance(
          pool: pool,
          commanderName: commanderName,
        );
        final build = buildDeterministicReferenceDeckResult(
          profile: profile!,
          referenceCardStats: statsLoad.stats,
          referenceDeckCorpusGuidance: corpus,
          targetMainQuantity: 99,
          minimumBasicLandQuantity: 36,
          requestedBracket: 2,
        );
        final rawCards = (build.deck['cards'] as List)
            .whereType<Map>()
            .map((card) => card.cast<String, dynamic>())
            .toList(growable: false);
        final validationService = GeneratedDeckValidationService(
          PostgresGeneratedDeckRepository(pool, preferredFormat: 'commander'),
        );
        var validation = await validationService.validate(
          format: 'commander',
          cards: rawCards,
          commanderName: commanderName,
        );

        final repair = await buildCommanderReferenceStructuralRepair(
          pool: pool,
          format: 'commander',
          requestedBracket: 2,
          prompt: prompt,
          commanderName: commanderName,
          resolvedCards: validation.resolvedCards,
          preferredCardNames: statsLoad.stats.map((stat) => stat.cardName),
        );
        expect(repair, isNotNull);
        final repairedCards = (repair!.deck['cards'] as List)
            .whereType<Map>()
            .map((card) => card.cast<String, dynamic>())
            .toList(growable: false);
        validation = await validationService.validate(
          format: 'commander',
          cards: repairedCards,
          commanderName: commanderName,
        );

        expect(
          validation.isValid,
          isTrue,
          reason: validation.errors.join(' | '),
        );
        expect(validation.invalidCards, isEmpty);
        expect(validation.totalResolvedCards, 99);
        expect(repair.diagnostics['target_land_count'], 36);
        final intentCounts =
            (repair.diagnostics['intent_counts'] as Map).cast<String, int>();
        expect(intentCounts['fastMana'] ?? 0, lessThanOrEqualTo(1));
        expect(intentCounts['freeInteraction'] ?? 0, 0);
        expect(intentCounts['extraTurns'] ?? 0, 0);
        expect(intentCounts['infiniteCombo'] ?? 0, 0);
        expect(intentCounts['stax'] ?? 0, 0);

        var body = applyAiGenerateCommanderBracketContract(
          format: 'commander',
          requestedBracket: 2,
          responseBody: {
            'format': 'commander',
            'generated_deck': validation.generatedDeck,
          },
        );
        body = applyAiGenerateCommanderStructuralContract(
          format: 'commander',
          requestedBracket: 2,
          prompt: prompt,
          responseBody: body,
          resolvedCards: validation.resolvedCards,
        );

        expect(aiGenerateCommanderBracketMustReject(body), isFalse);
        expect(
          aiGenerateCommanderStructuralMustReject(body),
          isFalse,
          reason: body['structural_quality'].toString(),
        );
        expect(
          ((body['structural_quality'] as Map)['mana_foundation']
              as Map)['land_count'],
          greaterThanOrEqualTo(36),
        );

        final generatedNames = (validation.generatedDeck['cards'] as List)
            .whereType<Map>()
            .map((card) => card['name']?.toString() ?? '')
            .where((name) => name.isNotEmpty)
            .toList(growable: false);
        final metadata = await loadReferenceEvaluationCardMetadata(
          pool: pool,
          cardNames: generatedNames,
        );
        final theme = evaluateGeneratedDeckAgainstReferenceStats(
          generatedDeck: validation.generatedDeck,
          profile: profile,
          stats: statsLoad.stats,
          cardMetadataByName: metadata,
        );
        expect(theme.counts['on_theme'], greaterThanOrEqualTo(20));
        expect(theme.counts['off_theme'], 0);
      } finally {
        await pool.close();
      }
    },
    skip: skipReason,
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'Lorehold deterministic outputs are playable and differentiated from B1 to B5',
    () async {
      final pool = openPool();
      try {
        const commanderName = 'Lorehold, the Historian';
        const prompt = 'Lorehold Miracle Big Spells';
        final profile = await loadUsableCommanderReferenceProfile(
          pool: pool,
          commanderName: commanderName,
        );
        expect(profile, isNotNull);
        final statsLoad = await loadUsableCommanderReferenceCardStats(
          pool: pool,
          commanderName: commanderName,
        );
        final corpus = await loadCommanderReferenceDeckCorpusGuidance(
          pool: pool,
          commanderName: commanderName,
        );
        final validationService = GeneratedDeckValidationService(
          PostgresGeneratedDeckRepository(pool, preferredFormat: 'commander'),
        );
        final deckMaterialByBracket = <int, String>{};

        for (var bracket = 1; bracket <= 5; bracket += 1) {
          final targetLands = commanderReferenceStructuralTargetLandCount(
            bracket,
          );
          final build = buildDeterministicReferenceDeckResult(
            profile: profile!,
            referenceCardStats: statsLoad.stats,
            referenceDeckCorpusGuidance: corpus,
            targetMainQuantity: 99,
            minimumBasicLandQuantity: targetLands,
            requestedBracket: bracket,
          );
          final rawCards = (build.deck['cards'] as List)
              .whereType<Map>()
              .map((card) => card.cast<String, dynamic>())
              .toList(growable: false);
          final sourceValidation = await validationService.validate(
            format: 'commander',
            cards: rawCards,
            commanderName: commanderName,
          );
          final repair = await buildCommanderReferenceStructuralRepair(
            pool: pool,
            format: 'commander',
            requestedBracket: bracket,
            prompt: prompt,
            commanderName: commanderName,
            resolvedCards: sourceValidation.resolvedCards,
            preferredCardNames: statsLoad.stats.map((stat) => stat.cardName),
          );
          expect(repair, isNotNull, reason: 'B$bracket repair');
          final repairedCards = (repair!.deck['cards'] as List)
              .whereType<Map>()
              .map((card) => card.cast<String, dynamic>())
              .toList(growable: false);
          final validation = await validationService.validate(
            format: 'commander',
            cards: repairedCards,
            commanderName: commanderName,
          );
          expect(validation.isValid, isTrue, reason: 'B$bracket validation');
          expect(validation.invalidCards, isEmpty, reason: 'B$bracket cards');
          expect(validation.totalResolvedCards, 99, reason: 'B$bracket total');

          var body = applyAiGenerateCommanderBracketContract(
            format: 'commander',
            requestedBracket: bracket,
            responseBody: {
              'format': 'commander',
              'generated_deck': validation.generatedDeck,
            },
          );
          body = applyAiGenerateCommanderStructuralContract(
            format: 'commander',
            requestedBracket: bracket,
            prompt: prompt,
            responseBody: body,
            resolvedCards: validation.resolvedCards,
          );
          expect(
            aiGenerateCommanderBracketMustReject(body),
            isFalse,
            reason: 'B$bracket bracket gate',
          );
          expect(
            aiGenerateCommanderStructuralMustReject(body),
            isFalse,
            reason: 'B$bracket structural gate',
          );
          expect(
            ((body['structural_quality'] as Map)['mana_foundation']
                as Map)['land_count'],
            targetLands,
            reason: 'B$bracket land target',
          );
          expect(
            repair.diagnostics['target_archetype'],
            bracket == 5 ? 'combo' : 'midrange',
            reason: 'B$bracket archetype',
          );
          deckMaterialByBracket[bracket] = jsonEncode(validation.generatedDeck);
        }

        expect(deckMaterialByBracket[1], isNot(deckMaterialByBracket[2]));
        expect(deckMaterialByBracket[4], isNot(deckMaterialByBracket[5]));
      } finally {
        await pool.close();
      }
    },
    skip: skipReason,
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
