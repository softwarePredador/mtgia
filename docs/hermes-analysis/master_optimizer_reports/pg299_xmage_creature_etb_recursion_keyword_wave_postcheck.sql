WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('cadaver imp', 'Cadaver Imp', '910ed751dff9fb80f8a7c8281e8128b9', 'battle_rule_v1:1f62355235258125d70850193a57c376', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_target":"creature","flying":true,"keywords":["flying"],"target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CadaverImp translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('griffin dreamfinder', 'Griffin Dreamfinder', '93eb7869756f2660ce3687dbed245a4f', 'battle_rule_v1:665bf5d3bac2c2881c49ec01c4963243', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_target":"enchantment","flying":true,"keywords":["flying"],"target_constraints":{"card_types":["enchantment"],"controller":"self","zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GriffinDreamfinder translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mnemonic wall', 'Mnemonic Wall', '38990ed649f59ec9b0756b3b7d437c1e', 'battle_rule_v1:51142803b38be588b3f2eddebf47fa6d', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_hand_v1","defender":true,"effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_target":"instant_or_sorcery","keywords":["defender"],"target_constraints":{"card_types":["instant","sorcery"],"controller":"self","zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MnemonicWall translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sanctum gargoyle', 'Sanctum Gargoyle', '1ab85b577dff1ec22a95fab98e61eed4', 'battle_rule_v1:9f727b3670308479674b28e324c1a8b2', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_target":"artifact","flying":true,"keywords":["flying"],"target_constraints":{"card_types":["artifact"],"controller":"self","zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SanctumGargoyle translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg299_xmage_creature_etb_recursion_keyword_wave_20260701) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
