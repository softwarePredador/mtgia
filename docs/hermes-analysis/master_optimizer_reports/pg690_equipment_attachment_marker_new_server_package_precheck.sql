WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('boots of speed', 'Boots of Speed', '93dcb240a5ebd1209fdc3afa694342d6', 'battle_rule_v1:3446416c027923c276d6b8a7e62e33cc', '{"ability_kind":"equipment_static","attached_keywords":["haste"],"battle_model_scope":"xmage_equipment_static_power_toughness_attachment_v1","effect":"equipment_static_attachment","equipment":true,"grants_haste":true,"instant":false,"power_boost":1,"sorcery":false,"static_power_bonus":1,"static_toughness_bonus":0,"target":"creature_you_control","target_constraints":{"card_types":["creature"],"controller":"self","zone":"battlefield"},"toughness_boost":0,"xmage_ability_classes":["EquipAbility","HasteAbility","SimpleStaticAbility"],"xmage_effect_classes":["BoostEquippedEffect","GainAbilityAttachedEffect"]}'::jsonb, '{"category":"support","effect":"equipment_static_attachment","subtype":"equipment_static_pump","target":"creature_you_control"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BootsOfSpeed translated into ManaLoom runtime scope xmage_equipment_static_power_toughness_attachment_v1. This row is package-ready only because the source signature is a narrow fixed Equipment attachment with static equipped-creature power/toughness and keyword modifier with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ranger''s longbow', 'Ranger''s Longbow', 'd90876a22ae99080f188b15cf5d91daf', 'battle_rule_v1:039950727e934a1464a14a3e8aaaac8e', '{"ability_kind":"equipment_static","attached_keywords":["reach"],"battle_model_scope":"xmage_equipment_static_power_toughness_attachment_v1","effect":"equipment_static_attachment","equipment":true,"grants_reach":true,"instant":false,"power_boost":2,"sorcery":false,"static_power_bonus":2,"static_toughness_bonus":1,"target":"creature_you_control","target_constraints":{"card_types":["creature"],"controller":"self","zone":"battlefield"},"toughness_boost":1,"xmage_ability_classes":["EquipAbility","ReachAbility","SimpleStaticAbility"],"xmage_effect_classes":["BoostEquippedEffect","GainAbilityAttachedEffect"]}'::jsonb, '{"category":"support","effect":"equipment_static_attachment","subtype":"equipment_static_pump","target":"creature_you_control"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RangersLongbow translated into ManaLoom runtime scope xmage_equipment_static_power_toughness_attachment_v1. This row is package-ready only because the source signature is a narrow fixed Equipment attachment with static equipped-creature power/toughness and keyword modifier with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
