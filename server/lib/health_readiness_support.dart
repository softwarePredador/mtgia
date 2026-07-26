import 'dart:convert';
import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:postgres/postgres.dart';

import 'ai/battle_engine_config.dart';
import 'battle/battle_live_cursor_contract.dart';
import 'battle/battle_live_service.dart';
import 'battle/battle_live_source_client.dart';
import 'openai_runtime_config.dart';

class AiRuntimeReadiness {
  const AiRuntimeReadiness({required this.healthy, required this.check});

  final bool healthy;
  final Map<String, dynamic> check;
}

typedef BattleSidecarProbe =
    Future<Map<String, dynamic>?> Function(String engine, Uri healthUri);
typedef BattleLiveSchemaProbe = Future<bool> Function(Pool? pool);

class BattleRuntimeReadiness {
  const BattleRuntimeReadiness({required this.healthy, required this.check});

  final bool healthy;
  final Map<String, dynamic> check;
}

class BattleJobWorkerReadiness {
  const BattleJobWorkerReadiness({required this.healthy, required this.check});

  final bool healthy;
  final Map<String, dynamic> check;
}

class DeckValidationSchemaReadiness {
  const DeckValidationSchemaReadiness({
    required this.healthy,
    required this.check,
  });

  final bool healthy;
  final Map<String, dynamic> check;
}

class AiJobSchemaReadiness {
  const AiJobSchemaReadiness({required this.healthy, required this.check});

  final bool healthy;
  final Map<String, dynamic> check;
}

class BattleJobSchemaReadiness {
  const BattleJobSchemaReadiness({required this.healthy, required this.check});

  final bool healthy;
  final Map<String, dynamic> check;
}

class BattleLiveSpectatorReadiness {
  const BattleLiveSpectatorReadiness({
    required this.healthy,
    required this.check,
  });

  final bool healthy;
  final Map<String, dynamic> check;
}

class CollectionAvailabilitySchemaReadiness {
  const CollectionAvailabilitySchemaReadiness({
    required this.healthy,
    required this.check,
  });

  final bool healthy;
  final Map<String, dynamic> check;
}

class ReleaseSchemaReadiness {
  const ReleaseSchemaReadiness({required this.healthy, required this.check});

  final bool healthy;
  final Map<String, dynamic> check;
}

const requiredReleaseSchemaMigrations = <String, String>{
  '038': 'add_privacy_and_post_game_sync_contracts',
  '039': 'persist_deck_validation_review_state',
  '040': 'align_cards_reserved_runtime_schema',
  '041': 'create_social_trade_messaging_runtime_schema',
  '042': 'create_account_recovery_and_session_revocation',
  '043': 'record_versioned_legal_acceptance',
  '044': 'create_email_verification_gate',
  '045': 'create_collection_availability_contract',
  '046': 'restore_price_history_runtime_contract',
  '047': 'close_deck_validation_state_transitions',
  '048': 'close_ai_job_lifecycle',
  '049': 'preserve_binder_physical_identity',
  '050': 'canonicalize_pricing_provenance',
  '051': 'close_social_safety_contract',
  '052': 'version_battle_simulation_attempts',
  '053': 'create_battle_replay_annotations',
  '054': 'create_battle_jobs',
  '055': 'create_battle_job_live_records',
};

