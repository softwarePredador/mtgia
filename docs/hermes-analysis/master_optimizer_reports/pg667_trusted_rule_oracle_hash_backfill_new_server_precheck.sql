WITH affected AS (
  SELECT
    r.card_name,
    r.normalized_name,
    r.card_id,
    r.logical_rule_key,
    r.review_status,
    r.execution_status,
    r.rule_version,
    r.effect_json->>'effect' AS effect,
    r.effect_json->>'battle_model_scope' AS battle_model_scope,
    c.name AS db_card_name,
    c.oracle_id,
    md5(coalesce(c.oracle_text, '')) AS computed_oracle_hash,
    length(coalesce(c.oracle_text, '')) AS oracle_text_length
  FROM public.card_battle_rules r
  JOIN public.cards c ON c.id = r.card_id
  WHERE r.review_status IN ('verified', 'active')
    AND r.execution_status = 'auto'
    AND (r.oracle_hash IS NULL OR btrim(r.oracle_hash) = '')
    AND btrim(coalesce(c.oracle_text, '')) <> ''
)
SELECT
  count(*) AS backfillable_rule_rows,
  count(DISTINCT card_id) AS affected_card_ids,
  min(card_name) AS first_card,
  max(card_name) AS last_card
FROM affected;

WITH unsafe AS (
  SELECT
    r.card_name,
    r.normalized_name,
    r.card_id,
    r.logical_rule_key,
    r.review_status,
    r.execution_status
  FROM public.card_battle_rules r
  LEFT JOIN public.cards c ON c.id = r.card_id
  WHERE r.review_status IN ('verified', 'active')
    AND r.execution_status = 'auto'
    AND (r.oracle_hash IS NULL OR btrim(r.oracle_hash) = '')
    AND (
      r.card_id IS NULL
      OR c.id IS NULL
      OR btrim(coalesce(c.oracle_text, '')) = ''
    )
)
SELECT count(*) AS unsafe_missing_hash_rows
FROM unsafe;

WITH affected AS (
  SELECT
    r.card_name,
    r.normalized_name,
    r.card_id,
    r.logical_rule_key,
    r.review_status,
    r.execution_status,
    r.rule_version,
    r.effect_json->>'effect' AS effect,
    r.effect_json->>'battle_model_scope' AS battle_model_scope,
    c.name AS db_card_name,
    c.oracle_id,
    md5(coalesce(c.oracle_text, '')) AS computed_oracle_hash,
    length(coalesce(c.oracle_text, '')) AS oracle_text_length
  FROM public.card_battle_rules r
  JOIN public.cards c ON c.id = r.card_id
  WHERE r.review_status IN ('verified', 'active')
    AND r.execution_status = 'auto'
    AND (r.oracle_hash IS NULL OR btrim(r.oracle_hash) = '')
    AND btrim(coalesce(c.oracle_text, '')) <> ''
)
SELECT *
FROM affected
ORDER BY card_name, logical_rule_key;
