import 'package:server/ai/commander_fallback_policy.dart';
import 'package:server/ai/commander_learning_snapshot_support.dart';
import 'package:server/ai/candidate_quality_data_support.dart';
import 'package:test/test.dart';

void main() {
  group('candidate quality deterministic tags', () {
    test('infers core functional tags without AI or card duplication', () {
      final cases = <String, Map<String, dynamic>>{
        'ramp': _card(
          name: 'Arcane Signet',
          typeLine: 'Artifact',
          oracleText:
              '{T}: Add one mana of any color in your commander\'s color identity.',
        ),
        'draw': _card(
          name: 'Chart a Course',
          typeLine: 'Sorcery',
          oracleText:
              'Draw two cards. Then discard a card unless you attacked.',
        ),
        'removal': _card(
          name: 'Swords to Plowshares',
          typeLine: 'Instant',
          oracleText: 'Exile target creature.',
        ),
        'board_wipe': _card(
          name: 'Wrath of God',
          typeLine: 'Sorcery',
          oracleText: 'Destroy all creatures. They can\'t be regenerated.',
        ),
        'protection': _card(
          name: 'Swiftfoot Boots',
          typeLine: 'Artifact - Equipment',
          oracleText: 'Equipped creature has hexproof and haste.',
        ),
        'tutor': _card(
          name: 'Demonic Tutor',
          typeLine: 'Sorcery',
          oracleText: 'Search your library for a card, put it into your hand.',
        ),
        'wincon': _card(
          name: 'Thassa\'s Oracle',
          typeLine: 'Creature',
          oracleText:
              'When this enters, if your devotion is greater than your library, you win the game.',
        ),
        'combo_piece': _card(
          name: 'Isochron Scepter',
          typeLine: 'Artifact',
          oracleText:
              'You may exile an instant card. You may copy the exiled card.',
        ),
        'graveyard': _card(
          name: 'Reanimate',
          typeLine: 'Sorcery',
          oracleText:
              'Put target creature card from a graveyard onto the battlefield under your control.',
        ),
        'token': _card(
          name: 'Dragon Fodder',
          typeLine: 'Sorcery',
          oracleText: 'Create two 1/1 red Goblin creature tokens.',
        ),
        'aristocrats': _card(
          name: 'Blood Artist',
          typeLine: 'Creature',
          oracleText:
              'Whenever Blood Artist or another creature dies, target player loses 1 life and you gain 1 life.',
        ),
        'counterspell': _card(
          name: 'Counterspell',
          typeLine: 'Instant',
          oracleText: 'Counter target spell.',
        ),
      };

      for (final entry in cases.entries) {
        final tags = inferCandidateFunctionTags(
          name: entry.value['name'] as String,
          typeLine: entry.value['type_line'] as String,
          oracleText: entry.value['oracle_text'] as String,
          manaCost: entry.value['mana_cost'] as String,
        ).map((tag) => tag.tag);

        expect(
          tags,
          contains(entry.key),
          reason: entry.value['name'] as String,
        );
      }
    });

    test('does not duplicate land ramp searches as generic tutors', () {
      final tags =
          inferCandidateFunctionTags(
            name: 'Nature\'s Lore',
            typeLine: 'Sorcery',
            oracleText:
                'Search your library for a Forest card, put that card onto the battlefield, then shuffle.',
            manaCost: '{1}{G}',
          ).map((tag) => tag.tag).toSet();

      expect(tags, contains('ramp'));
      expect(tags, isNot(contains('tutor')));
    });

    test('does not classify fetch lands as net mana acceleration', () {
      final tags =
          inferCandidateFunctionTags(
            name: 'Bloodstained Mire',
            typeLine: 'Land',
            oracleText:
                '{T}, Pay 1 life, Sacrifice this land: Search your library for a Swamp or Mountain card, put it onto the battlefield, then shuffle.',
          ).map((tag) => tag.tag).toSet();

      expect(tags, contains('land'));
      expect(tags, isNot(contains('ramp')));
    });

    test('routes nonbasic land locks as stax and protection evidence', () {
      final tags =
          inferCandidateFunctionTags(
            name: 'Back to Basics',
            typeLine: 'Enchantment',
            oracleText:
                "Nonbasic lands don't untap during their controllers' untap steps.",
            manaCost: '{2}{U}',
          ).map((tag) => tag.tag).toSet();

      expect(tags, containsAll({'stax', 'protection'}));
    });

    test('role scores carry budget and bracket suitability metadata', () {
      final scores = buildCandidateRoleScores(
        name: 'Mana Crypt',
        typeLine: 'Artifact',
        oracleText: '{T}: Add {C}{C}.',
        manaCost: '{0}',
        priceUsd: 180,
        priceUsdFoil: null,
        cmc: 0,
        metaUsageCount: 100,
        metaDeckCount: 20,
      );

      expect(scores.map((score) => score.role), contains('ramp'));
      final ramp = scores.firstWhere((score) => score.role == 'ramp');
      expect(ramp.budgetTier, equals('expensive'));
      expect(ramp.bracketScope, equals('bracket_3_4'));
      expect(ramp.score, greaterThanOrEqualTo(70));
    });

    test(
      'role scores use bounded EDHREC inclusion evidence as a ranking signal',
      () {
        final baseline = buildCandidateRoleScores(
          name: 'Arcane Signet',
          typeLine: 'Artifact',
          oracleText:
              '{T}: Add one mana of any color in your commander\'s color identity.',
          manaCost: '{2}',
          priceUsd: 1.5,
          priceUsdFoil: null,
          cmc: 2,
        ).firstWhere((score) => score.role == 'ramp');

        final withEdhrec = buildCandidateRoleScores(
          name: 'Arcane Signet',
          typeLine: 'Artifact',
          oracleText:
              '{T}: Add one mana of any color in your commander\'s color identity.',
          manaCost: '{2}',
          priceUsd: 1.5,
          priceUsdFoil: null,
          cmc: 2,
          edhrecInclusionRate: 0.42,
          edhrecSampleDecks: 4200,
        ).firstWhere((score) => score.role == 'ramp');

        expect(withEdhrec.score, greaterThan(baseline.score));
        expect(withEdhrec.evidence, contains('edhrec_inclusion_rate=0.420'));
        expect(withEdhrec.evidence, contains('edhrec_sample_decks=4200'));
      },
    );

    test('uses versioned high-power and premium name policy', () {
      expect(candidateQualityHighPowerNames, contains('thassa\'s oracle'));
      expect(candidateQualityPremiumNames, contains('sol ring'));
      expect(
        inferCandidateBracketScope(
          name: 'Thassa\'s Oracle',
          role: 'combo_piece',
          score: 30,
          budgetTier: 'accessible',
        ),
        equals('bracket_3_4'),
      );
      expect(isPremiumCommanderCandidateName('Sol Ring'), isTrue);
      expect(isPremiumCommanderCandidateName('Cancel'), isFalse);
    });

    test('schema is additive and targets metadata tables only', () {
      final schema =
          [
            ...candidateQualitySchemaStatements,
            ...candidateQualityIndexStatements,
            optimizeCandidateQualitySummaryViewStatement,
            cardIntelligenceSnapshotViewStatement,
          ].join('\n').toLowerCase();

      expect(schema, contains('create table if not exists card_function_tags'));
      expect(
        schema,
        contains('create table if not exists card_semantic_tags_v2'),
      );
      expect(schema, contains('create table if not exists card_role_scores'));
      expect(
        schema,
        contains('create table if not exists commander_card_synergy'),
      );
      expect(
        schema,
        contains('create table if not exists optimize_rejection_penalties'),
      );
      expect(schema, isNot(contains('insert into cards')));
      expect(schema, isNot(contains('update cards')));
      expect(schema, isNot(contains('delete from cards')));
      expect(schema, isNot(contains('alter table cards')));
      expect(schema, isNot(contains('alter table card_legalities')));
    });

    test('card intelligence snapshot aggregates sources before card joins', () {
      final view = cardIntelligenceSnapshotViewStatement.toLowerCase();

      expect(
        view,
        contains('create or replace view card_intelligence_snapshot'),
      );
      expect(view, contains('c.id as id'));
      expect(view, contains('c.id as card_id'));
      expect(view, contains('c.name as name'));
      expect(view, contains('c.name as card_name'));
      expect(view, contains('c.image_url'));
      expect(view, contains('with function_tags as'));
      expect(view, contains('role_scores as'));
      expect(view, contains('commander_synergy as'));
      expect(view, contains('semantic_v2 as'));
      expect(view, contains('battle_rule_matches as'));
      expect(view, contains('battle_rules as'));
      expect(view, contains('legalities as'));
      expect(view, contains('rulings as'));
      expect(view, contains('group by card_id'));
      expect(view, contains('from battle_rule_matches'));
      expect(view, contains('br.normalized_name in'));
      expect(view, contains('lower(trim(c.name))'));
      expect(view, contains("lower(trim(split_part(c.name, ' // ', 1)))"));
      expect(view, contains('from cards c'));
      expect(view, contains('left join function_tags ft on ft.card_id = c.id'));
      expect(view, contains('left join role_scores rs on rs.card_id = c.id'));
      expect(view, contains('left join battle_rules br on br.card_id = c.id'));
      expect(view, contains('battle_rule_count'));
      expect(view, contains('verified_battle_rules'));
      expect(view, contains("'execution_status', execution_status"));
      expect(view, contains('source_coverage'));

      for (final source in [
        'from card_function_tags',
        'from card_role_scores',
        'from commander_card_synergy',
        'from card_semantic_tags_v2',
        'from card_battle_rules',
        'from card_legalities',
        'from card_rulings',
      ]) {
        expect(
          view,
          contains(source),
          reason: '$source must remain inside an aggregating CTE.',
        );
      }

      expect(view, isNot(contains('left join card_battle_rules')));
      expect(view, isNot(contains('left join card_function_tags')));
      expect(view, isNot(contains('left join card_semantic_tags_v2')));
      expect(view, isNot(contains('left join card_role_scores')));
      expect(view, isNot(contains('left join commander_card_synergy')));
    });

    test('candidate quality summary aggregates multi-row sources first', () {
      final view = optimizeCandidateQualitySummaryViewStatement.toLowerCase();

      expect(
        view,
        contains('create or replace view optimize_candidate_quality_summary'),
      );
      expect(view, contains('with meta_insights as'));
      expect(view, contains('function_tags as'));
      expect(view, contains('role_scores as'));
      expect(view, contains('semantic_v2 as'));
      expect(view, contains('group by card_id'));
      expect(view, contains('from cards c'));
      expect(view, contains('left join function_tags ft on ft.card_id = c.id'));
      expect(view, contains('left join role_scores rs on rs.card_id = c.id'));
      expect(view, contains('left join semantic_v2 sv2 on sv2.card_id = c.id'));
      expect(view, isNot(contains('left join card_function_tags')));
      expect(view, isNot(contains('left join card_semantic_tags_v2')));
      expect(view, isNot(contains('left join card_role_scores')));
    });

    test('commander learning snapshot aggregates safe learning signals', () {
      final view = commanderLearningSnapshotViewStatement.toLowerCase();

      expect(
        view,
        contains('create or replace view commander_learning_snapshot'),
      );
      expect(view, contains('active_learned_decks as'));
      expect(view, contains('usage_summary as'));
      expect(view, contains('synergy_summary as'));
      expect(view, contains('from commander_learned_decks'));
      expect(view, contains('from commander_card_usage'));
      expect(view, contains('from commander_card_synergy'));
      expect(view, contains('card_identity_bridge'));
      expect(view, contains('jsonb_agg'));
      expect(view, contains('metadata_hidden'));
      expect(view, contains('source_coverage'));
      expect(view, contains('partition by ccu.commander_name_normalized'));
      expect(view, contains('partition by ccs.commander_name_normalized'));

      expect(
        view,
        isNot(contains("'metadata'")),
        reason: 'Raw Hermes metadata must not be surfaced in the snapshot.',
      );
      expect(
        view,
        isNot(contains('cld.metadata')),
        reason: 'Raw Hermes metadata must stay hidden from normal consumers.',
      );
      expect(view, isNot(contains('left join card_battle_rules')));
    });
  });
}

Map<String, dynamic> _card({
  required String name,
  required String typeLine,
  required String oracleText,
}) {
  return {
    'name': name,
    'type_line': typeLine,
    'oracle_text': oracleText,
    'mana_cost': '',
  };
}
