-- PG625 apply: promote verified priority Lorehold scoped rules and backfill
-- oracle_hash for trusted executable rules. The card_intelligence_snapshot
-- rule identity fallback is applied by migration 032.
-- Run via: ./server/bin/with_new_server_pg.sh psql -X -v ON_ERROR_STOP=1 -f <this file>

BEGIN;

WITH target_rules(normalized_name, logical_rule_key) AS (
  VALUES
    ('fellwar stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba'),
    ('library of leng', 'battle_rule_v1:b6491cf6f7d7df9a3fb0d91abd3d31c3'),
    ('scroll rack', 'battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2'),
    ('talisman of conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470')
)
UPDATE card_battle_rules cbr
SET review_status = 'verified',
    execution_status = 'auto',
    reviewed_by = 'codex-pg625-priority-lorehold-validation',
    reviewed_at = CURRENT_TIMESTAMP,
    updated_at = CURRENT_TIMESTAMP,
    notes = concat_ws(
      E'\n',
      NULLIF(cbr.notes, ''),
      'PG625 2026-07-07: promoted to verified/auto after focused priority Lorehold runtime validation; Fellwar Stone now derives opponent land colors from table context, and the other rows are verified for their scoped battle_model_scope.'
    )
FROM target_rules t
WHERE cbr.normalized_name = t.normalized_name
  AND cbr.logical_rule_key = t.logical_rule_key
  AND cbr.review_status = 'active'
  AND cbr.execution_status = 'auto';

WITH candidate_hashes AS (
  SELECT
    cbr.normalized_name,
    cbr.logical_rule_key,
    md5(trim(COALESCE(c.oracle_text, cn.oracle_text))) AS new_oracle_hash
  FROM card_battle_rules cbr
  LEFT JOIN cards c ON c.id = cbr.card_id
  LEFT JOIN LATERAL (
    SELECT c2.oracle_text
    FROM cards c2
    WHERE lower(c2.name) = lower(cbr.card_name)
      AND COALESCE(trim(c2.oracle_text), '') <> ''
    ORDER BY c2.created_at DESC NULLS LAST, c2.id
    LIMIT 1
  ) cn ON COALESCE(trim(c.oracle_text), '') = ''
  WHERE cbr.source IN ('curated', 'manual')
    AND cbr.review_status IN ('verified', 'active')
    AND cbr.execution_status IN ('auto', 'executable')
    AND COALESCE(cbr.oracle_hash, '') = ''
    AND COALESCE(trim(COALESCE(c.oracle_text, cn.oracle_text)), '') <> ''
)
UPDATE card_battle_rules cbr
SET oracle_hash = candidate_hashes.new_oracle_hash,
    updated_at = CURRENT_TIMESTAMP,
    notes = concat_ws(
      E'\n',
      NULLIF(cbr.notes, ''),
      'PG625 2026-07-07: oracle_hash backfilled from canonical cards.oracle_text for trusted executable rule integrity gate.'
    )
FROM candidate_hashes
WHERE cbr.normalized_name = candidate_hashes.normalized_name
  AND cbr.logical_rule_key = candidate_hashes.logical_rule_key
  AND COALESCE(cbr.oracle_hash, '') = '';

COMMIT;
