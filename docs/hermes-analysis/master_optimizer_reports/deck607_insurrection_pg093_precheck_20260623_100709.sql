WITH target_rules(normalized_name, card_name, expected_oracle_hash, expected_logical_rule_key, expected_effect, expected_scope) AS (
  VALUES
    (
      'insurrection',
      'Insurrection',
      'a756d0c90be63a18b7eaf97582e75b8e',
      'battle_rule_v1:e6b0d9f25aff060aa1f813e43154c954',
      'steal_all_creatures',
      'steal_all_creatures_until_eot_haste_attack_projection_v1'
    )
),
cards_resolved AS (
  SELECT tr.*, c.id AS card_id, c.name AS pg_card_name, c.type_line, c.oracle_text,
         md5(c.oracle_text) AS raw_oracle_hash
  FROM target_rules tr
  LEFT JOIN cards c ON lower(c.name) = tr.normalized_name
),
current_rows AS (
  SELECT cbr.*
  FROM card_battle_rules cbr
  JOIN target_rules tr USING (normalized_name)
),
target_key_rows AS (
  SELECT cbr.*
  FROM card_battle_rules cbr
  JOIN target_rules tr
    ON cbr.normalized_name = tr.normalized_name
   AND cbr.logical_rule_key = tr.expected_logical_rule_key
),
non_target_rows AS (
  SELECT cbr.*
  FROM card_battle_rules cbr
  JOIN target_rules tr USING (normalized_name)
  WHERE cbr.logical_rule_key <> tr.expected_logical_rule_key
)
SELECT
  (SELECT count(*) FROM target_rules) AS expected_target_rules,
  (SELECT count(*) FROM cards_resolved WHERE card_id IS NOT NULL) AS cards_resolved_rows,
  (SELECT count(*) FROM cards_resolved WHERE raw_oracle_hash = expected_oracle_hash) AS raw_oracle_hash_match_rows,
  (SELECT count(*) FROM current_rows) AS current_rule_rows,
  (SELECT count(*) FROM target_key_rows) AS current_expected_key_rows,
  (SELECT count(*) FROM current_rows WHERE review_status IN ('verified', 'active') AND execution_status IN ('auto', 'executable')) AS current_trusted_executable_rows,
  (SELECT count(*) FROM non_target_rows) AS rows_to_disable,
  to_regclass('manaloom_deploy_audit.pg093_deck607_insurrection_20260623_100709') IS NOT NULL AS backup_table_already_exists;

WITH target_rules(normalized_name, card_name) AS (
  VALUES
    ('insurrection', 'Insurrection')
)
SELECT c.name, c.type_line, c.mana_cost, c.cmc, c.oracle_text, md5(c.oracle_text) AS raw_oracle_hash
FROM target_rules tr
JOIN cards c ON lower(c.name) = tr.normalized_name
ORDER BY c.name;

SELECT normalized_name, card_name, logical_rule_key, oracle_hash, effect_json,
       deck_role_json, review_status, execution_status, source, confidence,
       rule_version
FROM card_battle_rules
WHERE normalized_name = 'insurrection'
ORDER BY normalized_name, execution_status, review_status, logical_rule_key;
