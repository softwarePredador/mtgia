-- MUTATING. Requires explicit PostgreSQL approval for this execution.
-- PG875 exact deterministic reconciliation for Lander Rizzi only.

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

LOCK TABLE public.cards IN SHARE MODE;
LOCK TABLE public.card_meta_insights IN SHARE MODE;
LOCK TABLE public.card_function_tags IN SHARE ROW EXCLUSIVE MODE;
LOCK TABLE public.card_role_scores IN SHARE ROW EXCLUSIVE MODE;
LOCK TABLE public.card_semantic_tags_v2 IN SHARE ROW EXCLUSIVE MODE;

DO $$
BEGIN
  IF to_regclass(
       'manaloom_deploy_audit.pg875_lander_target_20260716'
     ) IS NOT NULL
     OR to_regclass(
       'manaloom_deploy_audit.pg875_lander_function_backup_20260716'
     ) IS NOT NULL
     OR to_regclass(
       'manaloom_deploy_audit.pg875_lander_role_backup_20260716'
     ) IS NOT NULL
     OR to_regclass(
       'manaloom_deploy_audit.pg875_lander_semantic_backup_20260716'
     ) IS NOT NULL
     OR to_regclass(
       'manaloom_deploy_audit.pg875_lander_function_untouched_20260716'
     ) IS NOT NULL
     OR to_regclass(
       'manaloom_deploy_audit.pg875_lander_role_untouched_20260716'
     ) IS NOT NULL
     OR to_regclass(
       'manaloom_deploy_audit.pg875_lander_semantic_untouched_20260716'
     ) IS NOT NULL
     OR to_regclass(
       'manaloom_deploy_audit.pg875_lander_function_post_20260716'
     ) IS NOT NULL
     OR to_regclass(
       'manaloom_deploy_audit.pg875_lander_role_post_20260716'
     ) IS NOT NULL
     OR to_regclass(
       'manaloom_deploy_audit.pg875_lander_semantic_post_20260716'
     ) IS NOT NULL THEN
    RAISE EXCEPTION 'PG875 abort: an audit table already exists';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pg875_lander_target_20260716 AS
SELECT
  c.id AS card_id,
  c.name,
  coalesce(c.type_line, '') AS type_line,
  coalesce(c.oracle_text, '') AS oracle_text,
  coalesce(c.mana_cost, '') AS mana_cost,
  c.cmc,
  m.usage_count,
  m.meta_deck_count
FROM public.cards c
JOIN public.card_meta_insights m
  ON lower(m.card_name) = lower(c.name)
WHERE c.id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid;

ALTER TABLE manaloom_deploy_audit.pg875_lander_target_20260716
  ADD PRIMARY KEY (card_id);

CREATE TABLE manaloom_deploy_audit.pg875_lander_function_backup_20260716 AS
SELECT f.*
FROM public.card_function_tags f
WHERE f.card_id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
  AND f.source IN (
    'deterministic_heuristic_v1',
    'deterministic_semantic_v2'
  );

CREATE TABLE manaloom_deploy_audit.pg875_lander_role_backup_20260716 AS
SELECT r.*
FROM public.card_role_scores r
WHERE r.card_id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
  AND r.source = 'deterministic_heuristic_v1';

CREATE TABLE manaloom_deploy_audit.pg875_lander_semantic_backup_20260716 AS
SELECT s.*
FROM public.card_semantic_tags_v2 s
WHERE s.card_id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
  AND s.source = 'deterministic_semantic_v2';

-- Non-target sources are snapshotted separately and never deleted or updated.
CREATE TABLE manaloom_deploy_audit.pg875_lander_function_untouched_20260716 AS
SELECT f.*
FROM public.card_function_tags f
WHERE f.card_id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
  AND f.source NOT IN (
    'deterministic_heuristic_v1',
    'deterministic_semantic_v2'
  );

CREATE TABLE manaloom_deploy_audit.pg875_lander_role_untouched_20260716 AS
SELECT r.*
FROM public.card_role_scores r
WHERE r.card_id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
  AND r.source <> 'deterministic_heuristic_v1';

