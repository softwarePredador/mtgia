import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/decks/models/deck_analysis.dart';

void main() {
  group('DeckAnalysisData', () {
    test('parses functional_tags counts samples and coverage tolerantly', () {
      final analysis = DeckAnalysisData.fromJson({
        'deck_id': 'deck-1',
        'format': 'commander',
        'stats': {
          'composition': {
            'ramp': '9',
            'draw': 11,
            'removal': 8.2,
            'board_wipes': 2,
            'protection': null,
          },
        },
        'functional_tags': {
          'schema_version': 999,
          'semantic_schema_version': 'semantic_layer_v2_2026_05_18',
          'source': {
            'priority': 'persisted_then_heuristic',
            'persisted_rows': 20,
            'persisted_copies': 24,
            'heuristic_rows': 8,
            'heuristic_copies': 10,
          },
          'counts': {'ramp': 10, 'draw': '12', 'board_wipe': 3},
          'samples': {
            'ramp': ['Sol Ring', 'Arcane Signet', null, 42],
            'draw': [
              {'card_name': 'Skullclamp', 'role': 'draw'},
            ],
          },
          'sample_details': {
            'ramp': [
              {
                'name': 'Arcane Signet',
                'reason': 'Conta como ramp porque acelera mana.',
                'evidence': 'persisted_semantic_v2',
                'tag': 'ramp',
                'confidence': 0.88,
                'semantic_schema_version': 'semantic_layer_v2_2026_05_18',
                'speed': 'board_speed',
                'mana_efficiency': 'cheap',
                'interaction_scope': 'none',
              },
            ],
          },
          'coverage': {
            'card_rows': 80,
            'card_copies': 100,
            'tagged_rows': 45,
            'tagged_copies': 61,
            'other_rows': 35,
            'other_copies': 39,
          },
        },
      });

      expect(analysis.deckId, 'deck-1');
      expect(analysis.countFor(tagKey: 'ramp', compositionKey: 'ramp'), 10);
      expect(
        analysis.countFor(tagKey: 'removal', compositionKey: 'removal'),
        8,
      );
      expect(
        analysis.countFor(tagKey: 'board_wipe', compositionKey: 'board_wipes'),
        3,
      );
      expect(analysis.samplesFor('ramp').map((sample) => sample.name), [
        'Arcane Signet',
      ]);
      expect(analysis.samplesFor('ramp').first.reason, contains('ramp'));
      expect(
        analysis.samplesFor('ramp').first.evidence,
        'persisted_semantic_v2',
      );
      expect(analysis.samplesFor('ramp').first.tag, 'ramp');
      expect(analysis.samplesFor('ramp').first.manaEfficiency, 'cheap');
      expect(analysis.samplesFor('ramp').first.confidence, 0.88);
      expect(analysis.functionalTags?.semanticSchemaVersion, contains('v2'));
      expect(
        analysis.functionalTags?.source?.summary,
        contains('24 persistidas'),
      );
      expect(
        analysis.functionalTags?.coverage.summary,
        '61/100 cópias classificadas',
      );
      expect(analysis.sourceLabel, contains('999'));
    });

    test('parses launch readiness and battle coverage contract', () {
      final analysis = DeckAnalysisData.fromJson({
        'deck_id': 'deck-launch',
        'format': 'commander',
        'stats': {
          'composition': {'ramp': 10},
        },
        'readiness': {
          'schema_version': 'deck_readiness_v1_2026-07-01',
          'status': 'ready_with_warnings',
          'is_commander': true,
          'commander_count': '1',
          'total_cards': 100,
          'error_count': 0,
          'warning_count': 2,
          'blockers': [],
          'next_actions': ['Revisar avisos antes da simulação.'],
          'advanced_intelligence_enabled': 'true',
        },
        'battle_readiness': {
          'schema_version': 'deck_battle_readiness_v1_2026-07-01',
          'status': 'partial_simulation',
          'total_copies': 100,
          'verified_simulation_copies': 62,
          'partial_simulation_copies': 8,
          'pending_adapter_copies': 30,
          'rules_text_only_copies': 0,
          'verified_ratio': '0.62',
          'samples': {
            'verified_simulation': ['Sol Ring'],
            'pending_adapter': ['Complex Card', null],
          },
          'disclaimer': 'Runtime verificado quando existe.',
        },
        'card_battle_readiness': [
          {
            'schema_version': 'card_battle_readiness_v1_2026-07-01',
            'card_id': 'cmdr',
            'name': 'Talrand, Sky Summoner',
            'quantity': 1,
            'is_commander': true,
            'status': 'verified_simulation',
            'status_label': 'Simulação verificada',
            'battle_rule_count': 2,
            'verified_battle_rule_count': 1,
            'source_coverage': {'has_verified_battle_rules': true},
            'detail': '1 regra verificada para battle.',
          },
          {
            'schema_version': 'card_battle_readiness_v1_2026-07-01',
            'card_id': 'complex',
            'name': 'Complex Card',
            'quantity': 1,
            'is_commander': false,
            'status': 'pending_adapter',
            'status_label': 'Adaptador pendente',
            'battle_rule_count': 0,
            'verified_battle_rule_count': 0,
            'source_coverage': {},
            'detail': 'Texto Oracle presente.',
          },
        ],
        'understanding_summary': {
          'schema_version': 'deck_understanding_summary_v1_2026-07-01',
          'source': 'card_intelligence_snapshot',
          'total_copies': 100,
          'functional_tagged_copies': 74,
          'semantic_tagged_copies': 68,
          'verified_battle_rule_copies': 62,
          'functional_coverage_ratio': 0.74,
          'verified_battle_ratio': 0.62,
        },
        'commander_contract': {
          'schema_version': 'commander_contract_summary_v1_2026-07-01',
          'source_version': 'commander_deckbuilding_contract_v2_2026-06-29',
          'status': 'ready_for_battle_gate',
          'status_label': 'Pronto para battle gate',
          'is_commander_applicable': true,
          'commander_name': 'Talrand, Sky Summoner',
          'total_cards': 100,
          'commander_count': 1,
          'summary':
              'Estrutura e fontes suficientes; falta validar em battle gate igualado.',
          'battle_gate': {
            'required': true,
            'status': 'pending',
            'label': 'Pendente',
          },
          'gates': {
            'commander_present': true,
            'validation_valid': true,
            'unresolved_cards_zero': true,
            'has_reference_lane': true,
            'deterministic_reference_ready': true,
          },
          'source_lanes': [
            {
              'key': 'reference_card_stats',
              'label': 'Estatísticas de cartas',
              'available': true,
              'count': '12',
            },
          ],
          'planning_flow': [
            {
              'key': 'commander_intent_and_archetype',
              'label': 'Plano do comandante',
            },
          ],
          'overview_fields': [
            {'key': 'commander_plan_sentence', 'label': 'Frase do plano'},
          ],
          'blockers': [],
          'warnings': ['reference_profile_missing'],
          'next_actions': ['Rodar battle gate igualado.'],
          'disclaimer': 'Plano conservador.',
        },
        'launch_capabilities': {
          'schema_version': 'launch_capabilities_v1_2026-07-01',
          'release_channel': 'beta',
          'flags': {
            'beta_surfaces_enabled': true,
            'card_intelligence_snapshot': true,
          },
          'surfaces': [
            {
              'key': 'deck_analysis',
              'label': 'Análise de deck',
              'enabled': true,
              'stage': 'stable',
              'requires_review': false,
            },
            {
              'key': 'battle_readiness',
              'label': 'Battle readiness',
              'enabled': true,
              'stage': 'beta',
              'requires_review': true,
            },
            {
              'key': 'recommendations',
              'label': 'Recomendações',
              'enabled': true,
              'stage': 'advisory',
              'requires_review': true,
            },
          ],
          'disclaimer': 'Superfícies beta exigem review.',
        },
      });

      expect(analysis.hasLaunchSignals, isTrue);
      expect(analysis.readiness?.statusLabel, 'Pronto com avisos');
      expect(analysis.readiness?.primaryAction, contains('Revisar avisos'));
      expect(analysis.readiness?.advancedIntelligenceEnabled, isTrue);
      expect(analysis.battleReadiness?.statusLabel, 'Simulação parcial');
      expect(analysis.battleReadiness?.verifiedPercentLabel, '62% verificado');
      expect(analysis.battleReadiness?.samples['pending_adapter'], [
        'Complex Card',
      ]);
      expect(analysis.cardBattleReadiness, hasLength(2));
      expect(analysis.cardBattleReadiness.first.isCommander, isTrue);
      expect(
        analysis.cardBattleReadiness.first.safeStatusLabel,
        'Simulação verificada',
      );
      expect(analysis.cardBattleReadiness.last.sourceCoverage, isEmpty);
      expect(
        analysis.understandingSummary?.functionalCoverageLabel,
        '74% classificado',
      );
      expect(
        analysis.understandingSummary?.verifiedBattleLabel,
        '62% simulado',
      );
      expect(analysis.commanderContract?.shouldDisplay, isTrue);
      expect(
        analysis.commanderContract?.safeStatusLabel,
        'Pronto para battle gate',
      );
      expect(analysis.commanderContract?.footerLabel, 'Battle gate: Pendente');
      expect(analysis.commanderContract?.battleGate.required, isTrue);
      expect(analysis.commanderContract?.gates.hasReferenceLane, isTrue);
      expect(analysis.commanderContract?.sourceLanes.first.count, 12);
      expect(
        analysis.commanderContract?.planningFlow.first.label,
        'Plano do comandante',
      );
      expect(analysis.launchCapabilities?.releaseChannel, 'beta');
      expect(
        analysis.launchCapabilities?.visibleBetaSurfaces.map((s) => s.key),
        ['battle_readiness', 'recommendations'],
      );
    });

    test(
      'falls back to legacy stats.composition when functional_tags is absent',
      () {
        final analysis = DeckAnalysisData.fromJson({
          'deck_id': 'deck-legacy',
          'stats': {
            'composition': {
              'ramp': 7,
              'draw': 9,
              'removal': 5,
              'board_wipes': 1,
              'protection': 2,
            },
          },
        });

        expect(analysis.hasFunctionalTags, isFalse);
        expect(analysis.sourceLabel, 'stats.composition legado');
        expect(analysis.samplesFor('ramp'), isEmpty);
        expect(
          analysis.countFor(
            tagKey: 'board_wipe',
            compositionKey: 'board_wipes',
          ),
          1,
        );
      },
    );
  });
}