const releaseSchemaReadinessSql = '''
  WITH required_migrations(version, name) AS (
    VALUES
      ('038', 'add_privacy_and_post_game_sync_contracts'),
      ('039', 'persist_deck_validation_review_state'),
      ('040', 'align_cards_reserved_runtime_schema'),
      ('041', 'create_social_trade_messaging_runtime_schema'),
      ('042', 'create_account_recovery_and_session_revocation'),
      ('043', 'record_versioned_legal_acceptance'),
      ('044', 'create_email_verification_gate'),
      ('045', 'create_collection_availability_contract'),
      ('046', 'restore_price_history_runtime_contract'),
      ('047', 'close_deck_validation_state_transitions'),
      ('048', 'close_ai_job_lifecycle'),
      ('049', 'preserve_binder_physical_identity'),
      ('050', 'canonicalize_pricing_provenance'),
      ('051', 'close_social_safety_contract'),
      ('052', 'version_battle_simulation_attempts'),
      ('053', 'create_battle_replay_annotations'),
      ('054', 'create_battle_jobs'),
      ('055', 'create_battle_job_live_records')
  )
  SELECT
    (
      SELECT COUNT(*) = 18
      FROM required_migrations required
      JOIN public.schema_migrations actual
        ON actual.version = required.version
       AND actual.name = required.name
    ) AS required_migrations_registered,
    COALESCE(
      (SELECT MAX(version) FROM public.schema_migrations),
      ''
    ) = '055' AS latest_migration_ready,
    (
      SELECT COUNT(*)
      FROM pg_class
      WHERE oid IN (
        to_regclass('public.user_binder_items'),
        to_regclass('public.trade_offers'),
        to_regclass('public.trade_items'),
        to_regclass('public.trade_messages'),
        to_regclass('public.trade_status_history'),
        to_regclass('public.conversations'),
        to_regclass('public.direct_messages'),
        to_regclass('public.notifications'),
        to_regclass('public.password_reset_tokens'),
        to_regclass('public.email_verification_tokens'),
        to_regclass('public.price_history')
      )
        AND relkind IN ('r', 'p')
    ) = 11 AS release_runtime_tables_ready,
    (
      SELECT COUNT(*)
      FROM (
        VALUES
          ('users', 'auth_version'),
          ('users', 'password_changed_at'),
          ('users', 'terms_version'),
          ('users', 'terms_accepted_at'),
          ('users', 'privacy_version'),
          ('users', 'privacy_accepted_at'),
          ('users', 'email_verified_at')
      ) AS required(table_name, column_name)
      WHERE EXISTS (
        SELECT 1
        FROM information_schema.columns actual
        WHERE actual.table_schema = 'public'
          AND actual.table_name = required.table_name
          AND actual.column_name = required.column_name
      )
    ) = 7 AS account_columns_ready,
    (
      SELECT COUNT(*)
      FROM pg_constraint
      WHERE conrelid = to_regclass('public.users')
        AND conname IN (
          'chk_users_terms_acceptance_pair',
          'chk_users_privacy_acceptance_pair'
        )
        AND convalidated
    ) = 2 AS legal_constraints_ready,
    (
      SELECT COUNT(*)
      FROM pg_class
      WHERE oid IN (
        to_regclass('public.collection_availability_snapshot'),
        to_regclass('public.binder_item_availability')
      )
        AND relkind = 'v'
    ) = 2 AS collection_views_ready,
    (
      (
        SELECT COUNT(*)
        FROM pg_index
        WHERE indexrelid IN (
          to_regclass('public.idx_price_history_date'),
          to_regclass('public.idx_price_history_card_date'),
          to_regclass('public.idx_price_history_date_card_price'),
          to_regclass('public.idx_cards_price_usd')
        )
          AND indisvalid
          AND indisready
      ) = 4
      AND (
        SELECT COUNT(*)
        FROM (
          VALUES
            ('cards', 'price_usd'),
            ('cards', 'price_usd_foil'),
            ('cards', 'price_source'),
            ('decks', 'pricing_source')
        ) AS required(table_name, column_name)
        WHERE EXISTS (
          SELECT 1
          FROM information_schema.columns actual
          WHERE actual.table_schema = 'public'
            AND actual.table_name = required.table_name
            AND actual.column_name = required.column_name
        )
      ) = 4
      AND EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conrelid = to_regclass('public.cards')
          AND conname = 'chk_cards_price_source'
          AND convalidated
      )
    ) AS pricing_contract_ready,
    (
      SELECT COUNT(*)
      FROM pg_class
      WHERE oid IN (
        to_regclass('public.user_blocks'),
        to_regclass('public.user_block_events'),
        to_regclass('public.moderation_actions'),
        to_regclass('public.content_report_appeals')
      )
        AND relkind IN ('r', 'p')
    ) = 4 AS social_safety_tables_ready,
    (
      SELECT COUNT(*)
      FROM (
        VALUES
          ('users', 'profile_visibility'),
          ('users', 'binder_visibility'),
          ('users', 'location_visibility'),
          ('users', 'message_visibility'),
          ('users', 'trade_visibility'),
          ('users', 'trade_notes_visibility'),
          ('direct_messages', 'client_request_id'),
          ('direct_messages', 'moderation_status'),
          ('trade_messages', 'client_request_id'),
          ('trade_messages', 'moderation_status'),
          ('content_reports', 'priority'),
          ('content_reports', 'evidence'),
          ('content_reports', 'sla_due_at'),
          ('content_reports', 'resolution'),
          ('content_reports', 'resolution_action'),
          ('content_reports', 'updated_at')
      ) AS required(table_name, column_name)
      WHERE EXISTS (
        SELECT 1
        FROM information_schema.columns actual
        WHERE actual.table_schema = 'public'
          AND actual.table_name = required.table_name
          AND actual.column_name = required.column_name
      )
    ) = 16 AS social_safety_columns_ready,
    (
      SELECT COUNT(*)
      FROM pg_constraint
      WHERE conname IN (
        'chk_users_profile_visibility',
        'chk_users_binder_visibility',
        'chk_users_location_visibility',
        'chk_users_message_visibility',
        'chk_users_trade_visibility',
        'chk_users_trade_notes_visibility',
        'chk_direct_messages_moderation_status',
        'chk_trade_messages_moderation_status',
        'chk_content_reports_target_type',
        'chk_content_reports_status',
        'chk_content_reports_priority',
        'chk_content_reports_resolution_action'
      )
        AND convalidated
    ) = 12 AS social_safety_constraints_ready,
    (
      SELECT COUNT(*)
      FROM pg_index
      WHERE indexrelid IN (
        to_regclass('public.idx_user_blocks_blocked'),
        to_regclass('public.idx_user_block_events_actor_created'),
        to_regclass('public.uq_direct_messages_sender_request'),
        to_regclass('public.uq_trade_messages_sender_request'),
        to_regclass('public.idx_content_reports_queue'),
        to_regclass('public.uq_content_reports_active_reporter_target'),
        to_regclass('public.idx_moderation_actions_report_created'),
        to_regclass('public.uq_content_report_appeals_pending'),
        to_regclass('public.idx_content_report_appeals_queue')
      )
        AND indisvalid
        AND indisready
    ) = 9 AS social_safety_indexes_ready,
    (
      to_regclass('public.battle_simulation_attempts') IS NOT NULL
      AND (
        SELECT COUNT(*)
        FROM (
          VALUES
            ('outcome'),
            ('replay_id'),
            ('test_objective'),
            ('request_schema_version'),
            ('request_hash'),
            ('job_request_schema_version'),
            ('job_request_hash'),
            ('engine_request_correlation_source'),
            ('deck_hash_schema'),
            ('deck_a_hash'),
            ('deck_b_hash'),
            ('engine_process_id'),
            ('timeout_ms'),
            ('events_truncated'),
            ('snapshots_truncated')
        ) AS required(column_name)
        WHERE EXISTS (
          SELECT 1
          FROM information_schema.columns actual
          WHERE actual.table_schema = 'public'
            AND actual.table_name = 'battle_simulation_attempts'
            AND actual.column_name = required.column_name
        )
      ) = 15
      AND (
        SELECT COUNT(*)
        FROM pg_constraint
        WHERE conrelid = to_regclass('public.battle_simulation_attempts')
          AND conname IN (
            'chk_battle_attempt_outcome',
            'chk_battle_attempt_test_objective',
            'chk_battle_attempt_lifecycle',
            'chk_battle_attempt_job_request_hash',
            'chk_battle_attempt_request_correlation'
          )
          AND convalidated
      ) = 5
    ) AS battle_attempt_contract_ready,
    (
      to_regclass('public.battle_replay_annotations') IS NOT NULL
      AND (
        SELECT COUNT(*)
        FROM (
          VALUES
            ('user_id'),
            ('replay_id'),
            ('attempt_id'),
            ('subject_deck_id'),
            ('subject_deck_key'),
            ('deck_hash_schema'),
            ('subject_deck_hash'),
            ('subject_deck_revision'),
            ('event_ref'),
            ('snapshot_ref'),
            ('kind'),
            ('payload'),
            ('idempotency_key'),
            ('request_fingerprint'),
            ('created_at'),
            ('updated_at')
        ) AS required(column_name)
        WHERE EXISTS (
          SELECT 1
          FROM information_schema.columns actual
          WHERE actual.table_schema = 'public'
            AND actual.table_name = 'battle_replay_annotations'
            AND actual.column_name = required.column_name
        )
      ) = 16
      AND (
        SELECT COUNT(*)
        FROM pg_constraint
        WHERE conrelid = to_regclass('public.battle_replay_annotations')
          AND conname IN (
            'fk_battle_annotation_attempt_replay',
            'chk_battle_annotation_subject',
            'chk_battle_annotation_hash',
            'chk_battle_annotation_revision',
            'chk_battle_annotation_kind',
            'chk_battle_annotation_event_ref',
            'chk_battle_annotation_snapshot_ref',
            'chk_battle_annotation_payload',
            'chk_battle_annotation_kind_refs',
            'chk_battle_annotation_payload_shape',
            'chk_battle_annotation_idempotency',
            'chk_battle_annotation_timestamps'
          )
          AND convalidated
      ) = 12
      AND (
        SELECT COUNT(*)
        FROM pg_constraint
        WHERE conrelid = to_regclass('public.battle_replay_annotations')
          AND contype = 'f'
          AND confdeltype = 'c'
          AND convalidated
      ) = 4
      AND (
        SELECT COUNT(*)
        FROM pg_index
        WHERE indexrelid IN (
          to_regclass('public.idx_battle_annotation_user_replay_created'),
          to_regclass('public.idx_battle_annotation_subject_created'),
          to_regclass('public.idx_battle_annotation_kind_created'),
          to_regclass('public.uq_battle_annotation_reflection'),
          to_regclass('public.uq_battle_annotation_mulligan'),
          to_regclass('public.uq_battle_annotation_helpful')
        )
          AND indisvalid
          AND indisready
      ) = 6
    ) AS battle_annotation_contract_ready,
    (
      to_regclass('public.battle_jobs') IS NOT NULL
      AND (
        SELECT COUNT(*)
        FROM (
          VALUES
            ('schema_version'),
            ('user_id'),
            ('deck_a_hash'),
            ('deck_b_hash'),
            ('request_hash'),
            ('engine_request_schema_version'),
            ('engine_request_hash'),
            ('engine_request_correlation_source'),
            ('request_payload'),
            ('requested_engine'),
            ('engine_lane'),
            ('status'),
            ('progress_current'),
            ('progress_total'),
            ('lease_token'),
            ('lease_expires_at'),
            ('heartbeat_at'),
            ('attempt_id'),
            ('replay_id'),
            ('idempotency_key'),
            ('request_fingerprint'),
            ('engine_process_id'),
            ('finished_at')
        ) AS required(column_name)
        WHERE EXISTS (
          SELECT 1
          FROM information_schema.columns actual
          WHERE actual.table_schema = 'public'
            AND actual.table_name = 'battle_jobs'
            AND actual.column_name = required.column_name
        )
      ) = 23
      AND (
        SELECT COUNT(*)
        FROM pg_constraint
        WHERE conrelid = to_regclass('public.battle_jobs')
          AND conname IN (
            'fk_battle_job_attempt_replay',
            'chk_battle_job_schema',
            'chk_battle_job_status',
            'chk_battle_job_stage',
            'chk_battle_job_hashes',
            'chk_battle_job_request',
            'chk_battle_job_engine_request',
            'chk_battle_job_progress',
            'chk_battle_job_lease',
            'chk_battle_job_completed_replay'
          )
          AND convalidated
      ) = 10
      AND (
        SELECT COUNT(*)
        FROM pg_index
        WHERE indexrelid IN (
          to_regclass('public.uq_battle_jobs_user_idempotency'),
          to_regclass('public.idx_battle_jobs_user_active'),
          to_regclass('public.idx_battle_jobs_claim'),
          to_regclass('public.idx_battle_jobs_lease')
        )
          AND indisvalid
          AND indisready
      ) = 4
    ) AS battle_job_contract_ready,
    (
      to_regclass('public.battle_job_live_records') IS NOT NULL
      AND (
        SELECT COUNT(*)
        FROM (
          VALUES
            ('schema_version'),
            ('job_id'),
            ('sequence'),
            ('record_id'),
            ('kind'),
            ('payload'),
            ('content_truncated'),
            ('fingerprint'),
            ('source_kind'),
            ('public_visible'),
            ('source_process_id'),
            ('source_sequence'),
            ('source_record_id'),
            ('source_truncated'),
            ('created_at')
        ) AS required(column_name)
        WHERE EXISTS (
          SELECT 1
          FROM information_schema.columns actual
          WHERE actual.table_schema = 'public'
            AND actual.table_name = 'battle_job_live_records'
            AND actual.column_name = required.column_name
        )
      ) = 15
      AND (
        SELECT COUNT(*)
        FROM pg_constraint
        WHERE conrelid = to_regclass('public.battle_job_live_records')
          AND conname IN (
            'chk_battle_live_record_schema',
            'chk_battle_live_record_sequence',
            'chk_battle_live_record_id',
            'chk_battle_live_record_kind',
            'chk_battle_live_record_payload',
            'chk_battle_live_record_fingerprint',
            'chk_battle_live_record_source',
            'chk_battle_live_record_source_identity',
            'uq_battle_live_record_job_sequence',
            'uq_battle_live_record_job_fingerprint'
          )
          AND convalidated
      ) = 10
      AND (
        SELECT COUNT(*)
        FROM pg_index
        WHERE indexrelid IN (
          to_regclass('public.idx_battle_live_record_job_public_sequence'),
          to_regclass('public.idx_battle_live_record_checkpoint'),
          to_regclass('public.idx_battle_live_record_source_identity')
        )
          AND indisvalid
          AND indisready
      ) = 3
    ) AS battle_live_contract_ready
''';

