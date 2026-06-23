-- PG068 deck6 copy/token-copy stack rules postcheck.

\pset pager off
\set ON_ERROR_STOP on

WITH expected(card_name, normalized_name, expected_oracle_hash, logical_rule_key, expected_effect, expected_scope) AS (
  VALUES
    ('Dualcaster Mage', 'dualcaster mage', 'e26f613394b72e9724d299512983218a', 'battle_rule_v1:e176019b87d68d22e2388e08a4efbf55', 'copy_spell', 'creature_etb_copy_stack_instant_or_sorcery_v1'),
    ('Reiterate', 'reiterate', '996fb5f02f16605ff7f1c899f2c50f60', 'battle_rule_v1:18eeabc2a2fa631d99caf65a43a8c405', 'copy_spell', 'copy_stack_instant_or_sorcery_buyback_annotation_v1'),
    ('Heat Shimmer', 'heat shimmer', '9c4cfbeb99bfea90a8a5d4c3c7894793', 'battle_rule_v1:644897bfa688d33b1a718723360e2480', 'copy_creature_token', 'target_creature_copy_haste_exile_eot_v1'),
    ('Twinflame', 'twinflame', 'd9c51f63ac78f713113c52feadfba6db', 'battle_rule_v1:97ab0167213936bfa544f19731284e56', 'copy_creature_token', 'own_creature_single_copy_haste_exile_eot_v1'),
    ('Molten Duplication', 'molten duplication', '7c24d56660499c0af4db967925de1573', 'battle_rule_v1:e154b34c0deaa861094d5870f4c0ad69', 'copy_creature_token', 'own_artifact_or_creature_copy_artifact_haste_sacrifice_eot_v1')
),
target_rows AS (
  SELECT e.*, cbr.*
  FROM expected e
  LEFT JOIN card_battle_rules cbr
    ON cbr.normalized_name = e.normalized_name
   AND cbr.logical_rule_key = e.logical_rule_key
)
SELECT
  (SELECT count(*) FROM expected) AS expected_rows,
  (
    SELECT count(*)
    FROM target_rows
    WHERE source = 'curated'
      AND review_status = 'active'
      AND execution_status = 'auto'
      AND oracle_hash = expected_oracle_hash
      AND effect_json->>'effect' = expected_effect
      AND effect_json->>'battle_model_scope' = expected_scope
  ) AS exact_runtime_rows,
  (
    SELECT count(*)
    FROM target_rows
    WHERE oracle_hash IS DISTINCT FROM expected_oracle_hash
  ) AS hash_mismatch_rows,
  (
    SELECT count(*)
    FROM target_rows
    WHERE effect_json->>'effect' IS DISTINCT FROM expected_effect
  ) AS effect_mismatch_rows,
  (
    SELECT count(*)
    FROM target_rows
    WHERE effect_json->>'battle_model_scope' IS DISTINCT FROM expected_scope
  ) AS scope_mismatch_rows,
  (
    SELECT count(*)
    FROM card_battle_rules cbr
    JOIN expected e ON e.normalized_name = cbr.normalized_name
    WHERE cbr.logical_rule_key <> e.logical_rule_key
      AND cbr.review_status NOT IN ('deprecated', 'rejected')
      AND cbr.execution_status IN ('auto', 'executable', 'review_only')
  ) AS old_active_shadow_rows,
  (
    SELECT count(*)
    FROM card_battle_rules cbr
    JOIN expected e ON e.normalized_name = cbr.normalized_name
    WHERE cbr.source = 'curated'
      AND cbr.review_status IN ('verified', 'active')
      AND cbr.execution_status IN ('auto', 'executable')
      AND coalesce(cbr.oracle_hash, '') = ''
  ) AS trusted_executable_without_oracle_hash_rows,
  (
    SELECT count(*)
    FROM manaloom_deploy_audit.pg068_deck6_copy_token_stack_rules_20260623_034443
  ) AS backup_rows;

SELECT
  cbr.card_name,
  cbr.logical_rule_key,
  cbr.source,
  cbr.review_status,
  cbr.execution_status,
  cbr.oracle_hash,
  cbr.effect_json,
  cbr.deck_role_json
FROM card_battle_rules cbr
WHERE cbr.normalized_name IN (
  'dualcaster mage',
  'reiterate',
  'heat shimmer',
  'twinflame',
  'molten duplication'
)
ORDER BY cbr.normalized_name, cbr.review_status, cbr.execution_status, cbr.logical_rule_key;
