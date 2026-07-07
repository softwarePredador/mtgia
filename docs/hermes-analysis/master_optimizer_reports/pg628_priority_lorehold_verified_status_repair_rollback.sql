-- PG628 rollback: restore the four repaired rows to active/auto.
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
    reviewed_by = 'codex-pg625-priority-lorehold-validation',
    reviewed_at = CURRENT_TIMESTAMP,
    updated_at = CURRENT_TIMESTAMP,
    notes = regexp_replace(
      COALESCE(cbr.notes, ''),
      E'\\n?PG628 2026-07-07: repaired priority Lorehold verified status after current audit found active/auto drift; focused runtime tests and oracle_hash integrity were already present\\.',
      '',
      'g'
    )
FROM target_rules t
WHERE cbr.normalized_name = t.normalized_name
  AND cbr.logical_rule_key = t.logical_rule_key
  AND cbr.review_status = 'verified'
  AND cbr.execution_status = 'auto'
  AND cbr.reviewed_by = 'codex-pg628-priority-lorehold-verified-status';

COMMIT;
