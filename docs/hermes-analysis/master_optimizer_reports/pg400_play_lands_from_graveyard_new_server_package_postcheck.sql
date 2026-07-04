WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('crucible of worlds', 'Crucible of Worlds', 'cbfe8d699b0aab297f7c1ce0658589d9', 'battle_rule_v1:c110a961b3f1c43647de3466a77f152c', '{"ability_kind":"static","battle_model_scope":"xmage_static_play_lands_from_graveyard_v1","effect":"recursion","instant":false,"land_play_source_zone":"graveyard","play_lands_from_graveyard":true,"sorcery":false,"static_effect":"play_lands_from_graveyard","target":"land","target_constraints":{"card_types":["land"],"controller":"self","zone":"graveyard"},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"PlayFromGraveyardControllerEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"land"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CrucibleOfWorlds translated into ManaLoom runtime scope xmage_static_play_lands_from_graveyard_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ramunap excavator', 'Ramunap Excavator', 'cbfe8d699b0aab297f7c1ce0658589d9', 'battle_rule_v1:c110a961b3f1c43647de3466a77f152c', '{"ability_kind":"static","battle_model_scope":"xmage_static_play_lands_from_graveyard_v1","effect":"recursion","instant":false,"land_play_source_zone":"graveyard","play_lands_from_graveyard":true,"sorcery":false,"static_effect":"play_lands_from_graveyard","target":"land","target_constraints":{"card_types":["land"],"controller":"self","zone":"graveyard"},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"PlayFromGraveyardControllerEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"land"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RamunapExcavator translated into ManaLoom runtime scope xmage_static_play_lands_from_graveyard_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg400_play_lands_from_graveyard_new_server_20260704_1043) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
