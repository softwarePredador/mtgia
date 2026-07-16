import 'package:test/test.dart';
import '../lib/ai/optimization_functional_roles.dart';
import '../lib/ai/optimization_validator.dart';
import '../lib/ai/theme_contextual_rules_service.dart';

void main() {
  group('OptimizationValidator', () {
    late OptimizationValidator validator;

    setUp(() {
      validator = OptimizationValidator(); // Sem API key = sem Critic AI
    });

    test('validate approves when optimization improves consistency', () async {
      // Deck original: mal balanceado (poucos terrenos, CMC alto)
      final originalDeck = [
        ..._makeLands(28), // Poucos terrenos
        ..._makeSpells(72, avgCmc: 4), // CMC alto
      ];

      // Deck otimizado: melhor balanceado
      final optimizedDeck = [
        ..._makeLands(35), // Mais terrenos
        ..._makeSpells(65, avgCmc: 3), // CMC menor
      ];

      final report = await validator.validate(
        originalDeck: originalDeck,
        optimizedDeck: optimizedDeck,
        removals: ['Expensive Spell 1', 'Expensive Spell 2'],
        additions: ['Sol Ring', 'Arcane Signet'],
        commanders: ['Test Commander'],
        archetype: 'midrange',
      );

      expect(report.score, greaterThan(0));
      expect(report.verdict, isNotEmpty);
      expect(report.monteCarlo.before.consistencyScore, isNotNull);
      expect(report.monteCarlo.after.consistencyScore, isNotNull);
      print('Score: ${report.score}, Verdict: ${report.verdict}');
    });

    test('functional analysis detects role preservation', () async {
      final originalDeck = [
        {
          'name': 'Counterspell',
          'type_line': 'Instant',
          'mana_cost': '{U}{U}',
          'oracle_text': 'Counter target spell.',
          'cmc': 2,
          'quantity': 1,
        },
        ..._makeLands(36),
        ..._makeSpells(63, avgCmc: 3),
      ];

      final optimizedDeck = [
        {
          'name': 'Swan Song',
          'type_line': 'Instant',
          'mana_cost': '{U}',
          'oracle_text':
              'Counter target enchantment, instant, or sorcery spell.',
          'cmc': 1,
          'quantity': 1,
        },
        ..._makeLands(36),
        ..._makeSpells(63, avgCmc: 3),
      ];

      final report = await validator.validate(
        originalDeck: originalDeck,
        optimizedDeck: optimizedDeck,
        removals: ['Counterspell'],
        additions: ['Swan Song'],
        commanders: ['Test Commander'],
        archetype: 'control',
      );

      // Removal → Removal = role preserved = upgrade (CMC menor)
      final swap = report.functional.swaps.first;
      expect(swap.removedRole, equals('removal'));
      expect(swap.addedRole, equals('removal'));
      expect(swap.rolePreserved, isTrue);
      expect(swap.verdict, equals('upgrade'));
      print('Swap: ${swap.removed} → ${swap.added} = ${swap.verdict}');
    });

    test(
      'emits additive ramp_floor delta for structural to contextual ramp',
      () async {
        final solRing = {
          'name': 'Sol Ring',
          'type_line': 'Artifact',
          'mana_cost': '{1}',
          'oracle_text': '{T}: Add {C}{C}.',
          'cmc': 1,
          'quantity': 1,
          'functional_tags': const [
            {'tag': 'ramp', 'confidence': 0.99},
          ],
        };
        final rubyMedallion = {
          'name': 'Ruby Medallion',
          'type_line': 'Artifact',
          'mana_cost': '{2}',
          'oracle_text': 'Red spells you cast cost {1} less to cast.',
          'cmc': 2,
          'quantity': 1,
          'functional_tags': const [
            {'tag': 'ramp', 'confidence': 0.99},
          ],
        };
        final originalDeck = [
          solRing,
          ..._makeLands(36),
          ..._makeSpells(63, avgCmc: 3),
        ];
        final optimizedDeck = [
          rubyMedallion,
          ..._makeLands(36),
          ..._makeSpells(63, avgCmc: 3),
        ];

        final report = await validator.validate(
          originalDeck: originalDeck,
          optimizedDeck: optimizedDeck,
          removals: const ['Sol Ring'],
          additions: const ['Ruby Medallion'],
          commanders: const ['Test Commander'],
          archetype: 'midrange',
        );

        expect(report.functional.roleDelta['ramp'], equals(0));
        expect(report.functional.roleDelta['ramp_floor'], equals(-1));
        expect(
          report.functional.toJson()['role_delta'],
          containsPair('ramp_floor', -1),
        );
        expect(report.verdict, isNot(equals('aprovado')));
        expect(
          report.warnings.any((warning) => warning.contains('ramp estrutural')),
          isTrue,
        );
      },
    );

    test('does not penalize contextual to structural ramp upgrade', () async {
      final rubyMedallion = {
        'name': 'Ruby Medallion',
        'type_line': 'Artifact',
        'mana_cost': '{2}',
        'oracle_text': 'Red spells you cast cost {1} less to cast.',
        'cmc': 2,
        'quantity': 1,
        'functional_tags': const [
          {'tag': 'ramp', 'confidence': 0.99},
        ],
      };
      final solRing = {
        'name': 'Sol Ring',
        'type_line': 'Artifact',
        'mana_cost': '{1}',
        'oracle_text': '{T}: Add {C}{C}.',
        'cmc': 1,
        'quantity': 1,
        'functional_tags': const [
          {'tag': 'ramp', 'confidence': 0.99},
        ],
      };
      final originalDeck = [
        rubyMedallion,
        ..._makeLands(36),
        ..._makeSpells(63, avgCmc: 3),
      ];
      final optimizedDeck = [
        solRing,
        ..._makeLands(36),
        ..._makeSpells(63, avgCmc: 3),
      ];

      final report = await validator.validate(
        originalDeck: originalDeck,
        optimizedDeck: optimizedDeck,
        removals: const ['Ruby Medallion'],
        additions: const ['Sol Ring'],
        commanders: const ['Test Commander'],
        archetype: 'midrange',
      );

      expect(report.functional.roleDelta['ramp'], equals(0));
      expect(report.functional.roleDelta['ramp_floor'], equals(1));
      expect(
        report.warnings.any((warning) => warning.contains('ramp estrutural')),
        isFalse,
      );
    });

    test(
      'rejects 34 to 32 land-to-fast-mana canary despite tag overlap',
      () async {
        final turbulentSteppe = {
          'name': 'Turbulent Steppe',
          'type_line': 'Land',
          'mana_cost': '',
          'oracle_text': '{T}: Add {W}.',
          'cmc': 0,
          'quantity': 1,
          'functional_tags': const [
            {'tag': 'land', 'confidence': 0.99},
            {'tag': 'ramp', 'confidence': 0.95},
            {'tag': 'combo_piece', 'confidence': 0.90},
          ],
        };
        final bloodstainedMire = {
          'name': 'Bloodstained Mire',
          'type_line': 'Land',
          'mana_cost': '',
          'oracle_text': '{T}, Pay 1 life, Sacrifice: Search for a land.',
          'cmc': 0,
          'quantity': 1,
          'functional_tags': const [
            {'tag': 'land', 'confidence': 0.99},
            {'tag': 'ramp', 'confidence': 0.95},
            {'tag': 'combo_piece', 'confidence': 0.90},
          ],
        };
        final lotusPetal = {
          'name': 'Lotus Petal',
          'type_line': 'Artifact',
          'mana_cost': '{0}',
          'oracle_text': 'Sacrifice Lotus Petal: Add one mana of any color.',
          'cmc': 0,
          'quantity': 1,
          'functional_tags': const [
            {'tag': 'ramp', 'confidence': 0.99},
            {'tag': 'combo_piece', 'confidence': 0.90},
          ],
        };
        final chromeMox = {
          'name': 'Chrome Mox',
          'type_line': 'Artifact',
          'mana_cost': '{0}',
          'oracle_text': 'Imprint. {T}: Add one mana of an imprinted color.',
          'cmc': 0,
          'quantity': 1,
          'functional_tags': const [
            {'tag': 'ramp', 'confidence': 0.99},
            {'tag': 'combo_piece', 'confidence': 0.90},
          ],
        };
        final originalDeck = [
          ..._makeLands(32),
          turbulentSteppe,
          bloodstainedMire,
          ..._makeSpells(66, avgCmc: 3),
        ];
        final optimizedDeck = [
          ..._makeLands(32),
          lotusPetal,
          chromeMox,
          ..._makeSpells(66, avgCmc: 3),
        ];

        final report = await validator.validate(
          originalDeck: originalDeck,
          optimizedDeck: optimizedDeck,
          removals: const ['Turbulent Steppe', 'Bloodstained Mire'],
          additions: const ['Lotus Petal', 'Chrome Mox'],
          commanders: const ['Lorehold, the Historian'],
          archetype: 'midrange',
        );

        expect(report.functional.swaps, hasLength(2));
        expect(
          report.functional.swaps.every((swap) => !swap.rolePreserved),
          isTrue,
        );
        expect(
          report.functional.swaps.every((swap) => swap.verdict != 'upgrade'),
          isTrue,
        );
        expect(report.functional.roleDelta['land'], equals(-2));
        expect(report.verdict, equals('reprovado'));
        expect(
          report.warnings.any((warning) => warning.contains('perdeu terrenos')),
          isTrue,
        );
      },
    );

    test(
      'theme validation receives final proposal and blocks critical breach',
      () async {
        List<Map<String, dynamic>>? validatedCards;
        final themedValidator = OptimizationValidator(
          themeValidator: ({required archetype, required cards}) async {
            validatedCards = cards;
            return const ThemeValidationResult(
              theme: 'spellslinger',
              hasCriticalViolation: true,
              checks: [
                ThemeCheck(
                  function: 'spell_payoff',
                  current: 2,
                  min: 5,
                  max: 9,
                  priority: 'essential',
                  status: 'below_min',
                  description: 'Preservar payoffs do plano.',
                ),
              ],
            );
          },
        );
        final originalDeck = [..._makeLands(36), ..._makeSpells(64, avgCmc: 3)];
        final optimizedDeck = [
          ..._makeLands(36),
          ..._makeSpells(64, avgCmc: 2),
        ];

        final report = await themedValidator.validate(
          originalDeck: originalDeck,
          optimizedDeck: optimizedDeck,
          removals: const [],
          additions: const [],
          commanders: const ['Test Commander'],
          archetype: 'spellslinger',
        );

        expect(identical(validatedCards, optimizedDeck), isTrue);
        expect(report.themeValidation?.hasCriticalViolation, isTrue);
        expect(report.verdict, equals('reprovado'));
        expect(report.toJson()['theme_validation'], isA<Map>());
      },
    );

    test(
      'functional analysis exposes semantic v2 shadow diagnostics',
      () async {
        final originalDeck = [
          {
            'name': 'Old Ramp Rock',
            'type_line': 'Artifact',
            'mana_cost': '{3}',
            'oracle_text': '{T}: Add {C}.',
            'cmc': 3,
            'quantity': 1,
            'semantic_tags_v2': [
              {
                'tags': ['ramp'],
                'role_confidence': 0.9,
              },
            ],
          },
          ..._makeLands(36),
          ..._makeSpells(63, avgCmc: 3),
        ];

        final optimizedDeck = [
          {
            'name': 'Efficient Draw Spell',
            'type_line': 'Instant',
            'mana_cost': '{1}{U}',
            'oracle_text': 'Draw two cards.',
            'cmc': 2,
            'quantity': 1,
            'semantic_tags_v2': [
              {
                'tags': ['draw'],
                'role_confidence': 0.95,
              },
            ],
          },
          ..._makeLands(36),
          ..._makeSpells(63, avgCmc: 3),
        ];

        final report = await validator.validate(
          originalDeck: originalDeck,
          optimizedDeck: optimizedDeck,
          removals: ['Old Ramp Rock'],
          additions: ['Efficient Draw Spell'],
          commanders: ['Test Commander'],
          archetype: 'control',
        );

        final semantic = report.functional.toJson()['semantic_layer_v2'] as Map;
        expect(semantic['source'], equals('deterministic_semantic_v2'));
        expect(semantic['mode'], equals('shadow'));
        expect(semantic['enforcement'], equals('disabled'));
        expect(semantic['pairs_with_both_semantic_signals'], equals(1));
        expect(semantic['role_delta'], containsPair('ramp', -1));
        expect(semantic['role_delta'], containsPair('draw', 1));
      },
    );

    test(
      'semantic v2 diagnostics preserve secondary multi-tag role losses',
      () async {
        final originalDeck = [
          {
            'name': 'Combo Draw Engine',
            'type_line': 'Artifact',
            'mana_cost': '{3}',
            'oracle_text': '{T}: Draw a card.',
            'cmc': 3,
            'quantity': 1,
            'semantic_tags_v2': [
              {
                'tags': [
                  {'tag': 'draw', 'confidence': 0.93},
                  {'tag': 'engine', 'confidence': 0.9},
                ],
                'role_confidence': 0.94,
              },
            ],
          },
          ..._makeLands(36),
          ..._makeSpells(63, avgCmc: 3),
        ];

        final optimizedDeck = [
          {
            'name': 'Clean Removal',
            'type_line': 'Instant',
            'mana_cost': '{1}{B}',
            'oracle_text': 'Destroy target creature.',
            'cmc': 2,
            'quantity': 1,
            'semantic_tags_v2': [
              {
                'tags': [
                  {'tag': 'removal', 'confidence': 0.95},
                ],
                'role_confidence': 0.95,
              },
            ],
          },
          ..._makeLands(36),
          ..._makeSpells(63, avgCmc: 3),
        ];

        final report = await validator.validate(
          originalDeck: originalDeck,
          optimizedDeck: optimizedDeck,
          removals: const ['Combo Draw Engine'],
          additions: const ['Clean Removal'],
          commanders: const ['Test Commander'],
          archetype: 'midrange',
        );

        final semantic = report.functional.toJson()['semantic_layer_v2'] as Map;
        expect(semantic['role_delta'], containsPair('draw', -1));
        expect(semantic['role_delta'], containsPair('engine', -1));
        expect(semantic['role_delta'], containsPair('removal', 1));
        expect(report.functional.roleDelta['draw'], equals(-1));
        expect(report.functional.roleDelta['engine'], equals(-1));
        expect(report.functional.roleDelta['removal'], equals(1));
      },
    );

    test('semantic diagnostics prefer persisted functional tags before v2', () {
      final semantic = buildOptimizationSemanticV2Diagnostics(
        originalDeck: const [
          {
            'name': 'Persisted Draw Engine',
            'type_line': 'Artifact',
            'mana_cost': '{3}',
            'oracle_text': 'Legacy text with no semantic v2 payload.',
            'cmc': 3,
            'quantity': 1,
            'functional_tags': [
              {'tag': 'draw', 'confidence': 0.95},
              {'tag': 'engine', 'confidence': 0.92},
            ],
          },
        ],
        optimizedDeck: const [
          {
            'name': 'Persisted Ramp Rock',
            'type_line': 'Artifact',
            'mana_cost': '{2}',
            'oracle_text': '{T}: Add one mana of any color.',
            'cmc': 2,
            'quantity': 1,
            'functional_tags': [
              {'tag': 'ramp', 'confidence': 0.91},
            ],
            'semantic_tags_v2': [
              {
                'tags': ['utility'],
                'role_confidence': 0.98,
              },
            ],
          },
        ],
        removals: const ['Persisted Draw Engine'],
        additions: const ['Persisted Ramp Rock'],
      );

      expect(
        semantic['role_source_priority'],
        equals('functional_tags_then_semantic_v2_then_heuristic'),
      );
      expect(
        semantic['role_signal_source_counts'],
        equals(const {'persisted': 2}),
      );
      expect(semantic['role_delta'], containsPair('draw', -1));
      expect(semantic['role_delta'], containsPair('engine', -1));
      expect(semantic['role_delta'], containsPair('ramp', 1));
      expect(semantic['role_delta'], isNot(containsPair('utility', 1)));
    });

    test(
      'semantic v2 enforcement defaults to disabled and is non-blocking',
      () {
        final mode = resolveSemanticV2OptimizeEnforcementMode(null);
        final semantic = buildOptimizationSemanticV2Diagnostics(
          originalDeck: [
            _semanticCard('Old Draw', ['draw']),
          ],
          optimizedDeck: [
            _semanticCard('New Utility', ['utility']),
          ],
          removals: const ['Old Draw'],
          additions: const ['New Utility'],
        );

        final diagnostics = withOptimizationSemanticV2EnforcementDiagnostics(
          semanticLayerV2: semantic,
          mode: mode,
        );

        expect(mode, equals(SemanticV2OptimizeEnforcementMode.disabled));
        expect(resolveSemanticV2OptimizeEnforcementMode(''), equals(mode));
        expect(resolveSemanticV2OptimizeEnforcementMode('full'), equals(mode));
        expect(
          resolveSemanticV2OptimizeEnforcementMode('PARTIAL'),
          equals(SemanticV2OptimizeEnforcementMode.partial),
        );
        expect(resolveSemanticV2ExpandedCriticalRoles(null), isFalse);
        expect(resolveSemanticV2ExpandedCriticalRoles(''), isFalse);
        expect(resolveSemanticV2ExpandedCriticalRoles('true'), isTrue);
        expect(resolveSemanticV2ExpandedCriticalRoles('1'), isTrue);
        expect(diagnostics['mode'], equals('shadow'));
        expect(diagnostics['enforcement'], equals('disabled'));
        expect(diagnostics['enforcement_mode'], equals('disabled'));
        expect(diagnostics['expanded_critical_roles'], isFalse);
        expect(diagnostics['critical_loss_roles'], equals(const ['draw']));
        expect(diagnostics['blocked_by_semantic_v2'], isFalse);
      },
    );

    test('semantic v2 partial blocks critical and contextual role losses', () {
      // Base critical roles (land, draw, removal, ramp, wipe) block by default
      for (final role in const ['land', 'draw', 'removal', 'ramp', 'wipe']) {
        final decision = evaluateOptimizationSemanticV2Enforcement(
          semanticLayerV2: {
            'role_delta': {role: -1},
          },
          mode: SemanticV2OptimizeEnforcementMode.partial,
        );

        expect(decision.criticalLossRoles, equals([role]));
        expect(decision.reviewLossRoles, isEmpty);
        expect(decision.blockedBySemanticV2, isTrue);
      }

      // Expanded critical roles (wincon, combo_piece, engine, payoff, enabler)
      // require expandedCriticalRoles=true to block (default: false = review-only)
      for (final role in const [
        'wincon',
        'combo_piece',
        'engine',
        'payoff',
        'enabler',
      ]) {
        // Default (false): review-only, NOT blocking
        final defaultDecision = evaluateOptimizationSemanticV2Enforcement(
          semanticLayerV2: {
            'role_delta': {role: -1},
          },
          mode: SemanticV2OptimizeEnforcementMode.partial,
        );

        expect(defaultDecision.criticalLossRoles, isEmpty);
        expect(defaultDecision.reviewLossRoles, equals([role]));
        expect(defaultDecision.blockedBySemanticV2, isFalse);

        // With expandedCriticalRoles=true: blocking
        final expandedDecision = evaluateOptimizationSemanticV2Enforcement(
          semanticLayerV2: {
            'role_delta': {role: -1},
          },
          mode: SemanticV2OptimizeEnforcementMode.partial,
          expandedCriticalRoles: true,
        );

        expect(expandedDecision.criticalLossRoles, equals([role]));
        expect(expandedDecision.reviewLossRoles, isEmpty);
        expect(expandedDecision.blockedBySemanticV2, isTrue);
      }
    });

    test('semantic v2 partial keeps protection review-only', () {
      final diagnostics = withOptimizationSemanticV2EnforcementDiagnostics(
        semanticLayerV2: const {
          'role_delta': {'protection': -1},
        },
        mode: SemanticV2OptimizeEnforcementMode.partial,
      );

      expect(diagnostics['critical_loss_roles'], isEmpty);
      expect(diagnostics['review_loss_roles'], equals(const ['protection']));
      expect(diagnostics['blocked_by_semantic_v2'], isFalse);
    });

    test('semantic v2 partial does not block missing semantic signal', () {
      final decision = evaluateOptimizationSemanticV2Enforcement(
        semanticLayerV2: const <String, dynamic>{},
        mode: SemanticV2OptimizeEnforcementMode.partial,
      );

      expect(decision.criticalLossRoles, isEmpty);
      expect(decision.reviewLossRoles, isEmpty);
      expect(decision.blockedBySemanticV2, isFalse);
    });

    test(
      'semantic v2 shadow builder keeps backward-compatible core fields',
      () {
        final semantic = buildOptimizationSemanticV2Diagnostics(
          originalDeck: [
            _semanticCard('Old Protection', ['protection']),
          ],
          optimizedDeck: [
            _semanticCard('New Draw', ['draw']),
          ],
          removals: const ['Old Protection'],
          additions: const ['New Draw'],
        );

        expect(
          semantic['schema_version'],
          equals('semantic_layer_v2_2026_05_18'),
        );
        expect(semantic['source'], equals('deterministic_semantic_v2'));
        expect(semantic['mode'], equals('shadow'));
        expect(semantic['enforcement'], equals('disabled'));
        expect(semantic.containsKey('enforcement_mode'), isFalse);
        expect(semantic['role_delta'], containsPair('protection', -1));
      },
    );

    test('Commander free mulligan keeps first redraw in keep_at_7', () async {
      final deck = [..._makeLands(36), ..._makeSpells(64, avgCmc: 3)];

      final report = await validator.validate(
        originalDeck: deck,
        optimizedDeck: deck, // Same deck = no change
        removals: [],
        additions: [],
        commanders: ['Test Commander'],
        archetype: 'midrange',
      );

      final mulligan = report.monteCarlo.beforeMulligan;
      // Both the initial hand and the first (free) redraw are seven-card keeps.
      // With this deck that moves keep_at_7 above 90%; labeling the free redraw
      // as keep_at_6 leaves it near 80% and fails this regression check.
      expect(mulligan.keepAt7Rate, greaterThan(0.9));
      expect(mulligan.keepAt6Rate, lessThan(0.1));
      expect(
        mulligan.keepAt7Rate +
            mulligan.keepAt6Rate +
            mulligan.keepAt5Rate +
            mulligan.keepAt4OrLessRate,
        closeTo(1, 0.000001),
      );
      expect(mulligan.avgMulligans, lessThan(2.0)); // Average < 2 mulls
      print('Keep@7: ${(mulligan.keepAt7Rate * 100).toStringAsFixed(1)}%');
      print('Avg mulligans: ${mulligan.avgMulligans.toStringAsFixed(2)}');
    });

    test('toJson produces valid JSON structure', () async {
      final deck = [..._makeLands(36), ..._makeSpells(64, avgCmc: 3)];

      final report = await validator.validate(
        originalDeck: deck,
        optimizedDeck: deck,
        removals: [],
        additions: [],
        commanders: ['Test Commander'],
        archetype: 'control',
      );

      final json = report.toJson();
      expect(json['validation_score'], isA<int>());
      expect(json['verdict'], isA<String>());
      expect(json['monte_carlo'], isA<Map>());
      expect(json['functional_analysis'], isA<Map>());
      expect(json['warnings'], isA<List>());
      expect(json.containsKey('critic_ai'), isFalse); // No API key = no critic
    });

    test(
      'approves healthy deck with measurable but incremental upgrade',
      () async {
        final originalDeck = [
          {
            'name': 'Test Commander',
            'type_line': 'Legendary Creature',
            'mana_cost': '{3}{U}',
            'oracle_text': 'Flying.',
            'cmc': 4,
            'quantity': 1,
            'colors': ['U'],
          },
          ..._makeLands(32),
          ...List.generate(
            4,
            (i) => {
              'name': 'Wastes ${i + 1}',
              'type_line': 'Basic Land',
              'mana_cost': '',
              'oracle_text': '{T}: Add {C}.',
              'cmc': 0,
              'quantity': 1,
              'colors': <String>[],
            },
          ),
          {
            'name': 'Clunky Spell 1',
            'type_line': 'Instant',
            'mana_cost': '{4}{U}{U}',
            'oracle_text': 'Counter target spell.',
            'cmc': 6,
            'quantity': 1,
            'colors': ['U'],
          },
          {
            'name': 'Clunky Spell 2',
            'type_line': 'Sorcery',
            'mana_cost': '{4}{U}',
            'oracle_text': 'Draw two cards.',
            'cmc': 5,
            'quantity': 1,
            'colors': ['U'],
          },
          {
            'name': 'Clunky Spell 3',
            'type_line': 'Sorcery',
            'mana_cost': '{5}{U}',
            'oracle_text': 'Draw three cards.',
            'cmc': 5,
            'quantity': 1,
            'colors': ['U'],
          },
          {
            'name': 'Clunky Spell 4',
            'type_line': 'Instant',
            'mana_cost': '{4}{U}',
            'oracle_text': 'Destroy target creature.',
            'cmc': 6,
            'quantity': 1,
            'colors': ['U'],
          },
          ..._makeSpells(59, avgCmc: 3),
        ];

        final optimizedDeck = [
          {
            'name': 'Test Commander',
            'type_line': 'Legendary Creature',
            'mana_cost': '{3}{U}',
            'oracle_text': 'Flying.',
            'cmc': 4,
            'quantity': 1,
            'colors': ['U'],
          },
          ..._makeLands(36),
          {
            'name': 'Brainstorm',
            'type_line': 'Instant',
            'mana_cost': '{U}',
            'oracle_text':
                'Draw three cards, then put two cards from your hand on top of your library in any order.',
            'cmc': 1,
            'quantity': 1,
            'colors': ['U'],
          },
          {
            'name': 'Counterspell',
            'type_line': 'Instant',
            'mana_cost': '{U}{U}',
            'oracle_text': 'Counter target spell.',
            'cmc': 2,
            'quantity': 1,
            'colors': ['U'],
          },
          {
            'name': 'Preordain',
            'type_line': 'Sorcery',
            'mana_cost': '{U}',
            'oracle_text': 'Scry 2, then draw a card.',
            'cmc': 1,
            'quantity': 1,
            'colors': ['U'],
          },
          {
            'name': 'Rapid Hybridization',
            'type_line': 'Instant',
            'mana_cost': '{U}',
            'oracle_text': 'Destroy target creature. It cannot be regenerated.',
            'cmc': 1,
            'quantity': 1,
            'colors': ['U'],
          },
          ..._makeSpells(59, avgCmc: 3),
        ];

        final report = await validator.validate(
          originalDeck: originalDeck,
          optimizedDeck: optimizedDeck,
          removals: const [
            'Wastes 1',
            'Wastes 2',
            'Wastes 3',
            'Wastes 4',
            'Clunky Spell 1',
            'Clunky Spell 2',
            'Clunky Spell 3',
            'Clunky Spell 4',
          ],
          additions: const [
            'Island 33',
            'Island 34',
            'Island 35',
            'Island 36',
            'Brainstorm',
            'Counterspell',
            'Preordain',
            'Rapid Hybridization',
          ],
          commanders: const ['Test Commander'],
          archetype: 'control',
        );

        expect(report.healthScore, greaterThanOrEqualTo(70));
        expect(report.improvementScore, greaterThanOrEqualTo(55));
        expect(report.score, greaterThanOrEqualTo(75));
        expect(report.verdict, equals('aprovado'));
      },
    );

    test('keeps degenerate deck rejected even after cosmetic land swap', () async {
      final originalDeck = [
        {
          'name': 'Talrand, Sky Summoner',
          'type_line': 'Legendary Creature',
          'mana_cost': '{2}{U}{U}',
          'oracle_text':
              'Whenever you cast an instant or sorcery spell, create a 2/2 blue Drake creature token with flying.',
          'cmc': 4,
          'quantity': 1,
          'colors': ['U'],
        },
        {
          'name': 'Wastes',
          'type_line': 'Basic Land',
          'mana_cost': '',
          'oracle_text': '{T}: Add {C}.',
          'cmc': 0,
          'quantity': 99,
          'colors': <String>[],
        },
      ];

      final optimizedDeck = [
        {
          'name': 'Talrand, Sky Summoner',
          'type_line': 'Legendary Creature',
          'mana_cost': '{2}{U}{U}',
          'oracle_text':
              'Whenever you cast an instant or sorcery spell, create a 2/2 blue Drake creature token with flying.',
          'cmc': 4,
          'quantity': 1,
          'colors': ['U'],
        },
        {
          'name': 'Wastes',
          'type_line': 'Basic Land',
          'mana_cost': '',
          'oracle_text': '{T}: Add {C}.',
          'cmc': 0,
          'quantity': 98,
          'colors': <String>[],
        },
        {
          'name': 'Command Tower',
          'type_line': 'Land',
          'mana_cost': '',
          'oracle_text':
              '{T}: Add one mana of any color in your commander\'s color identity.',
          'cmc': 0,
          'quantity': 1,
          'colors': <String>[],
        },
      ];

      final report = await validator.validate(
        originalDeck: originalDeck,
        optimizedDeck: optimizedDeck,
        removals: const ['Wastes'],
        additions: const ['Command Tower'],
        commanders: const ['Talrand, Sky Summoner'],
        archetype: 'control',
      );

      expect(report.healthScore, lessThan(45));
      expect(report.score, lessThan(45));
      expect(report.verdict, equals('reprovado'));
    });
  });
}

