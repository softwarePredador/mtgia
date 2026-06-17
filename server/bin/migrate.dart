// ignore_for_file: avoid_print

import 'dart:io';
import 'package:dotenv/dotenv.dart';
import 'package:postgres/postgres.dart';
import 'package:server/ai/candidate_quality_data_support.dart';
import 'package:server/ai/commander_learning_snapshot_support.dart';
import 'package:server/import_card_lookup_service.dart';

/// Sistema de Migrações Versionado para MTG IA
///
/// Gerencia migrações de banco de dados de forma ordenada e idempotente.
/// Cada migração é executada apenas uma vez e registrada na tabela `schema_migrations`.
///
/// Uso: dart run bin/migrate.dart [--status] [--rollback N]
///
/// Opções:
///   --status    Mostra o status das migrações
///   --rollback N  Reverte as últimas N migrações (não implementado - apenas placeholder)

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
        effect_json JSONB NOT NULL DEFAULT '{}'::jsonb,
        deck_role_json JSONB NOT NULL DEFAULT '{}'::jsonb,
        source TEXT NOT NULL DEFAULT 'curated',
        confidence NUMERIC(4,3) NOT NULL DEFAULT 1.0
          CHECK (confidence >= 0 AND confidence <= 1),
        review_status TEXT NOT NULL DEFAULT 'verified',
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

void main(List<String> args) async {
  final showStatus = args.contains('--status');

  final env = DotEnv()..load();

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
    // Criar tabela de controle de migrações
    await connection.execute('''
      CREATE TABLE IF NOT EXISTS schema_migrations (
        version TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        executed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Buscar migrações já executadas
    final executedResult = await connection.execute(
      'SELECT version FROM schema_migrations ORDER BY version',
    );
    final executedVersions = executedResult.map((r) => r[0] as String).toSet();

    if (showStatus) {
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
        // Executar cada statement da migração separadamente
        final statements = migration.up
            .split(';')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

        for (final statement in statements) {
          await connection.execute(statement);
        }

        // Registrar como executada
        await connection.execute(
          Sql.named('''
            INSERT INTO schema_migrations (version, name)
            VALUES (@version, @name)
            ON CONFLICT (version) DO NOTHING
          '''),
          parameters: {
            'version': migration.version,
            'name': migration.name,
          },
        );

        print('   ✅ Sucesso');
        migratedCount++;
      } catch (e) {
        print('   ❌ Erro: $e');
        print(
            '\n⚠️  Migração interrompida. Corrija o erro e execute novamente.');
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
