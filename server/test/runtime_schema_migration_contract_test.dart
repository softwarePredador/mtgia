import 'dart:io';

import 'package:test/test.dart';

import '../bin/migrate.dart' as migrate;

void main() {
  group('runtime schema ownership', () {
    test('active request paths do not execute PostgreSQL DDL', () {
      final sources = <String, String>{
        'async generate job store':
            File('lib/ai_generate_job.dart').readAsStringSync(),
        'community engagement service':
            File('lib/community_engagement_service.dart').readAsStringSync(),
        'deck learning support':
            File('lib/ai/deck_learning_event_support.dart').readAsStringSync(),
        'deck create route': File('routes/decks/index.dart').readAsStringSync(),
        'commander reference route':
            File('routes/ai/commander-reference/index.dart').readAsStringSync(),
      };

      for (final entry in sources.entries) {
        final source = entry.value.toLowerCase();
        expect(
          source,
          isNot(contains('create table')),
          reason: '${entry.key} must rely on migrations for tables',
        );
        expect(
          source,
          isNot(contains('create index')),
          reason: '${entry.key} must rely on migrations for indexes',
        );
        expect(
          source,
          isNot(contains('alter table')),
          reason: '${entry.key} must rely on migrations for schema changes',
        );
      }

      expect(
        sources['async generate job store'],
        isNot(contains('_ensureSchema')),
      );
      expect(
        sources['community engagement service'],
        isNot(contains('ensureSchema')),
      );
      expect(
        sources['deck create route'],
        isNot(contains('ensureDeckLearningEventsTable')),
      );
      expect(
        sources['deck create route'],
        isNot(contains('ensureCommanderCardUsageTable')),
      );
      expect(
        sources['commander reference route'],
        isNot(contains('_ensureCommanderProfileCacheTable')),
      );
    });

    test('every removed runtime DDL has a canonical migration owner', () {
      final expectedTablesByMigration = <String, List<String>>{
        '014': const ['ai_generate_jobs'],
        '023': const [
          'commander_learned_decks',
          'deck_learning_events',
          'commander_card_usage',
        ],
        '031': const ['deck_comments', 'content_reports'],
        '034': const [
          'commander_reference_profiles',
          'commander_reference_card_stats',
          'commander_reference_decks',
          'commander_reference_deck_cards',
          'commander_reference_deck_analysis',
        ],
      };

      for (final entry in expectedTablesByMigration.entries) {
        final migration = migrate.migrations.singleWhere(
          (migration) => migration.version == entry.key,
        );
        final up = migration.up.toLowerCase();
        for (final table in entry.value) {
          expect(
            up,
            contains('create table if not exists $table'),
            reason: 'migration ${entry.key} must own $table',
          );
        }
      }
    });
  });
}
