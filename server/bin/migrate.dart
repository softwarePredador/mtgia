// ignore_for_file: avoid_print

import 'dart:io';
import 'package:postgres/postgres.dart';
import 'package:server/ai/candidate_quality_data_support.dart';
import 'package:server/ai/commander_learning_snapshot_support.dart';
import 'package:server/collection_availability_contract.dart';
import 'package:server/import_card_lookup_service.dart';
import 'package:server/runtime_environment.dart';
import 'package:server/sql_statement_splitter.dart';

/// Sistema de Migrações Versionado para MTG IA
///
/// Gerencia migrações de banco de dados de forma ordenada e idempotente.
/// Cada migração é executada apenas uma vez e registrada na tabela `schema_migrations`.
///
/// Uso: dart run bin/migrate.dart [--status] [--rollback N]
///
/// Opções:
///   --status    Mostra o status das migrações
///   --rollback N  Reverte, em transação, as últimas N migrações conhecidas

const migrationWriteApprovalEnvironment = 'MANALOOM_CONFIRM_POSTGRES_WRITES';
const migrationLiveApprovalEnvironment = 'MANALOOM_CONFIRM_LIVE_MUTATIONS';
const migrationWriteApprovalPhrase = 'I_HAVE_EXPLICIT_APPROVAL';

