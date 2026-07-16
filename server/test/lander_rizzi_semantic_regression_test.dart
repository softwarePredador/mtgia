import 'package:server/ai/candidate_quality_data_support.dart';
import 'package:server/ai/functional_card_tags.dart';
import 'package:test/test.dart';

const _name = 'Lander Rizzi';
const _typeLine = 'Legendary Artifact Creature — Lander Rogue';
const _manaCost = r'{X}{G}{G}';
const _oracle = '''
When Lander enters, create X lander tokens (They're artifacts with "{2}, {T}, Sacrifice this token: Search you library for a basic land card, put it onto the battlefield tapped, then shuffle.)
Landerfall — Whenever a lander you control enters, put a +1/+1 counter on Lander.
{2}, {T}, Sacrifice Lander: Search you library for a basic land card, put it onto the battlefield tapped, then shuffle.
''';

void main() {
  test('Lander Rizzi is nonland ramp with exact deterministic semantics', () {
    final functional = inferFunctionalCardTags(
      name: _name,
      typeLine: _typeLine,
      oracleText: _oracle,
      manaCost: _manaCost,
      cmc: 2,
    );
    expect(
      functional.map((tag) => tag.tag).toSet(),
      equals({
        'artifact_synergy',
        'engine',
        'etb',
        'payoff',
        'ramp',
        'sacrifice_outlet',
        'token_maker',
      }),
    );

    final candidate = inferCandidateFunctionTags(
      name: _name,
      typeLine: _typeLine,
      oracleText: _oracle,
      manaCost: _manaCost,
    );
    expect(
      candidate.map((tag) => tag.tag).toSet(),
      equals({
        'artifact_synergy',
        'engine',
        'etb',
        'payoff',
        'ramp',
        'sacrifice',
        'sacrifice_outlet',
        'token',
        'token_maker',
      }),
    );

    final roles = buildCandidateRoleScores(
      name: _name,
      typeLine: _typeLine,
      oracleText: _oracle,
      manaCost: _manaCost,
      cmc: 2,
      metaUsageCount: 30,
      metaDeckCount: 5,
    );
    expect(
      {for (final role in roles) role.role: role.score},
      equals({
        'ramp': 80,
        'token': 76,
        'sacrifice': 75,
        'artifact_synergy': 70,
        'engine': 67,
        'etb': 67,
        'payoff': 69,
      }),
    );
    expect(
      roles.singleWhere((role) => role.role == 'ramp').bracketScope,
      'bracket_2_plus',
    );

    final semantic = inferSemanticCardAnalysisV2(
      name: _name,
      typeLine: _typeLine,
      oracleText: _oracle,
      manaCost: _manaCost,
      cmc: 2,
    );
    expect(
      semantic.tags.map((tag) => tag.tag).toSet(),
      equals({
        'artifact_synergy',
        'engine',
        'etb',
        'payoff',
        'ramp',
        'sacrifice_outlet',
        'token_maker',
      }),
    );
    expect(semantic.speed, 'triggered_engine');
    expect(semantic.manaEfficiency, 'cheap');
    expect(semantic.cardAdvantageType, 'board_material');
    expect(semantic.interactionScope, 'none');
    expect(semantic.engine, isTrue);
    expect(semantic.payoff, isTrue);
    expect(semantic.enabler, isTrue);
    expect(semantic.roleConfidence, 0.88);
    expect(semantic.explanationReason, 'mana_acceleration_or_land_search');
    expect(semantic.tags.map((tag) => tag.tag), isNot(contains('land')));
  });
}
