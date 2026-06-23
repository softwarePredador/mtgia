\pset pager off

CREATE TEMP TABLE pg088_expected_hashes AS
SELECT *
FROM (VALUES
  ('hexing squelcher', 'battle_rule_v1:c6587e309bfd402ee1b98b4848abc6d3', 'ed00818e6ca804b7d1a3ef47c29277ea'),
  ('ragavan, nimble pilferer', 'battle_rule_v1:3e0569d6bae4ed8b6e6e4289ea75084e', 'e337b9515b6984af8a1572db48f47eec'),
  ('skyclave apparition', 'battle_rule_v1:4f29c7a4bbe21a160f28452406153846', '4d0c162906712b2c428b754ad2f0b3a0'),
  ('underworld breach', 'battle_rule_v1:3f9f5259b05245670ee19b357aa2e999', 'a98ca5777789e48c44daff97999f2beb')
) AS t(normalized_name, logical_rule_key, raw_oracle_hash);

CREATE TEMP TABLE pg088_target AS
SELECT
  c.name,
  md5(coalesce(c.oracle_text, '')) AS computed_raw_oracle_hash,
  e.raw_oracle_hash,
  cbr.logical_rule_key,
  cbr.oracle_hash,
  cbr.review_status,
  cbr.execution_status,
  cbr.rule_version,
  cbr.effect_json,
  cbr.deck_role_json
FROM pg088_expected_hashes e
JOIN cards c ON lower(c.name) = e.normalized_name
JOIN card_battle_rules cbr
  ON cbr.card_id = c.id
 AND cbr.logical_rule_key = e.logical_rule_key;

SELECT
  count(*) AS target_rows,
  count(*) FILTER (WHERE computed_raw_oracle_hash = raw_oracle_hash) AS raw_hash_input_match_rows,
  count(*) FILTER (WHERE oracle_hash = raw_oracle_hash) AS target_hash_match_rows,
  count(*) FILTER (WHERE oracle_hash IS NULL OR oracle_hash = '') AS target_missing_hash_rows,
  count(*) FILTER (WHERE effect_json->>'battle_model_scope' IS NOT NULL) AS expected_scope_rows,
  count(*) FILTER (WHERE review_status = 'verified' AND execution_status = 'auto') AS trusted_auto_rows,
  count(*) FILTER (WHERE rule_version >= 2) AS rule_version_at_least_2_rows,
  (SELECT count(*) FROM manaloom_deploy_audit.pg088_deck606_pg087_hash_convention_fix_20260623_090018) AS backup_rows
FROM pg088_target;

SELECT
  name,
  logical_rule_key,
  oracle_hash,
  effect_json->>'effect' AS effect,
  effect_json->>'battle_model_scope' AS battle_model_scope,
  effect_json->>'oracle_runtime_scope' AS oracle_runtime_scope,
  review_status,
  execution_status,
  rule_version
FROM pg088_target
ORDER BY name;
