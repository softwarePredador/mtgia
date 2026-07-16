-- READ ONLY. PG876 exact deterministic reconciliation precheck for
-- Ronin, Shadow Stalker only. No semantic snapshot is created by this package.

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
    (SELECT count(*) FROM target) AS target_count,
    (SELECT max(name) FROM target) AS target_name,
    (SELECT max(type_line) FROM target) AS target_type_line,
    (SELECT md5(max(oracle_text)) FROM target) AS oracle_md5,
    (
      SELECT encode(digest(string_agg(
        concat_ws(
          '|', card_id::text, name, type_line, oracle_text, mana_cost,
          cmc::text, price_usd, price_usd_foil, usage_count::text,
          meta_deck_count::text, inclusion_rate::text, sample_decks::text
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
    (
      SELECT count(*)
      FROM public.card_semantic_tags_v2 s
      WHERE s.card_id = '115df6db-5280-4223-921b-dc4f591841f2'::uuid
    ) AS semantic_snapshot_count,
    (
      SELECT count(*)
      FROM public.card_function_tags f
      WHERE f.card_id = '115df6db-5280-4223-921b-dc4f591841f2'::uuid
        AND f.source <> 'deterministic_heuristic_v1'
    ) AS untouched_function_count,
    (
      SELECT count(*)
      FROM public.card_role_scores r
      WHERE r.card_id = '115df6db-5280-4223-921b-dc4f591841f2'::uuid
        AND r.source <> 'deterministic_heuristic_v1'
    ) AS untouched_role_count
)
SELECT
  *,
  CASE
    WHEN target_count = 1
      AND target_name = 'Ronin, Shadow Stalker'
      AND target_type_line = 'Legendary Creature — Human Rogue Hero'
      AND oracle_md5 = '1c426ab026cf7ecac7f33b5e21775a6b'
      AND target_sha256 =
        '853b46a8324082709733e85a6486098aaf786cc73924cd7e85d6035b0105b3c8'
      AND function_count = 1
      AND function_sha256 =
        '83d684394dda226d06f4afb55fbb32b150b2d3780aa3856cc339c45abbf03381'
      AND role_count = 0
      AND role_sha256 IS NULL
      AND semantic_snapshot_count = 0
      AND untouched_function_count = 0
      AND untouched_role_count = 0
      AND to_regclass(
        'manaloom_deploy_audit.pg876_ronin_target_20260716'
      ) IS NULL
      AND to_regclass(
        'manaloom_deploy_audit.pg876_ronin_function_backup_20260716'
      ) IS NULL
      AND to_regclass(
        'manaloom_deploy_audit.pg876_ronin_role_backup_20260716'
      ) IS NULL
      AND to_regclass(
        'manaloom_deploy_audit.pg876_ronin_function_untouched_20260716'
      ) IS NULL
      AND to_regclass(
        'manaloom_deploy_audit.pg876_ronin_role_untouched_20260716'
      ) IS NULL
      AND to_regclass(
        'manaloom_deploy_audit.pg876_ronin_function_post_20260716'
      ) IS NULL
      AND to_regclass(
        'manaloom_deploy_audit.pg876_ronin_role_post_20260716'
      ) IS NULL
    THEN 'PG876_PRECHECK_PASS'
    ELSE 'PG876_PRECHECK_ABORT_STATE_DRIFT'
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
