WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('bankrupt in blood', 'Bankrupt in Blood', '2ee300a774e18b23ed901a015682bbbe', 'battle_rule_v1:2f3a02050c062eec03ca64e2607443ea', '{"additional_cost":"sacrifice_two_creatures","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","count":3,"effect":"draw_cards","instant":false,"requires_sacrifice_creature_count":2,"sorcery":true,"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"creature","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BankruptInBlood translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('merciless resolve', 'Merciless Resolve', 'd0d4839dec3a3b975aedbfdf1c8992a6', 'battle_rule_v1:a4c9fccbf34922235bff7a9c562e4c85', '{"additional_cost":"sacrifice_creature_or_land","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","count":2,"effect":"draw_cards","instant":true,"requires_sacrifice_creature_or_land":true,"sorcery":false,"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"creature_or_land","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MercilessResolve translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg706_draw_sacrifice_additional_cost_new_20260710_151446) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
