BEGIN;

CREATE TEMP TABLE pg090_deck6_l2_hash_target (
  normalized_name text,
  logical_rule_key text
);

INSERT INTO pg090_deck6_l2_hash_target VALUES
  ('scroll rack', 'battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2'),
  ('silence', 'battle_rule_v1:74b210b77b004a677906e0216d44e445'),
  ('fellwar stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba'),
  ('mana vault', 'battle_rule_v1:5a2533694ffd19223d3cde1e25d258ff'),
  ('mox amber', 'battle_rule_v1:972703914ee50acd7a4e6f529fea1adf'),
  ('seething song', 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7'),
  ('talisman of conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470'),
  ('unexpected windfall', 'battle_rule_v1:f9f98ea1925518eea7a7c94c21ef2dc4'),
  ('valakut awakening // valakut stoneforge', 'battle_rule_v1:6e1f3b876822abafe1de47610f46858d');

DELETE FROM card_battle_rules r
USING pg090_deck6_l2_hash_target t
WHERE r.normalized_name = t.normalized_name
  AND r.logical_rule_key = t.logical_rule_key;

INSERT INTO card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg090_deck6_l2_hash_restore_20260623_061026;

COMMIT;