CREATE TABLE manaloom_deploy_audit.pg875_lander_semantic_untouched_20260716 AS
SELECT s.*
FROM public.card_semantic_tags_v2 s
WHERE s.card_id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
  AND s.source <> 'deterministic_semantic_v2';

DO $$
DECLARE
  v_target_count bigint;
  v_target_sha text;
  v_oracle_md5 text;
  v_usage integer;
  v_meta_decks integer;
  v_function_count bigint;
  v_function_sha text;
  v_role_count bigint;
  v_role_sha text;
  v_semantic_count bigint;
  v_semantic_sha text;
BEGIN
  SELECT
    count(*),
    encode(digest(string_agg(
      concat_ws(
        '|', card_id::text, name, type_line, oracle_text, mana_cost,
        cmc::text, usage_count::text, meta_deck_count::text
      ), E'\n' ORDER BY card_id::text
    ), 'sha256'), 'hex'),
    md5(max(oracle_text)),
    max(usage_count),
    max(meta_deck_count)
  INTO
    v_target_count, v_target_sha, v_oracle_md5, v_usage, v_meta_decks
  FROM manaloom_deploy_audit.pg875_lander_target_20260716;

  SELECT
    count(*),
    encode(digest(string_agg(
      concat_ws(
        '|', card_id::text, card_name, tag, confidence::text, source,
        evidence
      ), E'\n' ORDER BY source, tag
    ), 'sha256'), 'hex')
  INTO v_function_count, v_function_sha
  FROM manaloom_deploy_audit.pg875_lander_function_backup_20260716;

  SELECT
    count(*),
    encode(digest(string_agg(
      concat_ws(
        '|', card_id::text, card_name, role, score::text, format,
        subformat, bracket_scope, budget_tier, source, evidence
      ), E'\n' ORDER BY source, role, format, subformat, bracket_scope,
        budget_tier
    ), 'sha256'), 'hex')
  INTO v_role_count, v_role_sha
  FROM manaloom_deploy_audit.pg875_lander_role_backup_20260716;

  SELECT
    count(*),
    encode(digest(string_agg(
      concat_ws(
        '|', card_id::text, card_name, schema_version, speed,
        mana_efficiency, card_advantage_type, interaction_scope,
        combo_piece::text, wincon::text, engine::text, payoff::text,
        enabler::text, protection_type, recursion_type,
        role_confidence::text, explanation_reason, tags::text, source
      ), E'\n' ORDER BY source, schema_version
    ), 'sha256'), 'hex')
  INTO v_semantic_count, v_semantic_sha
  FROM manaloom_deploy_audit.pg875_lander_semantic_backup_20260716;

  IF v_target_count <> 1
     OR v_target_sha <>
       'd507f9cad9c0d2c08a76c07ed183ed2772a72eb71ced7f6018a88233dce4edfe'
     OR v_oracle_md5 <> '6c261900f590f9084d7a8feadc132020'
     OR v_usage <> 30
     OR v_meta_decks <> 5
     OR v_function_count <> 11
     OR v_function_sha <>
       '940bfb92b0dd23af72999cff33de4dfd6de5cbb00581f0edb421c01609e7d2f7'
     OR v_role_count <> 4
     OR v_role_sha <>
       '99f4819e273c273bc5dc15ef8db0251a8c376fa13b0c76029b90596350ea3f6d'
     OR v_semantic_count <> 1
     OR v_semantic_sha <>
       '0fc3a335e8d7184782c666fb4a7b1269cf636b244371cd4aceb5fef9547c66c2'
  THEN
    RAISE EXCEPTION
      'PG875 abort: prestate drift target=% function=% role=% semantic=%',
      v_target_count, v_function_count, v_role_count, v_semantic_count;
  END IF;
END $$;

DELETE FROM public.card_function_tags
WHERE card_id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
  AND source IN (
    'deterministic_heuristic_v1',
    'deterministic_semantic_v2'
  );

DELETE FROM public.card_role_scores
WHERE card_id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
  AND source = 'deterministic_heuristic_v1';

DELETE FROM public.card_semantic_tags_v2
WHERE card_id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
  AND source = 'deterministic_semantic_v2';

