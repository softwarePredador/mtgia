import '../bin/migrate.dart' as migrate;
import 'package:test/test.dart';

void main() {
  group('data model migrations', () {
    test('migration 022 persists aggregate identity and intelligence views',
        () {
      final migration = migrate.migrations.singleWhere(
        (migration) => migration.version == '022',
      );
      final up = migration.up.toLowerCase();

      expect(
        migration.name,
        equals('create_card_identity_and_intelligence_views'),
      );
      expect(up, contains('create table if not exists card_meta_insights'));
      expect(up, contains('create table if not exists card_localized_names'));
      expect(up, contains('create or replace view card_identity_bridge'));
      expect(
        up,
        contains('create or replace view optimize_candidate_quality_summary'),
      );
      expect(up, contains('create or replace view card_intelligence_snapshot'));

      expect(
        up.indexOf('create table if not exists card_meta_insights'),
        lessThan(
            up.indexOf('create or replace view card_intelligence_snapshot')),
      );
      expect(
        up.indexOf('create table if not exists card_localized_names'),
        lessThan(up.indexOf('create or replace view card_identity_bridge')),
      );
      expect(
        up.indexOf('create table if not exists card_function_tags'),
        lessThan(
          up.indexOf(
              'create or replace view optimize_candidate_quality_summary'),
        ),
      );
    });

    test('migration 023 persists commander learning aggregate snapshot', () {
      final migration = migrate.migrations.singleWhere(
        (migration) => migration.version == '023',
      );
      final up = migration.up.toLowerCase();

      expect(
        migration.name,
        equals('create_commander_learning_snapshot'),
      );
      expect(
          up, contains('create table if not exists commander_learned_decks'));
      expect(up, contains('create table if not exists deck_learning_events'));
      expect(up, contains('create table if not exists commander_card_usage'));
      expect(
          up, contains('create or replace view commander_learning_snapshot'));
      expect(
        up.indexOf('create table if not exists commander_learned_decks'),
        lessThan(
          up.indexOf('create or replace view commander_learning_snapshot'),
        ),
      );
      expect(
        up.indexOf('create table if not exists commander_card_usage'),
        lessThan(
          up.indexOf('create or replace view commander_learning_snapshot'),
        ),
      );

      final down = migration.down!.toLowerCase();
      expect(down, contains('drop view if exists commander_learning_snapshot'));
      expect(down, contains('drop table if exists commander_card_usage'));
      expect(down, contains('drop table if exists deck_learning_events'));
      expect(down, contains('drop table if exists commander_learned_decks'));
      expect(down, isNot(contains('commander_card_synergy')));
    });

    test('migration 024 refreshes commander learning snapshot definition', () {
      final migration = migrate.migrations.singleWhere(
        (migration) => migration.version == '024',
      );
      final up = migration.up.toLowerCase();

      expect(
        migration.name,
        equals('refresh_commander_learning_snapshot_bridge_resolution'),
      );
      expect(
          up, contains('create or replace view commander_learning_snapshot'));
      expect(up, contains('bridge_names as'));
      expect(up, contains('card_identity_bridge'));
      expect(up, isNot(contains('left join lateral')));
    });

    test('migration 025 refreshes candidate quality anti-fanout view', () {
      final migration = migrate.migrations.singleWhere(
        (migration) => migration.version == '025',
      );
      final up = migration.up.toLowerCase();

      expect(
        migration.name,
        equals('refresh_optimize_candidate_quality_summary_anti_fanout'),
      );
      expect(
        up,
        contains('create or replace view optimize_candidate_quality_summary'),
      );
      expect(up, contains('with meta_insights as'));
      expect(up, contains('function_tags as'));
      expect(up, contains('role_scores as'));
      expect(up, contains('semantic_v2 as'));
      expect(up, isNot(contains('left join card_function_tags')));
      expect(up, isNot(contains('left join card_semantic_tags_v2')));
      expect(up, isNot(contains('left join card_role_scores')));
    });

    test('migration 026 keeps curated battle rules as the default source', () {
      final migration = migrate.migrations.singleWhere(
        (migration) => migration.version == '026',
      );
      final up = migration.up.toLowerCase();
      final down = migration.down!.toLowerCase();

      expect(
        migration.name,
        equals('default_card_battle_rules_source_curated'),
      );
      expect(up, contains("alter column source set default 'curated'"));
      expect(down, contains("alter column source set default 'manual'"));
    });

    test('migration 027 normalizes legacy handcrafted battle rule provenance',
        () {
      final migration = migrate.migrations.singleWhere(
        (migration) => migration.version == '027',
      );
      final up = migration.up.toLowerCase();
      final down = migration.down!.toLowerCase();

      expect(
        migration.name,
        equals('normalize_legacy_manual_battle_rule_sources'),
      );
      expect(up, contains("source = 'curated'"));
      expect(up, contains("source = 'manual'"));
      expect(up, contains('handcrafted_known_cards'));
      expect(up, contains('legacy handcrafted_known_cards provenance'));
      expect(down, contains("source = 'manual'"));
      expect(down, contains("source = 'curated'"));
    });

    test('migration 028 persists battle rule logical keys', () {
      final migration = migrate.migrations.singleWhere(
        (migration) => migration.version == '028',
      );
      final up = migration.up.toLowerCase();
      final down = migration.down!.toLowerCase();

      expect(
        migration.name,
        equals('persist_card_battle_rules_logical_rule_key'),
      );
      expect(up, contains('add column if not exists logical_rule_key'));
      expect(up, contains('primary key (normalized_name, logical_rule_key)'));
      expect(up, contains('idx_card_battle_rules_normalized_name'));
      expect(up, contains('create or replace view card_intelligence_snapshot'));
      expect(
        up,
        contains('create or replace view optimize_candidate_quality_summary'),
      );
      expect(down, contains('drop column if exists logical_rule_key'));
      expect(down, contains('primary key (normalized_name)'));
    });
  });
}