Map<String, dynamic> _semanticCard(String name, List<String> tags) => {
  'name': name,
  'type_line': 'Instant',
  'mana_cost': '{1}',
  'oracle_text': 'Test semantic card.',
  'cmc': 1,
  'quantity': 1,
  'semantic_tags_v2': [
    {'tags': tags, 'role_confidence': 0.9},
  ],
};

/// Helper: cria N terrenos básicos
List<Map<String, dynamic>> _makeLands(int count) {
  return List.generate(
    count,
    (i) => {
      'name': 'Island ${i + 1}',
      'type_line': 'Basic Land — Island',
      'mana_cost': '',
      'oracle_text': '{T}: Add {U}.',
      'cmc': 0,
      'quantity': 1,
      'colors': <String>[],
    },
  );
}

/// Helper: cria N spells com CMC médio controlado
List<Map<String, dynamic>> _makeSpells(int count, {int avgCmc = 3}) {
  return List.generate(count, (i) {
    final cmc = (i % 5) + 1; // CMC varia de 1-5
    final adjustedCmc = (cmc * avgCmc / 3).round().clamp(1, 8);
    return {
      'name': 'Spell ${i + 1}',
      'type_line':
          i % 3 == 0
              ? 'Creature — Wizard'
              : (i % 3 == 1 ? 'Instant' : 'Sorcery'),
      'mana_cost': '{${adjustedCmc}}',
      'oracle_text':
          i % 4 == 0
              ? 'Draw a card.'
              : (i % 4 == 1
                  ? 'Destroy target creature.'
                  : 'Target player gains 2 life.'),
      'cmc': adjustedCmc,
      'quantity': 1,
      'colors': ['U'],
    };
  });
}
