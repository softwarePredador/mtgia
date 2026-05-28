import 'package:server/ai/commander_fallback_policy.dart';
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

        expect(tags, contains(entry.key),
            reason: entry.value['name'] as String);
      }
    });

    test('does not duplicate land ramp searches as generic tutors', () {
      final tags = inferCandidateFunctionTags(
        name: 'Nature\'s Lore',
        typeLine: 'Sorcery',
        oracleText:
            'Search your library for a Forest card, put that card onto the battlefield, then shuffle.',
        manaCost: '{1}{G}',
      ).map((tag) => tag.tag).toSet();

      expect(tags, contains('ramp'));
      expect(tags, isNot(contains('tutor')));
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

    test('sample pool SQL keeps legality and color identity guardrails', () {
      final sql = buildCandidateQualitySamplePoolSql().toLowerCase();

      expect(sql, contains('card_legalities'));
      expect(sql, contains("cl.format = 'commander'"));
      expect(sql, contains('cl.status = \'legal\''));
      expect(sql, contains('c.color_identity <@ @identity::text[]'));
      expect(sql, isNot(contains('insert into cards')));
      expect(sql, isNot(contains('update cards')));
    });

    test('schema is additive and targets metadata tables only', () {
      final schema = [
        ...candidateQualitySchemaStatements,
        ...candidateQualityIndexStatements,
        optimizeCandidateQualitySummaryViewStatement,
      ].join('\n').toLowerCase();

      expect(schema, contains('create table if not exists card_function_tags'));
      expect(
          schema, contains('create table if not exists card_semantic_tags_v2'));
      expect(schema, contains('create table if not exists card_role_scores'));
      expect(schema,
          contains('create table if not exists commander_card_synergy'));
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
