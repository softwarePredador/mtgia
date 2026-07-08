WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('bloodthorn flail', 'Bloodthorn Flail', 'bb46b9b658a80f3d5eec51abf0dfb33a', 'battle_rule_v1:e1578e231f7cb23a2c4211fa2e08e51c', '{"ability_kind":"equipment_static","attached_keywords":[],"battle_model_scope":"xmage_equipment_static_power_toughness_attachment_v1","effect":"equipment_static_attachment","equipment":true,"instant":false,"power_boost":2,"sorcery":false,"static_power_bonus":2,"static_toughness_bonus":1,"target":"creature_you_control","target_constraints":{"card_types":["creature"],"controller":"self","zone":"battlefield"},"toughness_boost":1,"xmage_ability_classes":["EquipAbility","SimpleStaticAbility"],"xmage_effect_classes":["BoostEquippedEffect"]}'::jsonb, '{"category":"support","effect":"equipment_static_attachment","subtype":"equipment_static_pump","target":"creature_you_control"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BloodthornFlail translated into ManaLoom runtime scope xmage_equipment_static_power_toughness_attachment_v1. This row is package-ready only because the source signature is a narrow fixed Equipment attachment with static equipped-creature power/toughness and keyword modifier with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('demonmail hauberk', 'Demonmail Hauberk', '1f08deeab2c0475c0f80d8e4cc826355', 'battle_rule_v1:a501e1c0f5726aaf4689af5eacd7774a', '{"ability_kind":"equipment_static","attached_keywords":[],"battle_model_scope":"xmage_equipment_static_power_toughness_attachment_v1","effect":"equipment_static_attachment","equipment":true,"instant":false,"power_boost":4,"sorcery":false,"static_power_bonus":4,"static_toughness_bonus":2,"target":"creature_you_control","target_constraints":{"card_types":["creature"],"controller":"self","zone":"battlefield"},"toughness_boost":2,"xmage_ability_classes":["AddAbility","EquipAbility","SimpleStaticAbility"],"xmage_effect_classes":["BoostEquippedEffect"]}'::jsonb, '{"category":"support","effect":"equipment_static_attachment","subtype":"equipment_static_pump","target":"creature_you_control"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DemonmailHauberk translated into ManaLoom runtime scope xmage_equipment_static_power_toughness_attachment_v1. This row is package-ready only because the source signature is a narrow fixed Equipment attachment with static equipped-creature power/toughness and keyword modifier with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('murderer''s axe', 'Murderer''s Axe', '894f1d5c9adf8542002730887be9850d', 'battle_rule_v1:d207c85ffb0121236b7c49f49361f2aa', '{"ability_kind":"equipment_static","attached_keywords":[],"battle_model_scope":"xmage_equipment_static_power_toughness_attachment_v1","effect":"equipment_static_attachment","equipment":true,"instant":false,"power_boost":2,"sorcery":false,"static_power_bonus":2,"static_toughness_bonus":2,"target":"creature_you_control","target_constraints":{"card_types":["creature"],"controller":"self","zone":"battlefield"},"toughness_boost":2,"xmage_ability_classes":["AddAbility","EquipAbility","SimpleStaticAbility"],"xmage_effect_classes":["BoostEquippedEffect"]}'::jsonb, '{"category":"support","effect":"equipment_static_attachment","subtype":"equipment_static_pump","target":"creature_you_control"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MurderersAxe translated into ManaLoom runtime scope xmage_equipment_static_power_toughness_attachment_v1. This row is package-ready only because the source signature is a narrow fixed Equipment attachment with static equipped-creature power/toughness and keyword modifier with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg659_special_equip_cost_new_server_20260708_140658) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