// Lista de migrações em ordem cronológica
// Cada migração tem: versão, nome, SQL de up e SQL de down (opcional)
final migrations = <Migration>[
  Migration(
    version: '001',
    name: 'create_ai_logs',
    up: '''
      CREATE TABLE IF NOT EXISTS ai_logs (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID REFERENCES users(id) ON DELETE SET NULL,
        deck_id UUID REFERENCES decks(id) ON DELETE SET NULL,
        endpoint TEXT NOT NULL,
        model TEXT NOT NULL,
        prompt_summary TEXT,
        input_tokens INTEGER,
        output_tokens INTEGER,
        response_summary TEXT,
        success BOOLEAN NOT NULL DEFAULT TRUE,
        error_message TEXT,
        latency_ms INTEGER NOT NULL,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
      CREATE INDEX IF NOT EXISTS idx_ai_logs_user ON ai_logs (user_id);
      CREATE INDEX IF NOT EXISTS idx_ai_logs_deck ON ai_logs (deck_id);
      CREATE INDEX IF NOT EXISTS idx_ai_logs_endpoint ON ai_logs (endpoint);
      CREATE INDEX IF NOT EXISTS idx_ai_logs_created ON ai_logs (created_at DESC);
      CREATE INDEX IF NOT EXISTS idx_ai_logs_success ON ai_logs (success);
    ''',
    down: 'DROP TABLE IF EXISTS ai_logs CASCADE;',
  ),
  Migration(
    version: '002',
    name: 'create_critical_indexes',
    up: '''
      CREATE INDEX IF NOT EXISTS idx_cards_name_lower ON cards (LOWER(name));
      CREATE EXTENSION IF NOT EXISTS pg_trgm;
      CREATE INDEX IF NOT EXISTS idx_cards_name_trgm ON cards USING gin (name gin_trgm_ops);
      CREATE INDEX IF NOT EXISTS idx_cards_color_identity_gin ON cards USING gin (color_identity);
      CREATE INDEX IF NOT EXISTS idx_deck_cards_deck_id ON deck_cards (deck_id);
      CREATE INDEX IF NOT EXISTS idx_card_legalities_card_format ON card_legalities (card_id, format);
      CREATE INDEX IF NOT EXISTS idx_decks_user_id ON decks (user_id);
      CREATE INDEX IF NOT EXISTS idx_cards_scryfall_id ON cards (scryfall_id);
      CREATE INDEX IF NOT EXISTS idx_cards_type_line ON cards (type_line);
    ''',
    down: '''
      DROP INDEX IF EXISTS idx_cards_name_lower;
      DROP INDEX IF EXISTS idx_cards_name_trgm;
      DROP INDEX IF EXISTS idx_cards_color_identity_gin;
      DROP INDEX IF EXISTS idx_deck_cards_deck_id;
      DROP INDEX IF EXISTS idx_card_legalities_card_format;
      DROP INDEX IF EXISTS idx_decks_user_id;
      DROP INDEX IF EXISTS idx_cards_scryfall_id;
      DROP INDEX IF EXISTS idx_cards_type_line;
    ''',
  ),
  Migration(
    version: '003',
    name: 'add_deck_deleted_at',
    up: '''
      ALTER TABLE decks ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE;
      CREATE INDEX IF NOT EXISTS idx_decks_deleted_at ON decks (deleted_at) WHERE deleted_at IS NULL;
    ''',
    down: '''
      DROP INDEX IF EXISTS idx_decks_deleted_at;
      ALTER TABLE decks DROP COLUMN IF EXISTS deleted_at;
    ''',
  ),
  Migration(
    version: '004',
    name: 'add_card_price_columns',
    up: '''
      ALTER TABLE cards ADD COLUMN IF NOT EXISTS price_usd DECIMAL(10, 2);
      ALTER TABLE cards ADD COLUMN IF NOT EXISTS price_usd_foil DECIMAL(10, 2);
      ALTER TABLE cards ADD COLUMN IF NOT EXISTS price_updated_at TIMESTAMP WITH TIME ZONE;
      CREATE INDEX IF NOT EXISTS idx_cards_price ON cards (price_usd) WHERE price_usd IS NOT NULL;
    ''',
    down: '''
      DROP INDEX IF EXISTS idx_cards_price;
      ALTER TABLE cards DROP COLUMN IF EXISTS price_usd;
      ALTER TABLE cards DROP COLUMN IF EXISTS price_usd_foil;
      ALTER TABLE cards DROP COLUMN IF EXISTS price_updated_at;
    ''',
  ),
  Migration(
    version: '005',
    name: 'update_battle_simulations',
    up: '''
      ALTER TABLE battle_simulations ADD COLUMN IF NOT EXISTS simulation_type TEXT;
      UPDATE battle_simulations SET simulation_type = 'legacy' WHERE simulation_type IS NULL;
      ALTER TABLE battle_simulations ALTER COLUMN simulation_type SET NOT NULL;
      ALTER TABLE battle_simulations ADD COLUMN IF NOT EXISTS metrics JSONB DEFAULT '{}';
      UPDATE battle_simulations SET metrics = COALESCE(game_log, '{}') WHERE metrics IS NULL OR metrics = '{}';
      CREATE INDEX IF NOT EXISTS idx_battle_sim_deck_a ON battle_simulations (deck_a_id);
      CREATE INDEX IF NOT EXISTS idx_battle_sim_deck_b ON battle_simulations (deck_b_id);
      CREATE INDEX IF NOT EXISTS idx_battle_sim_type ON battle_simulations (simulation_type);
      CREATE INDEX IF NOT EXISTS idx_battle_sim_created ON battle_simulations (created_at DESC);
    ''',
    down: '''
      ALTER TABLE battle_simulations DROP COLUMN IF EXISTS simulation_type;
      ALTER TABLE battle_simulations DROP COLUMN IF EXISTS metrics;
    ''',
  ),
  Migration(
    version: '006',
    name: 'add_card_cmc_column',
    up: '''
      ALTER TABLE cards ADD COLUMN IF NOT EXISTS cmc DECIMAL(4, 1) DEFAULT 0;
      CREATE INDEX IF NOT EXISTS idx_cards_cmc ON cards (cmc);
    ''',
    down: '''
      DROP INDEX IF EXISTS idx_cards_cmc;
      ALTER TABLE cards DROP COLUMN IF EXISTS cmc;
    ''',
  ),
  Migration(
    version: '007',
    name: 'create_ai_optimize_fallback_telemetry',
    up: '''
      CREATE TABLE IF NOT EXISTS ai_optimize_fallback_telemetry (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID REFERENCES users(id) ON DELETE SET NULL,
        deck_id UUID REFERENCES decks(id) ON DELETE SET NULL,
        mode TEXT NOT NULL DEFAULT 'optimize',
        recognized_format BOOLEAN NOT NULL DEFAULT FALSE,
        triggered BOOLEAN NOT NULL DEFAULT FALSE,
        applied BOOLEAN NOT NULL DEFAULT FALSE,
        no_candidate BOOLEAN NOT NULL DEFAULT FALSE,
        no_replacement BOOLEAN NOT NULL DEFAULT FALSE,
        candidate_count INTEGER NOT NULL DEFAULT 0,
        replacement_count INTEGER NOT NULL DEFAULT 0,
        pair_count INTEGER NOT NULL DEFAULT 0,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
      CREATE INDEX IF NOT EXISTS idx_opt_fallback_created ON ai_optimize_fallback_telemetry (created_at DESC);
      CREATE INDEX IF NOT EXISTS idx_opt_fallback_user ON ai_optimize_fallback_telemetry (user_id);
      CREATE INDEX IF NOT EXISTS idx_opt_fallback_deck ON ai_optimize_fallback_telemetry (deck_id);
      CREATE INDEX IF NOT EXISTS idx_opt_fallback_triggered ON ai_optimize_fallback_telemetry (triggered, applied);
    ''',
    down: '''
      DROP INDEX IF EXISTS idx_opt_fallback_created;
      DROP INDEX IF EXISTS idx_opt_fallback_user;
      DROP INDEX IF EXISTS idx_opt_fallback_deck;
      DROP INDEX IF EXISTS idx_opt_fallback_triggered;
      DROP TABLE IF EXISTS ai_optimize_fallback_telemetry CASCADE;
    ''',
  ),
  Migration(
    version: '008',
    name: 'create_rate_limit_events',
    up: '''
      CREATE TABLE IF NOT EXISTS rate_limit_events (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        bucket TEXT NOT NULL,
        identifier TEXT NOT NULL,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
      CREATE INDEX IF NOT EXISTS idx_rate_limit_bucket_identifier_created
      ON rate_limit_events (bucket, identifier, created_at DESC);
    ''',
    down: '''
      DROP INDEX IF EXISTS idx_rate_limit_bucket_identifier_created;
      DROP TABLE IF EXISTS rate_limit_events CASCADE;
    ''',
  ),
  Migration(
    version: '009',
    name: 'create_ai_optimize_v2_tables',
    up: '''
      CREATE TABLE IF NOT EXISTS ai_user_preferences (
        user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
        preferred_archetype TEXT,
        preferred_bracket INTEGER,
        keep_theme_default BOOLEAN NOT NULL DEFAULT TRUE,
        preferred_colors TEXT[] NOT NULL DEFAULT '{}',
        budget_tier TEXT NOT NULL DEFAULT 'mid',
        playstyle TEXT NOT NULL DEFAULT 'balanced',
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
      CREATE INDEX IF NOT EXISTS idx_ai_user_preferences_archetype
      ON ai_user_preferences (preferred_archetype);

      CREATE TABLE IF NOT EXISTS ai_optimize_cache (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        cache_key TEXT NOT NULL UNIQUE,
        user_id UUID REFERENCES users(id) ON DELETE SET NULL,
        deck_id UUID REFERENCES decks(id) ON DELETE SET NULL,
        deck_signature TEXT NOT NULL,
        payload JSONB NOT NULL,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        expires_at TIMESTAMP WITH TIME ZONE NOT NULL
      );
      CREATE INDEX IF NOT EXISTS idx_ai_optimize_cache_expires_at
      ON ai_optimize_cache (expires_at);
      CREATE INDEX IF NOT EXISTS idx_ai_optimize_cache_user
      ON ai_optimize_cache (user_id);
      CREATE INDEX IF NOT EXISTS idx_ai_optimize_cache_deck
      ON ai_optimize_cache (deck_id);
    ''',
    down: '''
      DROP INDEX IF EXISTS idx_ai_optimize_cache_deck;
      DROP INDEX IF EXISTS idx_ai_optimize_cache_user;
      DROP INDEX IF EXISTS idx_ai_optimize_cache_expires_at;
      DROP TABLE IF EXISTS ai_optimize_cache CASCADE;
      DROP INDEX IF EXISTS idx_ai_user_preferences_archetype;
      DROP TABLE IF EXISTS ai_user_preferences CASCADE;
    ''',
  ),
  Migration(
    version: '010',
    name: 'create_activation_funnel_events',
    up: '''
      CREATE TABLE IF NOT EXISTS activation_funnel_events (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID REFERENCES users(id) ON DELETE CASCADE,
        event_name TEXT NOT NULL,
        format TEXT,
        deck_id UUID REFERENCES decks(id) ON DELETE SET NULL,
        source TEXT,
        metadata JSONB NOT NULL DEFAULT '{}',
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
      CREATE INDEX IF NOT EXISTS idx_activation_funnel_user_created
      ON activation_funnel_events (user_id, created_at DESC);
      CREATE INDEX IF NOT EXISTS idx_activation_funnel_event_created
      ON activation_funnel_events (event_name, created_at DESC);
    ''',
    down: '''
      DROP INDEX IF EXISTS idx_activation_funnel_event_created;
      DROP INDEX IF EXISTS idx_activation_funnel_user_created;
      DROP TABLE IF EXISTS activation_funnel_events CASCADE;
    ''',
  ),
  Migration(
    version: '011',
    name: 'create_user_plans',
    up: '''
      CREATE TABLE IF NOT EXISTS user_plans (
        user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
        plan_name TEXT NOT NULL DEFAULT 'free',
        status TEXT NOT NULL DEFAULT 'active',
        started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        renews_at TIMESTAMP WITH TIME ZONE,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT chk_user_plans_name CHECK (plan_name IN ('free', 'pro')),
        CONSTRAINT chk_user_plans_status CHECK (status IN ('active', 'canceled'))
      );

      CREATE INDEX IF NOT EXISTS idx_user_plans_plan_status
      ON user_plans (plan_name, status);

      INSERT INTO user_plans (user_id, plan_name, status)
      SELECT u.id, 'free', 'active'
      FROM users u
      WHERE NOT EXISTS (
        SELECT 1 FROM user_plans p WHERE p.user_id = u.id
      );
    ''',
    down: '''
      DROP INDEX IF EXISTS idx_user_plans_plan_status;
      DROP TABLE IF EXISTS user_plans CASCADE;
    ''',
  ),
  Migration(
    version: '012',
    name: 'add_hot_query_indexes',
    up: '''
      CREATE INDEX IF NOT EXISTS idx_cards_set_code_lower
      ON cards (LOWER(set_code));

      CREATE INDEX IF NOT EXISTS idx_cards_name_set_lower
      ON cards (LOWER(name), LOWER(set_code));

      CREATE INDEX IF NOT EXISTS idx_sets_release_date_desc
      ON sets (release_date DESC);

      CREATE INDEX IF NOT EXISTS idx_card_legalities_format_status
      ON card_legalities (format, status);
    ''',
    down: '''
      DROP INDEX IF EXISTS idx_card_legalities_format_status;
      DROP INDEX IF EXISTS idx_sets_release_date_desc;
      DROP INDEX IF EXISTS idx_cards_name_set_lower;
      DROP INDEX IF EXISTS idx_cards_set_code_lower;
    ''',
  ),
  Migration(
    version: '013',
    name: 'create_ai_optimize_jobs',
    up: '''
      CREATE TABLE IF NOT EXISTS ai_optimize_jobs (
        id TEXT PRIMARY KEY,
        deck_id UUID NOT NULL REFERENCES decks(id) ON DELETE CASCADE,
        archetype TEXT NOT NULL,
        user_id UUID REFERENCES users(id) ON DELETE SET NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        stage TEXT NOT NULL DEFAULT 'Iniciando...',
        stage_number INTEGER NOT NULL DEFAULT 0,
        total_stages INTEGER NOT NULL DEFAULT 6,
        result JSONB,
        error TEXT,
        quality_error JSONB,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT chk_ai_optimize_jobs_status
          CHECK (status IN ('pending', 'processing', 'completed', 'failed'))
      );

      CREATE INDEX IF NOT EXISTS idx_ai_optimize_jobs_user_updated
      ON ai_optimize_jobs (user_id, updated_at DESC);

      CREATE INDEX IF NOT EXISTS idx_ai_optimize_jobs_created
      ON ai_optimize_jobs (created_at DESC);
    ''',
    down: '''
      DROP INDEX IF EXISTS idx_ai_optimize_jobs_created;
      DROP INDEX IF EXISTS idx_ai_optimize_jobs_user_updated;
      DROP TABLE IF EXISTS ai_optimize_jobs CASCADE;
    ''',
  ),
  Migration(
    version: '014',
    name: 'create_ai_generate_jobs',
    up: '''
      CREATE TABLE IF NOT EXISTS ai_generate_jobs (
        id TEXT PRIMARY KEY,
        user_id UUID REFERENCES users(id) ON DELETE SET NULL,
        cache_key TEXT NOT NULL,
        format TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        stage TEXT NOT NULL DEFAULT 'Iniciando...',
        stage_number INTEGER NOT NULL DEFAULT 0,
        total_stages INTEGER NOT NULL DEFAULT 4,
        result_status_code INTEGER,
        result JSONB,
        error TEXT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT chk_ai_generate_jobs_status
          CHECK (status IN ('pending', 'processing', 'completed', 'failed'))
      );

      CREATE INDEX IF NOT EXISTS idx_ai_generate_jobs_user_updated
      ON ai_generate_jobs (user_id, updated_at DESC);

      CREATE INDEX IF NOT EXISTS idx_ai_generate_jobs_created
      ON ai_generate_jobs (created_at DESC);
    ''',
    down: '''
      DROP INDEX IF EXISTS idx_ai_generate_jobs_created;
      DROP INDEX IF EXISTS idx_ai_generate_jobs_user_updated;
      DROP TABLE IF EXISTS ai_generate_jobs CASCADE;
    ''',
  ),
  Migration(
    version: '015',
    name: 'create_card_combos',
    up: '''
      CREATE TABLE IF NOT EXISTS card_combos (
        id TEXT PRIMARY KEY,
        source TEXT NOT NULL DEFAULT 'commander_spellbook',
        status TEXT NOT NULL DEFAULT 'OK',
        color_identity TEXT NOT NULL DEFAULT '',
        mana_needed TEXT,
        prerequisites TEXT,
        description TEXT,
        produces TEXT[] NOT NULL DEFAULT '{}',
        card_oracle_ids TEXT[] NOT NULL DEFAULT '{}',
        card_names TEXT[] NOT NULL DEFAULT '{}',
        card_count INTEGER NOT NULL DEFAULT 0,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
      CREATE INDEX IF NOT EXISTS idx_card_combos_oracle_ids
      ON card_combos USING gin (card_oracle_ids);
      CREATE INDEX IF NOT EXISTS idx_card_combos_identity
      ON card_combos (color_identity);
      CREATE INDEX IF NOT EXISTS idx_card_combos_card_count
      ON card_combos (card_count);

      CREATE TABLE IF NOT EXISTS combo_cards (
        combo_id TEXT NOT NULL REFERENCES card_combos(id) ON DELETE CASCADE,
        oracle_id TEXT NOT NULL,
        card_name TEXT NOT NULL,
        must_be_commander BOOLEAN NOT NULL DEFAULT false,
        PRIMARY KEY (combo_id, oracle_id)
      );
      CREATE INDEX IF NOT EXISTS idx_combo_cards_oracle
      ON combo_cards (oracle_id);
      CREATE INDEX IF NOT EXISTS idx_combo_cards_name_lower
      ON combo_cards (LOWER(card_name));
    ''',
    down: '''
      DROP TABLE IF EXISTS combo_cards CASCADE;
      DROP INDEX IF EXISTS idx_card_combos_card_count;
      DROP INDEX IF EXISTS idx_card_combos_identity;
      DROP INDEX IF EXISTS idx_card_combos_oracle_ids;
      DROP TABLE IF EXISTS card_combos CASCADE;
    ''',
  ),
  Migration(
    version: '016',
    name: 'create_card_rulings',
    up: '''
      ALTER TABLE IF EXISTS card_rulings RENAME TO card_rulings_legacy;
      CREATE TABLE IF NOT EXISTS card_rulings (
        id BIGSERIAL PRIMARY KEY,
        oracle_id TEXT NOT NULL,
        source TEXT NOT NULL DEFAULT 'mtgjson',
        published_at DATE,
        comment TEXT NOT NULL,
        comment_hash TEXT NOT NULL,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
      CREATE UNIQUE INDEX IF NOT EXISTS uniq_card_rulings_oracle_hash
      ON card_rulings (oracle_id, comment_hash);
      CREATE INDEX IF NOT EXISTS idx_card_rulings_oracle
      ON card_rulings (oracle_id);
    ''',
    down: '''
      DROP INDEX IF EXISTS idx_card_rulings_oracle;
      DROP INDEX IF EXISTS uniq_card_rulings_oracle_hash;
      DROP TABLE IF EXISTS card_rulings CASCADE;
      ALTER TABLE IF EXISTS card_rulings_legacy RENAME TO card_rulings;
    ''',
  ),
  Migration(
    version: '017',
    name: 'create_edhrec_card_snapshots',
    up: '''
      CREATE TABLE IF NOT EXISTS edhrec_card_snapshots (
        id BIGSERIAL PRIMARY KEY,
        commander_slug TEXT NOT NULL,
        commander_name TEXT NOT NULL,
        card_name TEXT NOT NULL,
        inclusion DOUBLE PRECISION NOT NULL DEFAULT 0,
        synergy DOUBLE PRECISION NOT NULL DEFAULT 0,
        num_decks INTEGER NOT NULL DEFAULT 0,
        category TEXT NOT NULL DEFAULT '',
        snapshot_date DATE NOT NULL,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
      CREATE UNIQUE INDEX IF NOT EXISTS uniq_edhrec_snapshot
      ON edhrec_card_snapshots (commander_slug, card_name, snapshot_date);
      CREATE INDEX IF NOT EXISTS idx_edhrec_snapshot_commander
      ON edhrec_card_snapshots (commander_slug, snapshot_date);
      CREATE INDEX IF NOT EXISTS idx_edhrec_snapshot_card_lower
      ON edhrec_card_snapshots (LOWER(card_name));
    ''',
    down: '''
      DROP INDEX IF EXISTS idx_edhrec_snapshot_card_lower;
      DROP INDEX IF EXISTS idx_edhrec_snapshot_commander;
      DROP INDEX IF EXISTS uniq_edhrec_snapshot;
      DROP TABLE IF EXISTS edhrec_card_snapshots CASCADE;
    ''',
  ),
  Migration(
    version: '018',
    name: 'add_card_combat_metadata',
    up: '''
      ALTER TABLE cards ADD COLUMN IF NOT EXISTS power TEXT;
      ALTER TABLE cards ADD COLUMN IF NOT EXISTS toughness TEXT;
      ALTER TABLE cards ADD COLUMN IF NOT EXISTS keywords TEXT[];
      CREATE INDEX IF NOT EXISTS idx_cards_keywords ON cards USING gin (keywords);
    ''',
    down: '''
      DROP INDEX IF EXISTS idx_cards_keywords;
      ALTER TABLE cards DROP COLUMN IF EXISTS keywords;
      ALTER TABLE cards DROP COLUMN IF EXISTS toughness;
      ALTER TABLE cards DROP COLUMN IF EXISTS power;
    ''',
  ),
  Migration(
    version: '019',
    name: 'create_card_battle_rules',
    up: '''
      CREATE TABLE IF NOT EXISTS card_battle_rules (
        normalized_name TEXT PRIMARY KEY,
        card_id UUID REFERENCES cards(id) ON DELETE SET NULL,
        card_name TEXT NOT NULL,
        logical_rule_key TEXT,
        effect_json JSONB NOT NULL DEFAULT '{}'::jsonb,
        deck_role_json JSONB NOT NULL DEFAULT '{}'::jsonb,
        source TEXT NOT NULL DEFAULT 'curated',
        confidence NUMERIC(4,3) NOT NULL DEFAULT 1.0
          CHECK (confidence >= 0 AND confidence <= 1),
        review_status TEXT NOT NULL DEFAULT 'verified',
        execution_status TEXT NOT NULL DEFAULT 'auto',
        rule_version INTEGER NOT NULL DEFAULT 1 CHECK (rule_version >= 1),
        oracle_hash TEXT,
        notes TEXT,
        reviewed_by TEXT,
        reviewed_at TIMESTAMP WITH TIME ZONE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        last_seen_at TIMESTAMP WITH TIME ZONE,
        CONSTRAINT chk_card_battle_rules_source CHECK (
          source IN ('manual', 'curated', 'generated', 'heuristic', 'imported')
        ),
        CONSTRAINT chk_card_battle_rules_review_status CHECK (
          review_status IN (
            'verified',
            'active',
            'needs_review',
            'rejected',
            'deprecated'
          )
        ),
        CONSTRAINT chk_card_battle_rules_execution_status CHECK (
          execution_status IN (
            'auto',
            'executable',
            'annotation_only',
            'review_only',
            'disabled'
          )
        )
      );

      CREATE INDEX IF NOT EXISTS idx_card_battle_rules_card_id
      ON card_battle_rules (card_id);

      CREATE INDEX IF NOT EXISTS idx_card_battle_rules_source_status
      ON card_battle_rules (source, review_status);

      CREATE INDEX IF NOT EXISTS idx_card_battle_rules_effect
      ON card_battle_rules USING gin (effect_json);

      CREATE INDEX IF NOT EXISTS idx_card_battle_rules_deck_role
      ON card_battle_rules USING gin (deck_role_json);

      CREATE INDEX IF NOT EXISTS idx_card_battle_rules_name_lower
      ON card_battle_rules (LOWER(card_name));
    ''',
    down: '''
      DROP INDEX IF EXISTS idx_card_battle_rules_name_lower;
      DROP INDEX IF EXISTS idx_card_battle_rules_deck_role;
      DROP INDEX IF EXISTS idx_card_battle_rules_effect;
      DROP INDEX IF EXISTS idx_card_battle_rules_source_status;
      DROP INDEX IF EXISTS idx_card_battle_rules_card_id;
      DROP TABLE IF EXISTS card_battle_rules CASCADE;
    ''',
  ),
  Migration(
    version: '020',
    name: 'add_card_lookup_indexes',
    up: '''
      CREATE INDEX IF NOT EXISTS idx_cards_name_lower
      ON cards (LOWER(name));

      CREATE INDEX IF NOT EXISTS idx_cards_front_name_lower
      ON cards (LOWER(split_part(name, ' // ', 1)));
    ''',
    down: '''
      DROP INDEX IF EXISTS idx_cards_front_name_lower;
      DROP INDEX IF EXISTS idx_cards_name_lower;
    ''',
  ),
  Migration(
    version: '021',
    name: 'add_card_canonical_identity_columns',
    up: '''
      ALTER TABLE cards ADD COLUMN IF NOT EXISTS oracle_id UUID;
      ALTER TABLE cards ADD COLUMN IF NOT EXISTS layout TEXT;
      ALTER TABLE cards ADD COLUMN IF NOT EXISTS card_faces_json JSONB;

      CREATE INDEX IF NOT EXISTS idx_cards_oracle_id
      ON cards (oracle_id);

      CREATE INDEX IF NOT EXISTS idx_cards_layout
      ON cards (layout);
    ''',
    down: '''
      DROP INDEX IF EXISTS idx_cards_layout;
      DROP INDEX IF EXISTS idx_cards_oracle_id;
      ALTER TABLE cards DROP COLUMN IF EXISTS card_faces_json;
      ALTER TABLE cards DROP COLUMN IF EXISTS layout;
      ALTER TABLE cards DROP COLUMN IF EXISTS oracle_id;
    ''',
  ),
  Migration(
    version: '022',
    name: 'create_card_identity_and_intelligence_views',
    up: '''
      CREATE TABLE IF NOT EXISTS card_meta_insights (
        card_name TEXT PRIMARY KEY,
        usage_count INTEGER NOT NULL DEFAULT 0,
        meta_deck_count INTEGER NOT NULL DEFAULT 0,
        common_archetypes TEXT[] NOT NULL DEFAULT '{}',
        common_formats TEXT[] NOT NULL DEFAULT '{}',
        top_pairs JSONB NOT NULL DEFAULT '[]'::jsonb,
        learned_role TEXT,
        versatility_score NUMERIC(6,3) NOT NULL DEFAULT 0,
        created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
        last_updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
      );

      CREATE INDEX IF NOT EXISTS idx_card_meta_insights_usage
      ON card_meta_insights (usage_count DESC);

      CREATE INDEX IF NOT EXISTS idx_card_meta_insights_archetypes
      ON card_meta_insights USING gin (common_archetypes);

      $createCardLocalizedNamesTableSql;

      ${createCardLocalizedNamesIndexesSql.join(';\n')};

      ${candidateQualitySchemaStatements.join(';\n')};

      ${candidateQualityIndexStatements.join(';\n')};

      $optimizeCandidateQualitySummaryViewStatement;

      $cardIntelligenceSnapshotViewStatement;

      $createCardIdentityBridgeViewSql;
    ''',
    down: '''
      DROP VIEW IF EXISTS card_identity_bridge;
      DROP VIEW IF EXISTS card_intelligence_snapshot;
      DROP VIEW IF EXISTS optimize_candidate_quality_summary;
      DROP INDEX IF EXISTS idx_card_meta_insights_archetypes;
      DROP INDEX IF EXISTS idx_card_meta_insights_usage;
    ''',
  ),
  Migration(
    version: '023',
    name: 'create_commander_learning_snapshot',
    up: '''
      CREATE TABLE IF NOT EXISTS commander_learned_decks (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        commander_name TEXT NOT NULL,
        commander_name_normalized TEXT NOT NULL,
        deck_name TEXT NOT NULL,
        source_system TEXT NOT NULL,
        source_ref TEXT NOT NULL,
        source_url TEXT,
        archetype TEXT,
        card_list TEXT NOT NULL,
        card_count INTEGER NOT NULL,
        score NUMERIC,
        wincon_primary TEXT,
        wincon_backup TEXT,
        legal_status TEXT,
        notes TEXT,
        metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
        is_active BOOLEAN NOT NULL DEFAULT FALSE,
        promoted_at TIMESTAMPTZ,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        UNIQUE (source_system, source_ref)
      );

      CREATE INDEX IF NOT EXISTS idx_commander_learned_decks_active
      ON commander_learned_decks (
        commander_name_normalized,
        is_active,
        promoted_at DESC,
        updated_at DESC
      );

      CREATE TABLE IF NOT EXISTS deck_learning_events (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        deck_id UUID NOT NULL,
        commander_name TEXT,
        format TEXT NOT NULL,
        card_count INTEGER NOT NULL DEFAULT 0,
        source TEXT NOT NULL DEFAULT 'user_created',
        event_data JSONB DEFAULT '{}'::jsonb,
        synced_to_hermes BOOLEAN NOT NULL DEFAULT FALSE,
        synced_at TIMESTAMPTZ,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );

      CREATE INDEX IF NOT EXISTS idx_deck_learning_events_synced
      ON deck_learning_events (synced_to_hermes, created_at);

      CREATE TABLE IF NOT EXISTS commander_card_usage (
        commander_name_normalized TEXT NOT NULL,
        card_name_normalized TEXT NOT NULL,
        usage_count INTEGER NOT NULL DEFAULT 1,
        last_used_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        PRIMARY KEY (commander_name_normalized, card_name_normalized)
      );

      CREATE INDEX IF NOT EXISTS idx_commander_card_usage_commander
      ON commander_card_usage (commander_name_normalized, usage_count DESC);

      $commanderLearningSnapshotViewStatement;
    ''',
    down: '''
      DROP VIEW IF EXISTS commander_learning_snapshot;
      DROP TABLE IF EXISTS commander_card_usage CASCADE;
      DROP TABLE IF EXISTS deck_learning_events CASCADE;
      DROP TABLE IF EXISTS commander_learned_decks CASCADE;
    ''',
  ),
  Migration(
    version: '024',
    name: 'refresh_commander_learning_snapshot_bridge_resolution',
    up: '''
      $commanderLearningSnapshotViewStatement;
    ''',
    down: '''
      DROP VIEW IF EXISTS commander_learning_snapshot;
    ''',
  ),
  Migration(
    version: '025',
    name: 'refresh_optimize_candidate_quality_summary_anti_fanout',
    up: '''
      $optimizeCandidateQualitySummaryViewStatement;
    ''',
    down: '''
      DROP VIEW IF EXISTS optimize_candidate_quality_summary;
    ''',
  ),
  Migration(
    version: '026',
    name: 'default_card_battle_rules_source_curated',
    up: '''
      ALTER TABLE card_battle_rules
      ALTER COLUMN source SET DEFAULT 'curated';
    ''',
    down: '''
      ALTER TABLE card_battle_rules
      ALTER COLUMN source SET DEFAULT 'manual';
    ''',
  ),
  Migration(
    version: '027',
    name: 'normalize_legacy_manual_battle_rule_sources',
    up: '''
      UPDATE card_battle_rules
      SET
        source = 'curated',
        notes = trim(
          both ' ' from
          regexp_replace(
            COALESCE(notes, ''),
            'Seeded from HANDCRAFTED_KNOWN_CARDS\\.',
            'Migrated from legacy HANDCRAFTED_KNOWN_CARDS provenance to curated source on 2026-06-17.',
            'g'
          )
        ),
        updated_at = CURRENT_TIMESTAMP
      WHERE source = 'manual'
        AND notes ILIKE '%HANDCRAFTED_KNOWN_CARDS%';
    ''',
    down: '''
      UPDATE card_battle_rules
      SET
        source = 'manual',
        notes = trim(
          both ' ' from
          regexp_replace(
            COALESCE(notes, ''),
            'Migrated from legacy HANDCRAFTED_KNOWN_CARDS provenance to curated source on 2026-06-17\\.',
            'Seeded from HANDCRAFTED_KNOWN_CARDS.',
            'g'
          )
        ),
        updated_at = CURRENT_TIMESTAMP
      WHERE source = 'curated'
        AND notes ILIKE '%legacy HANDCRAFTED_KNOWN_CARDS provenance%';
    ''',
  ),
  Migration(
    version: '028',
    name: 'persist_card_battle_rules_logical_rule_key',
    up: '''
      ALTER TABLE card_battle_rules
      ADD COLUMN IF NOT EXISTS logical_rule_key TEXT;

      UPDATE card_battle_rules
      SET logical_rule_key = 'battle_rule_v1:' || substring(md5(
        jsonb_build_object(
          'effect', COALESCE(effect_json, '{}'::jsonb),
          'deck_role', COALESCE(deck_role_json, '{}'::jsonb),
          'face_name', COALESCE(effect_json->>'face_name', deck_role_json->>'face_name'),
          'face_index', COALESCE(effect_json->>'face_index', deck_role_json->>'face_index'),
          'variant_kind', COALESCE(effect_json->>'variant_kind', deck_role_json->>'variant_kind'),
          'ability_kind', COALESCE(effect_json->>'ability_kind', deck_role_json->>'ability_kind'),
          'timing_window', COALESCE(effect_json->>'timing_window', deck_role_json->>'timing_window'),
          'source_zone', COALESCE(effect_json->>'source_zone', deck_role_json->>'source_zone')
        )::text
      ) from 1 for 32)
      WHERE logical_rule_key IS NULL OR logical_rule_key = '';

      ALTER TABLE card_battle_rules
      ALTER COLUMN logical_rule_key SET NOT NULL;

      ALTER TABLE card_battle_rules
      DROP CONSTRAINT IF EXISTS card_battle_rules_pkey;

      ALTER TABLE card_battle_rules
      ADD CONSTRAINT card_battle_rules_pkey
      PRIMARY KEY (normalized_name, logical_rule_key);

      CREATE INDEX IF NOT EXISTS idx_card_battle_rules_normalized_name
      ON card_battle_rules (normalized_name);

      $cardIntelligenceSnapshotViewStatement;
      $optimizeCandidateQualitySummaryViewStatement;
    ''',
    down: '''
      DROP VIEW IF EXISTS optimize_candidate_quality_summary;
      DROP VIEW IF EXISTS card_intelligence_snapshot;

      DELETE FROM card_battle_rules a
      USING card_battle_rules b
      WHERE a.ctid < b.ctid
        AND a.normalized_name = b.normalized_name;

      DROP INDEX IF EXISTS idx_card_battle_rules_normalized_name;

      ALTER TABLE card_battle_rules
      DROP CONSTRAINT IF EXISTS card_battle_rules_pkey;

      ALTER TABLE card_battle_rules
      ADD CONSTRAINT card_battle_rules_pkey
      PRIMARY KEY (normalized_name);

      ALTER TABLE card_battle_rules
      DROP COLUMN IF EXISTS logical_rule_key;
    ''',
  ),
  Migration(
    version: '029',
    name: 'add_card_battle_rules_execution_status',
    up: '''
      ALTER TABLE card_battle_rules
      ADD COLUMN IF NOT EXISTS execution_status TEXT;

      UPDATE card_battle_rules
      SET execution_status = CASE
        WHEN review_status IN ('rejected', 'deprecated') THEN 'disabled'
        WHEN review_status = 'needs_review' THEN 'review_only'
        ELSE 'auto'
      END
      WHERE execution_status IS NULL OR execution_status = '';

      ALTER TABLE card_battle_rules
      ALTER COLUMN execution_status SET DEFAULT 'auto';

      ALTER TABLE card_battle_rules
      ALTER COLUMN execution_status SET NOT NULL;

      ALTER TABLE card_battle_rules
      DROP CONSTRAINT IF EXISTS chk_card_battle_rules_execution_status;

      ALTER TABLE card_battle_rules
      ADD CONSTRAINT chk_card_battle_rules_execution_status CHECK (
        execution_status IN (
          'auto',
          'executable',
          'annotation_only',
          'review_only',
          'disabled'
        )
      );

      $cardIntelligenceSnapshotViewStatement;
      $optimizeCandidateQualitySummaryViewStatement;
    ''',
    down: '''
      DROP VIEW IF EXISTS optimize_candidate_quality_summary;
      DROP VIEW IF EXISTS card_intelligence_snapshot;
      ALTER TABLE card_battle_rules
      DROP CONSTRAINT IF EXISTS chk_card_battle_rules_execution_status;
      ALTER TABLE card_battle_rules
      DROP COLUMN IF EXISTS execution_status;
    ''',
  ),
  Migration(
    version: '030',
    name: 'create_retention_and_shareable_report_tables',
    up: '''
      CREATE TABLE IF NOT EXISTS post_game_notes (
        id TEXT PRIMARY KEY,
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        deck_id UUID NOT NULL REFERENCES decks(id) ON DELETE CASCADE,
        created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
        result TEXT NOT NULL DEFAULT '',
        table_level TEXT NOT NULL DEFAULT '',
        notes TEXT NOT NULL DEFAULT '',
        performed_well JSONB NOT NULL DEFAULT '[]'::jsonb,
        underperformed JSONB NOT NULL DEFAULT '[]'::jsonb,
        issues JSONB NOT NULL DEFAULT '[]'::jsonb,
        updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
      );

      CREATE INDEX IF NOT EXISTS idx_post_game_notes_deck_created
      ON post_game_notes (deck_id, created_at DESC);

      CREATE INDEX IF NOT EXISTS idx_post_game_notes_user_updated
      ON post_game_notes (user_id, updated_at DESC);

      CREATE TABLE IF NOT EXISTS shared_deck_reports (
        id TEXT PRIMARY KEY,
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        deck_id UUID REFERENCES decks(id) ON DELETE SET NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        payload JSONB NOT NULL,
        is_public BOOLEAN NOT NULL DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
        expires_at TIMESTAMP WITH TIME ZONE
      );

      CREATE INDEX IF NOT EXISTS idx_shared_deck_reports_deck_created
      ON shared_deck_reports (deck_id, created_at DESC);

      CREATE INDEX IF NOT EXISTS idx_shared_deck_reports_public_updated
      ON shared_deck_reports (is_public, updated_at DESC);
    ''',
    down: '''
      DROP INDEX IF EXISTS idx_shared_deck_reports_public_updated;
      DROP INDEX IF EXISTS idx_shared_deck_reports_deck_created;
      DROP TABLE IF EXISTS shared_deck_reports CASCADE;
      DROP INDEX IF EXISTS idx_post_game_notes_user_updated;
      DROP INDEX IF EXISTS idx_post_game_notes_deck_created;
      DROP TABLE IF EXISTS post_game_notes CASCADE;
    ''',
  ),
  Migration(
    version: '031',
    name: 'create_community_engagement_tables',
    up: '''
      CREATE TABLE IF NOT EXISTS deck_comments (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        deck_id UUID NOT NULL REFERENCES decks(id) ON DELETE CASCADE,
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        body TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'visible',
        created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT chk_deck_comments_status CHECK (
          status IN ('visible', 'hidden', 'deleted')
        ),
        CONSTRAINT chk_deck_comments_body_length CHECK (
          char_length(body) BETWEEN 3 AND 1200
        )
      );

      CREATE INDEX IF NOT EXISTS idx_deck_comments_deck_created
      ON deck_comments (deck_id, created_at DESC)
      WHERE status = 'visible';

      CREATE INDEX IF NOT EXISTS idx_deck_comments_user_created
      ON deck_comments (user_id, created_at DESC);

      CREATE TABLE IF NOT EXISTS content_reports (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        reporter_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
        target_type TEXT NOT NULL,
        target_id TEXT NOT NULL,
        reason TEXT NOT NULL,
        details TEXT NOT NULL DEFAULT '',
        status TEXT NOT NULL DEFAULT 'open',
        created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
        reviewed_at TIMESTAMP WITH TIME ZONE,
        reviewed_by UUID REFERENCES users(id) ON DELETE SET NULL,
        CONSTRAINT chk_content_reports_target_type CHECK (
          target_type IN ('deck', 'comment', 'profile', 'binder_item')
        ),
        CONSTRAINT chk_content_reports_reason CHECK (
          reason IN ('spam', 'abuse', 'scam', 'inappropriate', 'copyright', 'other')
        ),
        CONSTRAINT chk_content_reports_status CHECK (
          status IN ('open', 'reviewing', 'resolved', 'dismissed')
        )
      );

      CREATE INDEX IF NOT EXISTS idx_content_reports_target_status
      ON content_reports (target_type, target_id, status, created_at DESC);
    ''',
    down: '''
      DROP INDEX IF EXISTS idx_content_reports_target_status;
      DROP TABLE IF EXISTS content_reports CASCADE;
      DROP INDEX IF EXISTS idx_deck_comments_user_created;
      DROP INDEX IF EXISTS idx_deck_comments_deck_created;
      DROP TABLE IF EXISTS deck_comments CASCADE;
    ''',
  ),
  Migration(
    version: '032',
    name: 'refresh_card_intelligence_snapshot_rule_identity_fallback',
    up: '''
      $cardIntelligenceSnapshotViewStatement;
    ''',
    down: '''
      DROP VIEW IF EXISTS card_intelligence_snapshot;
    ''',
  ),
  Migration(
    version: '033',
    name: 'create_deck_optimization_events',
    up: '''
      CREATE TABLE IF NOT EXISTS deck_optimization_events (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        deck_id UUID NOT NULL REFERENCES decks(id) ON DELETE CASCADE,
        event_type TEXT NOT NULL DEFAULT 'optimize_apply',
        mode TEXT NOT NULL DEFAULT '',
        intensity TEXT NOT NULL DEFAULT '',
        archetype TEXT NOT NULL DEFAULT '',
        bracket INT,
        selected_change_count INT NOT NULL DEFAULT 0,
        removals JSONB NOT NULL DEFAULT '[]'::jsonb,
        additions JSONB NOT NULL DEFAULT '[]'::jsonb,
        before_snapshot JSONB NOT NULL DEFAULT '{}'::jsonb,
        after_snapshot JSONB NOT NULL DEFAULT '{}'::jsonb,
        recommendation_context JSONB NOT NULL DEFAULT '{}'::jsonb,
        validation_status TEXT NOT NULL DEFAULT 'preview_applied',
        battle_status TEXT NOT NULL DEFAULT 'pending_after_apply',
        battle_message TEXT NOT NULL DEFAULT '',
        report_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
        created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
      );

      CREATE INDEX IF NOT EXISTS idx_deck_optimization_events_deck_created
      ON deck_optimization_events (deck_id, created_at DESC);

      CREATE INDEX IF NOT EXISTS idx_deck_optimization_events_user_created
      ON deck_optimization_events (user_id, created_at DESC);
    ''',
    down: '''
      DROP INDEX IF EXISTS idx_deck_optimization_events_user_created;
      DROP INDEX IF EXISTS idx_deck_optimization_events_deck_created;
      DROP TABLE IF EXISTS deck_optimization_events CASCADE;
    ''',
  ),
  Migration(
    version: '034',
    name: 'create_commander_reference_tables',
    up: '''
      CREATE TABLE IF NOT EXISTS commander_reference_profiles (
        commander_name TEXT PRIMARY KEY,
        source TEXT NOT NULL,
        deck_count INTEGER NOT NULL DEFAULT 0,
        profile_json JSONB NOT NULL,
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );

      CREATE TABLE IF NOT EXISTS commander_reference_card_stats (
        commander_name TEXT NOT NULL,
        commander_name_normalized TEXT NOT NULL,
        card_name TEXT NOT NULL,
        card_name_normalized TEXT NOT NULL,
        card_id UUID REFERENCES cards(id) ON DELETE SET NULL,
        package_key TEXT NOT NULL,
        role TEXT NOT NULL,
        score NUMERIC NOT NULL,
        confidence TEXT NOT NULL,
        confidence_rank SMALLINT NOT NULL,
        source TEXT NOT NULL,
        evidence_count INTEGER NOT NULL DEFAULT 1,
        unresolved BOOLEAN NOT NULL DEFAULT FALSE,
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        PRIMARY KEY (
          commander_name_normalized,
          card_name_normalized,
          package_key
        )
      );

      CREATE INDEX IF NOT EXISTS idx_commander_reference_card_stats_hot
      ON commander_reference_card_stats (
        commander_name_normalized,
        confidence_rank DESC,
        score DESC
      )
      WHERE unresolved = FALSE;

      CREATE INDEX IF NOT EXISTS idx_commander_reference_card_stats_unresolved
      ON commander_reference_card_stats (
        commander_name_normalized,
        unresolved,
        card_name_normalized
      );

      CREATE TABLE IF NOT EXISTS commander_reference_decks (
        source_deck_key TEXT PRIMARY KEY,
        commander_name TEXT NOT NULL,
        commander_name_normalized TEXT NOT NULL,
        source TEXT NOT NULL,
        source_url TEXT,
        power_lane TEXT,
        theme TEXT,
        deck_hash TEXT NOT NULL,
        main_quantity INTEGER NOT NULL,
        commander_quantity INTEGER NOT NULL,
        resolved_count INTEGER NOT NULL,
        unresolved_count INTEGER NOT NULL,
        off_color_count INTEGER NOT NULL,
        singleton_violations JSONB NOT NULL DEFAULT '{}'::jsonb,
        role_summary JSONB NOT NULL DEFAULT '{}'::jsonb,
        accepted BOOLEAN NOT NULL DEFAULT FALSE,
        rejection_reasons JSONB NOT NULL DEFAULT '[]'::jsonb,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );

      CREATE TABLE IF NOT EXISTS commander_reference_deck_cards (
        source_deck_key TEXT NOT NULL
          REFERENCES commander_reference_decks(source_deck_key)
          ON DELETE CASCADE,
        board TEXT NOT NULL,
        card_name TEXT NOT NULL,
        card_name_normalized TEXT NOT NULL,
        card_id UUID REFERENCES cards(id) ON DELETE SET NULL,
        quantity INTEGER NOT NULL,
        role TEXT NOT NULL,
        unresolved BOOLEAN NOT NULL DEFAULT FALSE,
        off_color BOOLEAN NOT NULL DEFAULT FALSE,
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        PRIMARY KEY (source_deck_key, board, card_name_normalized)
      );

      CREATE TABLE IF NOT EXISTS commander_reference_deck_analysis (
        commander_name_normalized TEXT NOT NULL,
        source TEXT NOT NULL,
        commander_name TEXT NOT NULL,
        deck_count INTEGER NOT NULL,
        accepted_deck_count INTEGER NOT NULL,
        average_role_counts JSONB NOT NULL DEFAULT '{}'::jsonb,
        top_cards JSONB NOT NULL DEFAULT '[]'::jsonb,
        theme_counts JSONB NOT NULL DEFAULT '{}'::jsonb,
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        PRIMARY KEY (commander_name_normalized, source)
      );

      CREATE INDEX IF NOT EXISTS idx_commander_reference_decks_lookup
      ON commander_reference_decks (
        commander_name_normalized,
        accepted,
        updated_at DESC
      );

      CREATE INDEX IF NOT EXISTS idx_commander_reference_deck_cards_hot
      ON commander_reference_deck_cards (
        card_name_normalized,
        role,
        unresolved,
        off_color
      );
    ''',
    down: '''
      DROP INDEX IF EXISTS idx_commander_reference_deck_cards_hot;
      DROP INDEX IF EXISTS idx_commander_reference_decks_lookup;
      DROP TABLE IF EXISTS commander_reference_deck_analysis CASCADE;
      DROP TABLE IF EXISTS commander_reference_deck_cards CASCADE;
      DROP TABLE IF EXISTS commander_reference_decks CASCADE;
      DROP INDEX IF EXISTS idx_commander_reference_card_stats_unresolved;
      DROP INDEX IF EXISTS idx_commander_reference_card_stats_hot;
      DROP TABLE IF EXISTS commander_reference_card_stats CASCADE;
      DROP TABLE IF EXISTS commander_reference_profiles CASCADE;
    ''',
  ),
  Migration(
    version: '035',
    name: 'create_data_source_snapshots',
    up: '''
      ALTER TABLE IF EXISTS card_rulings
      ALTER COLUMN source SET DEFAULT 'scryfall';
      ALTER TABLE IF EXISTS card_rulings
      ADD COLUMN IF NOT EXISTS ruling_source TEXT NOT NULL DEFAULT '';

      CREATE TABLE IF NOT EXISTS data_source_snapshots (
        id BIGSERIAL PRIMARY KEY,
        dataset TEXT NOT NULL,
        provider TEXT NOT NULL,
        source_uri TEXT NOT NULL,
        source_version TEXT NOT NULL DEFAULT '',
        source_updated_at TIMESTAMPTZ NOT NULL,
        source_etag TEXT NOT NULL DEFAULT '',
        content_sha256 TEXT NOT NULL,
        row_count BIGINT NOT NULL,
        distinct_identity_count BIGINT NOT NULL,
        latest_published_at DATE,
        status TEXT NOT NULL,
        metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
        started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        completed_at TIMESTAMPTZ
      );

      CREATE UNIQUE INDEX IF NOT EXISTS uniq_data_source_snapshots_content
      ON data_source_snapshots (dataset, provider, content_sha256);

      CREATE INDEX IF NOT EXISTS idx_data_source_snapshots_latest
      ON data_source_snapshots (dataset, provider, completed_at DESC);
    ''',
    down: '''
      DROP INDEX IF EXISTS idx_data_source_snapshots_latest;
      DROP INDEX IF EXISTS uniq_data_source_snapshots_content;
      DROP TABLE IF EXISTS data_source_snapshots CASCADE;
      ALTER TABLE IF EXISTS card_rulings
      DROP COLUMN IF EXISTS ruling_source;
      ALTER TABLE IF EXISTS card_rulings
      ALTER COLUMN source SET DEFAULT 'mtgjson';
    ''',
  ),
  Migration(
    version: '036',
    name: 'enforce_commander_bracket_range',
    up: '''
      UPDATE decks
      SET bracket = 5
      WHERE bracket = 4
        AND created_at < TIMESTAMPTZ '2026-07-16 16:45:00+00';
      UPDATE ai_user_preferences
      SET preferred_bracket = 5
      WHERE preferred_bracket = 4
        AND created_at < TIMESTAMPTZ '2026-07-16 16:45:00+00';
      UPDATE decks
      SET bracket = NULL
      WHERE bracket IS NOT NULL AND bracket NOT BETWEEN 1 AND 5;
      ALTER TABLE decks
      ADD CONSTRAINT chk_decks_commander_bracket
      CHECK (bracket IS NULL OR bracket BETWEEN 1 AND 5);
      UPDATE ai_user_preferences
      SET preferred_bracket = NULL
      WHERE preferred_bracket IS NOT NULL
        AND preferred_bracket NOT BETWEEN 1 AND 5;
      ALTER TABLE ai_user_preferences
      ADD CONSTRAINT chk_ai_user_preferences_commander_bracket
      CHECK (
        preferred_bracket IS NULL OR preferred_bracket BETWEEN 1 AND 5
      );
    ''',
    down: '''
      ALTER TABLE ai_user_preferences
      DROP CONSTRAINT IF EXISTS chk_ai_user_preferences_commander_bracket;
      ALTER TABLE decks
      DROP CONSTRAINT IF EXISTS chk_decks_commander_bracket;
    ''',
  ),
  Migration(
    version: '037',
    name: 'normalize_candidate_bracket_scopes',
    up: '''
      DELETE FROM card_role_scores legacy
      USING card_role_scores canonical
      WHERE legacy.card_id = canonical.card_id
        AND legacy.role = canonical.role
        AND legacy.format = canonical.format
        AND legacy.subformat = canonical.subformat
        AND legacy.source = canonical.source
        AND legacy.bracket_scope IN (
          'bracket_2_4', 'bracket_2_5', 'bracket_3_4', 'bracket_3_5'
        )
        AND canonical.bracket_scope = CASE
          WHEN legacy.bracket_scope IN ('bracket_2_4', 'bracket_2_5')
            THEN 'bracket_2_plus'
          ELSE 'bracket_3_plus'
        END;
      UPDATE card_role_scores
      SET bracket_scope = CASE
        WHEN bracket_scope IN ('bracket_2_4', 'bracket_2_5')
          THEN 'bracket_2_plus'
        ELSE 'bracket_3_plus'
      END
      WHERE bracket_scope IN (
        'bracket_2_4', 'bracket_2_5', 'bracket_3_4', 'bracket_3_5'
      );
    ''',
    down: '''
      UPDATE card_role_scores
      SET bracket_scope = CASE
        WHEN bracket_scope = 'bracket_2_plus' THEN 'bracket_2_5'
        ELSE 'bracket_3_5'
      END
      WHERE bracket_scope IN ('bracket_2_plus', 'bracket_3_plus');
    ''',
  ),
  Migration(
    version: '038',
    name: 'add_privacy_and_post_game_sync_contracts',
    up: '''
      CREATE EXTENSION IF NOT EXISTS "pgcrypto";

      ALTER TABLE users
      ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE;

      CREATE INDEX IF NOT EXISTS idx_users_active_identity
      ON users (LOWER(email), LOWER(username))
      WHERE deleted_at IS NULL;

      CREATE OR REPLACE FUNCTION manaloom_require_active_user()
      RETURNS trigger
      LANGUAGE plpgsql
      AS \$active_user_function\$
      DECLARE
        referenced_user_id UUID;
      BEGIN
        referenced_user_id := NULLIF(to_jsonb(NEW) ->> TG_ARGV[0], '')::UUID;
        IF referenced_user_id IS NULL THEN
          RETURN NEW;
        END IF;

        PERFORM 1
        FROM users
        WHERE id = referenced_user_id
          AND deleted_at IS NULL
        FOR UPDATE;

        IF NOT FOUND THEN
          RAISE EXCEPTION USING
            ERRCODE = '23503',
            MESSAGE = 'inactive_user_reference';
        END IF;
        RETURN NEW;
      END;
      \$active_user_function\$;

      DO \$active_user_triggers\$
      DECLARE
        reference RECORD;
        trigger_name TEXT;
      BEGIN
        FOR reference IN
          SELECT constraint_row.oid AS constraint_oid,
                 namespace_row.nspname AS schema_name,
                 relation_row.relname AS table_name,
                 attribute_row.attname AS column_name
          FROM pg_constraint constraint_row
          JOIN pg_class relation_row
            ON relation_row.oid = constraint_row.conrelid
          JOIN pg_namespace namespace_row
            ON namespace_row.oid = relation_row.relnamespace
          JOIN pg_attribute attribute_row
            ON attribute_row.attrelid = relation_row.oid
           AND attribute_row.attnum = constraint_row.conkey[1]
          WHERE constraint_row.contype = 'f'
            AND constraint_row.confrelid = 'users'::regclass
            AND array_length(constraint_row.conkey, 1) = 1
        LOOP
          trigger_name := 'manaloom_active_user_' || reference.constraint_oid;
          EXECUTE format(
            'DROP TRIGGER IF EXISTS %I ON %I.%I',
            trigger_name,
            reference.schema_name,
            reference.table_name
          );
          EXECUTE format(
            'CREATE TRIGGER %I BEFORE INSERT OR UPDATE OF %I ON %I.%I '
            'FOR EACH ROW EXECUTE FUNCTION manaloom_require_active_user(%L)',
            trigger_name,
            reference.column_name,
            reference.schema_name,
            reference.table_name,
            reference.column_name
          );
        END LOOP;
      END;
      \$active_user_triggers\$;

      ALTER TABLE post_game_notes
      ADD COLUMN IF NOT EXISTS play_session_id TEXT;
      ALTER TABLE post_game_notes
      ADD COLUMN IF NOT EXISTS session_started_at TIMESTAMP WITH TIME ZONE;
      ALTER TABLE post_game_notes
      ADD COLUMN IF NOT EXISTS session_ended_at TIMESTAMP WITH TIME ZONE;
      ALTER TABLE post_game_notes
      ADD COLUMN IF NOT EXISTS deck_snapshot_hash TEXT;
      ALTER TABLE post_game_notes
      ADD COLUMN IF NOT EXISTS deck_version_at TIMESTAMP WITH TIME ZONE;
      ALTER TABLE post_game_notes
      ADD COLUMN IF NOT EXISTS revision BIGINT NOT NULL DEFAULT 1;
      ALTER TABLE post_game_notes
      ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE;

      ALTER TABLE post_game_notes
      DROP CONSTRAINT IF EXISTS chk_post_game_notes_revision;
      ALTER TABLE post_game_notes
      ADD CONSTRAINT chk_post_game_notes_revision CHECK (revision > 0);

      ALTER TABLE post_game_notes
      DROP CONSTRAINT IF EXISTS chk_post_game_notes_session_order;
      ALTER TABLE post_game_notes
      ADD CONSTRAINT chk_post_game_notes_session_order CHECK (
        session_started_at IS NULL
        OR session_ended_at IS NULL
        OR session_ended_at >= session_started_at
      );

      CREATE INDEX IF NOT EXISTS idx_post_game_notes_user_sync
      ON post_game_notes (user_id, updated_at, revision);

      CREATE INDEX IF NOT EXISTS idx_post_game_notes_tombstones
      ON post_game_notes (user_id, deck_id, updated_at)
      WHERE deleted_at IS NOT NULL;

      CREATE UNIQUE INDEX IF NOT EXISTS uq_post_game_notes_play_session
      ON post_game_notes (user_id, deck_id, play_session_id)
      WHERE play_session_id IS NOT NULL AND deleted_at IS NULL;

      CREATE TABLE IF NOT EXISTS post_game_sync_state (
        id SMALLINT PRIMARY KEY CHECK (id = 1),
        watermark TIMESTAMP WITH TIME ZONE NOT NULL
      );

      INSERT INTO post_game_sync_state (id, watermark)
      SELECT 1, GREATEST(
        CURRENT_TIMESTAMP,
        COALESCE(MAX(updated_at), CURRENT_TIMESTAMP)
      )
      FROM post_game_notes
      ON CONFLICT (id) DO UPDATE
      SET watermark = GREATEST(
        post_game_sync_state.watermark,
        EXCLUDED.watermark
      );

      CREATE TABLE IF NOT EXISTS account_deletion_receipts (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        policy_version TEXT NOT NULL,
        deletion_mode TEXT NOT NULL,
        retention_summary JSONB NOT NULL DEFAULT '{}'::jsonb,
        completed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT chk_account_deletion_mode CHECK (
          deletion_mode IN ('anonymized')
        )
      );

      CREATE INDEX IF NOT EXISTS idx_account_deletion_receipts_completed
      ON account_deletion_receipts (completed_at DESC);

      CREATE TABLE IF NOT EXISTS privacy_keyring (
        key_version SMALLINT PRIMARY KEY,
        hmac_key BYTEA NOT NULL CHECK (octet_length(hmac_key) >= 32),
        is_active BOOLEAN NOT NULL DEFAULT FALSE,
        created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
      );

      CREATE UNIQUE INDEX IF NOT EXISTS uq_privacy_keyring_active
      ON privacy_keyring (is_active)
      WHERE is_active = TRUE;

      INSERT INTO privacy_keyring (key_version, hmac_key, is_active)
      VALUES (1, gen_random_bytes(32), FALSE)
      ON CONFLICT (key_version) DO NOTHING;

      UPDATE privacy_keyring
      SET is_active = TRUE
      WHERE key_version = (SELECT MIN(key_version) FROM privacy_keyring)
        AND NOT EXISTS (
          SELECT 1 FROM privacy_keyring WHERE is_active = TRUE
        );

      CREATE TABLE IF NOT EXISTS privacy_deleted_deck_tombstones (
        key_version SMALLINT NOT NULL
          REFERENCES privacy_keyring(key_version) ON DELETE RESTRICT,
        deck_token TEXT NOT NULL CHECK (char_length(deck_token) = 64),
        deleted_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (key_version, deck_token)
      );

      CREATE INDEX IF NOT EXISTS idx_privacy_deleted_deck_token
      ON privacy_deleted_deck_tombstones (deck_token);

      CREATE OR REPLACE FUNCTION manaloom_guard_deck_learning_event()
      RETURNS trigger
      LANGUAGE plpgsql
      AS \$deck_learning_guard\$
      DECLARE
        owner_user_id UUID;
      BEGIN
        SELECT user_id
        INTO owner_user_id
        FROM decks
        WHERE id = NEW.deck_id;

        IF owner_user_id IS NOT NULL THEN
          PERFORM 1
          FROM users
          WHERE id = owner_user_id
            AND deleted_at IS NULL
          FOR UPDATE;
          IF NOT FOUND THEN
            RAISE EXCEPTION USING
              ERRCODE = '23503',
              MESSAGE = 'inactive_deck_owner_reference';
          END IF;
        ELSIF EXISTS (
          SELECT 1
          FROM privacy_deleted_deck_tombstones tombstone
          JOIN privacy_keyring keyring
            ON keyring.key_version = tombstone.key_version
          WHERE tombstone.deck_token = encode(
            hmac(
              convert_to(NEW.deck_id::text, 'UTF8'),
              keyring.hmac_key,
              'sha256'
            ),
            'hex'
          )
        ) THEN
          RAISE EXCEPTION USING
            ERRCODE = '23503',
            MESSAGE = 'deleted_deck_learning_event_rejected';
        END IF;

        RETURN NEW;
      END;
      \$deck_learning_guard\$;

      CREATE OR REPLACE FUNCTION manaloom_guard_battle_simulation()
      RETURNS trigger
      LANGUAGE plpgsql
      AS \$battle_simulation_guard\$
      DECLARE
        referenced_decks UUID[];
        expected_owner_count INTEGER;
        active_owner_count INTEGER;
        active_owner_id UUID;
      BEGIN
        referenced_decks := ARRAY[
          NULLIF(to_jsonb(NEW) ->> 'deck_a_id', '')::UUID,
          NULLIF(to_jsonb(NEW) ->> 'deck_b_id', '')::UUID,
          NULLIF(to_jsonb(NEW) ->> 'winner_deck_id', '')::UUID
        ];

        SELECT COUNT(DISTINCT deck.user_id)::INTEGER
        INTO expected_owner_count
        FROM decks deck
        WHERE deck.id = ANY(referenced_decks);

        active_owner_count := 0;
        FOR active_owner_id IN
          SELECT user_row.id
          FROM users user_row
          WHERE user_row.id IN (
            SELECT DISTINCT deck.user_id
            FROM decks deck
            WHERE deck.id = ANY(referenced_decks)
          )
            AND user_row.deleted_at IS NULL
          ORDER BY user_row.id
          FOR UPDATE
        LOOP
          active_owner_count := active_owner_count + 1;
        END LOOP;

        IF active_owner_count <> expected_owner_count THEN
          RAISE EXCEPTION USING
            ERRCODE = '23503',
            MESSAGE = 'inactive_battle_deck_owner_reference';
        END IF;

        RETURN NEW;
      END;
      \$battle_simulation_guard\$;

      DO \$deck_learning_trigger\$
      BEGIN
        IF to_regclass('public.deck_learning_events') IS NOT NULL THEN
          DROP TRIGGER IF EXISTS manaloom_guard_deck_learning_event
          ON deck_learning_events;
          CREATE TRIGGER manaloom_guard_deck_learning_event
          BEFORE INSERT OR UPDATE OF deck_id ON deck_learning_events
          FOR EACH ROW
          EXECUTE FUNCTION manaloom_guard_deck_learning_event();
        END IF;
      END;
      \$deck_learning_trigger\$;

      DO \$battle_simulation_trigger\$
      BEGIN
        IF to_regclass('public.battle_simulations') IS NOT NULL THEN
          DROP TRIGGER IF EXISTS manaloom_guard_battle_simulation
          ON battle_simulations;
          CREATE TRIGGER manaloom_guard_battle_simulation
          BEFORE INSERT OR UPDATE OF deck_a_id, deck_b_id, winner_deck_id
          ON battle_simulations
          FOR EACH ROW
          EXECUTE FUNCTION manaloom_guard_battle_simulation();
        END IF;
      END;
      \$battle_simulation_trigger\$;

      ALTER TABLE IF EXISTS trade_items
      DROP CONSTRAINT IF EXISTS trade_items_binder_item_id_fkey;
      ALTER TABLE IF EXISTS trade_items
      ALTER COLUMN binder_item_id DROP NOT NULL;
      ALTER TABLE IF EXISTS trade_items
      ADD CONSTRAINT trade_items_binder_item_id_fkey
      FOREIGN KEY (binder_item_id)
      REFERENCES user_binder_items(id)
      ON DELETE SET NULL;
    ''',
    down: '''
      DO \$battle_simulation_trigger\$
      BEGIN
        IF to_regclass('public.battle_simulations') IS NOT NULL THEN
          DROP TRIGGER IF EXISTS manaloom_guard_battle_simulation
          ON battle_simulations;
        END IF;
      END;
      \$battle_simulation_trigger\$;
      DROP FUNCTION IF EXISTS manaloom_guard_battle_simulation();
      DO \$deck_learning_trigger\$
      BEGIN
        IF to_regclass('public.deck_learning_events') IS NOT NULL THEN
          DROP TRIGGER IF EXISTS manaloom_guard_deck_learning_event
          ON deck_learning_events;
        END IF;
      END;
      \$deck_learning_trigger\$;
      DROP FUNCTION IF EXISTS manaloom_guard_deck_learning_event();
      DROP INDEX IF EXISTS idx_privacy_deleted_deck_token;
      DROP TABLE IF EXISTS privacy_deleted_deck_tombstones;
      DROP INDEX IF EXISTS uq_privacy_keyring_active;
      DROP TABLE IF EXISTS privacy_keyring;
      ALTER TABLE IF EXISTS trade_items
      DROP CONSTRAINT IF EXISTS trade_items_binder_item_id_fkey;
      ALTER TABLE IF EXISTS trade_items
      ALTER COLUMN binder_item_id SET NOT NULL;
      ALTER TABLE IF EXISTS trade_items
      ADD CONSTRAINT trade_items_binder_item_id_fkey
      FOREIGN KEY (binder_item_id)
      REFERENCES user_binder_items(id)
      ON DELETE RESTRICT;
      DROP INDEX IF EXISTS idx_account_deletion_receipts_completed;
      DROP TABLE IF EXISTS account_deletion_receipts;
      DROP INDEX IF EXISTS uq_post_game_notes_play_session;
      DROP INDEX IF EXISTS idx_post_game_notes_tombstones;
      DROP INDEX IF EXISTS idx_post_game_notes_user_sync;
      DROP TABLE IF EXISTS post_game_sync_state;
      ALTER TABLE post_game_notes
      DROP CONSTRAINT IF EXISTS chk_post_game_notes_session_order;
      ALTER TABLE post_game_notes
      DROP CONSTRAINT IF EXISTS chk_post_game_notes_revision;
      ALTER TABLE post_game_notes DROP COLUMN IF EXISTS deleted_at;
      ALTER TABLE post_game_notes DROP COLUMN IF EXISTS revision;
      ALTER TABLE post_game_notes DROP COLUMN IF EXISTS deck_version_at;
      ALTER TABLE post_game_notes DROP COLUMN IF EXISTS deck_snapshot_hash;
      ALTER TABLE post_game_notes DROP COLUMN IF EXISTS session_ended_at;
      ALTER TABLE post_game_notes DROP COLUMN IF EXISTS session_started_at;
      ALTER TABLE post_game_notes DROP COLUMN IF EXISTS play_session_id;
      DO \$active_user_triggers\$
      DECLARE
        reference RECORD;
        trigger_name TEXT;
      BEGIN
        FOR reference IN
          SELECT constraint_row.oid AS constraint_oid,
                 namespace_row.nspname AS schema_name,
                 relation_row.relname AS table_name
          FROM pg_constraint constraint_row
          JOIN pg_class relation_row
            ON relation_row.oid = constraint_row.conrelid
          JOIN pg_namespace namespace_row
            ON namespace_row.oid = relation_row.relnamespace
          WHERE constraint_row.contype = 'f'
            AND constraint_row.confrelid = 'users'::regclass
            AND array_length(constraint_row.conkey, 1) = 1
        LOOP
          trigger_name := 'manaloom_active_user_' || reference.constraint_oid;
          EXECUTE format(
            'DROP TRIGGER IF EXISTS %I ON %I.%I',
            trigger_name,
            reference.schema_name,
            reference.table_name
          );
        END LOOP;
      END;
      \$active_user_triggers\$;
      DROP FUNCTION IF EXISTS manaloom_require_active_user();
      DROP INDEX IF EXISTS idx_users_active_identity;
      ALTER TABLE users DROP COLUMN IF EXISTS deleted_at;
    ''',
  ),
  Migration(
    version: '039',
    name: 'persist_deck_validation_review_state',
    up: '''
      ALTER TABLE decks
      ADD COLUMN IF NOT EXISTS validation_state TEXT;
      ALTER TABLE decks
      ADD COLUMN IF NOT EXISTS validation_reasons JSONB;
      ALTER TABLE decks
      ADD COLUMN IF NOT EXISTS validation_updated_at TIMESTAMP WITH TIME ZONE;

      UPDATE decks
      SET validation_state = COALESCE(validation_state, 'unknown'),
          validation_reasons = COALESCE(
            validation_reasons,
            '["validation_not_recorded"]'::jsonb
          );

      ALTER TABLE decks
      ALTER COLUMN validation_state SET DEFAULT 'unknown';
      ALTER TABLE decks
      ALTER COLUMN validation_state SET NOT NULL;
      ALTER TABLE decks
      ALTER COLUMN validation_reasons
      SET DEFAULT '["validation_not_recorded"]'::jsonb;
      ALTER TABLE decks
      ALTER COLUMN validation_reasons SET NOT NULL;

      ALTER TABLE decks
      DROP CONSTRAINT IF EXISTS chk_decks_validation_state;
      ALTER TABLE decks
      ADD CONSTRAINT chk_decks_validation_state CHECK (
        validation_state IN ('unknown', 'draft', 'validated')
      );

      ALTER TABLE decks
      DROP CONSTRAINT IF EXISTS chk_decks_validation_reasons_array;
      ALTER TABLE decks
      ADD CONSTRAINT chk_decks_validation_reasons_array CHECK (
        jsonb_typeof(validation_reasons) = 'array'
      );

      CREATE INDEX IF NOT EXISTS idx_decks_user_validation_state
      ON decks (user_id, validation_state, created_at DESC)
      WHERE deleted_at IS NULL;

      CREATE OR REPLACE FUNCTION manaloom_mark_deck_cards_changed()
      RETURNS trigger
      LANGUAGE plpgsql
      AS \$deck_cards_changed\$
      DECLARE
        affected_deck_ids UUID[];
      BEGIN
        IF TG_OP = 'DELETE' THEN
          affected_deck_ids := ARRAY[OLD.deck_id];
        ELSIF TG_OP = 'UPDATE'
              AND NEW.deck_id IS DISTINCT FROM OLD.deck_id THEN
          affected_deck_ids := ARRAY[OLD.deck_id, NEW.deck_id];
        ELSE
          affected_deck_ids := ARRAY[NEW.deck_id];
        END IF;

        UPDATE decks
        SET validation_state = 'draft',
            validation_reasons = CASE
              WHEN validation_state = 'validated' THEN
                '["deck_cards_changed_since_validation"]'::jsonb
              WHEN validation_reasons @>
                   '["deck_cards_changed_since_validation"]'::jsonb THEN
                validation_reasons
              ELSE validation_reasons ||
                   '["deck_cards_changed_since_validation"]'::jsonb
            END,
            validation_updated_at = CURRENT_TIMESTAMP
        WHERE id = ANY(affected_deck_ids);

        IF TG_OP = 'DELETE' THEN
          RETURN OLD;
        END IF;
        RETURN NEW;
      END;
      \$deck_cards_changed\$;

      DROP TRIGGER IF EXISTS manaloom_deck_cards_require_review
      ON deck_cards;
      CREATE TRIGGER manaloom_deck_cards_require_review
      AFTER INSERT OR DELETE OR UPDATE OF
        deck_id, card_id, quantity, is_commander
      ON deck_cards
      FOR EACH ROW
      EXECUTE FUNCTION manaloom_mark_deck_cards_changed();

      CREATE OR REPLACE FUNCTION manaloom_mark_deck_format_changed()
      RETURNS trigger
      LANGUAGE plpgsql
      AS \$deck_format_changed\$
      BEGIN
        IF NEW.format IS DISTINCT FROM OLD.format THEN
          NEW.validation_state := 'draft';
          NEW.validation_reasons := CASE
            WHEN OLD.validation_state = 'validated' THEN
              '["deck_format_changed_since_validation"]'::jsonb
            WHEN OLD.validation_reasons @>
                 '["deck_format_changed_since_validation"]'::jsonb THEN
              OLD.validation_reasons
            ELSE OLD.validation_reasons ||
                 '["deck_format_changed_since_validation"]'::jsonb
          END;
          NEW.validation_updated_at := CURRENT_TIMESTAMP;
        END IF;
        RETURN NEW;
      END;
      \$deck_format_changed\$;

      DROP TRIGGER IF EXISTS manaloom_deck_format_require_review
      ON decks;
      CREATE TRIGGER manaloom_deck_format_require_review
      BEFORE UPDATE OF format
      ON decks
      FOR EACH ROW
      EXECUTE FUNCTION manaloom_mark_deck_format_changed();
    ''',
    down: '''
      DROP TRIGGER IF EXISTS manaloom_deck_format_require_review ON decks;
      DROP FUNCTION IF EXISTS manaloom_mark_deck_format_changed();
      DROP TRIGGER IF EXISTS manaloom_deck_cards_require_review ON deck_cards;
      DROP FUNCTION IF EXISTS manaloom_mark_deck_cards_changed();
      DROP INDEX IF EXISTS idx_decks_user_validation_state;
      ALTER TABLE decks
      DROP CONSTRAINT IF EXISTS chk_decks_validation_reasons_array;
      ALTER TABLE decks
      DROP CONSTRAINT IF EXISTS chk_decks_validation_state;
      ALTER TABLE decks DROP COLUMN IF EXISTS validation_updated_at;
      ALTER TABLE decks DROP COLUMN IF EXISTS validation_reasons;
      ALTER TABLE decks DROP COLUMN IF EXISTS validation_state;
    ''',
  ),
  Migration(
    version: '040',
    name: 'align_cards_reserved_runtime_schema',
    up: '''
      ALTER TABLE cards
      ADD COLUMN IF NOT EXISTS is_reserved BOOLEAN NOT NULL DEFAULT FALSE;

      UPDATE cards
      SET is_reserved = FALSE
      WHERE is_reserved IS NULL;

      ALTER TABLE cards
      ALTER COLUMN is_reserved SET DEFAULT FALSE;
      ALTER TABLE cards
      ALTER COLUMN is_reserved SET NOT NULL;
    ''',
    // The column may predate this migration from an operational sync. Keep
    // product data and restore only the prior nullable shape on manual rollback.
    down: '''
      ALTER TABLE cards
      ALTER COLUMN is_reserved DROP NOT NULL;
    ''',
  ),
  Migration(
    version: '041',
    name: 'create_social_trade_messaging_runtime_schema',
    up: '''
      CREATE TABLE IF NOT EXISTS user_binder_items (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        card_id UUID NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
        quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
        condition TEXT NOT NULL DEFAULT 'NM'
          CHECK (condition IN ('NM', 'LP', 'MP', 'HP', 'DMG')),
        is_foil BOOLEAN NOT NULL DEFAULT FALSE,
        for_trade BOOLEAN NOT NULL DEFAULT FALSE,
        for_sale BOOLEAN NOT NULL DEFAULT FALSE,
        price DECIMAL(10, 2),
        currency TEXT NOT NULL DEFAULT 'BRL'
          CHECK (currency IN ('BRL', 'USD')),
        notes TEXT,
        language TEXT NOT NULL DEFAULT 'en',
        list_type TEXT NOT NULL DEFAULT 'have'
          CHECK (list_type IN ('have', 'want')),
        created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
      ALTER TABLE user_binder_items
      ADD COLUMN IF NOT EXISTS list_type TEXT NOT NULL DEFAULT 'have';
      ALTER TABLE user_binder_items
      DROP CONSTRAINT IF EXISTS user_binder_items_user_id_card_id_condition_is_foil_key;
      CREATE UNIQUE INDEX IF NOT EXISTS uq_user_binder_items_identity
      ON user_binder_items (
        user_id, card_id, condition, is_foil, list_type
      );
      CREATE INDEX IF NOT EXISTS idx_binder_user
      ON user_binder_items (user_id);
      CREATE INDEX IF NOT EXISTS idx_binder_card
      ON user_binder_items (card_id);
      CREATE INDEX IF NOT EXISTS idx_binder_for_trade
      ON user_binder_items (for_trade) WHERE for_trade = TRUE;
      CREATE INDEX IF NOT EXISTS idx_binder_for_sale
      ON user_binder_items (for_sale) WHERE for_sale = TRUE;

      CREATE TABLE IF NOT EXISTS trade_offers (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        receiver_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        status TEXT NOT NULL DEFAULT 'pending'
          CHECK (status IN (
            'pending', 'accepted', 'declined', 'shipped', 'delivered',
            'completed', 'cancelled', 'disputed'
          )),
        type TEXT NOT NULL DEFAULT 'trade'
          CHECK (type IN ('trade', 'sale', 'mixed')),
        delivery_method TEXT
          CHECK (
            delivery_method IS NULL
            OR delivery_method IN (
              'correios', 'motoboy', 'pessoalmente', 'outro',
              'mail', 'in_person'
            )
          ),
        payment_method TEXT
          CHECK (
            payment_method IS NULL
            OR payment_method IN ('pix', 'cash', 'transfer', 'other')
          ),
        payment_amount DECIMAL(10, 2),
        payment_currency TEXT NOT NULL DEFAULT 'BRL',
        tracking_code TEXT,
        message TEXT,
        created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT chk_no_self_trade CHECK (sender_id <> receiver_id)
      );
      ALTER TABLE trade_offers
      DROP CONSTRAINT IF EXISTS trade_offers_delivery_method_check;
      ALTER TABLE trade_offers
      DROP CONSTRAINT IF EXISTS chk_trade_offers_delivery_method;
      ALTER TABLE trade_offers
      ADD CONSTRAINT chk_trade_offers_delivery_method CHECK (
        delivery_method IS NULL
        OR delivery_method IN (
          'correios', 'motoboy', 'pessoalmente', 'outro',
          'mail', 'in_person'
        )
      );
      CREATE INDEX IF NOT EXISTS idx_trade_sender ON trade_offers (sender_id);
      CREATE INDEX IF NOT EXISTS idx_trade_receiver ON trade_offers (receiver_id);
      CREATE INDEX IF NOT EXISTS idx_trade_status ON trade_offers (status);

      CREATE TABLE IF NOT EXISTS trade_items (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        trade_offer_id UUID NOT NULL
          REFERENCES trade_offers(id) ON DELETE CASCADE,
        binder_item_id UUID
          REFERENCES user_binder_items(id) ON DELETE SET NULL,
        owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        direction TEXT NOT NULL
          CHECK (direction IN ('offering', 'requesting')),
        quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
        agreed_price DECIMAL(10, 2)
      );
      ALTER TABLE trade_items ALTER COLUMN binder_item_id DROP NOT NULL;
      ALTER TABLE trade_items
      DROP CONSTRAINT IF EXISTS trade_items_binder_item_id_fkey;
      ALTER TABLE trade_items
      ADD CONSTRAINT trade_items_binder_item_id_fkey
      FOREIGN KEY (binder_item_id)
      REFERENCES user_binder_items(id) ON DELETE SET NULL;
      CREATE INDEX IF NOT EXISTS idx_trade_items_offer
      ON trade_items (trade_offer_id);

      CREATE TABLE IF NOT EXISTS trade_messages (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        trade_offer_id UUID NOT NULL
          REFERENCES trade_offers(id) ON DELETE CASCADE,
        sender_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
        message TEXT,
        attachment_url TEXT,
        attachment_type TEXT
          CHECK (
            attachment_type IS NULL
            OR attachment_type IN ('receipt', 'tracking', 'photo', 'other')
          ),
        created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
      CREATE INDEX IF NOT EXISTS idx_trade_messages_offer
      ON trade_messages (trade_offer_id, created_at DESC);

      CREATE TABLE IF NOT EXISTS trade_status_history (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        trade_offer_id UUID NOT NULL
          REFERENCES trade_offers(id) ON DELETE CASCADE,
        old_status TEXT,
        new_status TEXT NOT NULL,
        changed_by UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
        notes TEXT,
        created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
      CREATE INDEX IF NOT EXISTS idx_trade_history_offer
      ON trade_status_history (trade_offer_id, created_at DESC);

      CREATE TABLE IF NOT EXISTS conversations (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_a_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        user_b_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        last_message_at TIMESTAMP WITH TIME ZONE,
        created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT chk_no_self_chat CHECK (user_a_id <> user_b_id)
      );
      CREATE UNIQUE INDEX IF NOT EXISTS uq_conversation_participants
      ON conversations (
        LEAST(user_a_id, user_b_id), GREATEST(user_a_id, user_b_id)
      );

      CREATE TABLE IF NOT EXISTS direct_messages (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        conversation_id UUID NOT NULL
          REFERENCES conversations(id) ON DELETE CASCADE,
        sender_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
        message TEXT NOT NULL,
        read_at TIMESTAMP WITH TIME ZONE,
        created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
      CREATE INDEX IF NOT EXISTS idx_dm_conversation
      ON direct_messages (conversation_id, created_at DESC);
      CREATE INDEX IF NOT EXISTS idx_dm_unread
      ON direct_messages (conversation_id) WHERE read_at IS NULL;

      CREATE TABLE IF NOT EXISTS notifications (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        type TEXT NOT NULL CHECK (type IN (
          'new_follower', 'trade_offer_received', 'trade_accepted',
          'trade_declined', 'trade_shipped', 'trade_delivered',
          'trade_completed', 'trade_message', 'direct_message'
        )),
        reference_id UUID,
        title TEXT NOT NULL,
        body TEXT,
        read_at TIMESTAMP WITH TIME ZONE,
        created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
      CREATE INDEX IF NOT EXISTS idx_notifications_user
      ON notifications (user_id, created_at DESC);
      CREATE INDEX IF NOT EXISTS idx_notifications_unread
      ON notifications (user_id) WHERE read_at IS NULL;

      DO \$active_user_triggers\$
      DECLARE
        reference RECORD;
        trigger_name TEXT;
      BEGIN
        FOR reference IN
          SELECT constraint_row.oid AS constraint_oid,
                 namespace_row.nspname AS schema_name,
                 relation_row.relname AS table_name,
                 attribute_row.attname AS column_name
          FROM pg_constraint constraint_row
          JOIN pg_class relation_row
            ON relation_row.oid = constraint_row.conrelid
          JOIN pg_namespace namespace_row
            ON namespace_row.oid = relation_row.relnamespace
          JOIN pg_attribute attribute_row
            ON attribute_row.attrelid = relation_row.oid
           AND attribute_row.attnum = constraint_row.conkey[1]
          WHERE constraint_row.contype = 'f'
            AND constraint_row.confrelid = 'users'::regclass
            AND array_length(constraint_row.conkey, 1) = 1
        LOOP
          trigger_name := 'manaloom_active_user_' || reference.constraint_oid;
          EXECUTE format(
            'DROP TRIGGER IF EXISTS %I ON %I.%I',
            trigger_name,
            reference.schema_name,
            reference.table_name
          );
          EXECUTE format(
            'CREATE TRIGGER %I BEFORE INSERT OR UPDATE OF %I ON %I.%I '
            'FOR EACH ROW EXECUTE FUNCTION manaloom_require_active_user(%L)',
            trigger_name,
            reference.column_name,
            reference.schema_name,
            reference.table_name,
            reference.column_name
          );
        END LOOP;
      END;
      \$active_user_triggers\$;
    ''',
    down: '''
      DROP TABLE IF EXISTS notifications;
      DROP TABLE IF EXISTS direct_messages;
      DROP TABLE IF EXISTS conversations;
      DROP TABLE IF EXISTS trade_status_history;
      DROP TABLE IF EXISTS trade_messages;
      DROP TABLE IF EXISTS trade_items;
      DROP TABLE IF EXISTS trade_offers;
      DROP TABLE IF EXISTS user_binder_items;
    ''',
  ),
  Migration(
    version: '042',
    name: 'create_account_recovery_and_session_revocation',
    up: '''
      ALTER TABLE users
      ADD COLUMN IF NOT EXISTS auth_version INTEGER NOT NULL DEFAULT 0;
      ALTER TABLE users
      ADD COLUMN IF NOT EXISTS password_changed_at TIMESTAMP WITH TIME ZONE;

      UPDATE users SET auth_version = 0 WHERE auth_version IS NULL;
      ALTER TABLE users ALTER COLUMN auth_version SET DEFAULT 0;
      ALTER TABLE users ALTER COLUMN auth_version SET NOT NULL;

      CREATE TABLE IF NOT EXISTS password_reset_tokens (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        token_hash CHAR(64) NOT NULL UNIQUE,
        expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
        consumed_at TIMESTAMP WITH TIME ZONE,
        created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
      CREATE INDEX IF NOT EXISTS idx_password_reset_tokens_user_active
      ON password_reset_tokens (user_id, expires_at DESC)
      WHERE consumed_at IS NULL;
    ''',
    down: '''
      DROP INDEX IF EXISTS idx_password_reset_tokens_user_active;
      DROP TABLE IF EXISTS password_reset_tokens;
      ALTER TABLE users DROP COLUMN IF EXISTS password_changed_at;
      ALTER TABLE users DROP COLUMN IF EXISTS auth_version;
    ''',
  ),
  Migration(
    version: '043',
    name: 'record_versioned_legal_acceptance',
    up: '''
      ALTER TABLE users ADD COLUMN IF NOT EXISTS terms_version TEXT;
      ALTER TABLE users
      ADD COLUMN IF NOT EXISTS terms_accepted_at TIMESTAMP WITH TIME ZONE;
      ALTER TABLE users ADD COLUMN IF NOT EXISTS privacy_version TEXT;
      ALTER TABLE users
      ADD COLUMN IF NOT EXISTS privacy_accepted_at TIMESTAMP WITH TIME ZONE;

      ALTER TABLE users
      DROP CONSTRAINT IF EXISTS chk_users_terms_acceptance_pair;
      ALTER TABLE users
      ADD CONSTRAINT chk_users_terms_acceptance_pair CHECK (
        (terms_version IS NULL AND terms_accepted_at IS NULL)
        OR (terms_version IS NOT NULL AND terms_accepted_at IS NOT NULL)
      );
      ALTER TABLE users
      DROP CONSTRAINT IF EXISTS chk_users_privacy_acceptance_pair;
      ALTER TABLE users
      ADD CONSTRAINT chk_users_privacy_acceptance_pair CHECK (
        (privacy_version IS NULL AND privacy_accepted_at IS NULL)
        OR (privacy_version IS NOT NULL AND privacy_accepted_at IS NOT NULL)
      );
    ''',
    down: '''
      ALTER TABLE users
      DROP CONSTRAINT IF EXISTS chk_users_privacy_acceptance_pair;
      ALTER TABLE users
      DROP CONSTRAINT IF EXISTS chk_users_terms_acceptance_pair;
      ALTER TABLE users DROP COLUMN IF EXISTS privacy_accepted_at;
      ALTER TABLE users DROP COLUMN IF EXISTS privacy_version;
      ALTER TABLE users DROP COLUMN IF EXISTS terms_accepted_at;
      ALTER TABLE users DROP COLUMN IF EXISTS terms_version;
    ''',
  ),
  Migration(
    version: '044',
    name: 'create_email_verification_gate',
    up: '''
      ALTER TABLE users
      ADD COLUMN IF NOT EXISTS email_verified_at TIMESTAMP WITH TIME ZONE;

      CREATE TABLE IF NOT EXISTS email_verification_tokens (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        token_hash CHAR(64) NOT NULL UNIQUE,
        expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
        consumed_at TIMESTAMP WITH TIME ZONE,
        created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
      CREATE INDEX IF NOT EXISTS idx_email_verification_tokens_user_active
      ON email_verification_tokens (user_id, expires_at DESC)
      WHERE consumed_at IS NULL;
    ''',
    down: '''
      DROP INDEX IF EXISTS idx_email_verification_tokens_user_active;
      DROP TABLE IF EXISTS email_verification_tokens;
      ALTER TABLE users DROP COLUMN IF EXISTS email_verified_at;
    ''',
  ),
  Migration(
    version: '045',
    name: 'create_collection_availability_contract',
    up: collectionAvailabilityViewsSql,
    down: dropCollectionAvailabilityViewsSql,
  ),
  Migration(
    version: '046',
    name: 'restore_price_history_runtime_contract',
    up: '''
      CREATE TABLE IF NOT EXISTS price_history (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        card_id UUID NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
        price_date DATE NOT NULL DEFAULT CURRENT_DATE,
        price_usd DECIMAL(10,2),
        price_usd_foil DECIMAL(10,2),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(card_id, price_date)
      );
      CREATE INDEX IF NOT EXISTS idx_price_history_date
      ON price_history (price_date DESC);
      CREATE INDEX IF NOT EXISTS idx_price_history_card_date
      ON price_history (card_id, price_date DESC);
      CREATE INDEX IF NOT EXISTS idx_price_history_date_card_price
      ON price_history (price_date DESC, card_id) INCLUDE (price_usd);
    ''',
    down: '''
      DROP INDEX IF EXISTS idx_price_history_date_card_price;
      DROP INDEX IF EXISTS idx_price_history_card_date;
      DROP INDEX IF EXISTS idx_price_history_date;
    ''',
  ),
  Migration(
    version: '047',
    name: 'close_deck_validation_state_transitions',
    up: '''
      UPDATE decks
      SET validation_reasons = CASE validation_state
            WHEN 'unknown' THEN '["validation_not_recorded"]'::jsonb
            WHEN 'validated' THEN '[]'::jsonb
            ELSE CASE
              WHEN jsonb_array_length(validation_reasons) = 0 THEN
                '["strict_validation_pending"]'::jsonb
              ELSE validation_reasons
            END
          END,
          validation_updated_at = CASE validation_state
            WHEN 'unknown' THEN NULL
            ELSE COALESCE(validation_updated_at, CURRENT_TIMESTAMP)
          END;

      ALTER TABLE decks
      DROP CONSTRAINT IF EXISTS chk_decks_validation_state_payload;
      ALTER TABLE decks
      ADD CONSTRAINT chk_decks_validation_state_payload CHECK (
        (
          validation_state = 'unknown'
          AND validation_reasons =
              '["validation_not_recorded"]'::jsonb
          AND validation_updated_at IS NULL
        ) OR (
          validation_state = 'draft'
          AND jsonb_array_length(validation_reasons) > 0
          AND validation_updated_at IS NOT NULL
        ) OR (
          validation_state = 'validated'
          AND jsonb_array_length(validation_reasons) = 0
          AND validation_updated_at IS NOT NULL
        )
      );

      CREATE OR REPLACE FUNCTION manaloom_mark_deck_cards_changed()
      RETURNS trigger
      LANGUAGE plpgsql
      AS \$deck_cards_changed\$
      DECLARE
        affected_deck_ids UUID[];
      BEGIN
        IF TG_OP = 'DELETE' THEN
          affected_deck_ids := ARRAY[OLD.deck_id];
        ELSIF TG_OP = 'UPDATE'
              AND NEW.deck_id IS DISTINCT FROM OLD.deck_id THEN
          affected_deck_ids := ARRAY[OLD.deck_id, NEW.deck_id];
        ELSE
          affected_deck_ids := ARRAY[NEW.deck_id];
        END IF;

        UPDATE decks
        SET validation_state = 'draft',
            validation_reasons =
              '["deck_cards_changed_since_validation"]'::jsonb,
            validation_updated_at = CURRENT_TIMESTAMP
        WHERE id = ANY(affected_deck_ids);

        IF TG_OP = 'DELETE' THEN
          RETURN OLD;
        END IF;
        RETURN NEW;
      END;
      \$deck_cards_changed\$;

      CREATE OR REPLACE FUNCTION manaloom_mark_deck_format_changed()
      RETURNS trigger
      LANGUAGE plpgsql
      AS \$deck_format_changed\$
      BEGIN
        IF NEW.format IS DISTINCT FROM OLD.format THEN
          NEW.validation_state := 'draft';
          NEW.validation_reasons :=
            '["deck_format_changed_since_validation"]'::jsonb;
          NEW.validation_updated_at := CURRENT_TIMESTAMP;
        END IF;
        RETURN NEW;
      END;
      \$deck_format_changed\$;
    ''',
    down: '''
      ALTER TABLE decks
      DROP CONSTRAINT IF EXISTS chk_decks_validation_state_payload;

      CREATE OR REPLACE FUNCTION manaloom_mark_deck_cards_changed()
      RETURNS trigger
      LANGUAGE plpgsql
      AS \$deck_cards_changed\$
      DECLARE
        affected_deck_ids UUID[];
      BEGIN
        IF TG_OP = 'DELETE' THEN
          affected_deck_ids := ARRAY[OLD.deck_id];
        ELSIF TG_OP = 'UPDATE'
              AND NEW.deck_id IS DISTINCT FROM OLD.deck_id THEN
          affected_deck_ids := ARRAY[OLD.deck_id, NEW.deck_id];
        ELSE
          affected_deck_ids := ARRAY[NEW.deck_id];
        END IF;

        UPDATE decks
        SET validation_state = 'draft',
            validation_reasons = CASE
              WHEN validation_state = 'validated' THEN
                '["deck_cards_changed_since_validation"]'::jsonb
              WHEN validation_reasons @>
                   '["deck_cards_changed_since_validation"]'::jsonb THEN
                validation_reasons
              ELSE validation_reasons ||
                   '["deck_cards_changed_since_validation"]'::jsonb
            END,
            validation_updated_at = CURRENT_TIMESTAMP
        WHERE id = ANY(affected_deck_ids);

        IF TG_OP = 'DELETE' THEN
          RETURN OLD;
        END IF;
        RETURN NEW;
      END;
      \$deck_cards_changed\$;

      CREATE OR REPLACE FUNCTION manaloom_mark_deck_format_changed()
      RETURNS trigger
      LANGUAGE plpgsql
      AS \$deck_format_changed\$
      BEGIN
        IF NEW.format IS DISTINCT FROM OLD.format THEN
          NEW.validation_state := 'draft';
          NEW.validation_reasons := CASE
            WHEN OLD.validation_state = 'validated' THEN
              '["deck_format_changed_since_validation"]'::jsonb
            WHEN OLD.validation_reasons @>
                 '["deck_format_changed_since_validation"]'::jsonb THEN
              OLD.validation_reasons
            ELSE OLD.validation_reasons ||
                 '["deck_format_changed_since_validation"]'::jsonb
          END;
          NEW.validation_updated_at := CURRENT_TIMESTAMP;
        END IF;
        RETURN NEW;
      END;
      \$deck_format_changed\$;
    ''',
  ),
  Migration(
    version: '048',
    name: 'close_ai_job_lifecycle',
    up: '''
      ALTER TABLE ai_generate_jobs
      ADD COLUMN IF NOT EXISTS request_key TEXT;
      ALTER TABLE ai_generate_jobs
      ADD COLUMN IF NOT EXISTS request_fingerprint TEXT;
      ALTER TABLE ai_generate_jobs
      ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMP WITH TIME ZONE;

      ALTER TABLE ai_optimize_jobs
      ADD COLUMN IF NOT EXISTS request_key TEXT;
      ALTER TABLE ai_optimize_jobs
      ADD COLUMN IF NOT EXISTS request_fingerprint TEXT;
      ALTER TABLE ai_optimize_jobs
      ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMP WITH TIME ZONE;

      ALTER TABLE ai_generate_jobs
      DROP CONSTRAINT IF EXISTS chk_ai_generate_jobs_status;
      ALTER TABLE ai_generate_jobs
      ADD CONSTRAINT chk_ai_generate_jobs_status CHECK (
        status IN ('pending', 'processing', 'completed', 'failed', 'cancelled')
      );

      ALTER TABLE ai_optimize_jobs
      DROP CONSTRAINT IF EXISTS chk_ai_optimize_jobs_status;
      ALTER TABLE ai_optimize_jobs
      ADD CONSTRAINT chk_ai_optimize_jobs_status CHECK (
        status IN ('pending', 'processing', 'completed', 'failed', 'cancelled')
      );

      CREATE UNIQUE INDEX IF NOT EXISTS
        idx_ai_generate_jobs_user_request_key
      ON ai_generate_jobs (user_id, request_key)
      WHERE user_id IS NOT NULL AND request_key IS NOT NULL;

      CREATE UNIQUE INDEX IF NOT EXISTS
        idx_ai_optimize_jobs_user_request_key
      ON ai_optimize_jobs (user_id, request_key)
      WHERE user_id IS NOT NULL AND request_key IS NOT NULL;
    ''',
    down: '''
      UPDATE ai_generate_jobs
      SET status = 'failed',
          stage = 'Erro',
          error = COALESCE(error, 'Job cancelado antes do rollback do schema.'),
          updated_at = CURRENT_TIMESTAMP
      WHERE status = 'cancelled';

      UPDATE ai_optimize_jobs
      SET status = 'failed',
          stage = 'Erro',
          error = COALESCE(error, 'Job cancelado antes do rollback do schema.'),
          updated_at = CURRENT_TIMESTAMP
      WHERE status = 'cancelled';

      DROP INDEX IF EXISTS idx_ai_generate_jobs_user_request_key;
      DROP INDEX IF EXISTS idx_ai_optimize_jobs_user_request_key;

      ALTER TABLE ai_generate_jobs
      DROP CONSTRAINT IF EXISTS chk_ai_generate_jobs_status;
      ALTER TABLE ai_generate_jobs
      ADD CONSTRAINT chk_ai_generate_jobs_status CHECK (
        status IN ('pending', 'processing', 'completed', 'failed')
      );

      ALTER TABLE ai_optimize_jobs
      DROP CONSTRAINT IF EXISTS chk_ai_optimize_jobs_status;
      ALTER TABLE ai_optimize_jobs
      ADD CONSTRAINT chk_ai_optimize_jobs_status CHECK (
        status IN ('pending', 'processing', 'completed', 'failed')
      );

      ALTER TABLE ai_generate_jobs DROP COLUMN IF EXISTS cancelled_at;
      ALTER TABLE ai_generate_jobs DROP COLUMN IF EXISTS request_fingerprint;
      ALTER TABLE ai_generate_jobs DROP COLUMN IF EXISTS request_key;
      ALTER TABLE ai_optimize_jobs DROP COLUMN IF EXISTS cancelled_at;
      ALTER TABLE ai_optimize_jobs DROP COLUMN IF EXISTS request_fingerprint;
      ALTER TABLE ai_optimize_jobs DROP COLUMN IF EXISTS request_key;
    ''',
  ),
  Migration(
    version: '049',
    name: 'preserve_binder_physical_identity',
    up: '''
      UPDATE user_binder_items
      SET language = LOWER(REPLACE(TRIM(language), '_', '-'))
      WHERE language IS DISTINCT FROM
        LOWER(REPLACE(TRIM(language), '_', '-'));

      UPDATE user_binder_items
      SET language = 'en'
      WHERE language = '';

      DROP INDEX IF EXISTS uq_user_binder_items_identity;
      CREATE UNIQUE INDEX IF NOT EXISTS
        uq_user_binder_items_physical_identity
      ON user_binder_items (
        user_id, card_id, condition, is_foil, language, list_type
      );

      ALTER TABLE user_binder_items
      DROP CONSTRAINT IF EXISTS chk_user_binder_items_language;
      ALTER TABLE user_binder_items
      ADD CONSTRAINT chk_user_binder_items_language CHECK (
        language ~ '^[a-z]{2,3}(-[a-z0-9]{2,8})*\$'
      );
    ''',
    // A reversão poderia colapsar linhas físicas de idiomas diferentes.
    // A policy manualOnly bloqueia execução automática deste marcador.
    down: 'SELECT 1;',
  ),
  Migration(
    version: '050',
    name: 'canonicalize_pricing_provenance',
    up: '''
      ALTER TABLE cards ADD COLUMN IF NOT EXISTS price_usd DECIMAL(10, 2);
      ALTER TABLE cards ADD COLUMN IF NOT EXISTS price_usd_foil DECIMAL(10, 2);
      ALTER TABLE cards ADD COLUMN IF NOT EXISTS price_source TEXT;

      UPDATE cards
      SET price_usd = price
      WHERE price_usd IS NULL AND price IS NOT NULL AND price > 0;

      UPDATE cards
      SET price = price_usd
      WHERE price_usd IS NOT NULL
        AND price IS DISTINCT FROM price_usd;

      UPDATE cards
      SET price_source = 'legacy'
      WHERE price_source IS NULL AND price_usd IS NOT NULL;

      ALTER TABLE cards DROP CONSTRAINT IF EXISTS chk_cards_price_source;
      ALTER TABLE cards ADD CONSTRAINT chk_cards_price_source CHECK (
        price_source IS NULL OR
        price_source IN ('scryfall', 'mtgjson', 'legacy')
      );

      CREATE INDEX IF NOT EXISTS idx_cards_price_usd
      ON cards (price_usd) WHERE price_usd IS NOT NULL;

      ALTER TABLE decks ADD COLUMN IF NOT EXISTS pricing_source TEXT;
      UPDATE decks
      SET pricing_source = 'legacy'
      WHERE pricing_total IS NOT NULL AND pricing_source IS NULL;
    ''',
    down: '''
      ALTER TABLE decks DROP COLUMN IF EXISTS pricing_source;
      DROP INDEX IF EXISTS idx_cards_price_usd;
      ALTER TABLE cards DROP CONSTRAINT IF EXISTS chk_cards_price_source;
      ALTER TABLE cards DROP COLUMN IF EXISTS price_source;
    ''',
  ),
  Migration(
    version: '051',
    name: 'close_social_safety_contract',
    up: '''
      ALTER TABLE users
      ADD COLUMN IF NOT EXISTS profile_visibility TEXT NOT NULL DEFAULT 'public';
      ALTER TABLE users
      ADD COLUMN IF NOT EXISTS binder_visibility TEXT NOT NULL DEFAULT 'public';
      ALTER TABLE users
      ADD COLUMN IF NOT EXISTS location_visibility TEXT NOT NULL DEFAULT 'private';
      ALTER TABLE users
      ADD COLUMN IF NOT EXISTS message_visibility TEXT NOT NULL DEFAULT 'everyone';
      ALTER TABLE users
      ADD COLUMN IF NOT EXISTS trade_visibility TEXT NOT NULL DEFAULT 'everyone';
      ALTER TABLE users
      ADD COLUMN IF NOT EXISTS trade_notes_visibility TEXT NOT NULL DEFAULT 'private';

      ALTER TABLE users DROP CONSTRAINT IF EXISTS chk_users_profile_visibility;
      ALTER TABLE users ADD CONSTRAINT chk_users_profile_visibility
      CHECK (profile_visibility IN ('public', 'private'));
      ALTER TABLE users DROP CONSTRAINT IF EXISTS chk_users_binder_visibility;
      ALTER TABLE users ADD CONSTRAINT chk_users_binder_visibility
      CHECK (binder_visibility IN ('public', 'private'));
      ALTER TABLE users DROP CONSTRAINT IF EXISTS chk_users_location_visibility;
      ALTER TABLE users ADD CONSTRAINT chk_users_location_visibility
      CHECK (location_visibility IN ('public', 'trade_only', 'private'));
      ALTER TABLE users DROP CONSTRAINT IF EXISTS chk_users_message_visibility;
      ALTER TABLE users ADD CONSTRAINT chk_users_message_visibility
      CHECK (message_visibility IN ('everyone', 'followers', 'none'));
      ALTER TABLE users DROP CONSTRAINT IF EXISTS chk_users_trade_visibility;
      ALTER TABLE users ADD CONSTRAINT chk_users_trade_visibility
      CHECK (trade_visibility IN ('everyone', 'followers', 'none'));
      ALTER TABLE users DROP CONSTRAINT IF EXISTS chk_users_trade_notes_visibility;
      ALTER TABLE users ADD CONSTRAINT chk_users_trade_notes_visibility
      CHECK (trade_notes_visibility IN ('trade_only', 'private'));

      CREATE TABLE IF NOT EXISTS user_blocks (
        blocker_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        blocked_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        reason TEXT,
        created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (blocker_id, blocked_id),
        CONSTRAINT chk_no_self_block CHECK (blocker_id <> blocked_id)
      );
      CREATE INDEX IF NOT EXISTS idx_user_blocks_blocked
      ON user_blocks (blocked_id, blocker_id);

      CREATE TABLE IF NOT EXISTS user_block_events (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        actor_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
        target_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
        action TEXT NOT NULL CHECK (action IN ('blocked', 'unblocked')),
        reason TEXT,
        request_id TEXT,
        created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
      CREATE INDEX IF NOT EXISTS idx_user_block_events_actor_created
      ON user_block_events (actor_user_id, created_at DESC);

      ALTER TABLE direct_messages
      ADD COLUMN IF NOT EXISTS client_request_id TEXT;
      ALTER TABLE direct_messages
      ADD COLUMN IF NOT EXISTS moderation_status TEXT NOT NULL DEFAULT 'visible';
      ALTER TABLE direct_messages
      DROP CONSTRAINT IF EXISTS chk_direct_messages_moderation_status;
      ALTER TABLE direct_messages
      ADD CONSTRAINT chk_direct_messages_moderation_status
      CHECK (moderation_status IN ('visible', 'removed'));
      CREATE UNIQUE INDEX IF NOT EXISTS uq_direct_messages_sender_request
      ON direct_messages (sender_id, client_request_id)
      WHERE client_request_id IS NOT NULL;

      ALTER TABLE trade_messages
      ADD COLUMN IF NOT EXISTS client_request_id TEXT;
      ALTER TABLE trade_messages
      ADD COLUMN IF NOT EXISTS moderation_status TEXT NOT NULL DEFAULT 'visible';
      ALTER TABLE trade_messages
      DROP CONSTRAINT IF EXISTS chk_trade_messages_moderation_status;
      ALTER TABLE trade_messages
      ADD CONSTRAINT chk_trade_messages_moderation_status
      CHECK (moderation_status IN ('visible', 'removed'));
      CREATE UNIQUE INDEX IF NOT EXISTS uq_trade_messages_sender_request
      ON trade_messages (sender_id, client_request_id)
      WHERE client_request_id IS NOT NULL;

      ALTER TABLE content_reports
      ADD COLUMN IF NOT EXISTS priority SMALLINT NOT NULL DEFAULT 2;
      ALTER TABLE content_reports
      ADD COLUMN IF NOT EXISTS evidence JSONB NOT NULL DEFAULT '{}'::jsonb;
      ALTER TABLE content_reports
      ADD COLUMN IF NOT EXISTS sla_due_at TIMESTAMP WITH TIME ZONE;
      UPDATE content_reports
      SET sla_due_at = created_at + INTERVAL '72 hours'
      WHERE sla_due_at IS NULL;
      ALTER TABLE content_reports ALTER COLUMN sla_due_at SET NOT NULL;
      ALTER TABLE content_reports ALTER COLUMN sla_due_at
      SET DEFAULT (CURRENT_TIMESTAMP + INTERVAL '72 hours');
      ALTER TABLE content_reports ADD COLUMN IF NOT EXISTS resolution TEXT;
      ALTER TABLE content_reports ADD COLUMN IF NOT EXISTS resolution_action TEXT;
      ALTER TABLE content_reports
      ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE
      NOT NULL DEFAULT CURRENT_TIMESTAMP;

      ALTER TABLE content_reports
      DROP CONSTRAINT IF EXISTS chk_content_reports_target_type;
      ALTER TABLE content_reports
      ADD CONSTRAINT chk_content_reports_target_type CHECK (
        target_type IN (
          'deck', 'comment', 'profile', 'binder_item',
          'message', 'trade_message'
        )
      );
      ALTER TABLE content_reports
      DROP CONSTRAINT IF EXISTS chk_content_reports_status;
      ALTER TABLE content_reports
      ADD CONSTRAINT chk_content_reports_status CHECK (
        status IN ('open', 'reviewing', 'resolved', 'dismissed', 'appealed')
      );
      ALTER TABLE content_reports
      DROP CONSTRAINT IF EXISTS chk_content_reports_priority;
      ALTER TABLE content_reports
      ADD CONSTRAINT chk_content_reports_priority
      CHECK (priority BETWEEN 1 AND 4);
      ALTER TABLE content_reports
      DROP CONSTRAINT IF EXISTS chk_content_reports_resolution_action;
      ALTER TABLE content_reports
      ADD CONSTRAINT chk_content_reports_resolution_action CHECK (
        resolution_action IS NULL OR
        resolution_action IN ('none', 'hide', 'remove', 'restrict')
      );

      CREATE INDEX IF NOT EXISTS idx_content_reports_queue
      ON content_reports (status, priority, sla_due_at, created_at);
      CREATE UNIQUE INDEX IF NOT EXISTS uq_content_reports_active_reporter_target
      ON content_reports (reporter_user_id, target_type, target_id)
      WHERE reporter_user_id IS NOT NULL
        AND status IN ('open', 'reviewing', 'appealed');

      CREATE TABLE IF NOT EXISTS moderation_actions (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        report_id UUID NOT NULL REFERENCES content_reports(id) ON DELETE CASCADE,
        moderator_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
        action TEXT NOT NULL CHECK (
          action IN (
            'start_review', 'dismiss', 'hide', 'remove', 'restrict', 'restore'
          )
        ),
        rationale TEXT NOT NULL,
        evidence JSONB NOT NULL DEFAULT '{}'::jsonb,
        request_id TEXT,
        created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
      CREATE INDEX IF NOT EXISTS idx_moderation_actions_report_created
      ON moderation_actions (report_id, created_at DESC);

      CREATE TABLE IF NOT EXISTS content_report_appeals (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        report_id UUID NOT NULL REFERENCES content_reports(id) ON DELETE CASCADE,
        appellant_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        reason TEXT NOT NULL CHECK (char_length(reason) BETWEEN 10 AND 2000),
        status TEXT NOT NULL DEFAULT 'pending'
          CHECK (status IN ('pending', 'reviewing', 'upheld', 'overturned')),
        reviewed_by UUID REFERENCES users(id) ON DELETE SET NULL,
        reviewed_at TIMESTAMP WITH TIME ZONE,
        resolution TEXT,
        created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
      CREATE UNIQUE INDEX IF NOT EXISTS uq_content_report_appeals_pending
      ON content_report_appeals (report_id, appellant_user_id)
      WHERE status IN ('pending', 'reviewing');
      CREATE INDEX IF NOT EXISTS idx_content_report_appeals_queue
      ON content_report_appeals (status, created_at);
    ''',
    down: 'SELECT 1;',
  ),
];

