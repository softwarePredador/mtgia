import 'package:server/ai/commander_reference_card_stats_support.dart';
import 'package:server/ai/commander_reference_profile_support.dart';
import 'package:test/test.dart';

void main() {
  group('Commander Reference Card Stats v1 | Lorehold', () {
    test('flattens expected packages into normalized, scoreable stats', () {
      final profile = buildLoreholdReferenceProfilePayload(
        updatedAt: DateTime.utc(2026, 5, 11, 12),
      );
      final stats = buildLoreholdReferenceCardStatsFromProfile(
        profile: profile,
        resolvedCardsByName: {
          'sensei\'s divining top': _resolvedCard(
            id: 'top-id',
            name: 'Sensei\'s Divining Top',
          ),
          'primal amulet': _resolvedCard(
            id: 'amulet-id',
            name: 'Primal Amulet // Primal Wellspring',
          ),
        },
      );

      expect(stats, isNotEmpty);
      final top = stats.singleWhere(
        (stat) => stat.cardName == "Sensei's Divining Top",
      );
      expect(top.cardId, equals('top-id'));
      expect(top.packageKey, equals('topdeck_and_miracle_setup'));
      expect(top.role, equals('topdeck_miracle_setup'));
      expect(top.score, greaterThanOrEqualTo(90));
      expect(
          top.confidenceRank,
          greaterThanOrEqualTo(
            commanderReferenceConfidenceRank('medium'),
          ));
      expect(top.unresolved, isFalse);

      final amulet = stats.singleWhere(
        (stat) => stat.cardName == 'Primal Amulet // Primal Wellspring',
      );
      expect(amulet.cardId, equals('amulet-id'));
      expect(amulet.unresolved, isFalse);

      final unresolved = stats.singleWhere(
        (stat) => stat.cardName == 'Scroll Rack',
      );
      expect(unresolved.cardId, isNull);
      expect(unresolved.unresolved, isTrue);
    });

    test('builds deterministic diagnostics and cache versions', () {
      final stats = [
        _stat(
          cardName: "Sensei's Divining Top",
          cardId: 'top-id',
          packageKey: 'topdeck_and_miracle_setup',
          role: 'topdeck_miracle_setup',
          score: 94,
          confidence: 'high',
        ),
        _stat(
          cardName: 'Scroll Rack',
          cardId: 'rack-id',
          packageKey: 'topdeck_and_miracle_setup',
          role: 'topdeck_miracle_setup',
          score: 94,
          confidence: 'high',
        ),
      ];
      final reversed = stats.reversed.toList();

      expect(
        commanderReferenceCardStatsCacheVersion(stats),
        equals(commanderReferenceCardStatsCacheVersion(reversed)),
      );

      final diagnostics = buildCommanderReferenceCardStatsDiagnostics(
        stats: stats,
        unresolvedCardNames: const ['Unresolved Test Card'],
      );
      expect(diagnostics['reference_card_stats_used'], isTrue);
      expect(diagnostics['on_theme_candidate_count'], equals(2));
      expect(
          diagnostics['package_keys'], equals(['topdeck_and_miracle_setup']));
      expect(diagnostics.toString().toLowerCase(), isNot(contains('secret')));
    });

    test('prompt uses stats as guidance without forcing every card', () {
      final prompt = buildCommanderReferenceCardStatsPrompt([
        _stat(
          cardName: "Sensei's Divining Top",
          cardId: 'top-id',
          packageKey: 'topdeck_and_miracle_setup',
          role: 'topdeck_miracle_setup',
          score: 94,
          confidence: 'high',
        ),
      ]);

      expect(prompt, contains('Reference card stats v1 active'));
      expect(prompt, contains("Sensei's Divining Top"));
      expect(prompt, contains('Do not force every card'));
    });

    test('flattens generic commander package stats', () {
      final profile = buildCommanderReferenceProfilePayload(
        commanderName: 'Test Commander',
        version: 'test_profile_v1',
        source: 'manual_reference_profile_v1',
        confidence: 'medium',
        sourceCount: 1,
        colorIdentity: const ['G'],
        themes: const [
          {'name': 'ramp_value', 'confidence': 'medium'}
        ],
        roleTargets: const {},
        expectedPackages: const {
          'ramp_package': ['Cultivate'],
        },
        avoidPatterns: const [],
      );

      final stats = buildCommanderReferenceCardStatsFromProfile(
        profile: profile,
        resolvedCardsByName: {
          'cultivate': _resolvedCard(id: 'cultivate-id', name: 'Cultivate'),
        },
      );

      expect(stats, hasLength(1));
      expect(stats.single.commanderName, equals('Test Commander'));
      expect(stats.single.packageKey, equals('ramp_package'));
      expect(stats.single.role, equals('ramp_package'));
      expect(stats.single.cardId, equals('cultivate-id'));
      expect(buildCommanderReferenceCardStatsPrompt(stats),
          contains('Test Commander'));
    });

    test('evaluator respects generic profile color identity', () {
      final profile = buildCommanderReferenceProfilePayload(
        commanderName: 'Test Commander',
        version: 'test_profile_v1',
        source: 'manual_reference_profile_v1',
        confidence: 'medium',
        sourceCount: 1,
        colorIdentity: const ['G'],
        themes: const [],
        roleTargets: const {},
        expectedPackages: const {},
        avoidPatterns: const [],
      );
      final evaluation = evaluateGeneratedDeckAgainstReferenceStats(
        generatedDeck: {
          'cards': [
            {'name': 'Lightning Bolt', 'quantity': 1},
          ],
        },
        profile: profile,
        stats: const [],
        cardMetadataByName: {
          'lightning bolt': _resolvedCard(
            id: 'bolt-id',
            name: 'Lightning Bolt',
            colorIdentity: const ['R'],
            typeLine: 'Instant',
          ),
        },
      );

      expect(evaluation.counts['off_theme'], equals(1));
      expect(evaluation.classification, equals('off_theme'));
    });

    test('evaluator classifies on-theme, generic, questionable and off-theme',
        () {
      final profile = buildLoreholdReferenceProfilePayload(
        updatedAt: DateTime.utc(2026, 5, 11, 12),
      );
      final evaluation = evaluateGeneratedDeckAgainstReferenceStats(
        generatedDeck: {
          'cards': [
            {'name': "Sensei's Divining Top", 'quantity': 1},
            {'name': 'Sol Ring', 'quantity': 1},
            {'name': 'Plains', 'quantity': 10},
            {'name': 'Temporal Mastery', 'quantity': 1},
            {'name': 'Unknown Haymaker', 'quantity': 1},
          ],
        },
        profile: profile,
        stats: [
          _stat(
            cardName: "Sensei's Divining Top",
            cardId: 'top-id',
            packageKey: 'topdeck_and_miracle_setup',
            role: 'topdeck_miracle_setup',
            score: 94,
            confidence: 'high',
          ),
        ],
        cardMetadataByName: {
          'sol ring': _resolvedCard(
            id: 'sol-ring-id',
            name: 'Sol Ring',
            typeLine: 'Artifact',
            oracleText: 'Add two colorless mana.',
          ),
          'temporal mastery': _resolvedCard(
            id: 'temporal-id',
            name: 'Temporal Mastery',
            colorIdentity: const ['U'],
            typeLine: 'Sorcery',
          ),
        },
      );

      expect(evaluation.counts['on_theme'], equals(1));
      expect(evaluation.counts['generic'], equals(11));
      expect(evaluation.counts['questionable'], equals(1));
      expect(evaluation.counts['off_theme'], equals(1));
      expect(evaluation.classification, equals('off_theme'));
    });

    test('non-Lorehold commander is not a reference stats candidate', () {
      expect(
        isLoreholdCommanderReferenceCandidate('Atraxa, Praetors\' Voice'),
        isFalse,
      );
    });
  });
}

Map<String, dynamic> _resolvedCard({
  required String id,
  required String name,
  List<String> colorIdentity = const [],
  String typeLine = 'Artifact',
  String? oracleText,
}) {
  return {
    'id': id,
    'name': name,
    'type_line': typeLine,
    'color_identity': colorIdentity,
    'colors': colorIdentity,
    'oracle_text': oracleText,
    'mana_cost': '',
  };
}

CommanderReferenceCardStat _stat({
  required String cardName,
  required String cardId,
  required String packageKey,
  required String role,
  required double score,
  required String confidence,
}) {
  return CommanderReferenceCardStat(
    commanderName: loreholdReferenceCommanderName,
    commanderNameNormalized: normalizeCommanderReferenceName(
      loreholdReferenceCommanderName,
    ),
    cardName: cardName,
    cardNameNormalized: normalizeCommanderReferenceCardName(cardName),
    cardId: cardId,
    packageKey: packageKey,
    role: role,
    score: score,
    confidence: confidence,
    confidenceRank: commanderReferenceConfidenceRank(confidence),
    source: loreholdReferenceProfileSource,
    evidenceCount: 4,
    unresolved: false,
  );
}
