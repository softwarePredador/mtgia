WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('deathreap ritual', 'Deathreap Ritual', '3a2b787a9baa1e5deb9cdf7d4c9412d0', 'battle_rule_v1:b96df7a05d6dd5cddfb8203c4c22a5f2', '{"ability_kind":"triggered","battle_model_scope":"xmage_beginning_end_step_conditional_draw_v1","effect":"draw_engine","end_step_draw_condition":"creature_died_this_turn","end_step_draw_condition_status":"runtime_executor_v1","end_step_draw_count":1,"end_step_draw_optional":true,"trigger":"each_end_step","trigger_effect":"draw_cards","xmage_ability_class":"BeginningOfEndStepTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DeathreapRitual translated into ManaLoom runtime scope xmage_beginning_end_step_conditional_draw_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mercadian atlas', 'Mercadian Atlas', 'c0cdb0863bf2a20247312e48ba4801e8', 'battle_rule_v1:7acc3adc0a28b308a447e6a850210efb', '{"ability_kind":"triggered","battle_model_scope":"xmage_beginning_end_step_conditional_draw_v1","effect":"draw_engine","end_step_draw_condition":"controller_did_not_play_land_this_turn","end_step_draw_condition_status":"runtime_executor_v1","end_step_draw_count":1,"end_step_draw_optional":true,"trigger":"controller_end_step","trigger_effect":"draw_cards","xmage_ability_class":"BeginningOfEndStepTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MercadianAtlas translated into ManaLoom runtime scope xmage_beginning_end_step_conditional_draw_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('owlbear shepherd', 'Owlbear Shepherd', 'd30d89d549fe6fd0824f4d39537322ac', 'battle_rule_v1:12545c02f606b4ec5aa00e3aa833f1be', '{"ability_kind":"triggered","battle_model_scope":"xmage_beginning_end_step_conditional_draw_v1","effect":"creature","end_step_draw_condition":"controlled_creatures_total_power_gte","end_step_draw_condition_status":"runtime_executor_v1","end_step_draw_condition_threshold":8,"end_step_draw_count":1,"end_step_draw_optional":false,"is_creature_permanent":true,"trigger":"controller_end_step","trigger_effect":"draw_cards","xmage_ability_class":"BeginningOfEndStepTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OwlbearShepherd translated into ManaLoom runtime scope xmage_beginning_end_step_conditional_draw_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sygg, river cutthroat', 'Sygg, River Cutthroat', '9a7a849585f81a1e1c6199432027f213', 'battle_rule_v1:dd4b8987ae497ad050d0ada5e491d122', '{"ability_kind":"triggered","battle_model_scope":"xmage_beginning_end_step_conditional_draw_v1","effect":"creature","end_step_draw_condition":"opponent_lost_life_gte","end_step_draw_condition_status":"runtime_executor_v1","end_step_draw_condition_threshold":3,"end_step_draw_count":1,"end_step_draw_optional":true,"is_creature_permanent":true,"trigger":"each_end_step","trigger_effect":"draw_cards","xmage_ability_class":"BeginningOfEndStepTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SyggRiverCutthroat translated into ManaLoom runtime scope xmage_beginning_end_step_conditional_draw_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('the gaffer', 'The Gaffer', 'f2cfb32b3314493afd737d0b6cae2a4f', 'battle_rule_v1:364521bf8772f4f0a3b3d283334411d0', '{"ability_kind":"triggered","battle_model_scope":"xmage_beginning_end_step_conditional_draw_v1","effect":"creature","end_step_draw_condition":"controller_gained_life_gte","end_step_draw_condition_status":"runtime_executor_v1","end_step_draw_condition_threshold":3,"end_step_draw_count":1,"end_step_draw_optional":false,"is_creature_permanent":true,"trigger":"each_end_step","trigger_effect":"draw_cards","xmage_ability_class":"BeginningOfEndStepTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TheGaffer translated into ManaLoom runtime scope xmage_beginning_end_step_conditional_draw_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('twinblade assassins', 'Twinblade Assassins', 'c1ae690ea3d614c9e254fb4f27e93aff', 'battle_rule_v1:1506d707a427fb391ca0a225d35558d2', '{"ability_kind":"triggered","battle_model_scope":"xmage_beginning_end_step_conditional_draw_v1","effect":"creature","end_step_draw_condition":"creature_died_this_turn","end_step_draw_condition_status":"runtime_executor_v1","end_step_draw_count":1,"end_step_draw_optional":false,"is_creature_permanent":true,"trigger":"controller_end_step","trigger_effect":"draw_cards","xmage_ability_class":"BeginningOfEndStepTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TwinbladeAssassins translated into ManaLoom runtime scope xmage_beginning_end_step_conditional_draw_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('well of discovery', 'Well of Discovery', '3afd21e4065afb7492b392e78a50e29b', 'battle_rule_v1:04931c0d85ab9f7a9b9f343969b897e0', '{"ability_kind":"triggered","battle_model_scope":"xmage_beginning_end_step_conditional_draw_v1","effect":"draw_engine","end_step_draw_condition":"controller_controls_no_untapped_lands","end_step_draw_condition_status":"runtime_executor_v1","end_step_draw_count":1,"end_step_draw_optional":false,"trigger":"controller_end_step","trigger_effect":"draw_cards","xmage_ability_class":"BeginningOfEndStepTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WellOfDiscovery translated into ManaLoom runtime scope xmage_beginning_end_step_conditional_draw_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
