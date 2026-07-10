WITH targets AS (
  SELECT
    cbr.normalized_name,
    cbr.card_name,
    cbr.logical_rule_key,
    cbr.review_status,
    cbr.execution_status,
    c.id AS card_id,
    md5(c.oracle_text) AS computed_oracle_hash
  FROM public.card_battle_rules cbr
  JOIN public.cards c ON c.id = cbr.card_id
  WHERE cbr.review_status IN ('verified', 'active')
    AND cbr.execution_status IN ('auto', 'executable')
    AND COALESCE(btrim(cbr.oracle_hash), '') = ''
    AND btrim(COALESCE(c.oracle_text, '')) <> ''
)
SELECT
  count(*) AS fillable_trusted_executable_missing_hash_rows,
  count(DISTINCT card_id) AS fillable_card_count,
  count(DISTINCT normalized_name) AS fillable_identity_count
FROM targets;

WITH targets AS (
  SELECT
    cbr.normalized_name,
    cbr.card_name,
    cbr.logical_rule_key,
    cbr.review_status,
    cbr.execution_status,
    c.id AS card_id,
    md5(c.oracle_text) AS computed_oracle_hash
  FROM public.card_battle_rules cbr
  JOIN public.cards c ON c.id = cbr.card_id
  WHERE cbr.review_status IN ('verified', 'active')
    AND cbr.execution_status IN ('auto', 'executable')
    AND COALESCE(btrim(cbr.oracle_hash), '') = ''
    AND btrim(COALESCE(c.oracle_text, '')) <> ''
)
SELECT
  normalized_name,
  card_name,
  logical_rule_key,
  review_status,
  execution_status,
  computed_oracle_hash
FROM targets
ORDER BY normalized_name, logical_rule_key;
