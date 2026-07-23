import 'dart:io';

import '../bin/migrate.dart' as migrate;
import 'package:server/sql_statement_splitter.dart';
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
      expect(migrate.hasMigrationLiveApproval(const {}), isFalse);
      expect(
        migrate.hasMigrationLiveApproval(const {
          'MANALOOM_CONFIRM_LIVE_MUTATIONS': 'I_HAVE_EXPLICIT_APPROVAL',
        }),
        isTrue,
      );
    });

    test('protected migration destinations require independent anchors', () {
      expect(
        migrate.migrationDestinationViolation(
          environment: const {
            'ENVIRONMENT': 'production',
            'DB_HOST': 'db.internal',
            'DB_NAME': 'halder',
            'DB_PORT': '5432',
          },
          callerEnvironment: const {},
          writeRequested: true,
        ),
        isNotNull,
      );
      expect(
        migrate.migrationDestinationViolation(
          environment: const {
            'ENVIRONMENT': 'production',
            'DB_HOST': '127.0.0.1',
            'DB_NAME': 'halder',
            'DB_PORT': '49152',
          },
          callerEnvironment: const {
            'MANALOOM_PG_WRAPPER_MODE': 'write-approved',
          },
          writeRequested: true,
        ),
        isNull,
      );
      expect(
        migrate.migrationDestinationViolation(
          environment: const {
            'DB_HOST': '127.0.0.1',
            'DB_NAME': 'local_dev',
            'DB_PORT': '5432',
          },
          callerEnvironment: const {},
          writeRequested: true,
        ),
        isNull,
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
      expect(
        migrate.migrationRollbackPolicy('036'),
        migrate.MigrationRollbackPolicy.manualOnly,
      );
      expect(
        migrate.migrationRollbackPolicy('037'),
        migrate.MigrationRollbackPolicy.manualOnly,
      );
      expect(
        migrate.migrationRollbackPolicy('038'),
        migrate.MigrationRollbackPolicy.manualOnly,
      );
      expect(
        migrate.migrationRollbackPolicy('039'),
        migrate.MigrationRollbackPolicy.manualOnly,
      );
      expect(
        migrate.migrationRollbackPolicy('040'),
        migrate.MigrationRollbackPolicy.manualOnly,
      );
      expect(
        migrate.migrationRollbackPolicy('041'),
        migrate.MigrationRollbackPolicy.manualOnly,
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

    test('migration 038 owns privacy and post-game sync schema', () {
      final migration = migrate.migrations.singleWhere(
        (migration) => migration.version == '038',
      );
      final up = migration.up.toLowerCase();

      expect(
        migration.name,
        equals('add_privacy_and_post_game_sync_contracts'),
      );
      expect(up, contains('alter table users'));
      expect(up, contains('create extension if not exists "pgcrypto"'));
      expect(up, contains('add column if not exists deleted_at'));
      expect(up, contains('add column if not exists play_session_id'));
      expect(up, contains('add column if not exists revision bigint'));
      expect(up, contains('create table if not exists post_game_sync_state'));
      expect(up, contains('set watermark = greatest'));
      expect(
        up,
        contains('create table if not exists account_deletion_receipts'),
      );
      expect(
        up,
        contains('create table if not exists privacy_deleted_deck_tombstones'),
      );
      expect(up, contains('create table if not exists privacy_keyring'));
      expect(up, contains('gen_random_bytes(32)'));
      expect(up, contains('hmac('));
      expect(up, contains('deck_token text not null'));
      expect(up, isNot(contains('deck_id uuid primary key')));
      expect(
        up,
        contains('create or replace function manaloom_require_active_user'),
      );
      expect(up, contains('for update'));
      expect(up, contains('create trigger %i before insert or update of %i'));
      expect(
        up,
        contains(
          'create or replace function manaloom_guard_deck_learning_event',
        ),
      );
      expect(
        up,
        contains('create or replace function manaloom_guard_battle_simulation'),
      );
      expect(up, contains('on delete set null'));
      final statements = splitPostgresStatements(migration.up);
      expect(
        statements.any(
          (statement) =>
              statement.contains('CREATE OR REPLACE FUNCTION') &&
              statement.contains('manaloom_require_active_user') &&
              statement.contains('END;'),
        ),
        isTrue,
      );
      expect(
        statements.any(
          (statement) =>
              statement.contains('DO \$active_user_triggers\$') &&
              statement.contains('END;'),
        ),
        isTrue,
      );
      final down = migration.down!.toLowerCase();
      expect(down, contains('alter column binder_item_id set not null'));
      expect(down, contains('on delete restrict'));
      expect(down, contains('drop table if exists post_game_sync_state'));
      expect(down, contains('drop table if exists privacy_keyring'));
      expect(
        down,
        contains('drop function if exists manaloom_require_active_user'),
      );
      expect(
        down,
        contains('drop function if exists manaloom_guard_deck_learning_event'),
      );
      expect(
        down,
        contains('drop function if exists manaloom_guard_battle_simulation'),
      );
      expect(
        migrate.migrationRollbackPolicy('038'),
        equals(migrate.MigrationRollbackPolicy.manualOnly),
      );
    });

    test('migration 039 persists deck review state and invalidates safely', () {
      final migration = migrate.migrations.singleWhere(
        (migration) => migration.version == '039',
      );
      final up = migration.up.toLowerCase();
      final down = migration.down!.toLowerCase();

      expect(migration.name, equals('persist_deck_validation_review_state'));
      expect(up, contains('add column if not exists validation_state text'));
      expect(up, contains('add column if not exists validation_reasons jsonb'));
      expect(
        up,
        contains(
          'add column if not exists validation_updated_at timestamp with time zone',
        ),
      );
      expect(up, contains('chk_decks_validation_state'));
      expect(up, contains('chk_decks_validation_reasons_array'));
      expect(up, contains('idx_decks_user_validation_state'));
      expect(up, contains('manaloom_mark_deck_cards_changed'));
      expect(up, contains('manaloom_mark_deck_format_changed'));
      expect(up, contains('new.deck_id is distinct from old.deck_id'));
      expect(up, contains('array[old.deck_id, new.deck_id]'));
      expect(up, contains('where id = any(affected_deck_ids)'));
      expect(
        RegExp(
          r'update of\s+deck_id,\s*card_id,\s*quantity,\s*is_commander',
        ).hasMatch(up),
        isTrue,
      );
      expect(
        splitPostgresStatements(migration.up).any(
          (statement) =>
              statement.contains('CREATE OR REPLACE FUNCTION') &&
              statement.contains('manaloom_mark_deck_cards_changed') &&
              statement.contains('RETURN NEW;'),
        ),
        isTrue,
      );
      expect(
        migrate.migrationRollbackPolicy('039'),
        migrate.MigrationRollbackPolicy.manualOnly,
      );
      expect(
        down,
        contains('drop trigger if exists manaloom_deck_cards_require_review'),
      );
      expect(down, contains('drop column if exists validation_state'));
    });

    test('migration 040 aligns cards reserved runtime schema safely', () {
      final migration = migrate.migrations.singleWhere(
        (migration) => migration.version == '040',
      );
      final up = migration.up.toLowerCase();
      final down = migration.down!.toLowerCase();

      expect(migration.name, equals('align_cards_reserved_runtime_schema'));
      expect(
        up,
        contains(
          'add column if not exists is_reserved boolean not null default false',
        ),
      );
      expect(up, contains('set is_reserved = false'));
      expect(up, contains('where is_reserved is null'));
      expect(up, contains('alter column is_reserved set default false'));
      expect(up, contains('alter column is_reserved set not null'));
      expect(down, contains('alter column is_reserved drop not null'));
      expect(down, isNot(contains('drop column')));
      expect(
        migrate.migrationRollbackPolicy('040'),
        migrate.MigrationRollbackPolicy.manualOnly,
      );
    });

    test('migration 041 creates the social runtime schema used by routes', () {
      final migration = migrate.migrations.singleWhere(
        (migration) => migration.version == '041',
      );
      final up = migration.up.toLowerCase();
      final down = migration.down!.toLowerCase();

      expect(
        migration.name,
        equals('create_social_trade_messaging_runtime_schema'),
      );
      for (final table in const [
        'user_binder_items',
        'trade_offers',
        'trade_items',
        'trade_messages',
        'trade_status_history',
        'conversations',
        'direct_messages',
        'notifications',
      ]) {
        expect(up, contains('create table if not exists $table'));
        expect(down, contains('drop table if exists $table'));
      }

      expect(up, contains("list_type in ('have', 'want')"));
      expect(up, contains('uq_user_binder_items_identity'));
      expect(up, contains('on delete set null'));
      expect(up, contains('uq_conversation_participants'));
      expect(up, contains('least(user_a_id, user_b_id)'));
      expect(up, contains('greatest(user_a_id, user_b_id)'));
      expect(up, contains('chk_trade_offers_delivery_method'));
      for (final deliveryMethod in const [
        'correios',
        'motoboy',
        'pessoalmente',
        'outro',
      ]) {
        expect(up, contains("'$deliveryMethod'"));
      }
      expect(up, contains(r'do $active_user_triggers$'));
      expect(up, contains('manaloom_require_active_user'));
      expect(
        migrate.migrationRollbackPolicy('041'),
        migrate.MigrationRollbackPolicy.manualOnly,
      );
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

    test('migration 036 enforces the five Commander brackets', () {
      final migration = migrate.migrations.singleWhere(
        (migration) => migration.version == '036',
      );
      final up = migration.up.toLowerCase();

      expect(up, contains('chk_decks_commander_bracket'));
      expect(up, contains('chk_ai_user_preferences_commander_bracket'));
      expect(up, contains('set bracket = 5'));
      expect(up, contains('set preferred_bracket = 5'));
      expect(up, contains('2026-07-16 16:45:00+00'));
      expect(up, contains('bracket between 1 and 5'));
      expect(up, contains('preferred_bracket between 1 and 5'));
    });

    test('migration 037 replaces capped candidate bracket scopes', () {
      final migration = migrate.migrations.singleWhere(
        (migration) => migration.version == '037',
      );
      final up = migration.up.toLowerCase();

      expect(migration.name, equals('normalize_candidate_bracket_scopes'));
      expect(up, contains('delete from card_role_scores legacy'));
      expect(up, contains("'bracket_2_plus'"));
      expect(up, contains("'bracket_3_plus'"));
      expect(up, contains("'bracket_2_4'"));
      expect(up, contains("'bracket_3_5'"));
    });

    test('migration 046 restores the runtime price history dependency', () {
      final migration = migrate.migrations.singleWhere(
        (migration) => migration.version == '046',
      );
      final up = migration.up.toLowerCase();
      final bootstrap =
          File('database_setup.sql').readAsStringSync().toLowerCase();

      expect(migration.name, equals('restore_price_history_runtime_contract'));
      for (final source in [up, bootstrap]) {
        expect(source, contains('create table if not exists price_history'));
        expect(source, contains('unique(card_id, price_date)'));
        expect(source, contains('idx_price_history_date_card_price'));
        expect(source, contains('include (price_usd)'));
      }
      expect(
        migrate.migrationRollbackPolicy('046'),
        migrate.MigrationRollbackPolicy.manualOnly,
      );
      expect(migration.down, isNot(contains('drop table')));
    });

    test('migration 047 closes deck validation state transitions', () {
      final migration = migrate.migrations.singleWhere(
        (migration) => migration.version == '047',
      );
      final up = migration.up.toLowerCase();
      final bootstrap =
          File('database_setup.sql').readAsStringSync().toLowerCase();

      expect(migration.name, equals('close_deck_validation_state_transitions'));
      for (final source in [up, bootstrap]) {
        expect(source, contains('chk_decks_validation_state_payload'));
        expect(
          source,
          contains("'[\"deck_cards_changed_since_validation\"]'::jsonb"),
        );
        expect(
          source,
          contains("'[\"deck_format_changed_since_validation\"]'::jsonb"),
        );
        expect(
          source,
          isNot(
            contains(
              "else validation_reasons ||\n                 '[\"deck_cards_changed_since_validation\"]'::jsonb",
            ),
          ),
        );
      }
      expect(
        migrate.migrationRollbackPolicy('047'),
        migrate.MigrationRollbackPolicy.manualOnly,
      );
    });

    test('migration 048 closes the async AI job lifecycle', () {
      final migration = migrate.migrations.singleWhere(
        (migration) => migration.version == '048',
      );
      final up = migration.up.toLowerCase();
      final bootstrap =
          File('database_setup.sql').readAsStringSync().toLowerCase();

      expect(migration.name, equals('close_ai_job_lifecycle'));
      for (final source in [up, bootstrap]) {
        expect(source, contains('request_key'));
        expect(source, contains('request_fingerprint'));
        expect(source, contains('cancelled_at'));
        expect(source, contains("'cancelled'"));
        expect(source, contains('idx_ai_generate_jobs_user_request_key'));
        expect(source, contains('idx_ai_optimize_jobs_user_request_key'));
      }
      expect(
        migrate.migrationRollbackPolicy('048'),
        migrate.MigrationRollbackPolicy.manualOnly,
      );
    });

    test('migration 049 preserves binder physical copy identity', () {
      final migration = migrate.migrations.singleWhere(
        (migration) => migration.version == '049',
      );
      final up = migration.up.toLowerCase();
      final bootstrap =
          File('database_setup.sql').readAsStringSync().toLowerCase();

      expect(migration.name, equals('preserve_binder_physical_identity'));
      for (final source in [up, bootstrap]) {
        expect(source, contains('uq_user_binder_items_physical_identity'));
        expect(source, contains('user_id, card_id, condition, is_foil'));
        expect(source, contains('language, list_type'));
        expect(source, contains('chk_user_binder_items_language'));
        expect(source, contains("replace(trim(language), '_', '-')"));
      }
      expect(
        migrate.migrationRollbackPolicy('049'),
        migrate.MigrationRollbackPolicy.manualOnly,
      );
    });

    test('migration 050 canonicalizes price and records provenance', () {
      final migration = migrate.migrations.singleWhere(
        (migration) => migration.version == '050',
      );
      final up = migration.up.toLowerCase();
      final bootstrap =
          File('database_setup.sql').readAsStringSync().toLowerCase();

      expect(migration.name, equals('canonicalize_pricing_provenance'));
      for (final source in [up, bootstrap]) {
        expect(source, contains('price_usd'));
        expect(source, contains('price_source'));
        expect(source, contains('pricing_source'));
        expect(source, contains('chk_cards_price_source'));
      }
      expect(up, contains('set price_usd = price'));
      expect(up, contains("set price_source = 'legacy'"));
      expect(
        migrate.migrationRollbackPolicy('050'),
        migrate.MigrationRollbackPolicy.manualOnly,
      );
    });
  });
}