INSERT INTO public.card_function_tags (
  card_id, card_name, tag, confidence, source, evidence, updated_at
)
VALUES
  (
    '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid,
    'Lander Rizzi', 'ramp', 0.880, 'deterministic_heuristic_v1',
    'mana_or_land_ramp_text', CURRENT_TIMESTAMP
  ),
  (
    '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid,
    'Lander Rizzi', 'token_maker', 0.820, 'deterministic_heuristic_v1',
    'token_creation_text', CURRENT_TIMESTAMP
  ),
  (
    '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid,
    'Lander Rizzi', 'token', 0.820, 'deterministic_heuristic_v1',
    'token_creation_text;alias=v1', CURRENT_TIMESTAMP
  ),
  (
    '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid,
    'Lander Rizzi', 'sacrifice_outlet', 0.800,
    'deterministic_heuristic_v1',
    'external_activated_sacrifice_outlet_cost', CURRENT_TIMESTAMP
  ),
  (
    '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid,
    'Lander Rizzi', 'sacrifice', 0.800, 'deterministic_heuristic_v1',
    'external_activated_sacrifice_outlet_cost;alias=v1', CURRENT_TIMESTAMP
  ),
  (
    '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid,
    'Lander Rizzi', 'artifact_synergy', 0.740,
    'deterministic_heuristic_v1', 'artifact_payoff_text', CURRENT_TIMESTAMP
  ),
  (
    '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid,
    'Lander Rizzi', 'payoff', 0.720, 'deterministic_heuristic_v1',
    'payoff_trigger_or_scaling_text', CURRENT_TIMESTAMP
  ),
  (
    '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid,
    'Lander Rizzi', 'ramp', 0.880, 'deterministic_semantic_v2',
    'mana_or_land_ramp_text', CURRENT_TIMESTAMP
  ),
  (
    '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid,
    'Lander Rizzi', 'token_maker', 0.820, 'deterministic_semantic_v2',
    'token_creation_text', CURRENT_TIMESTAMP
  ),
  (
    '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid,
    'Lander Rizzi', 'sacrifice_outlet', 0.800,
    'deterministic_semantic_v2',
    'external_activated_sacrifice_outlet_cost', CURRENT_TIMESTAMP
  ),
  (
    '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid,
    'Lander Rizzi', 'artifact_synergy', 0.740,
    'deterministic_semantic_v2', 'artifact_payoff_text', CURRENT_TIMESTAMP
  ),
  (
    '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid,
    'Lander Rizzi', 'payoff', 0.720, 'deterministic_semantic_v2',
    'payoff_trigger_or_scaling_text', CURRENT_TIMESTAMP
  );

INSERT INTO public.card_role_scores (
  card_id, card_name, role, score, format, subformat, bracket_scope,
  budget_tier, source, evidence, updated_at
)
VALUES
  (
    '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid,
    'Lander Rizzi', 'ramp', 80, 'commander', 'any', 'bracket_2_4',
    'unknown', 'deterministic_heuristic_v1', 'mana_or_land_ramp_text',
    CURRENT_TIMESTAMP
  ),
  (
    '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid,
    'Lander Rizzi', 'token', 76, 'commander', 'any', 'any', 'unknown',
    'deterministic_heuristic_v1', 'token_creation_text;alias=v1',
    CURRENT_TIMESTAMP
  ),
  (
    '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid,
    'Lander Rizzi', 'sacrifice', 75, 'commander', 'any', 'any', 'unknown',
    'deterministic_heuristic_v1',
    'external_activated_sacrifice_outlet_cost;alias=v1', CURRENT_TIMESTAMP
  ),
  (
    '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid,
    'Lander Rizzi', 'artifact_synergy', 70, 'commander', 'any', 'any',
    'unknown', 'deterministic_heuristic_v1', 'artifact_payoff_text',
    CURRENT_TIMESTAMP
  ),
  (
    '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid,
    'Lander Rizzi', 'payoff', 69, 'commander', 'any', 'any', 'unknown',
    'deterministic_heuristic_v1', 'payoff_trigger_or_scaling_text',
    CURRENT_TIMESTAMP
  );

