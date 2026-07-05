WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('ogre siegebreaker', 'Ogre Siegebreaker', 'd9fe6fc297eeb748b517f9c308c77065', 'battle_rule_v1:034bd4c748e35fe57e52d223c648e8fd', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"destroy_target","activated_remove_effect":"remove_creature","activated_remove_target":"creature_damaged_this_turn","activation_cost_colors":["B","R"],"activation_cost_generic":2,"activation_cost_mana":"{2}{B}{R}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"],"damaged_this_turn":true},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","activated_effect":"destroy_target","activated_remove_effect":"remove_creature","activated_remove_target":"creature_damaged_this_turn","activation_cost_colors":["B","R"],"activation_cost_generic":2,"activation_cost_mana":"{2}{B}{R}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"creature","target":"creature","target_constraints":{"card_types":["creature"],"damaged_this_turn":true},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OgreSiegebreaker translated into ManaLoom runtime scope xmage_permanent_simple_activated_destroy_target_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated destroy-target ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('opportunist', 'Opportunist', 'aba5ffef49bc71c0b02a3ce50eca9c8c', 'battle_rule_v1:06261c009c5bcea9c7932e535c7b3359', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"direct_damage","activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_requires_sacrifice":false,"activation_requires_tap":true,"activation_sacrifice_cost":null,"amount":1,"battle_model_scope":"xmage_permanent_simple_activated_damage_v1","damage":1,"effect":"direct_damage","target":"creature_damaged_this_turn","target_constraints":{"card_types":["creature"],"damaged_this_turn":true},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DamageTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_damage_v1","activated_damage_amount":1,"activated_effect":"direct_damage","activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_damage_v1","effect":"creature","target":"creature_damaged_this_turn","target_constraints":{"card_types":["creature"],"damaged_this_turn":true},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature_damaged_this_turn"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Opportunist translated into ManaLoom runtime scope xmage_permanent_simple_activated_damage_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated damage ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('witch''s mist', 'Witch''s Mist', '6feafae65830ccd4967852c92320404b', 'battle_rule_v1:9b34535f520f3ad0fd7e365e758a83b0', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"destroy_target","activated_remove_effect":"remove_creature","activated_remove_target":"creature_damaged_this_turn","activation_cost_colors":["B"],"activation_cost_generic":2,"activation_cost_mana":"{2}{B}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"],"damaged_this_turn":true},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","activated_effect":"destroy_target","activated_remove_effect":"remove_creature","activated_remove_target":"creature_damaged_this_turn","activation_cost_colors":["B"],"activation_cost_generic":2,"activation_cost_mana":"{2}{B}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"enchantment","target":"creature","target_constraints":{"card_types":["creature"],"damaged_this_turn":true},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"enchantment","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WitchsMist translated into ManaLoom runtime scope xmage_permanent_simple_activated_destroy_target_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated destroy-target ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
