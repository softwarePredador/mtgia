\echo 'PG696 trusted rule oracle_hash backfill precheck'

WITH target AS (
  SELECT
    b.normalized_name,
    b.card_name,
    b.logical_rule_key,
    b.card_id,
    c.name AS matched_card_name,
    md5(coalesce(c.oracle_text, '')) AS computed_oracle_hash
  FROM public.card_battle_rules b
  JOIN public.cards c ON c.id = b.card_id
  WHERE b.execution_status IN ('auto', 'executable')
    AND b.review_status IN ('verified', 'active')
    AND coalesce(b.oracle_hash, '') = ''
    AND btrim(coalesce(c.oracle_text, '')) <> ''
)
SELECT
  count(*) AS target_rows,
  count(*) FILTER (WHERE card_id IS NULL) AS unresolved_card_id_rows,
  count(*) FILTER (WHERE computed_oracle_hash = md5('')) AS empty_oracle_hash_rows
FROM target;

WITH unsafe AS (
  SELECT
    b.normalized_name,
    b.card_name,
    b.logical_rule_key,
    b.card_id
  FROM public.card_battle_rules b
  LEFT JOIN public.cards c ON c.id = b.card_id
  WHERE b.execution_status IN ('auto', 'executable')
    AND b.review_status IN ('verified', 'active')
    AND coalesce(b.oracle_hash, '') = ''
    AND (
      b.card_id IS NULL
      OR c.id IS NULL
      OR btrim(coalesce(c.oracle_text, '')) = ''
    )
)
SELECT count(*) AS unsafe_missing_hash_rows
FROM unsafe;

WITH target AS (
  SELECT
    b.normalized_name,
    b.card_name,
    b.logical_rule_key,
    b.card_id,
    c.name AS matched_card_name,
    md5(coalesce(c.oracle_text, '')) AS computed_oracle_hash
  FROM public.card_battle_rules b
  JOIN public.cards c ON c.id = b.card_id
  WHERE b.execution_status IN ('auto', 'executable')
    AND b.review_status IN ('verified', 'active')
    AND coalesce(b.oracle_hash, '') = ''
    AND btrim(coalesce(c.oracle_text, '')) <> ''
)
SELECT *
FROM target
ORDER BY normalized_name, logical_rule_key;