class Migration {
  final String version;
  final String name;
  final String up;
  final String? down;

  Migration({
    required this.version,
    required this.name,
    required this.up,
    this.down,
  });

  String get fullName => '${version}_$name';
}

bool hasMigrationWriteApproval(Map<String, String> environment) =>
    environment[migrationWriteApprovalEnvironment] ==
    migrationWriteApprovalPhrase;

bool hasMigrationLiveApproval(Map<String, String> environment) =>
    environment[migrationLiveApprovalEnvironment] ==
    migrationWriteApprovalPhrase;

bool isLoopbackMigrationHost(String host) {
  final normalized = host.trim().toLowerCase();
  return normalized == 'localhost' ||
      normalized == '127.0.0.1' ||
      normalized == '::1';
}

String? migrationDestinationViolation({
  required Map<String, String> environment,
  required Map<String, String> callerEnvironment,
  required bool writeRequested,
}) {
  final host = environment['DB_HOST'] ?? 'localhost';
  final database = environment['DB_NAME'] ?? 'mtg_db';
  final port = environment['DB_PORT'] ?? '5432';
  final wrapperMode = callerEnvironment['MANALOOM_PG_WRAPPER_MODE'];
  if (wrapperMode == 'read-only' && !writeRequested) return null;
  if (wrapperMode == 'write-approved' && writeRequested) return null;

  final productionLike =
      environment['ENVIRONMENT']?.toLowerCase() == 'production' ||
      !isLoopbackMigrationHost(host);
  if (!productionLike) return null;

  final expectedHost = callerEnvironment['MANALOOM_EXPECTED_DB_HOST'];
  final expectedDatabase = callerEnvironment['MANALOOM_EXPECTED_DB_NAME'];
  final expectedPort = callerEnvironment['MANALOOM_EXPECTED_DB_PORT'];
  if (expectedHost == null ||
      expectedDatabase == null ||
      expectedPort == null) {
    return 'destino PostgreSQL protegido exige anchors do processo chamador';
  }
  if (host != expectedHost ||
      database != expectedDatabase ||
      port != expectedPort) {
    return 'destino PostgreSQL diverge dos anchors aprovados';
  }
  return null;
}