Future<ReleaseSchemaReadiness> evaluateReleaseSchemaReadiness(Pool pool) async {
  try {
    final result = await pool
        .execute(releaseSchemaReadinessSql)
        .timeout(const Duration(seconds: 5));
    final row = result.first;
    final healthy =
        row.length >= 15 && row.take(15).every((value) => value == true);
    return ReleaseSchemaReadiness(
      healthy: healthy,
      check: {
        'status': healthy ? 'healthy' : 'unhealthy',
        'required_range': '038-055',
        'latest_migration': '055',
        'migrations': requiredReleaseSchemaMigrations.keys.toList(
          growable: false,
        ),
        if (!healthy) 'error_code': 'release_schema_not_ready',
      },
    );
  } on Object {
    return ReleaseSchemaReadiness(
      healthy: false,
      check: {
        'status': 'unhealthy',
        'required_range': '038-055',
        'latest_migration': '055',
        'migrations': requiredReleaseSchemaMigrations.keys.toList(
          growable: false,
        ),
        'error_code': 'release_schema_check_failed',
      },
    );
  }
}

const aiJobSchemaReadinessSql = '''
  SELECT
    EXISTS (
      SELECT 1
      FROM schema_migrations
      WHERE version = '048'
        AND name = 'close_ai_job_lifecycle'
    ) AS migration_048_registered,
    (
      SELECT COUNT(*)
      FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name IN ('ai_generate_jobs', 'ai_optimize_jobs')
        AND column_name IN (
          'request_key', 'request_fingerprint', 'cancelled_at'
        )
    ) = 6 AS lifecycle_columns_ready,
    (
      SELECT COUNT(*)
      FROM pg_constraint
      WHERE conname IN (
        'chk_ai_generate_jobs_status',
        'chk_ai_optimize_jobs_status'
      )
        AND convalidated
        AND pg_get_constraintdef(oid) LIKE '%cancelled%'
    ) = 2 AS status_constraints_ready,
    (
      SELECT COUNT(*)
      FROM pg_index
      WHERE indexrelid IN (
        to_regclass('public.idx_ai_generate_jobs_user_request_key'),
        to_regclass('public.idx_ai_optimize_jobs_user_request_key')
      )
        AND indisvalid
        AND indisready
    ) = 2 AS idempotency_indexes_ready
''';

