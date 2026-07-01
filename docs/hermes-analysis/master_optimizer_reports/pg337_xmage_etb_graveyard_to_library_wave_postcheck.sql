WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('dukhara scavenger', 'Dukhara Scavenger', '5aa0fc1f83928ece835da7974b31b899', 'battle_rule_v1:aff86b7a250d8bcea98713b8ab9e81f4', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_put_graveyard_card_on_library_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"library_top","etb_recursion_target":"artifact_or_creature","library_controller":"self","target_constraints":{"card_types":["artifact","creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"PutOnLibraryTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DukharaScavenger translated into ManaLoom runtime scope xmage_creature_etb_put_graveyard_card_on_library_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('meldweb curator', 'Meldweb Curator', 'a0955a787ec1b1c7b6f17f2cf63d860b', 'battle_rule_v1:0a4eab7f075f8c25bd6e8cd872aa4dbe', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_put_graveyard_card_on_library_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"library_top","etb_recursion_target":"instant_or_sorcery","etb_recursion_up_to_count":true,"library_controller":"self","target_constraints":{"card_types":["instant","sorcery"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"PutOnLibraryTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MeldwebCurator translated into ManaLoom runtime scope xmage_creature_etb_put_graveyard_card_on_library_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg337_xmage_etb_graveyard_to_library_wave_pg337_xmage_et) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
