\pset pager off

BEGIN;

DELETE FROM card_battle_rules
WHERE (normalized_name, logical_rule_key) IN (
  ('fellwar stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba'),
  ('mana vault', 'battle_rule_v1:5a2533694ffd19223d3cde1e25d258ff'),
  ('mox amber', 'battle_rule_v1:972703914ee50acd7a4e6f529fea1adf'),
  ('talisman of conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470'),
  ('seething song', 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7')
);

INSERT INTO card_battle_rules (
  normalized_name,
  card_id,
  card_name,
  effect_json,
  deck_role_json,
  source,
  confidence,
  review_status,
  rule_version,
  oracle_hash,
  notes,
  reviewed_by,
  reviewed_at,
  created_at,
  updated_at,
  last_seen_at,
  logical_rule_key,
  execution_status
)
SELECT
  normalized_name,
  card_id,
  card_name,
  effect_json,
  deck_role_json,
  source,
  confidence,
  review_status,
  rule_version,
  oracle_hash,
  notes,
  reviewed_by,
  reviewed_at,
  created_at,
  updated_at,
  last_seen_at,
  logical_rule_key,
  execution_status
FROM manaloom_deploy_audit.pg083_runtime_hash_restore_20260623_083050;

COMMIT;