enum MigrationRollbackPolicy { standard, emptyOnly, manualOnly }

MigrationRollbackPolicy migrationRollbackPolicy(String version) =>
    switch (version) {
      '033' || '035' => MigrationRollbackPolicy.emptyOnly,
      // Estas migrations alteram ou adotam dados preexistentes. O down
      // automático não consegue reconstruir o estado anterior com segurança.
      '034' ||
      '036' ||
      '037' ||
      '038' ||
      '039' ||
      '040' ||
      '041' ||
      '042' ||
      '043' ||
      '044' ||
      '046' ||
      '047' ||
      '048' ||
      '049' ||
      '050' ||
      '051' => MigrationRollbackPolicy.manualOnly,
      _ => MigrationRollbackPolicy.standard,
    };

Future<void> _assertRollbackSafe(Session tx, Migration migration) async {
  final policy = migrationRollbackPolicy(migration.version);
  if (policy == MigrationRollbackPolicy.standard) return;
  if (policy == MigrationRollbackPolicy.manualOnly) {
    throw StateError(
      'Rollback automático de ${migration.fullName} é bloqueado: a migration '
      'alterou ou adotou dados preexistentes. Use um plano manual com backup '
      'e restore validados.',
    );
  }

  final unsafe = switch (migration.version) {
    '033' =>
      (await tx.execute(
            'SELECT EXISTS (SELECT 1 FROM deck_optimization_events)',
          )).first[0] ==
          true,
    '035' =>
      (await tx.execute('''
        SELECT
          EXISTS (SELECT 1 FROM data_source_snapshots)
          OR EXISTS (
            SELECT 1
            FROM card_rulings
            WHERE source = 'scryfall' OR ruling_source <> ''
          )
      ''')).first[0] ==
          true,
    _ => false,
  };
  if (unsafe) {
    throw StateError(
      'Rollback automático de ${migration.fullName} é bloqueado porque a '
      'tabela já contém dados de produto ou lineage. Use rollback seletivo '
      'com snapshot validado.',
    );
  }
}

