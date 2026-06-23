\pset pager off

BEGIN;

DELETE FROM card_battle_rules
WHERE (normalized_name, logical_rule_key) IN (
  ('angel''s grace', 'battle_rule_v1:2833836fd4d943d3e02d1cfa2d284227'),
  ('fellwar stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba'),
  ('library of leng', 'battle_rule_v1:b6491cf6f7d7df9a3fb0d91abd3d31c3'),
  ('mana vault', 'battle_rule_v1:5a2533694ffd19223d3cde1e25d258ff'),
  ('mox amber', 'battle_rule_v1:972703914ee50acd7a4e6f529fea1adf'),
  ('scroll rack', 'battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2'),
  ('seething song', 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7'),
  ('silence', 'battle_rule_v1:74b210b77b004a677906e0216d44e445'),
  ('talisman of conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470'),
  ('unexpected windfall', 'battle_rule_v1:f9f98ea1925518eea7a7c94c21ef2dc4'),
  ('valakut awakening // valakut stoneforge', 'battle_rule_v1:6e1f3b876822abafe1de47610f46858d'),
  ('wayfarer''s bauble', 'battle_rule_v1:97eb0d5868d1c777b74aa7d35fc85eab')
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
FROM manaloom_deploy_audit.pg105_hash_scope_restore_current_drift_20260623_133948;

COMMIT;
