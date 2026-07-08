WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('contentious plan', 'Contentious Plan', '4582abf74328130a7ac8ca45cbcd1d2d', 'battle_rule_v1:821bc3c6274082b25465b68c03d58653', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_proliferate_spell_v1","compose_on_resolution":true,"effect":"proliferate","proliferate_count":1,"xmage_effect_class":"ProliferateEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_proliferate_and_draw_cards_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":false,"proliferate_count":1,"resolution_order":"proliferate_then_draw","sorcery":true,"xmage_effect_classes":["DrawCardSourceControllerEffect","ProliferateEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ContentiousPlan translated into ManaLoom runtime scope xmage_fixed_proliferate_and_draw_cards_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('steady progress', 'Steady Progress', '4582abf74328130a7ac8ca45cbcd1d2d', 'battle_rule_v1:6f809a58fe795aff31937be7484e5915', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_proliferate_spell_v1","compose_on_resolution":true,"effect":"proliferate","proliferate_count":1,"xmage_effect_class":"ProliferateEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_proliferate_and_draw_cards_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":true,"proliferate_count":1,"resolution_order":"proliferate_then_draw","sorcery":false,"xmage_effect_classes":["DrawCardSourceControllerEffect","ProliferateEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SteadyProgress translated into ManaLoom runtime scope xmage_fixed_proliferate_and_draw_cards_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tezzeret''s gambit', 'Tezzeret''s Gambit', 'cd253b1acdf30fc75b8a62d7630b45cd', 'battle_rule_v1:a550b8881a1b501010aad2549aa54472', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":2,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"},{"battle_model_scope":"xmage_fixed_proliferate_spell_v1","compose_on_resolution":true,"effect":"proliferate","proliferate_count":1,"xmage_effect_class":"ProliferateEffect"}],"battle_model_scope":"xmage_fixed_proliferate_and_draw_cards_spell_v1","count":2,"draw_count":2,"effect":"composite_resolution","instant":false,"proliferate_count":1,"resolution_order":"draw_then_proliferate","sorcery":true,"xmage_effect_classes":["DrawCardSourceControllerEffect","ProliferateEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TezzeretsGambit translated into ManaLoom runtime scope xmage_fixed_proliferate_and_draw_cards_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vivisurgeon''s insight', 'Vivisurgeon''s Insight', '225971006721adf2999911730a636afc', 'battle_rule_v1:5f0f5e17992389750140c3f40957d89c', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":3,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"},{"battle_model_scope":"xmage_fixed_proliferate_spell_v1","compose_on_resolution":true,"effect":"proliferate","proliferate_count":1,"xmage_effect_class":"ProliferateEffect"}],"battle_model_scope":"xmage_fixed_proliferate_and_draw_cards_spell_v1","count":3,"draw_count":3,"effect":"composite_resolution","instant":false,"proliferate_count":1,"resolution_order":"draw_then_proliferate","sorcery":true,"xmage_effect_classes":["DrawCardSourceControllerEffect","ProliferateEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VivisurgeonsInsight translated into ManaLoom runtime scope xmage_fixed_proliferate_and_draw_cards_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
),
rule_rows AS (
  SELECT
    r.normalized_name,
    r.logical_rule_key,
    r.oracle_hash,
    r.review_status,
    r.execution_status
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key = p.logical_rule_key
)
SELECT
  p.card_name,
  p.normalized_name,
  p.logical_rule_key,
  count(r.*) FILTER (WHERE r.logical_rule_key = p.logical_rule_key) AS promoted_rule_rows,
  count(r.*) FILTER (WHERE r.review_status = 'verified' AND r.execution_status = 'auto') AS promoted_verified_auto_rows,
  count(r.*) FILTER (WHERE r.oracle_hash = p.oracle_hash) AS promoted_oracle_hash_rows,
  (SELECT count(*) FROM manaloom_deploy_audit.pg675_proliferate_draw_new_server_prolif_20260708_223712) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
