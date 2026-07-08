WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('bloodthorn flail', 'Bloodthorn Flail', 'bb46b9b658a80f3d5eec51abf0dfb33a', 'battle_rule_v1:e1578e231f7cb23a2c4211fa2e08e51c', '{"ability_kind":"equipment_static","attached_keywords":[],"battle_model_scope":"xmage_equipment_static_power_toughness_attachment_v1","effect":"equipment_static_attachment","equipment":true,"instant":false,"power_boost":2,"sorcery":false,"static_power_bonus":2,"static_toughness_bonus":1,"target":"creature_you_control","target_constraints":{"card_types":["creature"],"controller":"self","zone":"battlefield"},"toughness_boost":1,"xmage_ability_classes":["EquipAbility","SimpleStaticAbility"],"xmage_effect_classes":["BoostEquippedEffect"]}'::jsonb, '{"category":"support","effect":"equipment_static_attachment","subtype":"equipment_static_pump","target":"creature_you_control"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BloodthornFlail translated into ManaLoom runtime scope xmage_equipment_static_power_toughness_attachment_v1. This row is package-ready only because the source signature is a narrow fixed Equipment attachment with static equipped-creature power/toughness and keyword modifier with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('demonmail hauberk', 'Demonmail Hauberk', '1f08deeab2c0475c0f80d8e4cc826355', 'battle_rule_v1:a501e1c0f5726aaf4689af5eacd7774a', '{"ability_kind":"equipment_static","attached_keywords":[],"battle_model_scope":"xmage_equipment_static_power_toughness_attachment_v1","effect":"equipment_static_attachment","equipment":true,"instant":false,"power_boost":4,"sorcery":false,"static_power_bonus":4,"static_toughness_bonus":2,"target":"creature_you_control","target_constraints":{"card_types":["creature"],"controller":"self","zone":"battlefield"},"toughness_boost":2,"xmage_ability_classes":["AddAbility","EquipAbility","SimpleStaticAbility"],"xmage_effect_classes":["BoostEquippedEffect"]}'::jsonb, '{"category":"support","effect":"equipment_static_attachment","subtype":"equipment_static_pump","target":"creature_you_control"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DemonmailHauberk translated into ManaLoom runtime scope xmage_equipment_static_power_toughness_attachment_v1. This row is package-ready only because the source signature is a narrow fixed Equipment attachment with static equipped-creature power/toughness and keyword modifier with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('murderer''s axe', 'Murderer''s Axe', '894f1d5c9adf8542002730887be9850d', 'battle_rule_v1:d207c85ffb0121236b7c49f49361f2aa', '{"ability_kind":"equipment_static","attached_keywords":[],"battle_model_scope":"xmage_equipment_static_power_toughness_attachment_v1","effect":"equipment_static_attachment","equipment":true,"instant":false,"power_boost":2,"sorcery":false,"static_power_bonus":2,"static_toughness_bonus":2,"target":"creature_you_control","target_constraints":{"card_types":["creature"],"controller":"self","zone":"battlefield"},"toughness_boost":2,"xmage_ability_classes":["AddAbility","EquipAbility","SimpleStaticAbility"],"xmage_effect_classes":["BoostEquippedEffect"]}'::jsonb, '{"category":"support","effect":"equipment_static_attachment","subtype":"equipment_static_pump","target":"creature_you_control"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MurderersAxe translated into ManaLoom runtime scope xmage_equipment_static_power_toughness_attachment_v1. This row is package-ready only because the source signature is a narrow fixed Equipment attachment with static equipped-creature power/toughness and keyword modifier with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
