import 'dart:convert';
import 'dart:io';

import 'package:server/ai/commander_spellbook_service.dart';
import 'package:test/test.dart';

import '../bin/sync_combos.dart' as sync;

Map<String, dynamic> variant({
  List<Map<String, dynamic>>? uses,
  List<Map<String, dynamic>> requires = const [],
  String easyPrerequisites = '',
  String notablePrerequisites = '',
}) {
  return {
    'id': 'variant-1',
    'status': 'OK',
    'identity': 'UR',
    'legalities': const {'commander': true},
    'uses':
        uses ??
        [
          {
            'card': {'oracleId': 'card-a', 'name': 'Card A'},
            'quantity': 1,
            'zoneLocations': const ['B'],
            'mustBeCommander': false,
          },
          {
            'card': {'oracleId': 'card-b', 'name': 'Card B'},
            'quantity': 1,
            'zoneLocations': const ['B'],
            'mustBeCommander': false,
          },
        ],
    'requires': requires,
    'produces': const [],
    'easyPrerequisites': easyPrerequisites,
    'notablePrerequisites': notablePrerequisites,
    'manaNeeded': '{1}{U}{R}',
    'description': 'Execute the loop.',
  };
}

void main() {
  group('Commander Spellbook sync parser', () {
    test('marks no requirements as composition-verifiable', () {
      final parsed = sync.parseCommanderSpellbookVariant(variant());

      expect(parsed, isNotNull);
      expect(
        parsed!.prerequisites,
        commanderSpellbookVerifiedNoPrerequisitesMarker,
      );
    });

    test('persists a marker for unmodeled template requirements', () {
      final parsed = sync.parseCommanderSpellbookVariant(
        variant(
          requires: const [
            {
              'template': {'name': 'A creature'},
              'quantity': 1,
            },
          ],
        ),
      );

      expect(parsed, isNotNull);
      expect(
        parsed!.prerequisites,
        contains('unverified_template_requirements:1'),
      );
    });

    test('preserves must-be-commander when a duplicate use strengthens it', () {
      final parsed = sync.parseCommanderSpellbookVariant(
        variant(
          uses: const [
            {
              'card': {'oracleId': 'card-a', 'name': 'Card A'},
              'quantity': 1,
              'zoneLocations': const ['B'],
              'mustBeCommander': false,
            },
            {
              'card': {'oracleId': 'card-a', 'name': 'Card A'},
              'quantity': 1,
              'zoneLocations': const ['B'],
              'mustBeCommander': true,
            },
            {
              'card': {'oracleId': 'card-b', 'name': 'Card B'},
              'quantity': 1,
              'zoneLocations': const ['B'],
              'mustBeCommander': false,
            },
          ],
        ),
      );

      expect(parsed, isNotNull);
      expect(parsed!.oracleIds, ['card-a', 'card-b']);
      expect(parsed.commanderFlags, [true, false]);
      expect(parsed.prerequisites, contains('unverified_card_multiplicity'));
    });

    test('fails closed for quantities and use-state requirements', () {
      final parsed = sync.parseCommanderSpellbookVariant(
        variant(
          uses: const [
            {
              'card': {'oracleId': 'card-a', 'name': 'Card A'},
              'quantity': 2,
              'zoneLocations': ['B'],
              'battlefieldCardState': 'Tapped',
            },
            {
              'card': {'oracleId': 'card-b', 'name': 'Card B'},
              'quantity': 1,
              'zoneLocations': ['B'],
            },
          ],
        ),
      );

      expect(parsed, isNotNull);
      expect(parsed!.prerequisites, contains('unverified_card_multiplicity'));
      expect(
        parsed.prerequisites,
        contains('unverified_use_state_requirements'),
      );
    });

    test('rejects variants not explicitly legal in Commander', () {
      final raw = variant()..['legalities'] = {'commander': false};
      expect(sync.parseCommanderSpellbookVariant(raw), isNull);
    });

    test('requires exact PostgreSQL write approval', () {
      expect(sync.hasComboSyncWriteApproval(const {}), isFalse);
      expect(
        sync.hasComboSyncWriteApproval(const {
          sync.comboSyncWriteApprovalEnvironment: 'yes',
        }),
        isFalse,
      );
      expect(
        sync.hasComboSyncWriteApproval(const {
          sync.comboSyncWriteApprovalEnvironment:
              sync.comboSyncWriteApprovalPhrase,
        }),
        isTrue,
      );
    });

    test('snapshot validation rejects truncation and duplicate IDs', () {
      final first = sync.parseCommanderSpellbookVariant(variant())!;
      expect(
        () =>
            sync.validateCommanderSpellbookSnapshot([first], minimumCombos: 2),
        throwsStateError,
      );
      expect(
        () => sync.validateCommanderSpellbookSnapshot([
          first,
          first,
        ], minimumCombos: 2),
        throwsStateError,
      );
    });

    test(
      'streams the bulk without materializing its full object graph',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'spellbook-stream-test-',
        );
        final file = File('${directory.path}/variants.json');
        try {
          final accepted =
              variant()
                ..['description'] = 'Loop with {braces}, commas, and "quotes".';
          final rejected =
              variant()
                ..['id'] = 'variant-2'
                ..['status'] = 'DRAFT';
          await file.writeAsString(
            jsonEncode({
              'version': '5.6.0',
              'timestamp': '2026-07-15T19:34:32Z',
              'variants': [accepted, rejected],
            }),
          );

          final snapshot = await sync.parseCommanderSpellbookBulk(file);

          expect(snapshot.version, '5.6.0');
          expect(
            snapshot.sourceUpdatedAt,
            DateTime.utc(2026, 7, 15, 19, 34, 32),
          );
          expect(snapshot.rawVariantCount, 2);
          expect(snapshot.skippedVariantCount, 1);
          expect(snapshot.combos.single.id, 'variant-1');
        } finally {
          await directory.delete(recursive: true);
        }
      },
    );

    test('combo tag reconciliation joins canonical oracle_id only', () {
      final source = File('bin/sync_combos.dart').readAsStringSync();

      expect(source, contains('cc.oracle_id = c.oracle_id::text'));
      expect(source, isNot(contains('cc.oracle_id = c.scryfall_id::text')));
      expect(source, contains('incoming_commander_spellbook_combo_ids'));
      expect(source, contains("c.source = 'commander_spellbook'"));
      expect(source, contains('data_source_snapshots'));
      expect(source, isNot(contains('cacheFile.readAsString()')));
    });
  });
}
