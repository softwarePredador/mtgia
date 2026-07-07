BEGIN;

WITH params AS (
  SELECT 'PG623_TRUSTED_ORACLE_HASH_BACKFILL_20260707: oracle_hash=md5(cards.oracle_text); previous oracle_hash was blank.'::text AS marker
),
updated AS (
  UPDATE card_battle_rules b
  SET
    oracle_hash = NULL,
    notes = nullif(
      btrim(replace(coalesce(b.notes, ''), params.marker, ''), E'\n '),
      ''
    ),
    updated_at = now()
  FROM cards c, params
  WHERE c.id = b.card_id
    AND b.review_status IN ('verified', 'active')
    AND b.execution_status IN ('auto', 'executable')
    AND b.oracle_hash = md5(coalesce(c.oracle_text, ''))
    AND coalesce(b.notes, '') LIKE '%' || params.marker || '%'
  RETURNING b.card_name, b.normalized_name, b.logical_rule_key
)
SELECT count(*) AS rolled_back_rows
FROM updated;

COMMIT;
