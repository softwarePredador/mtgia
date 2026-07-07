-- PG631 apply: metadata-only oracle_hash backfill for trusted executable battle rules.
-- Uses md5(cards.oracle_text) for rows with valid card_id and nonblank Oracle text.
-- Run via: ./server/bin/with_new_server_pg.sh psql -X -v ON_ERROR_STOP=1 -f <this file>

BEGIN;

WITH target_rows AS (
  SELECT cbr.normalized_name, cbr.logical_rule_key, md5(coalesce(c.oracle_text, '')) AS computed_oracle_hash
  FROM card_battle_rules cbr
  JOIN cards c ON c.id = cbr.card_id
  WHERE cbr.source IN ('curated', 'manual')
    AND cbr.review_status IN ('verified', 'active')
    AND cbr.execution_status IN ('auto', 'executable')
    AND COALESCE(cbr.oracle_hash, '') = ''
    AND COALESCE(c.oracle_text, '') <> ''
)
UPDATE card_battle_rules cbr
SET oracle_hash = t.computed_oracle_hash,
    reviewed_by = COALESCE(cbr.reviewed_by, 'codex-pg631-oracle-hash-backfill'),
    updated_at = CURRENT_TIMESTAMP,
    notes = concat_ws(
      E'\n',
      NULLIF(cbr.notes, ''),
      'PG631 2026-07-07: metadata-only oracle_hash backfill from current cards.oracle_text for trusted executable battle-rule audit integrity.'
    )
FROM target_rows t
WHERE cbr.normalized_name = t.normalized_name
  AND cbr.logical_rule_key = t.logical_rule_key;

COMMIT;
