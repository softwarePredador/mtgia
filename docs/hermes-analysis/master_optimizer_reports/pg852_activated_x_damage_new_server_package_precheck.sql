WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('ballista squad', 'Ballista Squad', 'b83a1f67ed318231a171f1a5e38d8f4f', 'battle_rule_v1:710a219d5a896a02e7028bfc6349bc83', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"direct_damage","activation_cost_colors":["W"],"activation_cost_generic":0,"activation_cost_mana":"{X}{W}","activation_life_cost":0,"activation_requires_sacrifice":false,"activation_requires_tap":true,"activation_sacrifice_cost":null,"activation_tap_cost":null,"amount":0,"battle_model_scope":"xmage_permanent_simple_activated_damage_v1","damage":0,"damage_amount_source":"x_value","e2e_x_value":3,"effect":"direct_damage","target":"attacking_or_blocking_creature","target_constraints":{"card_types":["creature"],"combat_state":"attacking_or_blocking"},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DamageTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_damage_v1","activated_damage_amount":0,"activated_effect":"direct_damage","activation_cost_colors":["W"],"activation_cost_generic":0,"activation_cost_mana":"{X}{W}","activation_life_cost":0,"activation_requires_sacrifice":false,"activation_requires_tap":true,"activation_tap_cost":null,"amount":0,"battle_model_scope":"xmage_permanent_simple_activated_damage_v1","damage":0,"damage_amount_source":"x_value","e2e_x_value":3,"effect":"creature","target":"attacking_or_blocking_creature","target_constraints":{"card_types":["creature"],"combat_state":"attacking_or_blocking"},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"attacking_or_blocking_creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BallistaSquad translated into ManaLoom runtime scope xmage_permanent_simple_activated_damage_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated damage ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('cinder elemental', 'Cinder Elemental', '526abe5bb0e0a87b45acd6ba5526d96c', 'battle_rule_v1:3eec9da8077f0b046a6165abefc549e7', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"direct_damage","activated_self_sacrifice_damage":true,"activation_cost_colors":["R"],"activation_cost_generic":0,"activation_cost_mana":"{X}{R}","activation_life_cost":0,"activation_requires_sacrifice":true,"activation_requires_tap":true,"activation_sacrifice_cost":null,"activation_tap_cost":null,"amount":0,"battle_model_scope":"xmage_permanent_simple_activated_damage_v1","damage":0,"damage_amount_source":"x_value","e2e_x_value":3,"effect":"direct_damage","target":"any_target","target_constraints":{"scope":"any_target"},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DamageTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_damage_v1","activated_damage_amount":0,"activated_effect":"direct_damage","activated_self_sacrifice_damage":true,"activation_cost_colors":["R"],"activation_cost_generic":0,"activation_cost_mana":"{X}{R}","activation_life_cost":0,"activation_requires_sacrifice":true,"activation_requires_tap":true,"activation_tap_cost":null,"amount":0,"battle_model_scope":"xmage_permanent_simple_activated_damage_v1","damage":0,"damage_amount_source":"x_value","e2e_x_value":3,"effect":"creature","target":"any_target","target_constraints":{"scope":"any_target"},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CinderElemental translated into ManaLoom runtime scope xmage_permanent_simple_activated_damage_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated damage ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pain kami', 'Pain Kami', '26a05e4293b86b7271616759793588eb', 'battle_rule_v1:0cd76164b3a7d4d43ff86d69f3d6f2e1', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"direct_damage","activated_self_sacrifice_damage":true,"activation_cost_colors":["R"],"activation_cost_generic":0,"activation_cost_mana":"{X}{R}","activation_life_cost":0,"activation_requires_sacrifice":true,"activation_requires_tap":false,"activation_sacrifice_cost":null,"activation_tap_cost":null,"amount":0,"battle_model_scope":"xmage_permanent_simple_activated_damage_v1","damage":0,"damage_amount_source":"x_value","e2e_x_value":3,"effect":"direct_damage","target":"creature","target_constraints":{"card_types":["creature"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DamageTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_damage_v1","activated_damage_amount":0,"activated_effect":"direct_damage","activated_self_sacrifice_damage":true,"activation_cost_colors":["R"],"activation_cost_generic":0,"activation_cost_mana":"{X}{R}","activation_life_cost":0,"activation_requires_sacrifice":true,"activation_requires_tap":false,"activation_tap_cost":null,"amount":0,"battle_model_scope":"xmage_permanent_simple_activated_damage_v1","damage":0,"damage_amount_source":"x_value","e2e_x_value":3,"effect":"creature","target":"creature","target_constraints":{"card_types":["creature"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PainKami translated into ManaLoom runtime scope xmage_permanent_simple_activated_damage_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated damage ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