Future<AiJobSchemaReadiness> evaluateAiJobSchemaReadiness(Pool pool) async {
  try {
    final result = await pool
        .execute(aiJobSchemaReadinessSql)
        .timeout(const Duration(seconds: 5));
    final row = result.first;
    final healthy =
        row.length >= 4 && row.take(4).every((value) => value == true);
    return AiJobSchemaReadiness(
      healthy: healthy,
      check: {
        'status': healthy ? 'healthy' : 'unhealthy',
        'migrations': const ['048'],
        if (!healthy) 'error_code': 'ai_job_schema_not_ready',
      },
    );
  } on Object {
    return const AiJobSchemaReadiness(
      healthy: false,
      check: {
        'status': 'unhealthy',
        'migrations': ['048'],
        'error_code': 'ai_job_schema_check_failed',
      },
    );
  }
}

const battleJobSchemaReadinessSql = '''
  SELECT
    EXISTS (
      SELECT 1
      FROM schema_migrations
      WHERE version = '054'
        AND name = 'create_battle_jobs'
    ) AS migration_054_registered,
    (
      SELECT COUNT(*)
      FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = 'battle_jobs'
        AND column_name IN (
          'status',
          'request_hash',
          'deck_a_hash',
          'deck_b_hash',
          'idempotency_key',
          'request_fingerprint',
          'lease_token',
          'lease_expires_at',
          'heartbeat_at',
          'attempt_id',
          'replay_id',
          'engine_process_id',
          'engine_request_schema_version',
          'engine_request_hash',
          'engine_request_correlation_source'
        )
    ) = 15 AS battle_job_columns_ready,
    (
      SELECT COUNT(*)
      FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = 'battle_simulation_attempts'
        AND column_name IN (
          'job_request_schema_version',
          'job_request_hash',
          'engine_request_correlation_source'
        )
    ) = 3 AS battle_attempt_correlation_columns_ready,
    (
      SELECT COUNT(*)
      FROM pg_constraint
      WHERE conrelid = to_regclass('public.battle_jobs')
        AND conname IN (
          'chk_battle_job_status',
          'chk_battle_job_lease',
          'chk_battle_job_completed_replay',
          'chk_battle_job_engine_request'
        )
        AND convalidated
    ) = 4 AS battle_job_constraints_ready,
    (
      SELECT COUNT(*)
      FROM pg_index
      WHERE indexrelid IN (
        to_regclass('public.uq_battle_jobs_user_idempotency'),
        to_regclass('public.idx_battle_jobs_claim'),
        to_regclass('public.idx_battle_jobs_lease')
      )
        AND indisvalid
        AND indisready
    ) = 3 AS battle_job_indexes_ready
''';

