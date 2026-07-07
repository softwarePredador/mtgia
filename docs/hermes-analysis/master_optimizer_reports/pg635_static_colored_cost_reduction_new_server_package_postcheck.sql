WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('edgewalker', 'Edgewalker', '9dbbd985fcdc89be41cf2c5b86ff79bf', 'battle_rule_v1:2f9f9069e9192da0c8e90d58cff9fcda', '{"ability_kind":"static","applies_to_subtypes":["cleric"],"battle_model_scope":"xmage_static_generic_cost_reduction_for_matching_spells_v1","cost_reduction_amount_source":"fixed","cost_reduction_applies_to":"spells_you_cast","cost_reduction_color_symbols":["W","B"],"cost_reduction_generic":0,"effect":"static_cost_reduction","permanent_type":"creature","static_effect":"generic_cost_reduction_for_matching_spells","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SpellsCostReductionControllerEffect"}'::jsonb, '{"category":"support","effect":"static_cost_reduction"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Edgewalker translated into ManaLoom runtime scope xmage_static_generic_cost_reduction_for_matching_spells_v1. This row is package-ready only because the source signature is a narrow permanent static generic cost reduction for matching spells you cast with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ragemonger', 'Ragemonger', '2535a2d4ca1ff4aa0700f0feedcc9688', 'battle_rule_v1:43f0b5923df1d7ea90f69aec83340904', '{"ability_kind":"static","applies_to_subtypes":["minotaur"],"battle_model_scope":"xmage_static_generic_cost_reduction_for_matching_spells_v1","cost_reduction_amount_source":"fixed","cost_reduction_applies_to":"spells_you_cast","cost_reduction_color_symbols":["B","R"],"cost_reduction_generic":0,"effect":"static_cost_reduction","permanent_type":"creature","static_effect":"generic_cost_reduction_for_matching_spells","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SpellsCostReductionControllerEffect"}'::jsonb, '{"category":"support","effect":"static_cost_reduction"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Ragemonger translated into ManaLoom runtime scope xmage_static_generic_cost_reduction_for_matching_spells_v1. This row is package-ready only because the source signature is a narrow permanent static generic cost reduction for matching spells you cast with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg635_static_colored_cost_reduction_new_20260707_195231) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
