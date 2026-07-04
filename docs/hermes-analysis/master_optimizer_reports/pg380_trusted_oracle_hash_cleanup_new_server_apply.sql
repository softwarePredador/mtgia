BEGIN;

WITH target AS (
  SELECT
    cbr.normalized_name,
    cbr.logical_rule_key,
    md5(coalesce(c.oracle_text, '')) AS expected_oracle_hash
  FROM card_battle_rules cbr
  JOIN cards c
    ON lower(c.name) = cbr.normalized_name
  WHERE cbr.normalized_name IN ('angel''s grace', 'seething song')
    AND cbr.source IN ('curated', 'manual')
    AND cbr.review_status IN ('verified', 'active')
    AND cbr.execution_status IN ('auto', 'executable')
    AND COALESCE(cbr.oracle_hash, '') = ''
)
UPDATE card_battle_rules cbr
SET
  oracle_hash = target.expected_oracle_hash,
  notes = concat_ws(
    E'\n',
    NULLIF(cbr.notes, ''),
    'PG380 trusted oracle hash cleanup: backfilled from cards.oracle_text on new server.'
  ),
  updated_at = now()
FROM target
WHERE cbr.normalized_name = target.normalized_name
  AND cbr.logical_rule_key = target.logical_rule_key
RETURNING
  cbr.card_name,
  cbr.normalized_name,
  cbr.logical_rule_key,
  cbr.oracle_hash,
  cbr.updated_at;

COMMIT;
