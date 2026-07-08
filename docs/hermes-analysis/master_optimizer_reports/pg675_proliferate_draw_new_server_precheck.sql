WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('contentious plan', 'Contentious Plan', '4582abf74328130a7ac8ca45cbcd1d2d', 'battle_rule_v1:821bc3c6274082b25465b68c03d58653', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_proliferate_spell_v1","compose_on_resolution":true,"effect":"proliferate","proliferate_count":1,"xmage_effect_class":"ProliferateEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_proliferate_and_draw_cards_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":false,"proliferate_count":1,"resolution_order":"proliferate_then_draw","sorcery":true,"xmage_effect_classes":["DrawCardSourceControllerEffect","ProliferateEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ContentiousPlan translated into ManaLoom runtime scope xmage_fixed_proliferate_and_draw_cards_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('steady progress', 'Steady Progress', '4582abf74328130a7ac8ca45cbcd1d2d', 'battle_rule_v1:6f809a58fe795aff31937be7484e5915', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_proliferate_spell_v1","compose_on_resolution":true,"effect":"proliferate","proliferate_count":1,"xmage_effect_class":"ProliferateEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_proliferate_and_draw_cards_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":true,"proliferate_count":1,"resolution_order":"proliferate_then_draw","sorcery":false,"xmage_effect_classes":["DrawCardSourceControllerEffect","ProliferateEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SteadyProgress translated into ManaLoom runtime scope xmage_fixed_proliferate_and_draw_cards_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tezzeret''s gambit', 'Tezzeret''s Gambit', 'cd253b1acdf30fc75b8a62d7630b45cd', 'battle_rule_v1:a550b8881a1b501010aad2549aa54472', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":2,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"},{"battle_model_scope":"xmage_fixed_proliferate_spell_v1","compose_on_resolution":true,"effect":"proliferate","proliferate_count":1,"xmage_effect_class":"ProliferateEffect"}],"battle_model_scope":"xmage_fixed_proliferate_and_draw_cards_spell_v1","count":2,"draw_count":2,"effect":"composite_resolution","instant":false,"proliferate_count":1,"resolution_order":"draw_then_proliferate","sorcery":true,"xmage_effect_classes":["DrawCardSourceControllerEffect","ProliferateEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TezzeretsGambit translated into ManaLoom runtime scope xmage_fixed_proliferate_and_draw_cards_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vivisurgeon''s insight', 'Vivisurgeon''s Insight', '225971006721adf2999911730a636afc', 'battle_rule_v1:5f0f5e17992389750140c3f40957d89c', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":3,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"},{"battle_model_scope":"xmage_fixed_proliferate_spell_v1","compose_on_resolution":true,"effect":"proliferate","proliferate_count":1,"xmage_effect_class":"ProliferateEffect"}],"battle_model_scope":"xmage_fixed_proliferate_and_draw_cards_spell_v1","count":3,"draw_count":3,"effect":"composite_resolution","instant":false,"proliferate_count":1,"resolution_order":"draw_then_proliferate","sorcery":true,"xmage_effect_classes":["DrawCardSourceControllerEffect","ProliferateEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VivisurgeonsInsight translated into ManaLoom runtime scope xmage_fixed_proliferate_and_draw_cards_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
