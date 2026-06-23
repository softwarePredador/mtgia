\pset pager off

CREATE TEMP TABLE pg074_targets(normalized_name text, logical_rule_key text);

INSERT INTO pg074_targets(normalized_name, logical_rule_key)
VALUES
  ('fellwar stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba'),
  ('mana vault', 'battle_rule_v1:5a2533694ffd19223d3cde1e25d258ff'),
  ('mox amber', 'battle_rule_v1:972703914ee50acd7a4e6f529fea1adf'),
  ('scroll rack', 'battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2'),
  ('seething song', 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7'),
  ('talisman of conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470'),
  ('unexpected windfall', 'battle_rule_v1:f9f98ea1925518eea7a7c94c21ef2dc4'),
  ('valakut awakening // valakut stoneforge', 'battle_rule_v1:6e1f3b876822abafe1de47610f46858d');

CREATE TEMP TABLE pg074_target_rules AS
SELECT
  c.name,
  c.type_line,
  md5(coalesce(c.oracle_text, '')) AS current_oracle_hash,
  cbr.normalized_name,
  cbr.logical_rule_key,
  cbr.source,
  cbr.review_status,
  cbr.execution_status,
  cbr.oracle_hash,
  cbr.effect_json->>'battle_model_scope' AS battle_model_scope,
  cbr.effect_json,
  cbr.deck_role_json
FROM pg074_targets t
JOIN card_battle_rules cbr
  ON cbr.normalized_name = t.normalized_name
 AND cbr.logical_rule_key = t.logical_rule_key
JOIN cards c ON c.id = cbr.card_id;

SELECT
  (SELECT count(*) FROM pg074_targets) AS expected_target_rows,
  count(*) AS target_rule_rows,
  count(*) FILTER (WHERE oracle_hash IS NULL) AS missing_oracle_hash_rows,
  count(*) FILTER (
    WHERE oracle_hash IS NOT NULL
      AND oracle_hash <> current_oracle_hash
  ) AS hash_mismatch_rows,
  count(*) FILTER (
    WHERE battle_model_scope IS NULL OR battle_model_scope = ''
  ) AS missing_scope_rows,
  to_regclass('manaloom_deploy_audit.pg074_deck6_hash_provenance_restore_20260623_052703') IS NOT NULL AS backup_table_already_exists
FROM pg074_target_rules;

SELECT
  name,
  normalized_name,
  logical_rule_key,
  review_status,
  execution_status,
  current_oracle_hash,
  oracle_hash,
  battle_model_scope,
  effect_json
FROM pg074_target_rules
ORDER BY name, logical_rule_key;
