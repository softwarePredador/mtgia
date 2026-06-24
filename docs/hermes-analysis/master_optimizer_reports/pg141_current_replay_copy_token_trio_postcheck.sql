WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('flash photography', 'Flash Photography', 'c3fb29c6ec7bd40a4d59959e9abe9ee8', 'battle_rule_v1:e5ea20bd49a563c1256183af42e86c71', '{"ability_kind":"one_shot","battle_model_scope":"copy_target_permanent_v1","copy_target_types":["permanent"],"effect":"copy_creature_token","target_controller":"any","token_haste":false}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class FlashPhotography mapped to family copy_creature_token; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('astral dragon', 'Astral Dragon', '5efa9ecc8bca6d341f1dc4dea3e51c49', 'battle_rule_v1:7f8364137188a184510b1cfc4ebeac33', '{"ability_kind":"triggered","battle_model_scope":"etb_copy_target_noncreature_permanent_twice_as_3_3_flying_dragon_v1","effect":"creature","etb_copy_force_creature":true,"etb_copy_target_types":["noncreature_permanent"],"etb_copy_token_count":2,"etb_copy_token_flying":true,"etb_copy_token_power":3,"etb_copy_token_subtype":"Dragon","etb_copy_token_toughness":3,"flying":true,"power":4,"toughness":4}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class AstralDragon mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('clone legion', 'Clone Legion', 'd5300831d3df4276f01145ddeca85521', 'battle_rule_v1:391956936dfadf0b7bd0f0123226279f', '{"ability_kind":"one_shot","battle_model_scope":"copy_each_creature_target_player_controls_v1","copy_all_matching_targets":true,"copy_target_types":["creature"],"effect":"copy_creature_token","target_controller":"opponent"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class CloneLegion mapped to family copy_creature_token; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
),
rule_rows AS (
  SELECT
    r.normalized_name,
    r.logical_rule_key,
    r.oracle_hash,
    r.review_status,
    r.execution_status
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key = p.logical_rule_key
)
SELECT
  p.card_name,
  p.normalized_name,
  p.logical_rule_key,
  count(r.*) FILTER (WHERE r.logical_rule_key = p.logical_rule_key) AS promoted_rule_rows,
  count(r.*) FILTER (WHERE r.review_status = 'verified' AND r.execution_status = 'auto') AS promoted_verified_auto_rows,
  count(r.*) FILTER (WHERE r.oracle_hash = p.oracle_hash) AS promoted_oracle_hash_rows,
  (SELECT count(*) FROM manaloom_deploy_audit.pg141_current_replay_copy_token_trio_20260624_035857) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