Future<BattleJobSchemaReadiness> evaluateBattleJobSchemaReadiness(
  Pool pool,
) async {
  try {
    final result = await pool
        .execute(battleJobSchemaReadinessSql)
        .timeout(const Duration(seconds: 5));
    final row = result.first;
    final healthy =
        row.length >= 5 && row.take(5).every((value) => value == true);
    return BattleJobSchemaReadiness(
      healthy: healthy,
      check: {
        'status': healthy ? 'healthy' : 'unhealthy',
        'schema_version': 'battle_job_v1',
        'migrations': const ['054'],
        if (!healthy) 'error_code': 'battle_job_schema_not_ready',
      },
    );
  } on Object {
    return const BattleJobSchemaReadiness(
      healthy: false,
      check: {
        'status': 'unhealthy',
        'schema_version': 'battle_job_v1',
        'migrations': ['054'],
        'error_code': 'battle_job_schema_check_failed',
      },
    );
  }
}

const battleLiveSchemaReadinessSql = '''
  SELECT
    EXISTS (
      SELECT 1
      FROM schema_migrations
      WHERE version = '055'
        AND name = 'create_battle_job_live_records'
    ) AS migration_055_registered,
    (
      SELECT COUNT(*)
      FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = 'battle_job_live_records'
        AND column_name IN (
          'schema_version',
          'job_id',
          'sequence',
          'record_id',
          'kind',
          'payload',
          'content_truncated',
          'fingerprint',
          'source_kind',
          'public_visible',
          'source_process_id',
          'source_sequence',
          'source_record_id',
          'source_truncated',
          'created_at'
        )
    ) = 15 AS battle_live_columns_ready,
    (
      SELECT COUNT(*)
      FROM pg_constraint
      WHERE conrelid = to_regclass('public.battle_job_live_records')
        AND conname IN (
          'chk_battle_live_record_schema',
          'chk_battle_live_record_sequence',
          'chk_battle_live_record_id',
          'chk_battle_live_record_kind',
          'chk_battle_live_record_payload',
          'chk_battle_live_record_fingerprint',
          'chk_battle_live_record_source',
          'chk_battle_live_record_source_identity',
          'uq_battle_live_record_job_sequence',
          'uq_battle_live_record_job_fingerprint'
        )
        AND convalidated
    ) = 10 AS battle_live_constraints_ready,
    (
      SELECT COUNT(*)
      FROM pg_index
      WHERE indexrelid IN (
        to_regclass('public.idx_battle_live_record_job_public_sequence'),
        to_regclass('public.idx_battle_live_record_checkpoint'),
        to_regclass('public.idx_battle_live_record_source_identity')
      )
        AND indisvalid
        AND indisready
    ) = 3 AS battle_live_indexes_ready
''';

Future<bool> probeBattleLiveSchema(Pool? pool) async {
  if (pool == null) return false;
  final result = await pool
      .execute(battleLiveSchemaReadinessSql)
      .timeout(const Duration(seconds: 5));
  final row = result.first;
  return row.length >= 4 && row.take(4).every((value) => value == true);
}

