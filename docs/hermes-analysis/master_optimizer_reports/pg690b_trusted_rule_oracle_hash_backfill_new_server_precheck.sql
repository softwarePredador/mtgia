\echo 'PG690b trusted rule oracle_hash backfill precheck'

WITH target AS (
  SELECT
    r.card_id,
    r.card_name,
    r.normalized_name,
    r.logical_rule_key,
    r.rule_version,
    r.source,
    r.review_status,
    r.execution_status,
    r.effect_json->>'effect' AS effect,
    r.effect_json->>'battle_model_scope' AS battle_model_scope,
    md5(coalesce(c.oracle_text, '')) AS computed_oracle_hash
  FROM public.card_battle_rules r
  JOIN public.cards c ON c.id = r.card_id
  WHERE r.review_status IN ('verified', 'active')
    AND r.execution_status IN ('auto', 'executable')
    AND (r.oracle_hash IS NULL OR btrim(r.oracle_hash) = '')
    AND btrim(coalesce(c.oracle_text, '')) <> ''
), unsafe AS (
  SELECT count(*)::int AS unsafe_count
  FROM public.card_battle_rules r
  LEFT JOIN public.cards c ON c.id = r.card_id
  WHERE r.review_status IN ('verified', 'active')
    AND r.execution_status IN ('auto', 'executable')
    AND (r.oracle_hash IS NULL OR btrim(r.oracle_hash) = '')
    AND (
      r.card_id IS NULL
      OR c.id IS NULL
      OR btrim(coalesce(c.oracle_text, '')) = ''
    )
)
SELECT
  (SELECT count(*) FROM target) AS backfillable_rows,
  (SELECT unsafe_count FROM unsafe) AS unsafe_missing_hash_rows;

WITH target AS (
  SELECT
    r.card_id,
    r.card_name,
    r.normalized_name,
    r.logical_rule_key,
    r.rule_version,
    r.source,
    r.review_status,
    r.execution_status,
    r.effect_json->>'effect' AS effect,
    r.effect_json->>'battle_model_scope' AS battle_model_scope,
    md5(coalesce(c.oracle_text, '')) AS computed_oracle_hash
  FROM public.card_battle_rules r
  JOIN public.cards c ON c.id = r.card_id
  WHERE r.review_status IN ('verified', 'active')
    AND r.execution_status IN ('auto', 'executable')
    AND (r.oracle_hash IS NULL OR btrim(r.oracle_hash) = '')
    AND btrim(coalesce(c.oracle_text, '')) <> ''
)
SELECT *
FROM target
ORDER BY card_name, normalized_name, logical_rule_key;
