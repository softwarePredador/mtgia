WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('alpha status', 'Alpha Status', 'dc2fe49152d99850434f64f24d3b6436', 'battle_rule_v1:4637a9f25fc3d815d44d059da775da61', '{"ability_kind":"aura_static","attachment_dynamic_boost":true,"aura":true,"battle_model_scope":"xmage_aura_static_power_toughness_attachment_v1","battlefield_count_scope":"all_battlefields","effect":"aura_static_attachment","enchant_target":"creature","enchant_target_controller":"any","instant":false,"power_base_delta":0,"power_boost":0,"power_delta_per_graveyard_count":2,"sorcery":false,"stat_modifier_amount_source":"attached_creature_shared_type_count","static_effect":"attached_creature_power_toughness_boost_equal_count","static_power_bonus":0,"static_toughness_bonus":0,"target":"creature","target_constraints":{"card_types":["creature"],"zone":"battlefield"},"toughness_base_delta":0,"toughness_boost":0,"toughness_delta_per_graveyard_count":2,"xmage_ability_classes":["EnchantAbility","SimpleStaticAbility"],"xmage_effect_classes":["AttachEffect","BoostEnchantedEffect"]}'::jsonb, '{"category":"support","effect":"aura_static_attachment","subtype":"aura_static_pump","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AlphaStatus translated into ManaLoom runtime scope xmage_aura_static_power_toughness_attachment_v1. This row is package-ready only because the source signature is a narrow Aura attachment with static enchanted-creature power/toughness modifier with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('death''s approach', 'Death''s Approach', 'c33040d9c32eb56deeb4d9295862aa7a', 'battle_rule_v1:5893f8937a4b929d2a45bc185d7914f9', '{"ability_kind":"aura_static","attachment_dynamic_boost":true,"aura":true,"battle_model_scope":"xmage_aura_static_power_toughness_attachment_v1","effect":"aura_static_attachment","enchant_target":"creature","enchant_target_controller":"any","graveyard_count_card_types":["creature"],"graveyard_count_scope":"attached_creature_controller_graveyard","instant":false,"power_base_delta":0,"power_boost":0,"power_delta_per_graveyard_count":-1,"sorcery":false,"stat_modifier_amount_source":"graveyard_card_count","static_effect":"attached_creature_power_toughness_boost_equal_count","static_power_bonus":0,"static_toughness_bonus":0,"target":"creature","target_constraints":{"card_types":["creature"],"zone":"battlefield"},"toughness_base_delta":0,"toughness_boost":0,"toughness_delta_per_graveyard_count":-1,"xmage_ability_classes":["EnchantAbility","SimpleStaticAbility"],"xmage_effect_classes":["AttachEffect","BoostEnchantedEffect"]}'::jsonb, '{"category":"support","effect":"aura_static_attachment","subtype":"aura_static_pump","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DeathsApproach translated into ManaLoom runtime scope xmage_aura_static_power_toughness_attachment_v1. This row is package-ready only because the source signature is a narrow Aura attachment with static enchanted-creature power/toughness modifier with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('exoskeletal armor', 'Exoskeletal Armor', '162e12aada2989c9078456aed98e2095', 'battle_rule_v1:fcc874adc294a491e7ac9a650df1f03e', '{"ability_kind":"aura_static","attachment_dynamic_boost":true,"aura":true,"battle_model_scope":"xmage_aura_static_power_toughness_attachment_v1","effect":"aura_static_attachment","enchant_target":"creature","enchant_target_controller":"any","graveyard_count_card_types":["creature"],"graveyard_count_scope":"all_graveyards","instant":false,"power_base_delta":0,"power_boost":0,"power_delta_per_graveyard_count":1,"sorcery":false,"stat_modifier_amount_source":"graveyard_card_count","static_effect":"attached_creature_power_toughness_boost_equal_count","static_power_bonus":0,"static_toughness_bonus":0,"target":"creature","target_constraints":{"card_types":["creature"],"zone":"battlefield"},"toughness_base_delta":0,"toughness_boost":0,"toughness_delta_per_graveyard_count":1,"xmage_ability_classes":["EnchantAbility","SimpleStaticAbility"],"xmage_effect_classes":["AttachEffect","BoostEnchantedEffect"]}'::jsonb, '{"category":"support","effect":"aura_static_attachment","subtype":"aura_static_pump","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ExoskeletalArmor translated into ManaLoom runtime scope xmage_aura_static_power_toughness_attachment_v1. This row is package-ready only because the source signature is a narrow Aura attachment with static enchanted-creature power/toughness modifier with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('stoneforge masterwork', 'Stoneforge Masterwork', 'dfe3dafdedf9063733f412f35e1c3eab', 'battle_rule_v1:949bd09f92871413f5d3497f1f71389a', '{"ability_kind":"equipment_static","attached_keywords":[],"attachment_dynamic_boost":true,"battle_model_scope":"xmage_equipment_static_power_toughness_attachment_v1","battlefield_count_scope":"controller_battlefield","effect":"equipment_static_attachment","equipment":true,"instant":false,"power_base_delta":0,"power_boost":0,"power_delta_per_graveyard_count":1,"sorcery":false,"stat_modifier_amount_source":"attached_creature_shared_type_count","static_effect":"attached_creature_power_toughness_boost_equal_count","static_power_bonus":0,"static_toughness_bonus":0,"target":"creature_you_control","target_constraints":{"card_types":["creature"],"controller":"self","zone":"battlefield"},"toughness_base_delta":0,"toughness_boost":0,"toughness_delta_per_graveyard_count":1,"xmage_ability_classes":["EquipAbility","SimpleStaticAbility"],"xmage_effect_classes":["BoostEquippedEffect"]}'::jsonb, '{"category":"support","effect":"equipment_static_attachment","subtype":"equipment_static_pump","target":"creature_you_control"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StoneforgeMasterwork translated into ManaLoom runtime scope xmage_equipment_static_power_toughness_attachment_v1. This row is package-ready only because the source signature is a narrow Equipment attachment with static equipped-creature power/toughness and keyword modifier with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wreath of geists', 'Wreath of Geists', '6789d58ba0ee8ed5de943dd5ca5a1be1', 'battle_rule_v1:5f327f69a479abce2987fea68bdbb46f', '{"ability_kind":"aura_static","attachment_dynamic_boost":true,"aura":true,"battle_model_scope":"xmage_aura_static_power_toughness_attachment_v1","effect":"aura_static_attachment","enchant_target":"creature","enchant_target_controller":"any","graveyard_count_card_types":["creature"],"graveyard_count_scope":"controller_graveyard","instant":false,"power_base_delta":0,"power_boost":0,"power_delta_per_graveyard_count":1,"sorcery":false,"stat_modifier_amount_source":"graveyard_card_count","static_effect":"attached_creature_power_toughness_boost_equal_count","static_power_bonus":0,"static_toughness_bonus":0,"target":"creature","target_constraints":{"card_types":["creature"],"zone":"battlefield"},"toughness_base_delta":0,"toughness_boost":0,"toughness_delta_per_graveyard_count":1,"xmage_ability_classes":["EnchantAbility","SimpleStaticAbility"],"xmage_effect_classes":["AttachEffect","BoostEnchantedEffect"]}'::jsonb, '{"category":"support","effect":"aura_static_attachment","subtype":"aura_static_pump","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WreathOfGeists translated into ManaLoom runtime scope xmage_aura_static_power_toughness_attachment_v1. This row is package-ready only because the source signature is a narrow Aura attachment with static enchanted-creature power/toughness modifier with focused runtime coverage.', 'deprecate_nonmatching_rows')
),
matched_cards AS (
  SELECT
    p.normalized_name,
    p.card_name,
    p.oracle_hash,
    c.id AS card_id,
    c.name AS db_card_name
  FROM proposed p
  LEFT JOIN public.cards c
    ON (
         lower(c.name) = p.normalized_name
         OR split_part(lower(c.name), ' // ', 1) = p.normalized_name
       )
   AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
),
target_cards AS (
  SELECT
    normalized_name,
    card_name,
    oracle_hash,
    count(card_id) AS target_card_rows,
    min(card_id::text)::uuid AS canonical_card_id,
    min(db_card_name) AS canonical_card_name
  FROM matched_cards
  GROUP BY normalized_name, card_name, oracle_hash
),
rule_rows AS (
  SELECT p.normalized_name, count(r.*) AS existing_rule_rows
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
  GROUP BY p.normalized_name
),
expected_rows AS (
  SELECT p.normalized_name, count(r.*) AS expected_rule_rows_before
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key = p.logical_rule_key
  GROUP BY p.normalized_name
),
shadow_rows AS (
  SELECT p.normalized_name, count(r.*) AS would_deprecate_shadow_rows
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key <> p.logical_rule_key
   AND r.review_status NOT IN ('deprecated', 'rejected')
   AND r.execution_status <> 'disabled'
  GROUP BY p.normalized_name
)
SELECT
  p.card_name,
  p.normalized_name,
  p.oracle_hash,
  p.logical_rule_key,
  p.shadow_handling,
  tc.target_card_rows,
  tc.canonical_card_id,
  rr.existing_rule_rows,
  er.expected_rule_rows_before,
  sr.would_deprecate_shadow_rows
FROM proposed p
JOIN target_cards tc USING (normalized_name, card_name, oracle_hash)
JOIN rule_rows rr USING (normalized_name)
JOIN expected_rows er USING (normalized_name)
JOIN shadow_rows sr USING (normalized_name)
ORDER BY p.card_name;
