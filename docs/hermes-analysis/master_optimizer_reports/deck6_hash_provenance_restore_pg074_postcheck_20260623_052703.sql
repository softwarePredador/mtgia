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

SELECT
  count(*) AS target_rule_rows,
  count(*) FILTER (
    WHERE cbr.oracle_hash = md5(coalesce(c.oracle_text, ''))
  ) AS current_hash_rows,
  count(*) FILTER (
    WHERE cbr.oracle_hash IS NULL
  ) AS missing_oracle_hash_rows,
  count(*) FILTER (
    WHERE cbr.oracle_hash IS NOT NULL
      AND cbr.oracle_hash <> md5(coalesce(c.oracle_text, ''))
  ) AS hash_mismatch_rows,
  count(*) FILTER (
    WHERE cbr.effect_json->>'battle_model_scope' IS NULL
       OR cbr.effect_json->>'battle_model_scope' = ''
  ) AS missing_scope_rows,
  (
    SELECT count(*)
    FROM manaloom_deploy_audit.pg074_deck6_hash_provenance_restore_20260623_052703
  ) AS backup_rows
FROM pg074_targets t
JOIN card_battle_rules cbr
  ON cbr.normalized_name = t.normalized_name
 AND cbr.logical_rule_key = t.logical_rule_key
JOIN cards c ON c.id = cbr.card_id;

SELECT
  c.name,
  cbr.normalized_name,
  cbr.logical_rule_key,
  cbr.review_status,
  cbr.execution_status,
  cbr.oracle_hash,
  md5(coalesce(c.oracle_text, '')) AS current_oracle_hash,
  cbr.effect_json->>'battle_model_scope' AS battle_model_scope,
  cbr.notes
FROM pg074_targets t
JOIN card_battle_rules cbr
  ON cbr.normalized_name = t.normalized_name
 AND cbr.logical_rule_key = t.logical_rule_key
JOIN cards c ON c.id = cbr.card_id
ORDER BY c.name, cbr.logical_rule_key;
