WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('bear trap', 'Bear Trap', '96f5bf52ac3ff60d49307eda68e9bbb0', 'battle_rule_v1:f42916e2503558c6d07d0e4248ecfaa4', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"direct_damage","activated_self_sacrifice_damage":true,"activation_cost_colors":[],"activation_cost_generic":3,"activation_cost_mana":"{3}","activation_requires_sacrifice":true,"activation_requires_tap":true,"activation_sacrifice_cost":null,"amount":3,"battle_model_scope":"xmage_permanent_simple_activated_damage_v1","damage":3,"effect":"direct_damage","target":"creature","target_constraints":{"card_types":["creature"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DamageTargetEffect"}],"_keywords_are_self":true,"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_damage_v1","activated_damage_amount":3,"activated_effect":"direct_damage","activated_self_sacrifice_damage":true,"activation_cost_colors":[],"activation_cost_generic":3,"activation_cost_mana":"{3}","activation_requires_sacrifice":true,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_damage_v1","effect":"artifact","flash":true,"keywords":["flash"],"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_ability_classes":["FlashAbility","SimpleActivatedAbility"],"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"artifact","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BearTrap translated into ManaLoom runtime scope xmage_permanent_simple_activated_damage_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated damage ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('defender of chaos', 'Defender of Chaos', '0a5067d02cd8e46a4bcbcc67b9410e61', 'battle_rule_v1:8a6d1d1f78df760eaa3d55060ed162c9', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_colors_creature_v1","effect":"creature","flash":true,"keywords":["flash"],"protection_from":["white"],"protection_from_colors":["white"],"static_effect":"self_protection_from_colors","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DefenderOfChaos translated into ManaLoom runtime scope xmage_static_self_protection_from_colors_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('defender of law', 'Defender of Law', 'fd4214bb098c9fa877e15d35d1a8f26f', 'battle_rule_v1:d63de8e51b839f8f151ea9dc27062ac9', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_colors_creature_v1","effect":"creature","flash":true,"keywords":["flash"],"protection_from":["red"],"protection_from_colors":["red"],"static_effect":"self_protection_from_colors","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DefenderOfLaw translated into ManaLoom runtime scope xmage_static_self_protection_from_colors_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('springjaw trap', 'Springjaw Trap', '0cfb147f3137086ad77e1697c480b0c3', 'battle_rule_v1:4af262b74796a9830c2e46d341bcc49b', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"direct_damage","activated_self_sacrifice_damage":true,"activation_cost_colors":[],"activation_cost_generic":4,"activation_cost_mana":"{4}","activation_requires_sacrifice":true,"activation_requires_tap":true,"activation_sacrifice_cost":null,"amount":3,"battle_model_scope":"xmage_permanent_simple_activated_damage_v1","damage":3,"effect":"direct_damage","target":"any_target","target_constraints":{"scope":"any_target"},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DamageTargetEffect"}],"_keywords_are_self":true,"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_damage_v1","activated_damage_amount":3,"activated_effect":"direct_damage","activated_self_sacrifice_damage":true,"activation_cost_colors":[],"activation_cost_generic":4,"activation_cost_mana":"{4}","activation_requires_sacrifice":true,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_damage_v1","effect":"artifact","flash":true,"keywords":["flash"],"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_ability_class":"SimpleActivatedAbility","xmage_ability_classes":["FlashAbility","SimpleActivatedAbility"],"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"artifact","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SpringjawTrap translated into ManaLoom runtime scope xmage_permanent_simple_activated_damage_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated damage ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
