WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('deadly visit', 'Deadly Visit', 'e79fa6604f9bb48390a6eb47dc93465e', 'battle_rule_v1:8401f578a890f94339112252f3df8e51', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_surveil_spell_v1","compose_on_resolution":true,"count":2,"effect":"surveil","surveil_count":2,"xmage_effect_class":"SurveilEffect"}],"battle_model_scope":"xmage_destroy_target_and_surveil_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":false,"resolution_order":"destroy_then_surveil","sorcery":true,"surveil_count":2,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DestroyTargetEffect","SurveilEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DeadlyVisit translated into ManaLoom runtime scope xmage_destroy_target_and_surveil_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pile on', 'Pile On', 'd7cee896f072258bf3ffc01f35db1455', 'battle_rule_v1:eac4cda4892f93a03f1ee70150b79554', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_permanent","target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_surveil_spell_v1","compose_on_resolution":true,"count":2,"effect":"surveil","surveil_count":2,"xmage_effect_class":"SurveilEffect"}],"battle_model_scope":"xmage_destroy_target_and_surveil_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":true,"resolution_order":"destroy_then_surveil","sorcery":false,"surveil_count":2,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_effect_classes":["DestroyTargetEffect","SurveilEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature_or_planeswalker","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PileOn translated into ManaLoom runtime scope xmage_destroy_target_and_surveil_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('shattered wings', 'Shattered Wings', '1403ae9ff7f78a14e19ef7c4d6fbb3d9', 'battle_rule_v1:88df4325c9b9a46eac29e3040c908ab5', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_permanent","target":"permanent","target_constraints":{"any_of":[{"card_types":["artifact"]},{"card_types":["enchantment"]},{"card_types":["creature"],"required_keywords":["flying"]}]},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_surveil_spell_v1","compose_on_resolution":true,"count":1,"effect":"surveil","surveil_count":1,"xmage_effect_class":"SurveilEffect"}],"battle_model_scope":"xmage_destroy_target_and_surveil_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":false,"resolution_order":"destroy_then_surveil","sorcery":true,"surveil_count":1,"target":"permanent","target_constraints":{"any_of":[{"card_types":["artifact"]},{"card_types":["enchantment"]},{"card_types":["creature"],"required_keywords":["flying"]}]},"xmage_effect_classes":["DestroyTargetEffect","SurveilEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ShatteredWings translated into ManaLoom runtime scope xmage_destroy_target_and_surveil_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg604_destroy_surveil_new_server_pg604_d_20260707_082832) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
