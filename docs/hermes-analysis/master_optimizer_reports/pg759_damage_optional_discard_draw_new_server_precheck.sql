WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('incinerating blast', 'Incinerating Blast', 'ff2e12f0294569c33d55bebfc3eca937', 'battle_rule_v1:1010828ca52b1c537cd18a4254e3e5bb', '{"_composite_rule_components":[{"amount":6,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","compose_on_resolution":true,"damage":6,"effect":"direct_damage","target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"DamageTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"discard_count":1,"effect":"draw_cards","optional":true,"optional_cost":"discard_card","optional_cost_count":1,"xmage_effect_class":"DrawCardSourceControllerEffect"}],"amount":6,"battle_model_scope":"xmage_fixed_damage_target_and_draw_card_spell_v1","count":1,"damage":6,"draw_count":1,"effect":"composite_resolution","instant":false,"optional_discard_count":1,"optional_discard_draw":true,"optional_discard_draw_count":1,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class IncineratingBlast translated into ManaLoom runtime scope xmage_fixed_damage_target_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tweeze', 'Tweeze', '12413e4a3440fd6799c23650b4d33c89', 'battle_rule_v1:3d93135447239576a0f3960d2c831111', '{"_composite_rule_components":[{"amount":3,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","compose_on_resolution":true,"damage":3,"effect":"direct_damage","target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_class":"DamageTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"discard_count":1,"effect":"draw_cards","optional":true,"optional_cost":"discard_card","optional_cost_count":1,"xmage_effect_class":"DrawCardSourceControllerEffect"}],"amount":3,"battle_model_scope":"xmage_fixed_damage_target_and_draw_card_spell_v1","count":1,"damage":3,"draw_count":1,"effect":"composite_resolution","instant":true,"optional_discard_count":1,"optional_discard_draw":true,"optional_discard_draw_count":1,"sorcery":false,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["DamageTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"any_target","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Tweeze translated into ManaLoom runtime scope xmage_fixed_damage_target_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
