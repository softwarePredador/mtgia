import 'dart:io';

import 'package:test/test.dart';

import '../bin/sync_rulings.dart';

void main() {
  group('Scryfall rulings snapshot', () {
    test('parses, deduplicates, and summarizes official bulk rows', () {
      final rows = parseScryfallRulings([
        {
          'oracle_id': '11111111-1111-4111-8111-111111111111',
          'source': 'wotc',
          'published_at': '2025-01-02',
          'comment': ' First ruling. ',
        },
        {
          'oracle_id': '11111111-1111-4111-8111-111111111111',
          'source': 'wotc',
          'published_at': '2025-01-02',
          'comment': 'First ruling.',
        },
        {
          'oracle_id': '22222222-2222-4222-8222-222222222222',
          'source': 'scryfall',
          'published_at': '2026-03-20',
          'comment': 'Second ruling.',
        },
        {
          'oracle_id': '33333333-3333-4333-8333-333333333333',
          'source': 'wotc',
          'published_at': '2024-07-05',
          'comment': '\u00a0',
        },
      ]);

      expect(rows, hasLength(2));
      expect(rows.first.commentHash, hasLength(64));
      final summary = summarizeRulings(rows);
      expect(summary.rowCount, 2);
      expect(summary.distinctOracleIds, 2);
      expect(summary.latestPublishedAt, '2026-03-20');
      expect(
        () => validateRulingsSnapshot(
          summary,
          minimumRows: 2,
          minimumOracleIds: 2,
        ),
        returnsNormally,
      );
    });

    test(
      'fails closed on malformed identity, date, or incomplete snapshot',
      () {
        expect(
          () => parseScryfallRulings([
            {
              'oracle_id': 'printing-id-is-not-an-oracle-id',
              'source': 'wotc',
              'published_at': '2026-03-20',
              'comment': 'Invalid identity.',
            },
          ]),
          throwsFormatException,
        );
        expect(
          () => parseScryfallRulings([
            {
              'oracle_id': '11111111-1111-4111-8111-111111111111',
              'source': 'wotc',
              'published_at': 'not-a-date',
              'comment': 'Invalid date.',
            },
          ]),
          throwsFormatException,
        );
        expect(
          () => validateRulingsSnapshot(
            const RulingsSnapshotSummary(
              rowCount: 1,
              distinctOracleIds: 1,
              latestPublishedAt: '2026-03-20',
            ),
            minimumRows: 2,
            minimumOracleIds: 2,
          ),
          throwsStateError,
        );
      },
    );

    test('requires exact PostgreSQL write approval phrase', () {
      expect(hasRulingsWriteApproval(const {}), isFalse);
      expect(
        hasRulingsWriteApproval(const {rulingsWriteApprovalEnvironment: 'yes'}),
        isFalse,
      );
      expect(
        hasRulingsWriteApproval(const {
          rulingsWriteApprovalEnvironment: rulingsWriteApprovalPhrase,
        }),
        isTrue,
      );
    });

    test('source contract uses Scryfall and atomic managed-source replace', () {
      final source = File('bin/sync_rulings.dart').readAsStringSync();
      final migrations = File('bin/migrate.dart').readAsStringSync();

      expect(source, contains("entry['type'] == 'rulings'"));
      expect(source, contains('CREATE TEMP TABLE incoming_card_rulings'));
      expect(
        source,
        contains(
          "DELETE FROM card_rulings WHERE source IN ('mtgjson', 'scryfall')",
        ),
      );
      expect(source, contains("SELECT oracle_id, 'scryfall'"));
      expect(source, isNot(contains('AtomicCards')));
      expect(migrations, contains("version: '035'"));
      expect(
        migrations,
        contains('CREATE TABLE IF NOT EXISTS data_source_snapshots'),
      );
    });
  });
}
