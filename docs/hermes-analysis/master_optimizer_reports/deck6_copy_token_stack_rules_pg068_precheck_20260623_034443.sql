-- PG068 deck6 copy/token-copy stack rules precheck.
-- Targets: Dualcaster Mage, Reiterate, Heat Shimmer, Twinflame, Molten Duplication.

\pset pager off
\set ON_ERROR_STOP on

WITH target_rules(card_name, normalized_name, expected_oracle_hash, new_logical_rule_key, expected_effect, expected_scope) AS (
  VALUES
    ('Dualcaster Mage', 'dualcaster mage', 'e26f613394b72e9724d299512983218a', 'battle_rule_v1:e176019b87d68d22e2388e08a4efbf55', 'copy_spell', 'creature_etb_copy_stack_instant_or_sorcery_v1'),
    ('Reiterate', 'reiterate', '996fb5f02f16605ff7f1c899f2c50f60', 'battle_rule_v1:18eeabc2a2fa631d99caf65a43a8c405', 'copy_spell', 'copy_stack_instant_or_sorcery_buyback_annotation_v1'),
    ('Heat Shimmer', 'heat shimmer', '9c4cfbeb99bfea90a8a5d4c3c7894793', 'battle_rule_v1:644897bfa688d33b1a718723360e2480', 'copy_creature_token', 'target_creature_copy_haste_exile_eot_v1'),
    ('Twinflame', 'twinflame', 'd9c51f63ac78f713113c52feadfba6db', 'battle_rule_v1:97ab0167213936bfa544f19731284e56', 'copy_creature_token', 'own_creature_single_copy_haste_exile_eot_v1'),
    ('Molten Duplication', 'molten duplication', '7c24d56660499c0af4db967925de1573', 'battle_rule_v1:e154b34c0deaa861094d5870f4c0ad69', 'copy_creature_token', 'own_artifact_or_creature_copy_artifact_haste_sacrifice_eot_v1')
),
target_cards AS (
  SELECT tr.*, c.id AS card_id, md5(coalesce(c.oracle_text, '')) AS live_oracle_hash
  FROM target_rules tr
  LEFT JOIN cards c ON lower(c.name) = tr.normalized_name
),
target_cbr AS (
  SELECT cbr.*, tc.expected_oracle_hash, tc.new_logical_rule_key, tc.expected_effect, tc.expected_scope
  FROM card_battle_rules cbr
  JOIN target_cards tc ON tc.normalized_name = cbr.normalized_name
)
SELECT
  (SELECT count(*) FROM target_rules) AS expected_rows,
  (SELECT count(*) FROM target_cards WHERE card_id IS NOT NULL) AS target_card_rows,
  (SELECT count(*) FROM target_cards WHERE live_oracle_hash = expected_oracle_hash) AS oracle_hash_match_rows,
  (
    SELECT count(*)
    FROM deck_cards dc
    JOIN cards c ON c.id = dc.card_id
    WHERE dc.deck_id = '528c877f-f829-4207-95e6-73981776c323'::uuid
      AND lower(c.name) IN (SELECT normalized_name FROM target_rules)
  ) AS deck6_rows,
  (SELECT count(*) FROM target_cbr) AS current_rule_rows,
  (
    SELECT count(*)
    FROM target_cbr
    WHERE source = 'curated'
      AND review_status IN ('verified', 'active')
      AND execution_status IN ('auto', 'executable')
      AND coalesce(oracle_hash, '') = ''
  ) AS trusted_executable_without_oracle_hash_rows,
  (
    SELECT count(*)
    FROM target_cbr
    WHERE review_status IN ('needs_review', 'review_only')
       OR execution_status = 'review_only'
  ) AS active_review_only_rows,
  (
    SELECT count(*)
    FROM target_cbr
    WHERE logical_rule_key = new_logical_rule_key
  ) AS new_rule_key_rows_already_present,
  CASE
    WHEN to_regclass('manaloom_deploy_audit.pg068_deck6_copy_token_stack_rules_20260623_034443') IS NULL THEN 0
    ELSE 1
  END AS backup_table_exists;

WITH target_rules(card_name, normalized_name, expected_oracle_hash, new_logical_rule_key, expected_effect, expected_scope) AS (
  VALUES
    ('Dualcaster Mage', 'dualcaster mage', 'e26f613394b72e9724d299512983218a', 'battle_rule_v1:e176019b87d68d22e2388e08a4efbf55', 'copy_spell', 'creature_etb_copy_stack_instant_or_sorcery_v1'),
    ('Reiterate', 'reiterate', '996fb5f02f16605ff7f1c899f2c50f60', 'battle_rule_v1:18eeabc2a2fa631d99caf65a43a8c405', 'copy_spell', 'copy_stack_instant_or_sorcery_buyback_annotation_v1'),
    ('Heat Shimmer', 'heat shimmer', '9c4cfbeb99bfea90a8a5d4c3c7894793', 'battle_rule_v1:644897bfa688d33b1a718723360e2480', 'copy_creature_token', 'target_creature_copy_haste_exile_eot_v1'),
    ('Twinflame', 'twinflame', 'd9c51f63ac78f713113c52feadfba6db', 'battle_rule_v1:97ab0167213936bfa544f19731284e56', 'copy_creature_token', 'own_creature_single_copy_haste_exile_eot_v1'),
    ('Molten Duplication', 'molten duplication', '7c24d56660499c0af4db967925de1573', 'battle_rule_v1:e154b34c0deaa861094d5870f4c0ad69', 'copy_creature_token', 'own_artifact_or_creature_copy_artifact_haste_sacrifice_eot_v1')
),
target_cards AS (
  SELECT tr.*, c.id AS card_id, md5(coalesce(c.oracle_text, '')) AS live_oracle_hash
  FROM target_rules tr
  LEFT JOIN cards c ON lower(c.name) = tr.normalized_name
)
SELECT
  tc.card_name,
  tc.card_id,
  tc.live_oracle_hash,
  tc.expected_oracle_hash,
  tc.new_logical_rule_key,
  cbr.logical_rule_key AS current_logical_rule_key,
  cbr.source,
  cbr.review_status,
  cbr.execution_status,
  cbr.effect_json->>'effect' AS current_effect,
  cbr.effect_json->>'battle_model_scope' AS current_scope,
  cbr.oracle_hash AS current_oracle_hash
FROM target_cards tc
LEFT JOIN card_battle_rules cbr ON cbr.normalized_name = tc.normalized_name
ORDER BY tc.card_name, cbr.created_at NULLS LAST, cbr.logical_rule_key;