INSERT INTO public.card_semantic_tags_v2 (
  card_id, card_name, schema_version, speed, mana_efficiency,
  card_advantage_type, interaction_scope, combo_piece, wincon, engine,
  payoff, enabler, protection_type, recursion_type, role_confidence,
  explanation_reason, tags, source, updated_at
)
VALUES (
  '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid,
  'Lander Rizzi',
  'semantic_layer_v2_2026_05_18',
  'triggered_engine',
  'cheap',
  'board_material',
  'none',
  FALSE,
  FALSE,
  FALSE,
  TRUE,
  -- Code truth: the inferred ramp tag makes semantic enabler true.
  TRUE,
  'none',
  'none',
  0.880,
  'mana_acceleration_or_land_search',
  '[
    {"tag":"ramp","confidence":0.88,"evidence":"mana_or_land_ramp_text"},
    {"tag":"token_maker","confidence":0.82,"evidence":"token_creation_text"},
    {"tag":"sacrifice_outlet","confidence":0.8,"evidence":"external_activated_sacrifice_outlet_cost"},
    {"tag":"artifact_synergy","confidence":0.74,"evidence":"artifact_payoff_text"},
    {"tag":"payoff","confidence":0.72,"evidence":"payoff_trigger_or_scaling_text"}
  ]'::jsonb,
  'deterministic_semantic_v2',
  CURRENT_TIMESTAMP
);

CREATE TABLE manaloom_deploy_audit.pg875_lander_function_post_20260716 AS
SELECT f.*
FROM public.card_function_tags f
WHERE f.card_id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
  AND f.source IN (
    'deterministic_heuristic_v1',
    'deterministic_semantic_v2'
  );

CREATE TABLE manaloom_deploy_audit.pg875_lander_role_post_20260716 AS
SELECT r.*
FROM public.card_role_scores r
WHERE r.card_id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
  AND r.source = 'deterministic_heuristic_v1';

CREATE TABLE manaloom_deploy_audit.pg875_lander_semantic_post_20260716 AS
SELECT s.*
FROM public.card_semantic_tags_v2 s
WHERE s.card_id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
  AND s.source = 'deterministic_semantic_v2';

DO $$
DECLARE
  v_function_count bigint;
  v_function_sha text;
  v_role_count bigint;
  v_role_sha text;
  v_semantic_count bigint;
  v_semantic_sha text;
