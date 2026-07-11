WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('divine offering', 'Divine Offering', '0c067819a69c20217f9b19b711d92400', 'battle_rule_v1:384969d75fc0ceb3fc48e0fbadd1c0ca', '{"battle_model_scope":"xmage_destroy_target_and_dynamic_controller_gain_life_spell_v1","controller_gain_life_source":"target_mana_value","controller_gains_life":0,"destination":"graveyard","effect":"remove_permanent","instant":true,"sorcery":false,"target":"artifact","target_constraints":{"card_types":["artifact"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DivineOffering translated into ManaLoom runtime scope xmage_destroy_target_and_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('molder', 'Molder', '8d0f792325fcc149eaadf57e53ed1949', 'battle_rule_v1:ad6e9448ff14addb039ac653ac28c528', '{"battle_model_scope":"xmage_destroy_target_and_dynamic_controller_gain_life_spell_v1","controller_gain_life_source":"x_value","controller_gains_life":0,"destination":"graveyard","effect":"remove_permanent","instant":true,"sorcery":false,"target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"],"target_mana_value_source":"x_value"},"target_mana_value_exact_from_x":true,"target_mana_value_source":"x_value","xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact_or_enchantment","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Molder translated into ManaLoom runtime scope xmage_destroy_target_and_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('serene offering', 'Serene Offering', '514db4af9246c82d3b8817c1feef0f51', 'battle_rule_v1:45d637ad04edc0bd7690d28ff510deab', '{"battle_model_scope":"xmage_destroy_target_and_dynamic_controller_gain_life_spell_v1","controller_gain_life_source":"target_mana_value","controller_gains_life":0,"destination":"graveyard","effect":"remove_permanent","instant":true,"sorcery":false,"target":"enchantment","target_constraints":{"card_types":["enchantment"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"enchantment","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SereneOffering translated into ManaLoom runtime scope xmage_destroy_target_and_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tidy conclusion', 'Tidy Conclusion', '2b0c7ef2b530e70f2069bc11f7860ce1', 'battle_rule_v1:9ac359aa50729b9baf3955aa613a4cce', '{"battle_model_scope":"xmage_destroy_target_and_dynamic_controller_gain_life_spell_v1","battlefield_count_card_types":["artifact"],"battlefield_count_scope":"controller_battlefield","controller_gain_life_source":"battlefield_permanent_count","controller_gains_life":0,"destination":"graveyard","effect":"remove_creature","instant":true,"life_gain_per_count":1,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TidyConclusion translated into ManaLoom runtime scope xmage_destroy_target_and_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg776_destroy_dynamic_gain_life_new_serv_20260711_172405) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
