WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('annihilating glare', 'Annihilating Glare', '052006cb3d6f1f1e367184e4aaef7fc2', 'battle_rule_v1:0c659eb3371016f8ae5aa11bdab3fb36', '{"additional_cost":"choose_pay_generic_or_sacrifice_artifact_or_creature","additional_cost_options":[{"cost":"pay_generic","pay_generic_amount":4,"requires_pay_generic":true},{"cost":"sacrifice_artifact_or_creature","requires_sacrifice_artifact_or_creature":true,"xmage_additional_cost_target":"artifact_or_creature"}],"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_permanent","instant":false,"requires_one_additional_cost_option":true,"sorcery":true,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_additional_cost_class":"OrCost","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"creature_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AnnihilatingGlare translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('deadly precision', 'Deadly Precision', 'cc5f6c4cd7a27bdff8d87afac5e2584a', 'battle_rule_v1:7c424b775d1c33dfb798c380c1fa358a', '{"additional_cost":"choose_pay_generic_or_sacrifice_artifact_or_creature","additional_cost_options":[{"cost":"pay_generic","pay_generic_amount":4,"requires_pay_generic":true},{"cost":"sacrifice_artifact_or_creature","requires_sacrifice_artifact_or_creature":true,"xmage_additional_cost_target":"artifact_or_creature"}],"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":false,"requires_one_additional_cost_option":true,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_additional_cost_class":"OrCost","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DeadlyPrecision translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lash of the balrog', 'Lash of the Balrog', '3c626b87ad61938c72288ccc50ae07b6', 'battle_rule_v1:7a15a26745011ba967578b75c118531f', '{"additional_cost":"choose_sacrifice_creature_or_pay_generic","additional_cost_options":[{"cost":"sacrifice_creature","requires_sacrifice_creature":true,"xmage_additional_cost_target":"creature"},{"cost":"pay_generic","pay_generic_amount":4,"requires_pay_generic":true}],"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":false,"requires_one_additional_cost_option":true,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_additional_cost_class":"OrCost","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LashOfTheBalrog translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lightning axe', 'Lightning Axe', '2d756dc855b92af19e72842859dbfb5d', 'battle_rule_v1:7da25f92bcb8da5c8045c963e630cd28', '{"additional_cost":"choose_discard_card_or_pay_generic","additional_cost_options":[{"cost":"discard_card","requires_discard_card":true},{"cost":"pay_generic","pay_generic_amount":5,"requires_pay_generic":true}],"amount":5,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","damage":5,"effect":"direct_damage","instant":true,"requires_one_additional_cost_option":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_additional_cost_class":"OrCost","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LightningAxe translated into ManaLoom runtime scope xmage_fixed_damage_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pumpkin bombardment', 'Pumpkin Bombardment', 'e1144cbe56a6a9dd971af2e1795e123b', 'battle_rule_v1:81e4e488312dbfd27bed89b9f17cdec8', '{"additional_cost":"choose_discard_card_or_pay_generic","additional_cost_options":[{"cost":"discard_card","requires_discard_card":true},{"cost":"pay_generic","pay_generic_amount":2,"requires_pay_generic":true}],"amount":3,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","damage":3,"effect":"direct_damage","instant":false,"requires_one_additional_cost_option":true,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_additional_cost_class":"OrCost","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PumpkinBombardment translated into ManaLoom runtime scope xmage_fixed_damage_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg783_orcost_pay_generic_spell_cost_new_20260711_191856) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
