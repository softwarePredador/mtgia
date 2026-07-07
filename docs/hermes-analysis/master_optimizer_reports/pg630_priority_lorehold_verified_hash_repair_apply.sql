-- PG630 apply: repair verified status and oracle_hash for four priority Lorehold scoped rules.
-- Runtime coverage exists in test_priority_lorehold_card_runtime.py and XMage source
-- validates these scopes. This package repairs PostgreSQL drift only.
-- Run via: ./server/bin/with_new_server_pg.sh psql -X -v ON_ERROR_STOP=1 -f <this file>

BEGIN;

WITH target_rules(normalized_name, logical_rule_key, expected_hash) AS (
  VALUES
    ('fellwar stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba', 'd63befc8ac40d9a38732f9b5c1a7414a'),
    ('library of leng', 'battle_rule_v1:b6491cf6f7d7df9a3fb0d91abd3d31c3', '575aef3cc2523831e440ea7dcd55fa6e'),
    ('scroll rack', 'battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2', '8133928f03d5a5a77f2beecfcbd09e30'),
    ('talisman of conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470', 'd49ceec937367a344a9f0948eea4f8f2')
),
validated AS (
  SELECT t.normalized_name, t.logical_rule_key, t.expected_hash
  FROM target_rules t
  JOIN card_battle_rules cbr USING (normalized_name, logical_rule_key)
  JOIN cards c ON c.id = cbr.card_id
  WHERE cbr.review_status = 'active'
    AND cbr.execution_status = 'auto'
    AND md5(coalesce(c.oracle_text, '')) = t.expected_hash
)
UPDATE card_battle_rules cbr
SET review_status = 'verified',
    execution_status = 'auto',
    oracle_hash = v.expected_hash,
    reviewed_by = 'codex-pg630-priority-lorehold-verified-hash-repair',
    reviewed_at = CURRENT_TIMESTAMP,
    updated_at = CURRENT_TIMESTAMP,
    notes = concat_ws(
      E'\n',
      NULLIF(cbr.notes, ''),
      'PG630 2026-07-07: repaired priority Lorehold verified status and restored oracle_hash after new-server PostgreSQL drift; focused runtime tests passed and current cards.oracle_text hash matched expected snapshot hash.'
    )
FROM validated v
WHERE cbr.normalized_name = v.normalized_name
  AND cbr.logical_rule_key = v.logical_rule_key;

COMMIT;
