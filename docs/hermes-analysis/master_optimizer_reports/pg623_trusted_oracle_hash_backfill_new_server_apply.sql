BEGIN;

WITH params AS (
  SELECT 'PG623_TRUSTED_ORACLE_HASH_BACKFILL_20260707: oracle_hash=md5(cards.oracle_text); previous oracle_hash was blank.'::text AS marker
),
target AS (
  SELECT
    b.card_id,
    b.normalized_name,
    b.logical_rule_key,
    md5(coalesce(c.oracle_text, '')) AS computed_oracle_hash
  FROM card_battle_rules b
  JOIN cards c ON c.id = b.card_id
  WHERE b.review_status IN ('verified', 'active')
    AND b.execution_status IN ('auto', 'executable')
    AND coalesce(b.oracle_hash, '') = ''
    AND coalesce(c.oracle_text, '') <> ''
),
updated AS (
  UPDATE card_battle_rules b
  SET
    oracle_hash = target.computed_oracle_hash,
    notes = CASE
      WHEN coalesce(b.notes, '') LIKE '%' || params.marker || '%' THEN b.notes
      ELSE concat_ws(E'\n', nullif(b.notes, ''), params.marker)
    END,
    updated_at = now()
  FROM target, params
  WHERE b.card_id = target.card_id
    AND b.normalized_name = target.normalized_name
    AND b.logical_rule_key = target.logical_rule_key
    AND b.review_status IN ('verified', 'active')
    AND b.execution_status IN ('auto', 'executable')
    AND coalesce(b.oracle_hash, '') = ''
  RETURNING b.card_name, b.normalized_name, b.logical_rule_key, b.oracle_hash
)
SELECT count(*) AS updated_rows
FROM updated;

COMMIT;
