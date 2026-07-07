WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('dragon blood', 'Dragon Blood', '5a9ddd93f19673d19055cef4d28fabef', 'battle_rule_v1:7d7e66ad44970bb4b01eaf1c24ee22ea', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_add_counters":true,"activated_add_counters_count":1,"activated_add_counters_counter_type":"+1/+1","activated_add_counters_target":"creature","activated_effect":"add_counters","activation_cost_colors":[],"activation_cost_generic":3,"activation_cost_mana":"{3}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"+1/+1","effect":"add_counters","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"AddCountersTargetEffect"}],"ability_kind":"static_and_activated","activated_add_counters":true,"activated_add_counters_count":1,"activated_add_counters_counter_type":"+1/+1","activated_add_counters_target":"creature","activated_battle_model_scope":"xmage_permanent_simple_activated_add_counters_target_creature_v1","activated_effect":"add_counters","activation_cost_colors":[],"activation_cost_generic":3,"activation_cost_mana":"{3}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"+1/+1","effect":"artifact","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"artifact","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DragonBlood translated into ManaLoom runtime scope xmage_permanent_simple_activated_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fevered convulsions', 'Fevered Convulsions', '7c2478a8c06702e016f780e590c8e77f', 'battle_rule_v1:098a4dbc87403ab533c6a2a34790dd1c', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_add_counters":true,"activated_add_counters_count":1,"activated_add_counters_counter_type":"-1/-1","activated_add_counters_target":"creature","activated_effect":"add_counters","activation_cost_colors":["B","B"],"activation_cost_generic":2,"activation_cost_mana":"{2}{B}{B}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"-1/-1","effect":"add_counters","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"AddCountersTargetEffect"}],"ability_kind":"static_and_activated","activated_add_counters":true,"activated_add_counters_count":1,"activated_add_counters_counter_type":"-1/-1","activated_add_counters_target":"creature","activated_battle_model_scope":"xmage_permanent_simple_activated_add_counters_target_creature_v1","activated_effect":"add_counters","activation_cost_colors":["B","B"],"activation_cost_generic":2,"activation_cost_mana":"{2}{B}{B}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"-1/-1","effect":"enchantment","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"enchantment","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FeveredConvulsions translated into ManaLoom runtime scope xmage_permanent_simple_activated_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('gnarled effigy', 'Gnarled Effigy', 'a8fbb1ed07606e88c3e38453bd1854ae', 'battle_rule_v1:b2810c952a67dfca35dcc5c41e2ed248', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_add_counters":true,"activated_add_counters_count":1,"activated_add_counters_counter_type":"-1/-1","activated_add_counters_target":"creature","activated_effect":"add_counters","activation_cost_colors":[],"activation_cost_generic":4,"activation_cost_mana":"{4}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"-1/-1","effect":"add_counters","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"AddCountersTargetEffect"}],"ability_kind":"static_and_activated","activated_add_counters":true,"activated_add_counters_count":1,"activated_add_counters_counter_type":"-1/-1","activated_add_counters_target":"creature","activated_battle_model_scope":"xmage_permanent_simple_activated_add_counters_target_creature_v1","activated_effect":"add_counters","activation_cost_colors":[],"activation_cost_generic":4,"activation_cost_mana":"{4}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"-1/-1","effect":"artifact","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"artifact","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GnarledEffigy translated into ManaLoom runtime scope xmage_permanent_simple_activated_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