Future<BattleLiveSpectatorReadiness> evaluateBattleLiveSpectatorReadiness(
  DotEnv env,
  Pool? pool, {
  BattleSidecarProbe probe = probeBattleSidecarHealth,
  BattleLiveSchemaProbe schemaProbe = probeBattleLiveSchema,
}) async {
  final configured = env[battleLiveSpectatorEnabledEnvironment]?.trim();
  final enabled = battleLiveSpectatorEnabledValue(configured);
  if (!enabled) {
    final validDisabledValue =
        configured == null ||
        configured.isEmpty ||
        configured.toLowerCase() == 'false';
    return BattleLiveSpectatorReadiness(
      healthy: true,
      check: {
        'status': 'disabled',
        'enabled': false,
        'schema_version': battleLiveCursorSchemaVersion,
        'transport': battleLivePollingTransport,
        'configuration_status':
            validDisabledValue ? 'valid' : 'invalid_fail_closed',
      },
    );
  }

  var schemaReady = false;
  try {
    schemaReady = await schemaProbe(pool);
  } on Object {
    schemaReady = false;
  }

  var sourceReady = false;
  final sourceUrl = env['XMAGE_SIDECAR_URL']?.trim() ?? '';
  try {
    final config = BattleEngineConfig.fromEnvironment({
      'BATTLE_ENGINE': 'xmage',
      'XMAGE_SIDECAR_URL': sourceUrl,
      if (env['XMAGE_EXPECTED_COMMIT'] case final String value)
        'XMAGE_EXPECTED_COMMIT': value,
      if (env['XMAGE_EXPECTED_VERSION'] case final String value)
        'XMAGE_EXPECTED_VERSION': value,
    });
    final baseUri = Uri.tryParse(sourceUrl);
    if (baseUri != null &&
        const {'http', 'https'}.contains(baseUri.scheme) &&
        baseUri.host.isNotEmpty) {
      final health = await probe('xmage', baseUri.resolve('/health'));
      if (health != null) {
        final identityError = externalBattleIdentityValidationError(
          health,
          expected: config.xmageIdentity,
        );
        sourceReady =
            health['status'] == 'ok' &&
            identityError == null &&
            _validBattleLiveHealth(health['battle_live']);
      }
    }
  } on Object {
    sourceReady = false;
  }

  final healthy = schemaReady && sourceReady;
  return BattleLiveSpectatorReadiness(
    healthy: healthy,
    check: {
      'status': healthy ? 'ready' : 'unhealthy',
      'enabled': true,
      'schema_version': battleLiveCursorSchemaVersion,
      'source_schema_version': externalBattleLiveSourceSchema,
      'transport': battleLivePollingTransport,
      'database': schemaReady ? 'ready' : 'unhealthy',
      'source': sourceReady ? 'ready' : 'unhealthy',
      if (!healthy) 'error_code': 'battle_live_spectator_not_ready',
    },
  );
}

bool _validBattleLiveHealth(Object? raw) {
  if (raw is! Map) return false;
  final value = raw.map((key, value) => MapEntry(key.toString(), value));
  const keys = <String>{
    'schema_version',
    'stream_count',
    'record_count',
    'truncated_stream_count',
    'max_streams',
    'max_records_per_stream',
    'retention_ms',
  };
  if (value.keys.toSet().difference(keys).isNotEmpty ||
      keys.difference(value.keys.toSet()).isNotEmpty ||
      value['schema_version'] != externalBattleLiveSourceSchema) {
    return false;
  }
  final streamCount = value['stream_count'];
  final recordCount = value['record_count'];
  final truncatedCount = value['truncated_stream_count'];
  final maxStreams = value['max_streams'];
  final maxRecords = value['max_records_per_stream'];
  final retentionMs = value['retention_ms'];
  return streamCount is int &&
      streamCount >= 0 &&
      maxStreams is int &&
      maxStreams >= 1 &&
      maxStreams <= 10000 &&
      streamCount <= maxStreams &&
      recordCount is int &&
      recordCount >= 0 &&
      maxRecords is int &&
      maxRecords >= battleLiveSourcePageLimit &&
      maxRecords <= battleLiveMaximumSourceRecords &&
      recordCount <= streamCount * maxRecords &&
      truncatedCount is int &&
      truncatedCount >= 0 &&
      truncatedCount <= streamCount &&
      retentionMs is int &&
      retentionMs >= 1000 &&
      retentionMs <= 86400000;
}

BattleJobWorkerReadiness evaluateBattleJobWorkerReadiness(DotEnv env) {
  final enabled =
      (env['BATTLE_JOB_WORKER_ENABLED'] ?? 'true').trim().toLowerCase() ==
      'true';
  final missing = <String>[
    if ((env['XMAGE_SIDECAR_URL'] ?? '').trim().isEmpty) 'XMAGE_SIDECAR_URL',
    if ((env['FORGE_SIDECAR_URL'] ?? '').trim().isEmpty) 'FORGE_SIDECAR_URL',
    if ((env['NATIVE_BATTLE_SIDECAR_URL'] ?? '').trim().isEmpty)
      'NATIVE_BATTLE_SIDECAR_URL',
  ];
  final healthy = enabled && missing.isEmpty;
  return BattleJobWorkerReadiness(
    healthy: healthy,
    check: {
      'status': healthy ? 'healthy' : 'unhealthy',
      'enabled': enabled,
      'supervision': 'container_fail_closed',
      'required_engines': const ['xmage', 'forge', 'native'],
      if (missing.isNotEmpty) 'missing_configuration': missing,
      if (!healthy) 'error_code': 'battle_job_worker_not_ready',
    },
  );
}

