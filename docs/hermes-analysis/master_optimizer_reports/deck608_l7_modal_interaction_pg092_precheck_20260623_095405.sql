WITH target_rules(normalized_name, card_name, expected_oracle_hash, expected_logical_rule_key, expected_effect, expected_scope) AS (
  VALUES
    (
      'return the favor',
      'Return the Favor',
      'a24911b7ea2027ebba59bb6792eee776',
      'battle_rule_v1:fb3ee27205e34477fa9753b38433e9a2',
      'copy_spell',
      'spree_copy_instant_or_sorcery_stack_spell_change_target_annotation_v1'
    ),
    (
      'untimely malfunction',
      'Untimely Malfunction',
      '877f2d75c90c7886ca9536135829bb90',
      'battle_rule_v1:667ba8e5e69696402f9cd213886e57a8',
      'remove_permanent',
      'modal_destroy_artifact_redirect_or_cant_block_annotation_v1'
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
non_target_rows AS (
  SELECT cbr.*
  FROM card_battle_rules cbr
  JOIN target_rules tr USING (normalized_name)
  WHERE cbr.logical_rule_key <> tr.expected_logical_rule_key
),
key_conflicts AS (
  SELECT cbr.*
  FROM card_battle_rules cbr
  JOIN target_rules tr
    ON cbr.normalized_name = tr.normalized_name
   AND cbr.logical_rule_key = tr.expected_logical_rule_key
)
SELECT
  (SELECT count(*) FROM target_rules) AS expected_target_rules,
  (SELECT count(*) FROM cards_resolved WHERE card_id IS NOT NULL) AS cards_resolved_rows,
  (SELECT count(*) FROM cards_resolved WHERE raw_oracle_hash = expected_oracle_hash) AS raw_oracle_hash_match_rows,
  (SELECT count(*) FROM current_rows) AS current_rule_rows,
  (SELECT count(*) FROM current_rows WHERE review_status IN ('verified', 'active') AND execution_status IN ('auto', 'executable')) AS current_trusted_executable_rows,
  (SELECT count(*) FROM non_target_rows) AS rows_to_disable,
  (SELECT count(*) FROM key_conflicts) AS new_key_conflict_rows,
  to_regclass('manaloom_deploy_audit.pg092_deck608_l7_modal_interaction_20260623_095405') IS NOT NULL AS backup_table_already_exists;

WITH target_rules(normalized_name, card_name) AS (
  VALUES
    ('return the favor', 'Return the Favor'),
    ('untimely malfunction', 'Untimely Malfunction')
)
SELECT c.name, c.type_line, c.oracle_text
FROM target_rules tr
JOIN cards c ON lower(c.name) = tr.normalized_name
ORDER BY c.name;

SELECT normalized_name, card_name, logical_rule_key, oracle_hash, effect_json,
       deck_role_json, review_status, execution_status, source, confidence,
       rule_version
FROM card_battle_rules
WHERE normalized_name IN ('return the favor', 'untimely malfunction')
ORDER BY normalized_name, execution_status, review_status, logical_rule_key;
