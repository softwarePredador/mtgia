WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('ashen powder', 'Ashen Powder', '48fc82665cd4ba6542c9f84103f99fee', 'battle_rule_v1:edf213db3ea1551941983dd3d9a8ce4c', '{"battle_model_scope":"xmage_return_target_graveyard_card_to_battlefield_spell_v1","battlefield_controller":"self","count":1,"destination":"battlefield","effect":"recursion","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"opponent","zone":"graveyard"},"target_controller":"opponent","target_graveyard_controller":"opponent","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AshenPowder translated into ManaLoom runtime scope xmage_return_target_graveyard_card_to_battlefield_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('helping hand', 'Helping Hand', 'b7c291fb6ddaf079528e501c8a48c36a', 'battle_rule_v1:10d934ad92de0065f345f6b463df6911', '{"battle_model_scope":"xmage_return_target_graveyard_card_to_battlefield_spell_v1","battlefield_controller":"self","count":1,"destination":"battlefield","effect":"recursion","enters_tapped":true,"instant":false,"recursion_mana_value_max":3,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","mana_value_max":3,"zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HelpingHand translated into ManaLoom runtime scope xmage_return_target_graveyard_card_to_battlefield_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hymn of rebirth', 'Hymn of Rebirth', '0b6dfa60b13f980af9cbf9f032d2dbbe', 'battle_rule_v1:6c21b07e86b0625f859ea8797a5c9a71', '{"battle_model_scope":"xmage_return_target_graveyard_card_to_battlefield_spell_v1","battlefield_controller":"self","count":1,"destination":"battlefield","effect":"recursion","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"any_player","zone":"graveyard"},"target_controller":"any_player","target_graveyard_controller":"any_player","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HymnOfRebirth translated into ManaLoom runtime scope xmage_return_target_graveyard_card_to_battlefield_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg329_xmage_recursion_battlefield_simple_wave_20260701_2) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