const collectionAvailabilitySchemaReadinessSql = '''
  SELECT
    EXISTS (
      SELECT 1
      FROM schema_migrations
      WHERE version = '045'
        AND name = 'create_collection_availability_contract'
    ) AS migration_045_registered,
    EXISTS (
      SELECT 1
      FROM schema_migrations
      WHERE version = '049'
        AND name = 'preserve_binder_physical_identity'
    ) AS migration_049_registered,
    (
      SELECT COUNT(*)
      FROM pg_class
      WHERE oid IN (
        to_regclass('public.collection_availability_snapshot'),
        to_regclass('public.binder_item_availability')
      )
        AND relkind = 'v'
    ) = 2 AS availability_views_ready,
    EXISTS (
      SELECT 1
      FROM pg_constraint
      WHERE conrelid = to_regclass('public.user_binder_items')
        AND conname = 'chk_user_binder_items_language'
        AND convalidated
    ) AS language_constraint_ready,
    EXISTS (
      SELECT 1
      FROM pg_index
      WHERE indexrelid = to_regclass(
        'public.uq_user_binder_items_physical_identity'
      )
        AND indisunique
        AND indisvalid
        AND indisready
        AND pg_get_indexdef(indexrelid) LIKE '%language%'
    ) AS physical_identity_index_ready
''';

Future<CollectionAvailabilitySchemaReadiness>
evaluateCollectionAvailabilitySchemaReadiness(Pool pool) async {
  try {
    final result = await pool
        .execute(collectionAvailabilitySchemaReadinessSql)
        .timeout(const Duration(seconds: 5));
    final row = result.first;
    final healthy =
        row.length >= 5 && row.take(5).every((value) => value == true);
    return CollectionAvailabilitySchemaReadiness(
      healthy: healthy,
      check: {
        'status': healthy ? 'healthy' : 'unhealthy',
        'migrations': const ['045', '049'],
        if (!healthy) 'error_code': 'collection_availability_schema_not_ready',
      },
    );
  } on Object {
    return const CollectionAvailabilitySchemaReadiness(
      healthy: false,
      check: {
        'status': 'unhealthy',
        'migrations': ['045', '049'],
        'error_code': 'collection_availability_schema_check_failed',
      },
    );
  }
}

const deckValidationSchemaReadinessSql = '''
  SELECT
    EXISTS (
      SELECT 1
      FROM schema_migrations
      WHERE version = '039'
        AND name = 'persist_deck_validation_review_state'
    ) AS migration_039_registered,
    EXISTS (
      SELECT 1
      FROM schema_migrations
      WHERE version = '040'
        AND name = 'align_cards_reserved_runtime_schema'
    ) AS migration_040_registered,
    EXISTS (
      SELECT 1
      FROM schema_migrations
      WHERE version = '047'
        AND name = 'close_deck_validation_state_transitions'
    ) AS migration_047_registered,
    (
      SELECT COUNT(*)
      FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = 'decks'
        AND column_name IN (
          'validation_state',
          'validation_reasons',
          'validation_updated_at'
        )
    ) = 3 AS columns_ready,
    (
      SELECT COUNT(*)
      FROM pg_constraint
      WHERE conrelid = to_regclass('public.decks')
        AND conname IN (
          'chk_decks_validation_state',
          'chk_decks_validation_reasons_array',
          'chk_decks_validation_state_payload'
        )
        AND convalidated
    ) = 3 AS constraints_ready,
    EXISTS (
      SELECT 1
      FROM pg_index
      WHERE indexrelid = to_regclass(
        'public.idx_decks_user_validation_state'
      )
        AND indisvalid
        AND indisready
    ) AS index_ready,
    (
      SELECT COUNT(*)
      FROM pg_trigger
      WHERE tgname IN (
          'manaloom_deck_cards_require_review',
          'manaloom_deck_format_require_review'
        )
        AND tgenabled IN ('O', 'A')
        AND NOT tgisinternal
    ) = 2 AS triggers_ready,
    EXISTS (
      SELECT 1
      FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = 'cards'
        AND column_name = 'is_reserved'
        AND data_type = 'boolean'
        AND is_nullable = 'NO'
        AND lower(column_default) = 'false'
    ) AS cards_reserved_ready
''';

Future<DeckValidationSchemaReadiness> evaluateDeckValidationSchemaReadiness(
  Pool pool,
) async {
  try {
    final result = await pool
        .execute(deckValidationSchemaReadinessSql)
        .timeout(const Duration(seconds: 5));
    final row = result.first;
    final healthy =
        row.length >= 8 && row.take(8).every((value) => value == true);
    return DeckValidationSchemaReadiness(
      healthy: healthy,
      check: {
        'status': healthy ? 'healthy' : 'unhealthy',
        'migrations': const ['039', '040', '047'],
        if (!healthy) 'error_code': 'deck_validation_schema_not_ready',
      },
    );
  } on Object {
    return const DeckValidationSchemaReadiness(
      healthy: false,
      check: {
        'status': 'unhealthy',
        'migrations': ['039', '040', '047'],
        'error_code': 'deck_validation_schema_check_failed',
      },
    );
  }
}

