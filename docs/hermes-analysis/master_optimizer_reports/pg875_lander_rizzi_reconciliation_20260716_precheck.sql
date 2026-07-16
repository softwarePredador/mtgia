-- READ ONLY. PG875 exact deterministic reconciliation precheck for Lander Rizzi.
-- This package is intentionally limited to card UUID
-- 1f10f7b7-a895-4a76-9d64-7751eced092e.

BEGIN TRANSACTION READ ONLY;

WITH target AS (
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
), function_rows AS (
  SELECT f.*
  FROM public.card_function_tags f
  WHERE f.card_id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
    AND f.source IN (
      'deterministic_heuristic_v1',
      'deterministic_semantic_v2'
    )
), role_rows AS (
  SELECT r.*
  FROM public.card_role_scores r
  WHERE r.card_id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
    AND r.source = 'deterministic_heuristic_v1'
), semantic_rows AS (
  SELECT s.*
  FROM public.card_semantic_tags_v2 s
  WHERE s.card_id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
    AND s.source = 'deterministic_semantic_v2'
), metrics AS (
  SELECT
    (SELECT count(*) FROM target) AS target_count,
    (SELECT max(name) FROM target) AS target_name,
    (SELECT max(type_line) FROM target) AS target_type_line,
    (SELECT md5(max(oracle_text)) FROM target) AS oracle_md5,
    (SELECT max(usage_count) FROM target) AS usage_count,
    (SELECT max(meta_deck_count) FROM target) AS meta_deck_count,
    (
      SELECT encode(digest(string_agg(
        concat_ws(
          '|', card_id::text, name, type_line, oracle_text, mana_cost,
          cmc::text, usage_count::text, meta_deck_count::text
        ), E'\n' ORDER BY card_id::text
      ), 'sha256'), 'hex')
      FROM target
    ) AS target_sha256,
    (SELECT count(*) FROM function_rows) AS function_count,
    (
      SELECT encode(digest(string_agg(
        concat_ws(
          '|', card_id::text, card_name, tag, confidence::text, source,
          evidence
        ), E'\n' ORDER BY source, tag
      ), 'sha256'), 'hex')
      FROM function_rows
    ) AS function_sha256,
    (SELECT count(*) FROM role_rows) AS role_count,
    (
      SELECT encode(digest(string_agg(
        concat_ws(
          '|', card_id::text, card_name, role, score::text, format,
          subformat, bracket_scope, budget_tier, source, evidence
        ), E'\n' ORDER BY source, role, format, subformat, bracket_scope,
          budget_tier
      ), 'sha256'), 'hex')
      FROM role_rows
    ) AS role_sha256,
    (SELECT count(*) FROM semantic_rows) AS semantic_count,
    (
      SELECT encode(digest(string_agg(
        concat_ws(
          '|', card_id::text, card_name, schema_version, speed,
          mana_efficiency, card_advantage_type, interaction_scope,
          combo_piece::text, wincon::text, engine::text, payoff::text,
          enabler::text, protection_type, recursion_type,
          role_confidence::text, explanation_reason, tags::text, source
        ), E'\n' ORDER BY source, schema_version
      ), 'sha256'), 'hex')
      FROM semantic_rows
    ) AS semantic_sha256
)
SELECT
  *,
  CASE
    WHEN target_count = 1
      AND target_name = 'Lander Rizzi'
      AND target_type_line = 'Legendary Artifact Creature — Lander Rogue'
      AND oracle_md5 = '6c261900f590f9084d7a8feadc132020'
      AND usage_count = 30
      AND meta_deck_count = 5
      AND target_sha256 =
        'd507f9cad9c0d2c08a76c07ed183ed2772a72eb71ced7f6018a88233dce4edfe'
      AND function_count = 11
      AND function_sha256 =
        '940bfb92b0dd23af72999cff33de4dfd6de5cbb00581f0edb421c01609e7d2f7'
      AND role_count = 4
      AND role_sha256 =
        '99f4819e273c273bc5dc15ef8db0251a8c376fa13b0c76029b90596350ea3f6d'
      AND semantic_count = 1
      AND semantic_sha256 =
        '0fc3a335e8d7184782c666fb4a7b1269cf636b244371cd4aceb5fef9547c66c2'
      AND to_regclass(
        'manaloom_deploy_audit.pg875_lander_target_20260716'
      ) IS NULL
      AND to_regclass(
        'manaloom_deploy_audit.pg875_lander_function_backup_20260716'
      ) IS NULL
      AND to_regclass(
        'manaloom_deploy_audit.pg875_lander_role_backup_20260716'
      ) IS NULL
      AND to_regclass(
        'manaloom_deploy_audit.pg875_lander_semantic_backup_20260716'
      ) IS NULL
      AND to_regclass(
        'manaloom_deploy_audit.pg875_lander_function_untouched_20260716'
      ) IS NULL
      AND to_regclass(
        'manaloom_deploy_audit.pg875_lander_role_untouched_20260716'
      ) IS NULL
      AND to_regclass(
        'manaloom_deploy_audit.pg875_lander_semantic_untouched_20260716'
      ) IS NULL
      AND to_regclass(
        'manaloom_deploy_audit.pg875_lander_function_post_20260716'
      ) IS NULL
      AND to_regclass(
        'manaloom_deploy_audit.pg875_lander_role_post_20260716'
      ) IS NULL
      AND to_regclass(
        'manaloom_deploy_audit.pg875_lander_semantic_post_20260716'
      ) IS NULL
    THEN 'PG875_PRECHECK_PASS'
    ELSE 'PG875_PRECHECK_ABORT_STATE_DRIFT'
  END AS status
FROM metrics;

SELECT
  'function' AS row_kind,
  source,
  tag AS key,
  confidence::text AS value,
  evidence
FROM public.card_function_tags
WHERE card_id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
ORDER BY source, tag;

SELECT
  'role' AS row_kind,
  source,
  role AS key,
  score::text AS value,
  evidence
FROM public.card_role_scores
WHERE card_id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
ORDER BY source, role;

SELECT
  card_name,
  schema_version,
  speed,
  mana_efficiency,
  card_advantage_type,
  interaction_scope,
  engine,
  payoff,
  enabler,
  role_confidence,
  explanation_reason,
  tags,
  source
FROM public.card_semantic_tags_v2
WHERE card_id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
ORDER BY source, schema_version;

ROLLBACK;
