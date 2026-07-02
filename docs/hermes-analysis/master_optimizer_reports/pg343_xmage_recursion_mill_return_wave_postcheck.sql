WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('acolyte of affliction', 'Acolyte of Affliction', '1065260768af491ce6b27a5e9f634035', 'battle_rule_v1:313c45d8db9d3044d3f2d6151dc0a49d', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_mill_then_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_mill_count":2,"etb_recursion_target":"permanent","etb_recursion_up_to_count":true,"target_constraints":{"card_types":["artifact","creature","enchantment","planeswalker","battle","land"],"controller":"self","zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_classes":["MillCardsControllerEffect","ReturnCardChosenFromGraveyardEffect"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AcolyteOfAffliction translated into ManaLoom runtime scope xmage_creature_etb_mill_then_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('corpse churn', 'Corpse Churn', 'e89e2255330f3db9a8acfef47365aa36', 'battle_rule_v1:2a926d8f6e5d6d3947f2167ddbbbf450', '{"battle_model_scope":"xmage_mill_then_return_graveyard_card_to_hand_spell_v1","count":1,"destination":"hand","effect":"recursion","instant":true,"pre_recursion_mill_count":3,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","up_to_count":true,"xmage_effect_classes":["MillCardsControllerEffect","ReturnCardChosenFromGraveyardEffect"]}'::jsonb, '{"category":"engine","effect":"recursion","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CorpseChurn translated into ManaLoom runtime scope xmage_mill_then_return_graveyard_card_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('eccentric farmer', 'Eccentric Farmer', '93c7e9b37205b9ff286a1f6c48cc55fe', 'battle_rule_v1:8f1112c7845590f7af48ef2fe27e4042', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_mill_then_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_mill_count":3,"etb_recursion_target":"land","etb_recursion_up_to_count":true,"target_constraints":{"card_types":["land"],"controller":"self","zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_classes":["MillCardsControllerEffect","ReturnCardChosenFromGraveyardEffect"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EccentricFarmer translated into ManaLoom runtime scope xmage_creature_etb_mill_then_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('grapple with the past', 'Grapple with the Past', '05436728f69b35f7b1e8b0c3c0c468b1', 'battle_rule_v1:a6c4cee416262412bedfb007466f57cf', '{"battle_model_scope":"xmage_mill_then_return_graveyard_card_to_hand_spell_v1","count":1,"destination":"hand","effect":"recursion","instant":true,"pre_recursion_mill_count":3,"sorcery":false,"target":"creature_or_land","target_constraints":{"card_types":["creature","land"],"controller":"self","zone":"graveyard"},"target_controller":"self","up_to_count":true,"xmage_effect_classes":["MillCardsControllerEffect","ReturnCardChosenFromGraveyardEffect"]}'::jsonb, '{"category":"engine","effect":"recursion","target":"creature_or_land","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GrappleWithThePast translated into ManaLoom runtime scope xmage_mill_then_return_graveyard_card_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pothole mole', 'Pothole Mole', '93c7e9b37205b9ff286a1f6c48cc55fe', 'battle_rule_v1:8f1112c7845590f7af48ef2fe27e4042', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_mill_then_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_mill_count":3,"etb_recursion_target":"land","etb_recursion_up_to_count":true,"target_constraints":{"card_types":["land"],"controller":"self","zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_classes":["MillCardsControllerEffect","ReturnCardChosenFromGraveyardEffect"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PotholeMole translated into ManaLoom runtime scope xmage_creature_etb_mill_then_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg343_xmage_recursion_mill_return_wave_20260702_012603) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
