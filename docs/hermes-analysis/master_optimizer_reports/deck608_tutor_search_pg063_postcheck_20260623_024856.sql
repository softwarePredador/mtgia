-- PG063 deck608 tutor/search package postcheck.

WITH target_rules(
  normalized_name,
  logical_rule_key,
  expected_hash,
  expected_effect,
  expected_target,
  expected_destination,
  expected_scope,
  expected_runtime_scope
) AS (
  VALUES
    ('enlightened tutor', 'battle_rule_v1:ed0d4316c416061742e6eea0e4bade8a', '82899cda80d16c0c70ee5861f7e693d5', 'tutor', 'artifact_or_enchantment_to_top', 'library_top', 'artifact_enchantment_tutor_to_library_top_v1', 'instant_artifact_or_enchantment_reveal_shuffle_to_top_runtime'),
    ('idyllic tutor', 'battle_rule_v1:b516a3f8059b43f049f156445eeeaf21', 'c47e51a791e68f5ecb96f7187d68a20f', 'tutor', 'enchantment', 'hand', 'enchantment_tutor_to_hand_v1', 'sorcery_enchantment_reveal_shuffle_to_hand_runtime'),
    ('goblin engineer', 'battle_rule_v1:bbff8bfe05ccbe03f94fcbadd749be18', '64c401c2fd35257e988374fdfc22d86b', 'creature', 'artifact_to_graveyard', 'graveyard', 'goblin_engineer_etb_artifact_to_graveyard_v1', 'creature_etb_artifact_library_to_graveyard_runtime_activated_reanimation_annotation'),
    ('imperial recruiter', 'battle_rule_v1:3323c3883679f1a92af90fbb39918840', '8ed92583adcde1d5b9d01b21a2415fb0', 'creature', 'creature_power_lte_2', 'hand', 'imperial_recruiter_etb_power2_creature_to_hand_v1', 'creature_etb_power_lte_2_creature_reveal_shuffle_to_hand_runtime')
),
live AS (
  SELECT tr.*, cbr.source, cbr.review_status, cbr.execution_status, cbr.oracle_hash, cbr.effect_json, md5(coalesce(c.oracle_text, '')) AS live_hash
  FROM target_rules tr
  LEFT JOIN card_battle_rules cbr
    ON cbr.normalized_name = tr.normalized_name
   AND cbr.logical_rule_key = tr.logical_rule_key
  LEFT JOIN cards c ON c.id = cbr.card_id
)
SELECT 'target_runtime_rows' AS metric, count(*)::text AS value
FROM live
WHERE source = 'curated'
  AND review_status = 'active'
  AND execution_status = 'auto'
UNION ALL
SELECT 'target_hash_mismatch_rows', count(*)::text
FROM live
WHERE oracle_hash IS DISTINCT FROM expected_hash
   OR live_hash IS DISTINCT FROM expected_hash
UNION ALL
SELECT 'target_bad_effect_rows', count(*)::text
FROM live
WHERE effect_json->>'effect' IS DISTINCT FROM expected_effect
UNION ALL
SELECT 'target_bad_target_rows', count(*)::text
FROM live
WHERE coalesce(effect_json->>'target', effect_json->>'etb_tutor_target') IS DISTINCT FROM expected_target
UNION ALL
SELECT 'target_bad_destination_rows', count(*)::text
FROM live
WHERE coalesce(effect_json->>'tutor_destination', effect_json->>'etb_tutor_destination') IS DISTINCT FROM expected_destination
UNION ALL
SELECT 'target_bad_scope_rows', count(*)::text
FROM live
WHERE effect_json->>'battle_model_scope' IS DISTINCT FROM expected_scope
UNION ALL
SELECT 'target_bad_runtime_scope_rows', count(*)::text
FROM live
WHERE effect_json->>'oracle_runtime_scope' IS DISTINCT FROM expected_runtime_scope
UNION ALL
SELECT 'old_active_shadow_rows', count(*)::text
FROM card_battle_rules cbr
WHERE cbr.normalized_name IN (
    'enlightened tutor',
    'idyllic tutor',
    'goblin engineer',
    'imperial recruiter'
  )
  AND NOT EXISTS (
    SELECT 1
    FROM target_rules tr
    WHERE tr.normalized_name = cbr.normalized_name
      AND tr.logical_rule_key = cbr.logical_rule_key
  )
  AND cbr.review_status NOT IN ('deprecated', 'rejected')
  AND cbr.execution_status <> 'disabled'
UNION ALL
SELECT 'backup_rows', count(*)::text
FROM manaloom_deploy_audit.pg063_deck608_tutor_search_20260623_024856;
