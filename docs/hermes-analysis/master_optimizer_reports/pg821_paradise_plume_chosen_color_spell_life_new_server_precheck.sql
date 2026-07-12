WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('paradise plume', 'Paradise Plume', 'a2880170c087ee9a6c80e6b600d90f87', 'battle_rule_v1:8e6d57e4b283029ea7dffebfc3f096a5', '{"_composite_rule_components":[{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_gain_life_v1","effect":"life_gain_engine","spell_cast_gain_life":true,"spell_cast_gain_life_amount":1,"spell_cast_gain_life_any_player":true,"spell_cast_gain_life_optional":true,"spell_cast_gain_life_required_chosen_color":true,"trigger":"spell_cast","trigger_effect":"gain_life","xmage_ability_class":"ParadisePlumeSpellCastTriggeredAbility","xmage_effect_class":"GainLifeEffect"}],"ability_kind":"activated_mana_and_triggered","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","chosen_color_mana":true,"conditional_mana_modes":[{"color":"W","mode":"chosen_color_mana","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"U","mode":"chosen_color_mana","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"B","mode":"chosen_color_mana","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"R","mode":"chosen_color_mana","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"G","mode":"chosen_color_mana","restriction":"any_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","conditional_mana_same_color_choice":true,"effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"modeled_ability_subset":"mana_source_and_chosen_color_spell_cast_gain_life","permanent_type":"artifact","produces":"WUBRG","xmage_ability_classes":["AsEntersBattlefieldAbility","ParadisePlumeSpellCastTriggeredAbility","SimpleManaAbility"],"xmage_auxiliary_ability_classes":["AsEntersBattlefieldAbility","ParadisePlumeSpellCastTriggeredAbility"],"xmage_effect_classes":["AddManaChosenColorEffect","ChooseColorEffect","GainLifeEffect"],"xmage_mana_ability_classes":["SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ParadisePlume translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