BEGIN
  SELECT
    count(*),
    encode(digest(string_agg(
      concat_ws(
        '|', card_id::text, card_name, tag, confidence::text, source,
        evidence
      ), E'\n' ORDER BY source, tag
    ), 'sha256'), 'hex')
  INTO v_function_count, v_function_sha
  FROM manaloom_deploy_audit.pg875_lander_function_post_20260716;

  SELECT
    count(*),
    encode(digest(string_agg(
      concat_ws(
        '|', card_id::text, card_name, role, score::text, format,
        subformat, bracket_scope, budget_tier, source, evidence
      ), E'\n' ORDER BY source, role, format, subformat, bracket_scope,
        budget_tier
    ), 'sha256'), 'hex')
  INTO v_role_count, v_role_sha
  FROM manaloom_deploy_audit.pg875_lander_role_post_20260716;

  SELECT
    count(*),
    encode(digest(string_agg(
      concat_ws(
        '|', card_id::text, card_name, schema_version, speed,
        mana_efficiency, card_advantage_type, interaction_scope,
        combo_piece::text, wincon::text, engine::text, payoff::text,
        enabler::text, protection_type, recursion_type,
        role_confidence::text, explanation_reason, tags::text, source
      ), E'\n' ORDER BY source, schema_version
    ), 'sha256'), 'hex')
  INTO v_semantic_count, v_semantic_sha
  FROM manaloom_deploy_audit.pg875_lander_semantic_post_20260716;

  IF v_function_count <> 12
     OR v_function_sha <>
       '6a946bfdfaa01c1a16b5c9638a7504893f6b163832bd3ea0b12a07829460d284'
     OR v_role_count <> 5
     OR v_role_sha <>
       'eb51e1b334b9ff3a37612dca964a7306d2f8e2c46fd6a345ee39f09c1f6ca709'
     OR v_semantic_count <> 1
     OR v_semantic_sha <>
       '1f794fb8848be69a228982b31ea2cf58b074252f5243706b71d8628feabb3e34'
     OR (
       SELECT count(*)
       FROM manaloom_deploy_audit.pg875_lander_function_post_20260716
       WHERE source = 'deterministic_heuristic_v1'
     ) <> 7
     OR (
       SELECT count(*)
       FROM manaloom_deploy_audit.pg875_lander_function_post_20260716
       WHERE source = 'deterministic_semantic_v2'
     ) <> 5
  THEN
    RAISE EXCEPTION
      'PG875 abort: poststate drift function=% role=% semantic=%',
      v_function_count, v_role_count, v_semantic_count;
  END IF;

  IF EXISTS (
    (
      SELECT f.*
      FROM public.card_function_tags f
      WHERE f.card_id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
        AND f.source NOT IN (
          'deterministic_heuristic_v1', 'deterministic_semantic_v2'
        )
      EXCEPT
      SELECT *
      FROM manaloom_deploy_audit.pg875_lander_function_untouched_20260716
    )
    UNION ALL
    (
      SELECT *
      FROM manaloom_deploy_audit.pg875_lander_function_untouched_20260716
      EXCEPT
      SELECT f.*
      FROM public.card_function_tags f
      WHERE f.card_id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
        AND f.source NOT IN (
          'deterministic_heuristic_v1', 'deterministic_semantic_v2'
        )
    )
  ) THEN
    RAISE EXCEPTION 'PG875 abort: non-target function rows changed';
  END IF;

  IF EXISTS (
    (
      SELECT r.*
      FROM public.card_role_scores r
      WHERE r.card_id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
        AND r.source <> 'deterministic_heuristic_v1'
      EXCEPT
      SELECT *
      FROM manaloom_deploy_audit.pg875_lander_role_untouched_20260716
    )
    UNION ALL
    (
      SELECT *
      FROM manaloom_deploy_audit.pg875_lander_role_untouched_20260716
      EXCEPT
      SELECT r.*
      FROM public.card_role_scores r
      WHERE r.card_id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
        AND r.source <> 'deterministic_heuristic_v1'
    )
  ) THEN
    RAISE EXCEPTION 'PG875 abort: non-target role rows changed';
  END IF;

  IF EXISTS (
    (
      SELECT s.*
      FROM public.card_semantic_tags_v2 s
      WHERE s.card_id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
        AND s.source <> 'deterministic_semantic_v2'
      EXCEPT
      SELECT *
      FROM manaloom_deploy_audit.pg875_lander_semantic_untouched_20260716
    )
    UNION ALL
    (
      SELECT *
      FROM manaloom_deploy_audit.pg875_lander_semantic_untouched_20260716
      EXCEPT
      SELECT s.*
      FROM public.card_semantic_tags_v2 s
      WHERE s.card_id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
        AND s.source <> 'deterministic_semantic_v2'
    )
  ) THEN
    RAISE EXCEPTION 'PG875 abort: non-target semantic rows changed';
  END IF;

  IF EXISTS (
    (
      SELECT
        c.id AS card_id,
        c.name,
        coalesce(c.type_line, '') AS type_line,
        coalesce(c.oracle_text, '') AS oracle_text,
        coalesce(c.mana_cost, '') AS mana_cost,
        c.cmc,
        m.usage_count,
        m.meta_deck_count
      FROM public.cards c
      JOIN public.card_meta_insights m
        ON lower(m.card_name) = lower(c.name)
      WHERE c.id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
      EXCEPT
      SELECT *
      FROM manaloom_deploy_audit.pg875_lander_target_20260716
    )
    UNION ALL
    (
      SELECT *
      FROM manaloom_deploy_audit.pg875_lander_target_20260716
      EXCEPT
      SELECT
        c.id AS card_id,
        c.name,
        coalesce(c.type_line, '') AS type_line,
        coalesce(c.oracle_text, '') AS oracle_text,
        coalesce(c.mana_cost, '') AS mana_cost,
        c.cmc,
        m.usage_count,
        m.meta_deck_count
      FROM public.cards c
      JOIN public.card_meta_insights m
        ON lower(m.card_name) = lower(c.name)
      WHERE c.id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
    )
  ) THEN
    RAISE EXCEPTION 'PG875 abort: card or meta input changed';
  END IF;
END $$;

COMMIT;
