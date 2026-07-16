import '../bin/migrate.dart' as migrate;
import 'package:test/test.dart';

void main() {
  group('data model migrations', () {
    test('migration apply requires the exact textual PostgreSQL approval', () {
      expect(migrate.hasMigrationWriteApproval(const {}), isFalse);
      expect(
        migrate.hasMigrationWriteApproval(const {
          'MANALOOM_CONFIRM_POSTGRES_WRITES': 'yes',
        }),
        isFalse,
      );
      expect(
        migrate.hasMigrationWriteApproval(const {
          'MANALOOM_CONFIRM_POSTGRES_WRITES': 'I_HAVE_EXPLICIT_APPROVAL',
        }),
        isTrue,
      );
    });

    test('destructive migration rollback policies fail closed', () {
      expect(
        migrate.migrationRollbackPolicy('032'),
        migrate.MigrationRollbackPolicy.standard,
      );
      expect(
        migrate.migrationRollbackPolicy('033'),
        migrate.MigrationRollbackPolicy.emptyOnly,
      );
      expect(
        migrate.migrationRollbackPolicy('034'),
        migrate.MigrationRollbackPolicy.manualOnly,
      );
      expect(
        migrate.migrationRollbackPolicy('035'),
        migrate.MigrationRollbackPolicy.emptyOnly,
      );
    });

    test('migration 014 persists async generation jobs', () {
      final migration = migrate.migrations.singleWhere(
        (migration) => migration.version == '014',
      );
      final up = migration.up.toLowerCase();
      final down = migration.down!.toLowerCase();

      expect(migration.name, equals('create_ai_generate_jobs'));
      expect(up, contains('create table if not exists ai_generate_jobs'));
      expect(up, contains('idx_ai_generate_jobs_user_updated'));
      expect(up, contains('idx_ai_generate_jobs_created'));
      expect(down, contains('drop table if exists ai_generate_jobs'));
    });

    test(
      'migration 022 persists aggregate identity and intelligence views',
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
        expect(
          up,
          contains('create or replace view card_intelligence_snapshot'),
        );

        expect(
          up.indexOf('create table if not exists card_meta_insights'),
          lessThan(
            up.indexOf('create or replace view card_intelligence_snapshot'),
          ),
        );
        expect(
          up.indexOf('create table if not exists card_localized_names'),
          lessThan(up.indexOf('create or replace view card_identity_bridge')),
        );
        expect(
          up.indexOf('create table if not exists card_function_tags'),
          lessThan(
            up.indexOf(
              'create or replace view optimize_candidate_quality_summary',
            ),
          ),
        );
      },
    );

    test('migration 023 persists commander learning aggregate snapshot', () {
      final migration = migrate.migrations.singleWhere(
        (migration) => migration.version == '023',
      );
      final up = migration.up.toLowerCase();

      expect(migration.name, equals('create_commander_learning_snapshot'));
      expect(
        up,
        contains('create table if not exists commander_learned_decks'),
      );
      expect(up, contains('create table if not exists deck_learning_events'));
      expect(up, contains('create table if not exists commander_card_usage'));
      expect(
        up,
        contains('create or replace view commander_learning_snapshot'),
      );
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
        up,
        contains('create or replace view commander_learning_snapshot'),
      );
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

    test(
      'migration 027 normalizes legacy handcrafted battle rule provenance',
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
      },
    );

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

    test('migration 030 persists retention and shareable report tables', () {
      final migration = migrate.migrations.singleWhere(
        (migration) => migration.version == '030',
      );
      final up = migration.up.toLowerCase();
      final down = migration.down!.toLowerCase();

      expect(
        migration.name,
        equals('create_retention_and_shareable_report_tables'),
      );
      expect(up, contains('create table if not exists post_game_notes'));
      expect(up, contains('create table if not exists shared_deck_reports'));
      expect(up, contains('performed_well jsonb'));
      expect(up, contains('payload jsonb not null'));
      expect(up, contains('idx_post_game_notes_deck_created'));
      expect(up, contains('idx_shared_deck_reports_public_updated'));
      expect(down, contains('drop table if exists shared_deck_reports'));
      expect(down, contains('drop table if exists post_game_notes'));
    });

    test(
      'migration 031 persists community engagement and moderation tables',
      () {
        final migration = migrate.migrations.singleWhere(
          (migration) => migration.version == '031',
        );
        final up = migration.up.toLowerCase();
        final down = migration.down!.toLowerCase();

        expect(migration.name, equals('create_community_engagement_tables'));
        expect(up, contains('create table if not exists deck_comments'));
        expect(up, contains('create table if not exists content_reports'));
        expect(up, contains("status in ('visible', 'hidden', 'deleted')"));
        expect(
          up,
          contains(
            "target_type in ('deck', 'comment', 'profile', 'binder_item')",
          ),
        );
        expect(up, contains('idx_deck_comments_deck_created'));
        expect(up, contains('idx_content_reports_target_status'));
        expect(down, contains('drop table if exists content_reports'));
        expect(down, contains('drop table if exists deck_comments'));
      },
    );

    test('migration 032 refreshes card snapshot rule identity fallback', () {
      final migration = migrate.migrations.singleWhere(
        (migration) => migration.version == '032',
      );
      final up = migration.up.toLowerCase();
      final down = migration.down!.toLowerCase();

      expect(
        migration.name,
        equals('refresh_card_intelligence_snapshot_rule_identity_fallback'),
      );
      expect(up, contains('create or replace view card_intelligence_snapshot'));
      expect(up, contains('battle_rule_matches as'));
      expect(up, contains('br.normalized_name in'));
      expect(down, contains('drop view if exists card_intelligence_snapshot'));
    });

    test('migration 033 persists deck optimization events', () {
      final migration = migrate.migrations.singleWhere(
        (migration) => migration.version == '033',
      );
      final up = migration.up.toLowerCase();
      final down = migration.down!.toLowerCase();

      expect(migration.name, equals('create_deck_optimization_events'));
      expect(
        up,
        contains('create table if not exists deck_optimization_events'),
      );
      expect(up, contains('removals jsonb'));
      expect(up, contains('additions jsonb'));
      expect(up, contains('before_snapshot jsonb'));
      expect(up, contains('after_snapshot jsonb'));
      expect(up, contains('battle_status text'));
      expect(up, contains('idx_deck_optimization_events_deck_created'));
      expect(down, contains('drop table if exists deck_optimization_events'));
    });

    test('migration 034 persists the Commander reference data foundation', () {
      final migration = migrate.migrations.singleWhere(
        (migration) => migration.version == '034',
      );
      final up = migration.up.toLowerCase();
      final down = migration.down!.toLowerCase();

      expect(migration.name, equals('create_commander_reference_tables'));
      expect(
        up,
        contains('create table if not exists commander_reference_profiles'),
      );
      expect(
        up,
        contains('create table if not exists commander_reference_card_stats'),
      );
      expect(
        up,
        contains('create table if not exists commander_reference_decks'),
      );
      expect(
        up,
        contains('create table if not exists commander_reference_deck_cards'),
      );
      expect(
        up,
        contains(
          'create table if not exists commander_reference_deck_analysis',
        ),
      );
      expect(up, contains('idx_commander_reference_card_stats_hot'));
      expect(up, contains('idx_commander_reference_decks_lookup'));
      expect(
        down,
        contains('drop table if exists commander_reference_profiles'),
      );
      expect(
        down,
        contains('drop table if exists commander_reference_deck_cards'),
      );
    });

    test('migration 035 persists external snapshot lineage', () {
      final migration = migrate.migrations.singleWhere(
        (migration) => migration.version == '035',
      );
      final up = migration.up.toLowerCase();
      final down = migration.down!.toLowerCase();

      expect(migration.name, equals('create_data_source_snapshots'));
      expect(up, contains('create table if not exists data_source_snapshots'));
      expect(up, contains('content_sha256 text not null'));
      expect(up, contains('distinct_identity_count bigint not null'));
      expect(up, contains('add column if not exists ruling_source text'));
      expect(up, contains('uniq_data_source_snapshots_content'));
      expect(up, contains("alter column source set default 'scryfall'"));
      expect(down, contains('drop table if exists data_source_snapshots'));
      expect(down, contains('drop column if exists ruling_source'));
      expect(down, contains("alter column source set default 'mtgjson'"));
    });
  });
}
