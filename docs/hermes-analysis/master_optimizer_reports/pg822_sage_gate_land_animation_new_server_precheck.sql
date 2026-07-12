WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('sage of the maze', 'Sage of the Maze', 'daad64346959bcce99bbacd2fe8b446b', 'battle_rule_v1:2fb3b8cb0466f30ea443828df0589bed', '{"_activated_rule_effects":[{"ability_kind":"activated","activate_only_as_sorcery":true,"activated_effect":"land_animation","activated_land_animation":true,"activation_requires_tap":true,"battle_model_scope":"xmage_activated_land_becomes_creature_gate_count_v1","effect":"land_animation","land_animation_count_subtype":"Gate","land_animation_duration":"until_end_of_turn","land_animation_granted_keywords":["haste"],"land_animation_multiplier":2,"land_animation_power_toughness_source":"controlled_subtype_count_times","land_animation_subtype":"Citizen","target":"land","target_constraints":{"card_types":["land"],"controller":"self"},"target_controller":"self","xmage_ability_class":"ActivateAsSorceryActivatedAbility","xmage_effect_class":"SageOfTheMazeEffect"},{"ability_kind":"activated","activated_effect":"untap_source","activation_requires_tap_target":true,"activation_tap_cost":"untapped_controlled_gate","activation_tap_cost_controller":"self","activation_tap_cost_subtype":"Gate","battle_model_scope":"xmage_activated_tap_gate_untap_source_v1","effect":"untap_source","gate_tap_untap_source":true,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"UntapSourceEffect"}],"ability_kind":"mana_and_activated","activated_battle_model_scope":"xmage_activated_land_becomes_creature_gate_count_v1","activated_effect":"land_animation_and_gate_untap_source","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_with_gate_land_animation_untap_v1","effect":"ramp_permanent","gate_tap_untap_source":true,"gate_tap_untap_source_cost_subtype":"Gate","is_mana_source":true,"land_animation_count_subtype":"Gate","land_animation_duration":"until_end_of_turn","land_animation_granted_keywords":["haste"],"land_animation_multiplier":2,"land_animation_power_toughness_source":"controlled_subtype_count_times","land_animation_subtype":"Citizen","mana_activation_requires_tap":true,"mana_produced":2,"permanent_type":"creature","produces":"WUBRG","source_mana_cost":"{2}{G}","source_type_line":"Creature \u2014 Elf Wizard","xmage_ability_classes":["ActivateAsSorceryActivatedAbility","HasteAbility","SimpleActivatedAbility","SimpleManaAbility"],"xmage_effect_classes":["AddManaInAnyCombinationEffect","BecomesCreatureTargetEffect","OneShotEffect","SageOfTheMazeEffect","UntapSourceEffect"],"xmage_mana_ability_classes":["SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SageOfTheMaze translated into ManaLoom runtime scope xmage_simple_tap_mana_source_with_gate_land_animation_untap_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