void main(List<String> args) async {
  final showStatus = args.contains('--status');
  final rollbackRequested = args.contains('--rollback');
  int? rollbackCount;
  if (rollbackRequested) {
    final rollbackIndex = args.indexOf('--rollback');
    final rawCount =
        rollbackIndex + 1 < args.length ? args[rollbackIndex + 1] : null;
    rollbackCount = rawCount == null ? null : int.tryParse(rawCount);
    if (rollbackCount == null || rollbackCount <= 0) {
      stderr.writeln(
        'Uso inválido: --rollback exige um inteiro positivo. Nenhuma conexão foi aberta.',
      );
      exitCode = 2;
      return;
    }
  }

  if (!showStatus &&
      (!hasMigrationWriteApproval(Platform.environment) ||
          !hasMigrationLiveApproval(Platform.environment))) {
    stderr.writeln(
      'BLOCKED: aplicar migrações altera PostgreSQL. Defina '
      '$migrationWriteApprovalEnvironment=$migrationWriteApprovalPhrase e '
      '$migrationLiveApprovalEnvironment=$migrationWriteApprovalPhrase '
      'somente após aprovação explícita para esta execução.',
    );
    exitCode = 2;
    return;
  }

  final env = loadRuntimeEnvironment();
  env.addAll(Platform.environment);

  final destinationViolation = migrationDestinationViolation(
    environment: {
      for (final key in const ['DB_HOST', 'DB_NAME', 'DB_PORT', 'ENVIRONMENT'])
        if (env[key] case final value?) key: value,
    },
    callerEnvironment: Platform.environment,
    writeRequested: !showStatus,
  );
  if (destinationViolation != null) {
    stderr.writeln(
      'BLOCKED: $destinationViolation. Nenhuma conexão foi aberta.',
    );
    exitCode = 2;
    return;
  }

  final connection = await Connection.open(
    Endpoint(
      host: env['DB_HOST'] ?? 'localhost',
      database: env['DB_NAME'] ?? 'mtg_db',
      username: env['DB_USER'] ?? 'postgres',
      password: env['DB_PASS'] ?? 'postgres',
      port: int.parse(env['DB_PORT'] ?? '5432'),
    ),
    settings: ConnectionSettings(sslMode: SslMode.disable),
  );

  try {
    if (showStatus) {
      Set<String> executedVersions;
      try {
        final executedResult = await connection.execute(
          'SELECT version FROM schema_migrations ORDER BY version',
        );
        executedVersions = executedResult.map((r) => r[0] as String).toSet();
      } on ServerException catch (error) {
        if (error.code != '42P01') rethrow;
        executedVersions = <String>{};
        print(
          'ℹ️ schema_migrations ainda não existe; status tratado como '
          'banco sem migrações registradas (nenhuma DDL executada).',
        );
      }

      print('📊 Status das Migrações\n');
      print('${'Versão'.padRight(10)} ${'Nome'.padRight(30)} Status');
      print('-' * 60);

      for (final m in migrations) {
        final status =
            executedVersions.contains(m.version) ? '✅ Executada' : '⬜ Pendente';
        print('${m.version.padRight(10)} ${m.name.padRight(30)} $status');
      }

      print('\nTotal: ${migrations.length} migrações');
      print('Executadas: ${executedVersions.length}');
      print('Pendentes: ${migrations.length - executedVersions.length}');
      return;
    }

    if (rollbackRequested) {
      final executedResult = await connection.execute(
        Sql.named('''
          SELECT version, name
          FROM schema_migrations
          ORDER BY version DESC
          LIMIT @limit
        '''),
        parameters: {'limit': rollbackCount},
      );
      if (executedResult.length != rollbackCount) {
        throw StateError(
          'Rollback solicitou $rollbackCount migração(ões), mas apenas '
          '${executedResult.length} estão registradas.',
        );
      }

      final rollbackMigrations = <Migration>[];
      for (final row in executedResult) {
        final version = row[0] as String;
        final matches = migrations.where((item) => item.version == version);
        if (matches.isEmpty) {
          throw StateError(
            'Migração executada $version não existe neste código; rollback abortado antes de escrever.',
          );
        }
        final migration = matches.single;
        if (migration.down == null || migration.down!.trim().isEmpty) {
          throw StateError(
            'Migração ${migration.fullName} não possui rollback; operação abortada antes de escrever.',
          );
        }
        rollbackMigrations.add(migration);
      }

      print('↩️  Revertendo ${rollbackMigrations.length} migração(ões)...\n');
      await connection.runTx((tx) async {
        for (final migration in rollbackMigrations) {
          print('◀️  Revertendo ${migration.fullName}...');
          await _assertRollbackSafe(tx, migration);
          final statements = splitPostgresStatements(migration.down!);
          for (final statement in statements) {
            await tx.execute(statement);
          }
          await tx.execute(
            Sql.named('DELETE FROM schema_migrations WHERE version = @version'),
            parameters: {'version': migration.version},
          );
          print('   ✅ Revertida');
        }
      });
      print('\n✅ Rollback transacional concluído.');
      return;
    }

    // Apply mode only. Reaching this branch requires the explicit textual
    // PostgreSQL approval check above, before Connection.open.
    await connection.execute('''
      CREATE TABLE IF NOT EXISTS schema_migrations (
        version TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        executed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    final executedResult = await connection.execute(
      'SELECT version FROM schema_migrations ORDER BY version',
    );
    final executedVersions = executedResult.map((r) => r[0] as String).toSet();

    // Executar migrações pendentes
    print('🔄 Executando migrações...\n');
    var migratedCount = 0;

    for (final migration in migrations) {
      if (executedVersions.contains(migration.version)) {
        print('⏭️  ${migration.fullName} (já executada)');
        continue;
      }

      print('▶️  Executando ${migration.fullName}...');

      try {
        await connection.runTx((tx) async {
          // Cada migração e seu registro são atômicos: em caso de falha, nenhum
          // statement parcial fica aplicado.
          final statements = splitPostgresStatements(migration.up);

          for (final statement in statements) {
            await tx.execute(statement);
          }

          await tx.execute(
            Sql.named('''
              INSERT INTO schema_migrations (version, name)
              VALUES (@version, @name)
              ON CONFLICT (version) DO NOTHING
            '''),
            parameters: {'version': migration.version, 'name': migration.name},
          );
        });

        print('   ✅ Sucesso');
        migratedCount++;
      } catch (e) {
        print('   ❌ Erro: $e');
        print(
          '\n⚠️  Migração interrompida. Corrija o erro e execute novamente.',
        );
        exit(1);
      }
    }

    print('\n' + '=' * 50);
    if (migratedCount > 0) {
      print('✅ $migratedCount migração(ões) executada(s) com sucesso!');
    } else {
      print('✅ Banco de dados já está atualizado!');
    }
    print('=' * 50);
  } catch (e) {
    print('❌ Erro na migração: $e');
    exit(1);
  } finally {
    await connection.close();
  }
}
