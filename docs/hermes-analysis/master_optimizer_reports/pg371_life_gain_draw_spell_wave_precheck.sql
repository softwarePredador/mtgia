WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('dosan''s oldest chant', 'Dosan''s Oldest Chant', '5b0d387e45be18bc74411b6efac41e9e', 'battle_rule_v1:845cf002f1ea5f405217669601cd4aff', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_controller_gain_life_spell_v1","compose_on_resolution":true,"effect":"life_total_change","life_gain_amount":6,"target":"self","xmage_effect_class":"GainLifeEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_controller_gain_life_draw_card_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":false,"life_gain_amount":6,"sorcery":true,"xmage_effect_classes":["GainLifeEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DosansOldestChant translated into ManaLoom runtime scope xmage_fixed_controller_gain_life_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed controller life-gain plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('resupply', 'Resupply', '5b0d387e45be18bc74411b6efac41e9e', 'battle_rule_v1:48e6975a5607f029b81b95b3e5c06041', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_controller_gain_life_spell_v1","compose_on_resolution":true,"effect":"life_total_change","life_gain_amount":6,"target":"self","xmage_effect_class":"GainLifeEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_controller_gain_life_draw_card_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":true,"life_gain_amount":6,"sorcery":false,"xmage_effect_classes":["GainLifeEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Resupply translated into ManaLoom runtime scope xmage_fixed_controller_gain_life_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed controller life-gain plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('revitalize', 'Revitalize', '93b450ed3d279fd803dee8b045efb577', 'battle_rule_v1:87d5572300d4d26224ab50839985e9f7', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_controller_gain_life_spell_v1","compose_on_resolution":true,"effect":"life_total_change","life_gain_amount":3,"target":"self","xmage_effect_class":"GainLifeEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_controller_gain_life_draw_card_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":true,"life_gain_amount":3,"sorcery":false,"xmage_effect_classes":["GainLifeEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Revitalize translated into ManaLoom runtime scope xmage_fixed_controller_gain_life_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed controller life-gain plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('reviving dose', 'Reviving Dose', '93b450ed3d279fd803dee8b045efb577', 'battle_rule_v1:87d5572300d4d26224ab50839985e9f7', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_controller_gain_life_spell_v1","compose_on_resolution":true,"effect":"life_total_change","life_gain_amount":3,"target":"self","xmage_effect_class":"GainLifeEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_controller_gain_life_draw_card_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":true,"life_gain_amount":3,"sorcery":false,"xmage_effect_classes":["GainLifeEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RevivingDose translated into ManaLoom runtime scope xmage_fixed_controller_gain_life_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed controller life-gain plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ritual of rejuvenation', 'Ritual of Rejuvenation', '550480e66f0402692883f60b05c7f038', 'battle_rule_v1:c5be6b33be518357ce817f1ab3f2dedd', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_controller_gain_life_spell_v1","compose_on_resolution":true,"effect":"life_total_change","life_gain_amount":4,"target":"self","xmage_effect_class":"GainLifeEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_controller_gain_life_draw_card_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":true,"life_gain_amount":4,"sorcery":false,"xmage_effect_classes":["GainLifeEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RitualOfRejuvenation translated into ManaLoom runtime scope xmage_fixed_controller_gain_life_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed controller life-gain plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
