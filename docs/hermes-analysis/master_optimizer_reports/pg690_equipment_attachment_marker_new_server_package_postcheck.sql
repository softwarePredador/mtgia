WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('boots of speed', 'Boots of Speed', '93dcb240a5ebd1209fdc3afa694342d6', 'battle_rule_v1:3446416c027923c276d6b8a7e62e33cc', '{"ability_kind":"equipment_static","attached_keywords":["haste"],"battle_model_scope":"xmage_equipment_static_power_toughness_attachment_v1","effect":"equipment_static_attachment","equipment":true,"grants_haste":true,"instant":false,"power_boost":1,"sorcery":false,"static_power_bonus":1,"static_toughness_bonus":0,"target":"creature_you_control","target_constraints":{"card_types":["creature"],"controller":"self","zone":"battlefield"},"toughness_boost":0,"xmage_ability_classes":["EquipAbility","HasteAbility","SimpleStaticAbility"],"xmage_effect_classes":["BoostEquippedEffect","GainAbilityAttachedEffect"]}'::jsonb, '{"category":"support","effect":"equipment_static_attachment","subtype":"equipment_static_pump","target":"creature_you_control"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BootsOfSpeed translated into ManaLoom runtime scope xmage_equipment_static_power_toughness_attachment_v1. This row is package-ready only because the source signature is a narrow fixed Equipment attachment with static equipped-creature power/toughness and keyword modifier with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ranger''s longbow', 'Ranger''s Longbow', 'd90876a22ae99080f188b15cf5d91daf', 'battle_rule_v1:039950727e934a1464a14a3e8aaaac8e', '{"ability_kind":"equipment_static","attached_keywords":["reach"],"battle_model_scope":"xmage_equipment_static_power_toughness_attachment_v1","effect":"equipment_static_attachment","equipment":true,"grants_reach":true,"instant":false,"power_boost":2,"sorcery":false,"static_power_bonus":2,"static_toughness_bonus":1,"target":"creature_you_control","target_constraints":{"card_types":["creature"],"controller":"self","zone":"battlefield"},"toughness_boost":1,"xmage_ability_classes":["EquipAbility","ReachAbility","SimpleStaticAbility"],"xmage_effect_classes":["BoostEquippedEffect","GainAbilityAttachedEffect"]}'::jsonb, '{"category":"support","effect":"equipment_static_attachment","subtype":"equipment_static_pump","target":"creature_you_control"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RangersLongbow translated into ManaLoom runtime scope xmage_equipment_static_power_toughness_attachment_v1. This row is package-ready only because the source signature is a narrow fixed Equipment attachment with static equipped-creature power/toughness and keyword modifier with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg690_pg690_equipment_attachment_marker_20260709_041819) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