/// Verifies the exact engine set required by [BattleEngineConfig].
///
/// The response deliberately omits sidecar URLs and exception messages so the
/// public readiness endpoint cannot disclose internal network coordinates.
Future<BattleRuntimeReadiness> evaluateBattleRuntimeReadiness(
  DotEnv env, {
  BattleSidecarProbe probe = probeBattleSidecarHealth,
}) async {
  late final BattleEngineConfig config;
  try {
    config = BattleEngineConfig.fromEnvironment({
      for (final key in const [
        'BATTLE_ENGINE',
        'XMAGE_SIDECAR_URL',
        'FORGE_SIDECAR_URL',
        'NATIVE_BATTLE_SIDECAR_URL',
        'XMAGE_EXPECTED_COMMIT',
        'FORGE_EXPECTED_COMMIT',
        'XMAGE_EXPECTED_VERSION',
        'FORGE_EXPECTED_VERSION',
        'BATTLE_ALLOW_LEGACY_SIDECAR_IDENTITY',
      ])
        if (env[key] case final String value) key: value,
    });
  } on BattleEngineConfigurationException catch (error) {
    return BattleRuntimeReadiness(
      healthy: false,
      check: {
        'status': 'unhealthy',
        'mode': (env['BATTLE_ENGINE'] ?? 'auto').trim().toLowerCase(),
        'error_code': error.code,
      },
    );
  }

  final requiredUrls = <String, String>{
    if (config.mode == 'auto' || config.mode == 'xmage')
      'xmage': config.xmageSidecarUrl,
    if (config.mode == 'auto' || config.mode == 'forge')
      'forge': config.forgeSidecarUrl,
    if (config.mode == 'auto' || config.mode == 'native')
      'native': config.nativeSidecarUrl,
  };

  final engineChecks = <String, Map<String, dynamic>>{};
  await Future.wait(
    requiredUrls.entries.map((entry) async {
      final stopwatch = Stopwatch()..start();
      var healthy = false;
      var errorCode = 'battle_sidecar_unavailable';
      final baseUri = Uri.tryParse(entry.value);
      if (baseUri == null ||
          !const {'http', 'https'}.contains(baseUri.scheme) ||
          baseUri.host.isEmpty) {
        errorCode = 'battle_sidecar_invalid_url';
      } else {
        try {
          final payload = await probe(entry.key, baseUri.resolve('/health'));
          if (payload == null) {
            healthy = false;
          } else if (entry.key == 'native') {
            healthy =
                payload['status'] == 'ok' &&
                payload['engine'] == 'manaloom_native_reviewed';
            if (!healthy) errorCode = 'battle_sidecar_identity_mismatch';
          } else {
            final expected =
                entry.key == 'xmage'
                    ? config.xmageIdentity
                    : config.forgeIdentity;
            final identityError = externalBattleIdentityValidationError(
              payload,
              expected: expected,
              allowLegacy: config.allowLegacySidecarIdentity,
            );
            healthy = payload['status'] == 'ok' && identityError == null;
            if (identityError != null) {
              errorCode = 'battle_sidecar_identity_mismatch';
            }
          }
        } catch (_) {
          healthy = false;
        }
      }
      stopwatch.stop();
      engineChecks[entry.key] = {
        'status': healthy ? 'healthy' : 'unhealthy',
        'latency_ms': stopwatch.elapsedMilliseconds,
        if (!healthy) 'error_code': errorCode,
      };
    }),
  );

  final healthy =
      engineChecks.length == requiredUrls.length &&
      engineChecks.values.every((check) => check['status'] == 'healthy');
  return BattleRuntimeReadiness(
    healthy: healthy,
    check: {
      'status': healthy ? 'healthy' : 'unhealthy',
      'mode': config.mode,
      'engines': engineChecks,
      if (!healthy) 'error_code': 'battle_runtime_not_ready',
    },
  );
}

Future<Map<String, dynamic>?> probeBattleSidecarHealth(
  String engine,
  Uri healthUri,
) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
  try {
    final request = await client
        .getUrl(healthUri)
        .timeout(const Duration(seconds: 2));
    final response = await request.close().timeout(const Duration(seconds: 2));
    final body = await utf8.decoder
        .bind(response)
        .join()
        .timeout(const Duration(seconds: 2));
    if (response.statusCode != HttpStatus.ok) {
      return null;
    }
    final payload = jsonDecode(body);
    if (payload is! Map) {
      return null;
    }
    return payload.cast<String, dynamic>();
  } on Object {
    return null;
  } finally {
    client.close(force: true);
  }
}

AiRuntimeReadiness evaluateAiRuntimeReadiness(DotEnv env) {
  final config = OpenAiRuntimeConfig(env);
  final providerConfigured = (env['OPENAI_API_KEY'] ?? '').trim().isNotEmpty;
  final healthy =
      !config.isProductionLike ||
      (providerConfigured && !config.allowsMockFallbacks);

  return AiRuntimeReadiness(
    healthy: healthy,
    check: {
      'status': healthy ? 'healthy' : 'unhealthy',
      'profile': config.profile,
      'provider_configured': providerConfigured,
      'mock_fallbacks_allowed': config.allowsMockFallbacks,
      'models': config.selectedModels,
      if (!healthy) 'error_code': 'ai_provider_not_ready',
    },
  );
}

Map<String, dynamic> buildReadinessResponseBody({
  required Map<String, dynamic> checks,
  required bool allHealthy,
  DateTime? now,
  String? environment,
  bool e2eIsolatedRuntime = false,
}) {
  return {
    'status': allHealthy ? 'ready' : 'not_ready',
    'service': 'mtgia-server',
    'timestamp': (now ?? DateTime.now()).toIso8601String(),
    'environment':
        environment ?? Platform.environment['ENVIRONMENT'] ?? 'development',
    'e2e_isolated_runtime': e2eIsolatedRuntime,
    'checks': checks,
  };
}

int readinessStatusCode(bool allHealthy) =>
    allHealthy ? HttpStatus.ok : HttpStatus.serviceUnavailable;
