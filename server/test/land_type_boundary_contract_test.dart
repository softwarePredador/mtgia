import 'dart:io';

import 'package:server/ai/battle_simulator.dart';
import 'package:server/ai/cmc_safety.dart';
import 'package:server/ai/deck_state_analysis.dart';
import 'package:server/ai/meta_insight_role_support.dart';
import 'package:server/basic_land_utils.dart';
import 'package:test/test.dart';

void main() {
  group('standalone Land type boundary', () {
    test('real lands match and Lander/Island substrings do not', () {
      expect(isLandTypeLine('Artifact Land'), isTrue);
      expect(isLandTypeLine('Basic Snow Land — Island'), isTrue);
      expect(
        isLandTypeLine('Legendary Artifact Creature — Lander Rogue'),
        isFalse,
      );
      expect(isLandTypeLine('Creature — Island Fish'), isFalse);
      expect(isLandTypeLine('Nonland permanent'), isFalse);
    });

    test('battle and deck analysis share the same boundary', () {
      final lander = GameCard(
        id: 'lander-rizzi',
        name: 'Lander Rizzi',
        cmc: 3,
        typeLine: 'Legendary Artifact Creature — Lander Rogue',
        oracleText: '{T}: Add one mana of any color.',
        colors: const [],
      );
      expect(lander.isLand, isFalse);
      expect(lander.isCreature, isTrue);

      final card = <String, dynamic>{
        'name': lander.name,
        'type_line': lander.typeLine,
        'cmc': lander.cmc,
        'quantity': 1,
      };
      expect(isLikelyLandCard(card), isFalse);
      expect(
        DeckArchetypeAnalyzer([card], const []).countCardTypes(),
        containsPair('lands', 0),
      );
      expect(
        DeckArchetypeAnalyzer([card], const []).countCardTypes(),
        containsPair('creatures', 1),
      );
    });

    test(
      'meta insight roles use rules metadata, never card-name substrings',
      () {
        expect(
          inferMetaInsightRole(
            typeLine: 'Legendary Artifact Creature — Lander Rogue',
            oracleText: '{T}: Add one mana of any color.',
          ),
          isNot('mana_base'),
        );
        expect(
          inferMetaInsightRole(
            typeLine: 'Creature — Island Fish',
            oracleText: 'Whenever this attacks, draw a card.',
          ),
          isNot('mana_base'),
        );
        expect(
          inferMetaInsightRole(
            typeLine: 'Legendary Land',
            oracleText: '{T}: Add {C}.',
          ),
          'mana_base',
        );
      },
    );

    test('product source does not reintroduce substring land type checks', () {
      final dartFiles = <String>['lib', 'bin', 'routes']
          .expand(
            (root) => Directory(root)
                .listSync(recursive: true)
                .whereType<File>()
                .where((file) => file.path.endsWith('.dart')),
          )
          .toList(growable: false);
      final landSubstring = RegExp(
        r'''\b([A-Za-z_]\w*)\.contains\(\s*(?:'land'|"land")\s*\)''',
      );
      const intentionalNonTypeReceivers = <String, Set<String>>{
        'bin/ramp_family_audit.dart': {'oracle'},
        'lib/archetype_counters_service.dart': {'oracleText'},
        'lib/deck_recommendations_fallback_support.dart': {'oracleText'},
        'lib/ai/battle_simulator.dart': {'text'},
        'lib/ai/commander_learned_deck_support.dart': {'effectiveTags'},
        'lib/ai/edhrec_service.dart': {'lower'},
        'lib/ai/functional_card_tags.dart': {'tags'},
        'lib/ai/optimization_functional_roles.dart': {'o', 'oracle'},
        'lib/ai/optimize_candidate_quality_support.dart': {'normalized'},
        'lib/ai/optimize_functional_role_support.dart': {'oracle'},
        'lib/ai/optimize_state_support.dart': {'oracle', 'commanderOracle'},
      };
      final violations = <String>[];

      for (final file in dartFiles) {
        final source = file.readAsStringSync();
        final allowedReceivers = intentionalNonTypeReceivers[file.path] ?? {};
        for (final match in landSubstring.allMatches(source)) {
          final receiver = match.group(1)!;
          if (allowedReceivers.contains(receiver)) continue;
          final line =
              '\n'.allMatches(source.substring(0, match.start)).length + 1;
          violations.add('${file.path}:$line receiver=$receiver');
        }
        if (RegExp(
          r'''type_line[^\n]*(?:NOT\s+)?I?LIKE\s+['"][^'"]*(?:%land%|%basic%land%|basic land%|basic snow land%|%basic land%)[^'"]*['"]''',
          caseSensitive: false,
        ).hasMatch(source)) {
          violations.add('${file.path}: unsafe SQL type_line LIKE land');
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Land type checks must use isLandTypeLine/boundary SQL',
      );

      final recommendationsSource =
          File(
            'routes/decks/[id]/recommendations/index.dart',
          ).readAsStringSync();
      expect(
        recommendationsSource,
        contains(r"~* '(^|[^[:alpha:]])land([^[:alpha:]]|\$)'"),
      );

      const activePythonLandConsumers = <String>[
        'sync_pg_card_metadata_to_hermes.py',
        'lorehold_canonical_deck_snapshot.py',
        'global_commander_named_land_candidate_pool.py',
        'global_commander_payoff_source_lane_expander.py',
      ];
      final activePythonSources = activePythonLandConsumers.map(
        (name) => MapEntry(
          name,
          File(
            '../docs/hermes-analysis/manaloom-knowledge/scripts/$name',
          ).readAsStringSync(),
        ),
      );
      for (final source in activePythonSources) {
        expect(
          RegExp(
            r'''(?:NOT\s+)?LIKE\s+['"]%land%['"]''',
            caseSensitive: false,
          ).hasMatch(source.value),
          isFalse,
          reason: '${source.key} must use a standalone Land boundary',
        );
        expect(
          RegExp(
            r'''["']land["']\s+in\s+[^\n]*type_line''',
          ).hasMatch(source.value),
          isFalse,
          reason: '${source.key} must not classify type_line by substring',
        );
      }
      final metadataSyncSource = activePythonSources.first.value;
      expect(metadataSyncSource, isNot(contains("NOT LIKE '%land%'")));
      expect(metadataSyncSource, contains("GLOB '*[^a-z]land[^a-z]*'"));
    });
  });
}
