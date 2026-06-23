-- PG066 deck6 Birgi spell-cast resource engine postcheck.

WITH target_rules AS (
  SELECT *
  FROM card_battle_rules
  WHERE normalized_name = 'birgi, god of storytelling // harnfel, horn of bounty'
),
active_target AS (
  SELECT *
  FROM target_rules
  WHERE logical_rule_key = 'battle_rule_v1:05576012d8fca56910da7ea072abe15e'
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
    WHERE oracle_hash <> '5f1ed696a63cd668fd46a2fe9971a54e'
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
    WHERE effect_json->>'trigger' <> 'spell_cast'
  ) AS target_bad_trigger_rows,
  (
    SELECT count(*)
    FROM active_target
    WHERE effect_json->>'spell_cast_mana_color' <> 'R'
      OR coalesce((effect_json->>'spell_cast_add_mana')::integer, 0) <> 1
  ) AS target_bad_mana_rows,
  (
    SELECT count(*)
    FROM active_target
    WHERE effect_json->>'battle_model_scope' <> 'spell_cast_red_mana_trigger_v1'
      OR effect_json->>'oracle_runtime_scope' <> 'front_face_creature_spell_cast_add_red_runtime_back_face_annotation'
  ) AS target_bad_scope_rows,
  (
    SELECT count(*)
    FROM target_rules
    WHERE logical_rule_key <> 'battle_rule_v1:05576012d8fca56910da7ea072abe15e'
      AND review_status NOT IN ('deprecated', 'rejected')
  ) AS old_active_shadow_rows,
  (
    SELECT count(*)
    FROM manaloom_deploy_audit.pg066_deck6_birgi_spellcast_resource_engine_20260623_032200
  ) AS backup_rows;
