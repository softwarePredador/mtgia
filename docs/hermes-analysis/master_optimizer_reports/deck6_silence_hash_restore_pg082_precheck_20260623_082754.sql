\pset pager off

SELECT
  c.name,
  cbr.logical_rule_key,
  md5(coalesce(c.oracle_text, '')) AS current_oracle_hash,
  cbr.oracle_hash AS current_rule_oracle_hash,
  cbr.review_status,
  cbr.execution_status,
  cbr.effect_json->>'battle_model_scope' AS battle_model_scope,
  cbr.effect_json
FROM cards c
JOIN card_battle_rules cbr
  ON cbr.card_id = c.id
WHERE c.name = 'Silence'
  AND cbr.logical_rule_key = 'battle_rule_v1:74b210b77b004a677906e0216d44e445';

SELECT
  count(*) AS target_rows,
  count(*) FILTER (WHERE cbr.oracle_hash IS NULL OR cbr.oracle_hash = '') AS missing_hash_rows,
  count(*) FILTER (WHERE md5(coalesce(c.oracle_text, '')) = 'a0ca3c09a7db091c435ab31adb9c1780') AS oracle_hash_match_rows,
  count(*) FILTER (WHERE cbr.review_status = 'verified' AND cbr.execution_status = 'auto') AS trusted_auto_rows
FROM cards c
JOIN card_battle_rules cbr
  ON cbr.card_id = c.id
WHERE c.name = 'Silence'
  AND cbr.logical_rule_key = 'battle_rule_v1:74b210b77b004a677906e0216d44e445';
