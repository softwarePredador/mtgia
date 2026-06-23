-- PG064 deck6 Recruiter of the Guard postcheck.

WITH target_rules AS (
  SELECT *
  FROM card_battle_rules
  WHERE normalized_name = 'recruiter of the guard'
),
active_target AS (
  SELECT *
  FROM target_rules
  WHERE logical_rule_key = 'battle_rule_v1:423a8aa67b5cf450f4c4fb47ca50ae46'
    AND source = 'curated'
    AND review_status = 'active'
    AND execution_status = 'auto'
)
SELECT
  (SELECT count(*) FROM target_rules) AS target_rule_rows,
  (SELECT count(*) FROM active_target) AS target_runtime_rows,
  (
    SELECT count(*)
    FROM active_target
    WHERE oracle_hash <> 'aaa06784ff51d908d553ccc81d6854cd'
  ) AS target_hash_mismatch_rows,
  (
    SELECT count(*)
    FROM active_target
    WHERE effect_json->>'effect' <> 'creature'
      OR coalesce((effect_json->>'is_creature_permanent')::boolean, false) IS DISTINCT FROM true
  ) AS target_bad_effect_rows,
  (
    SELECT count(*)
    FROM active_target
    WHERE effect_json->>'etb_tutor_target' <> 'creature_toughness_lte_2'
  ) AS target_bad_target_rows,
  (
    SELECT count(*)
    FROM active_target
    WHERE effect_json->>'etb_tutor_destination' <> 'hand'
  ) AS target_bad_destination_rows,
  (
    SELECT count(*)
    FROM active_target
    WHERE effect_json->>'battle_model_scope' <> 'recruiter_guard_etb_toughness2_creature_to_hand_v1'
      OR effect_json->>'oracle_runtime_scope' <> 'creature_etb_toughness_lte_2_creature_reveal_shuffle_to_hand_runtime'
  ) AS target_bad_scope_rows,
  (
    SELECT count(*)
    FROM target_rules
    WHERE logical_rule_key <> 'battle_rule_v1:423a8aa67b5cf450f4c4fb47ca50ae46'
      AND review_status NOT IN ('deprecated', 'rejected')
  ) AS old_active_shadow_rows,
  (
    SELECT count(*)
    FROM manaloom_deploy_audit.pg064_deck6_recruiter_guard_20260623_025848
  ) AS backup_rows;
