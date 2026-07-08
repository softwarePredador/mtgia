BEGIN;

WITH missing AS (
  SELECT
    r.normalized_name,
    r.logical_rule_key,
    r.card_name,
    r.card_id
  FROM public.card_battle_rules r
  WHERE r.source IN ('curated', 'manual')
    AND r.review_status IN ('verified', 'active')
    AND r.execution_status IN ('auto', 'executable')
    AND COALESCE(r.oracle_hash, '') = ''
),
resolved AS (
  SELECT DISTINCT ON (m.normalized_name, m.logical_rule_key)
    m.normalized_name,
    m.logical_rule_key,
    md5(COALESCE(c.oracle_text, '')) AS oracle_hash
  FROM missing m
  JOIN public.cards c
    ON c.id = m.card_id
    OR lower(c.name) = m.normalized_name
    OR split_part(lower(c.name), ' // ', 1) = m.normalized_name
  WHERE COALESCE(c.oracle_text, '') <> ''
  ORDER BY
    m.normalized_name,
    m.logical_rule_key,
    CASE WHEN c.id = m.card_id THEN 0 ELSE 1 END,
    c.name,
    c.id
),
updated AS (
  UPDATE public.card_battle_rules r
  SET oracle_hash = resolved.oracle_hash,
      updated_at = CURRENT_TIMESTAMP
  FROM resolved
  WHERE r.normalized_name = resolved.normalized_name
    AND r.logical_rule_key = resolved.logical_rule_key
    AND r.source IN ('curated', 'manual')
    AND r.review_status IN ('verified', 'active')
    AND r.execution_status IN ('auto', 'executable')
    AND COALESCE(r.oracle_hash, '') = ''
  RETURNING
    r.card_name,
    r.normalized_name,
    r.logical_rule_key,
    r.oracle_hash
)
SELECT
  count(*) AS updated_rows
FROM updated;

COMMIT;
