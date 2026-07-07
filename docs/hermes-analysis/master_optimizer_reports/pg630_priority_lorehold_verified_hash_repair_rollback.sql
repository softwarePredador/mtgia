-- PG630 rollback: restore the exact pre-apply drift state for the four target rows.
-- Run only if PG630 postcheck fails.
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
SET review_status = 'active',
    execution_status = 'auto',
    oracle_hash = NULL,
    updated_at = CURRENT_TIMESTAMP,
    notes = concat_ws(
      E'\n',
      NULLIF(cbr.notes, ''),
      'PG630 rollback 2026-07-07: restored active/auto status and blank oracle_hash for priority Lorehold drift repair target.'
    )
FROM target_rules t
WHERE cbr.normalized_name = t.normalized_name
  AND cbr.logical_rule_key = t.logical_rule_key;

COMMIT;
