import 'dart:io';

import 'package:server/ai/battle_engine_config.dart';
import 'package:server/battle/battle_preflight_service.dart';
import 'package:test/test.dart';

void main() {
  group('BattlePreflightDeck', () {
    test('hash and revision are stable across card order', () {
      final first = _deck();
      final second = _deck(cards: first.cards.reversed.toList());

      expect(first.snapshotHash, second.snapshotHash);
      expect(first.revision, second.revision);
      expect(first.cardCount, 100);
      expect(first.commanderCount, 1);
    });

    test('reports every structural blocker before probing coverage', () {
      final deck = BattlePreflightDeck(
        id: '11111111-1111-4111-8111-111111111111',
        name: 'Invalid',
        format: 'modern',
        validationState: 'unknown',
        validationReasons: const ['validation_not_recorded'],
        validationUpdatedAt: null,
        cards: const [
          {'name': 'Only card', 'quantity': 1, 'is_commander': false},
        ],
      );
      final blockers = battlePreflightDeckBlockers(deck, prefix: 'deck');

      expect(
        blockers,
        containsAll([
          'deck_format_invalid',
          'deck_validation_required',
          'deck_size_invalid',
          'deck_commander_invalid',
        ]),
      );
      expect(shouldProbeBattleCoverage(blockers), isFalse);
      expect(shouldProbeBattleCoverage(const []), isTrue);
    });

    test('opponent inventory query matches the executable admission gate', () {
      final source =
          File('lib/battle/battle_preflight_service.dart').readAsStringSync();
      expect(source, contains('d.deleted_at IS NULL'));
      expect(source, contains("LOWER(d.format) = 'commander'"));
      expect(source, contains("d.validation_state = 'validated'"));
      expect(source, contains('SUM(dc.quantity)'));
      expect(source, contains('dc.is_commander = TRUE'));
    });
  });

  group('BattleCoverageReport', () {
    test('requires a selected engine and no blockers', () {
      expect(
        const BattleCoverageReport(
          engineCoverage: {'xmage': 'ready'},
          blockers: [],
          selectedEngine: 'xmage',
        ).ready,
        isTrue,
      );
      expect(
        const BattleCoverageReport(
          engineCoverage: {'xmage': 'unknown'},
          blockers: ['engine_coverage_unavailable'],
        ).ready,
        isFalse,
      );
    });
  });

  test(
    'strict XMage coverage does not claim Forge or native selection',
    () async {
      final config = BattleEngineConfig.fromEnvironment(const {
        'BATTLE_ENGINE': 'xmage',
        'XMAGE_SIDECAR_URL': 'http://xmage.invalid',
      });

      expect(config.isStrictXmage, isTrue);
      expect(config.isStrictForge, isFalse);
      expect(config.isNative, isFalse);
    },
  );
}

BattlePreflightDeck _deck({List<Map<String, dynamic>>? cards}) {
  final rows =
      cards ??
      [
        {
          'name': 'Commander',
          'set_code': 'TST',
          'collector_number': '1',
          'quantity': 1,
          'is_commander': true,
        },
        {
          'name': 'Plains',
          'set_code': 'TST',
          'collector_number': '2',
          'quantity': 99,
          'is_commander': false,
        },
      ];
  return BattlePreflightDeck(
    id: '11111111-1111-4111-8111-111111111111',
    name: 'Deck',
    format: 'commander',
    validationState: 'validated',
    validationReasons: const [],
    validationUpdatedAt: DateTime.utc(2026, 7, 26),
    cards: rows,
  );
}
