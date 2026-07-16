-- READ ONLY. Run only after an explicitly approved PG876 apply.

BEGIN TRANSACTION READ ONLY;

WITH meta AS (
  SELECT
    lower(card_name) AS normalized_name,
    max(coalesce(usage_count, 0))::int AS usage_count,
    max(coalesce(meta_deck_count, 0))::int AS meta_deck_count
  FROM public.card_meta_insights
  GROUP BY lower(card_name)
), edhrec AS (
  SELECT
    lower(card_name) AS normalized_name,
    max(coalesce(inclusion, 0))::double precision AS inclusion_rate,
    max(coalesce(num_decks, 0))::int AS sample_decks
  FROM public.edhrec_card_snapshots
  WHERE card_name IS NOT NULL
    AND trim(card_name) <> ''
  GROUP BY lower(card_name)
), target AS (
  SELECT
    c.id AS card_id,
    c.name,
    coalesce(c.type_line, '') AS type_line,
    coalesce(c.oracle_text, '') AS oracle_text,
    coalesce(c.mana_cost, '') AS mana_cost,
    c.cmc,
    coalesce(c.price_usd::text, '') AS price_usd,
    coalesce(c.price_usd_foil::text, '') AS price_usd_foil,
    coalesce(m.usage_count, 0) AS usage_count,
    coalesce(m.meta_deck_count, 0) AS meta_deck_count,
    coalesce(e.inclusion_rate, 0) AS inclusion_rate,
    coalesce(e.sample_decks, 0) AS sample_decks
  FROM public.cards c
  LEFT JOIN meta m ON m.normalized_name = lower(c.name)
  LEFT JOIN edhrec e ON e.normalized_name = lower(c.name)
  WHERE c.id = '115df6db-5280-4223-921b-dc4f591841f2'::uuid
), function_rows AS (
  SELECT f.*
  FROM public.card_function_tags f
  WHERE f.card_id = '115df6db-5280-4223-921b-dc4f591841f2'::uuid
    AND f.source = 'deterministic_heuristic_v1'
), role_rows AS (
  SELECT r.*
  FROM public.card_role_scores r
  WHERE r.card_id = '115df6db-5280-4223-921b-dc4f591841f2'::uuid
    AND r.source = 'deterministic_heuristic_v1'
), metrics AS (
  SELECT
    (
      SELECT count(*)
      FROM manaloom_deploy_audit.pg876_ronin_function_backup_20260716
    ) AS function_backup_count,
    (
      SELECT count(*)
      FROM manaloom_deploy_audit.pg876_ronin_role_backup_20260716
    ) AS role_backup_count,
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
    (
      SELECT count(*)
      FROM (
        (SELECT * FROM function_rows
         EXCEPT
         SELECT *
         FROM manaloom_deploy_audit.pg876_ronin_function_post_20260716)
        UNION ALL
        (SELECT *
         FROM manaloom_deploy_audit.pg876_ronin_function_post_20260716
         EXCEPT
         SELECT * FROM function_rows)
      ) diff
    ) AS function_post_diff,
    (
      SELECT count(*)
      FROM (
        (SELECT * FROM role_rows
         EXCEPT
         SELECT *
         FROM manaloom_deploy_audit.pg876_ronin_role_post_20260716)
        UNION ALL
        (SELECT *
         FROM manaloom_deploy_audit.pg876_ronin_role_post_20260716
         EXCEPT
         SELECT * FROM role_rows)
      ) diff
    ) AS role_post_diff,
    (
      SELECT count(*)
      FROM (
        (SELECT * FROM target
         EXCEPT
         SELECT *
         FROM manaloom_deploy_audit.pg876_ronin_target_20260716)
        UNION ALL
        (SELECT *
         FROM manaloom_deploy_audit.pg876_ronin_target_20260716
         EXCEPT
         SELECT * FROM target)
      ) diff
    ) AS target_diff,
    (
      SELECT count(*)
      FROM (
        (
          SELECT f.*
          FROM public.card_function_tags f
          WHERE f.card_id =
            '115df6db-5280-4223-921b-dc4f591841f2'::uuid
            AND f.source <> 'deterministic_heuristic_v1'
          EXCEPT
          SELECT *
          FROM manaloom_deploy_audit.pg876_ronin_function_untouched_20260716
        )
        UNION ALL
        (
          SELECT *
          FROM manaloom_deploy_audit.pg876_ronin_function_untouched_20260716
          EXCEPT
          SELECT f.*
          FROM public.card_function_tags f
          WHERE f.card_id =
            '115df6db-5280-4223-921b-dc4f591841f2'::uuid
            AND f.source <> 'deterministic_heuristic_v1'
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
            '115df6db-5280-4223-921b-dc4f591841f2'::uuid
            AND r.source <> 'deterministic_heuristic_v1'
          EXCEPT
          SELECT *
          FROM manaloom_deploy_audit.pg876_ronin_role_untouched_20260716
        )
        UNION ALL
        (
          SELECT *
          FROM manaloom_deploy_audit.pg876_ronin_role_untouched_20260716
          EXCEPT
          SELECT r.*
          FROM public.card_role_scores r
          WHERE r.card_id =
            '115df6db-5280-4223-921b-dc4f591841f2'::uuid
            AND r.source <> 'deterministic_heuristic_v1'
        )
      ) diff
    ) AS untouched_role_diff,
    (
      SELECT count(*)
      FROM public.card_semantic_tags_v2 s
      WHERE s.card_id = '115df6db-5280-4223-921b-dc4f591841f2'::uuid
    ) AS semantic_snapshot_count
)
SELECT
  *,
  CASE
    WHEN function_backup_count = 1
      AND role_backup_count = 0
      AND function_count = 4
      AND function_sha256 =
        '9fe4dcd49d1940beb9d517c7f970814a98197f6fd8548a5d2e28a577cc1f3b01'
      AND role_count = 3
      AND role_sha256 =
        'cb9a07b13db7249c50d9fb03769668d8f200531694390d81a7d32c507fbb558a'
      AND function_post_diff = 0
      AND role_post_diff = 0
      AND target_diff = 0
      AND untouched_function_diff = 0
      AND untouched_role_diff = 0
      AND semantic_snapshot_count = 0
    THEN 'PG876_POSTCHECK_PASS'
    ELSE 'PG876_POSTCHECK_ABORT_STATE_DRIFT'
  END AS status
FROM metrics;

SELECT
  source,
  tag,
  confidence,
  evidence
FROM public.card_function_tags
WHERE card_id = '115df6db-5280-4223-921b-dc4f591841f2'::uuid
ORDER BY source, tag;

SELECT
  source,
  role,
  score,
  format,
  subformat,
  bracket_scope,
  budget_tier,
  evidence
FROM public.card_role_scores
WHERE card_id = '115df6db-5280-4223-921b-dc4f591841f2'::uuid
ORDER BY source, role, format, subformat, bracket_scope, budget_tier;

ROLLBACK;
