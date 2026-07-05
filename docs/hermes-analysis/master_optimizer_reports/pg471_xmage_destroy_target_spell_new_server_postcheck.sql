WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('bone splinters', 'Bone Splinters', '5b0fa8f1b681a6327b1ffe89ef0ffbc9', 'battle_rule_v1:f4fb67d9af26b5ed562b437b85d0e3d3', '{"additional_cost":"sacrifice_creature","battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":false,"requires_sacrifice_creature":true,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"creature","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BoneSplinters translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('embrace oblivion', 'Embrace Oblivion', '05e8fd4bf8fae8602b5883385f75a6aa', 'battle_rule_v1:1330d6b65c530f0725148ec8f4e16576', '{"additional_cost":"sacrifice_artifact_or_creature","battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":false,"requires_sacrifice_artifact_or_creature":true,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"artifact_or_creature","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EmbraceOblivion translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('powerstone fracture', 'Powerstone Fracture', 'a5c06a971f3a0473c0568aba333cf79a', 'battle_rule_v1:142000d6120e9a04710f8a2cc31524b2', '{"additional_cost":"sacrifice_artifact_or_creature","battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_permanent","instant":false,"requires_sacrifice_artifact_or_creature":true,"sorcery":true,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"artifact_or_creature","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"creature_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PowerstoneFracture translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('raze', 'Raze', 'e0d0084f1ad04bd705cf38689a523622', 'battle_rule_v1:476f315b753e08d325a53d881500898a', '{"additional_cost":"sacrifice_land","battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_permanent","instant":false,"requires_sacrifice_land":true,"sorcery":true,"target":"land","target_constraints":{"card_types":["land"]},"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"land","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"land"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Raze translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg471_xmage_destroy_target_spell_new_server_20260705_021) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
