-- READ ONLY. Run only after an approved PG875 apply.

BEGIN TRANSACTION READ ONLY;

WITH function_rows AS (
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
    (
      SELECT count(*)
      FROM manaloom_deploy_audit.pg875_lander_function_backup_20260716
    ) AS function_backup_count,
    (
      SELECT count(*)
      FROM manaloom_deploy_audit.pg875_lander_role_backup_20260716
    ) AS role_backup_count,
    (
      SELECT count(*)
      FROM manaloom_deploy_audit.pg875_lander_semantic_backup_20260716
    ) AS semantic_backup_count,
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
    ) AS semantic_sha256,
    (
      SELECT count(*)
      FROM (
        (
          SELECT * FROM function_rows
          EXCEPT
          SELECT *
          FROM manaloom_deploy_audit.pg875_lander_function_post_20260716
        )
        UNION ALL
        (
          SELECT *
          FROM manaloom_deploy_audit.pg875_lander_function_post_20260716
          EXCEPT
          SELECT * FROM function_rows
        )
      ) diff
    ) AS function_post_diff,
    (
      SELECT count(*)
      FROM (
        (
          SELECT * FROM role_rows
          EXCEPT
          SELECT *
          FROM manaloom_deploy_audit.pg875_lander_role_post_20260716
        )
        UNION ALL
        (
          SELECT *
          FROM manaloom_deploy_audit.pg875_lander_role_post_20260716
          EXCEPT
          SELECT * FROM role_rows
        )
      ) diff
    ) AS role_post_diff,
    (
      SELECT count(*)
      FROM (
        (
          SELECT * FROM semantic_rows
          EXCEPT
          SELECT *
          FROM manaloom_deploy_audit.pg875_lander_semantic_post_20260716
        )
        UNION ALL
        (
          SELECT *
          FROM manaloom_deploy_audit.pg875_lander_semantic_post_20260716
          EXCEPT
          SELECT * FROM semantic_rows
        )
      ) diff
    ) AS semantic_post_diff,
    (
      SELECT count(*)
      FROM (
        (
          SELECT f.*
          FROM public.card_function_tags f
          WHERE f.card_id =
            '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
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
          WHERE f.card_id =
            '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
            AND f.source NOT IN (
              'deterministic_heuristic_v1', 'deterministic_semantic_v2'
            )
        )
      ) diff
    ) AS untouched_function_diff,
    (
      SELECT count(*)
      FROM (
        (
          SELECT r.*
          FROM public.card_role_scores r
          WHERE r.card_id =
            '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
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
          WHERE r.card_id =
            '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
            AND r.source <> 'deterministic_heuristic_v1'
        )
      ) diff
    ) AS untouched_role_diff,
    (
      SELECT count(*)
      FROM (
        (
          SELECT s.*
          FROM public.card_semantic_tags_v2 s
          WHERE s.card_id =
            '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
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
          WHERE s.card_id =
            '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
            AND s.source <> 'deterministic_semantic_v2'
        )
      ) diff
    ) AS untouched_semantic_diff,
    (
      SELECT count(*)
      FROM (
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
          WHERE c.id =
            '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
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
          WHERE c.id =
            '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
        )
      ) diff
    ) AS target_input_diff
)
SELECT
  *,
  CASE
    WHEN function_backup_count = 11
      AND role_backup_count = 4
      AND semantic_backup_count = 1
      AND function_count = 12
      AND function_sha256 =
        '6a946bfdfaa01c1a16b5c9638a7504893f6b163832bd3ea0b12a07829460d284'
      AND role_count = 5
      AND role_sha256 =
        'eb51e1b334b9ff3a37612dca964a7306d2f8e2c46fd6a345ee39f09c1f6ca709'
      AND semantic_count = 1
      AND semantic_sha256 =
        '1f794fb8848be69a228982b31ea2cf58b074252f5243706b71d8628feabb3e34'
      AND function_post_diff = 0
      AND role_post_diff = 0
      AND semantic_post_diff = 0
      AND untouched_function_diff = 0
      AND untouched_role_diff = 0
      AND untouched_semantic_diff = 0
      AND target_input_diff = 0
    THEN 'PG875_POSTCHECK_PASS'
    ELSE 'PG875_POSTCHECK_ABORT_STATE_DRIFT'
  END AS status
FROM metrics;

SELECT
  source,
  tag,
  confidence,
  evidence
FROM public.card_function_tags
WHERE card_id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
ORDER BY source, tag;

SELECT
  source,
  role,
  score,
  bracket_scope,
  budget_tier,
  evidence
FROM public.card_role_scores
WHERE card_id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
ORDER BY source, role;

SELECT
  source,
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
  tags
FROM public.card_semantic_tags_v2
WHERE card_id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
ORDER BY source, schema_version;

ROLLBACK;
