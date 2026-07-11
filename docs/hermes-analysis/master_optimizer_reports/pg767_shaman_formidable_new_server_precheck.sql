WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('shaman of forgotten ways', 'Shaman of Forgotten Ways', '182c9953ec3d764f9ab6a77500987289', 'battle_rule_v1:cf0bd9ea965d4aac08811c1d74300374', '{"ability_kind":"activated_mana_and_formidable_activated","activation_requires_tap":true,"auxiliary_activated_effect":"each_player_life_total_becomes_creatures_controlled","battle_model_scope":"xmage_simple_tap_restricted_mana_source_with_formidable_life_total_reset_v1","conditional_mana_modes":[{"color":"W","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"U","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"B","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"R","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"G","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","effect":"ramp_permanent","formidable_activation_mana_cost":"{9}{G}{G}","formidable_activation_requires_tap":true,"formidable_controlled_creatures_total_power_gte":8,"formidable_life_total_count_scope":"each_player_creatures_controlled","formidable_life_total_reset":true,"is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":2,"permanent_type":"creature","produces":"WUBRG","xmage_ability_classes":["ActivateIfConditionActivatedAbility","ConditionalAnyColorManaAbility"],"xmage_effect_classes":["OneShotEffect","ShamanOfForgottenWaysEffect"],"xmage_mana_ability_classes":["ConditionalAnyColorManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ShamanOfForgottenWays translated into ManaLoom runtime scope xmage_simple_tap_restricted_mana_source_with_formidable_life_total_reset_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
