WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('acolyte of affliction', 'Acolyte of Affliction', '1065260768af491ce6b27a5e9f634035', 'battle_rule_v1:313c45d8db9d3044d3f2d6151dc0a49d', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_mill_then_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_mill_count":2,"etb_recursion_target":"permanent","etb_recursion_up_to_count":true,"target_constraints":{"card_types":["artifact","creature","enchantment","planeswalker","battle","land"],"controller":"self","zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_classes":["MillCardsControllerEffect","ReturnCardChosenFromGraveyardEffect"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AcolyteOfAffliction translated into ManaLoom runtime scope xmage_creature_etb_mill_then_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('corpse churn', 'Corpse Churn', 'e89e2255330f3db9a8acfef47365aa36', 'battle_rule_v1:2a926d8f6e5d6d3947f2167ddbbbf450', '{"battle_model_scope":"xmage_mill_then_return_graveyard_card_to_hand_spell_v1","count":1,"destination":"hand","effect":"recursion","instant":true,"pre_recursion_mill_count":3,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","up_to_count":true,"xmage_effect_classes":["MillCardsControllerEffect","ReturnCardChosenFromGraveyardEffect"]}'::jsonb, '{"category":"engine","effect":"recursion","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CorpseChurn translated into ManaLoom runtime scope xmage_mill_then_return_graveyard_card_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('eccentric farmer', 'Eccentric Farmer', '93c7e9b37205b9ff286a1f6c48cc55fe', 'battle_rule_v1:8f1112c7845590f7af48ef2fe27e4042', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_mill_then_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_mill_count":3,"etb_recursion_target":"land","etb_recursion_up_to_count":true,"target_constraints":{"card_types":["land"],"controller":"self","zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_classes":["MillCardsControllerEffect","ReturnCardChosenFromGraveyardEffect"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EccentricFarmer translated into ManaLoom runtime scope xmage_creature_etb_mill_then_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('grapple with the past', 'Grapple with the Past', '05436728f69b35f7b1e8b0c3c0c468b1', 'battle_rule_v1:a6c4cee416262412bedfb007466f57cf', '{"battle_model_scope":"xmage_mill_then_return_graveyard_card_to_hand_spell_v1","count":1,"destination":"hand","effect":"recursion","instant":true,"pre_recursion_mill_count":3,"sorcery":false,"target":"creature_or_land","target_constraints":{"card_types":["creature","land"],"controller":"self","zone":"graveyard"},"target_controller":"self","up_to_count":true,"xmage_effect_classes":["MillCardsControllerEffect","ReturnCardChosenFromGraveyardEffect"]}'::jsonb, '{"category":"engine","effect":"recursion","target":"creature_or_land","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GrappleWithThePast translated into ManaLoom runtime scope xmage_mill_then_return_graveyard_card_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pothole mole', 'Pothole Mole', '93c7e9b37205b9ff286a1f6c48cc55fe', 'battle_rule_v1:8f1112c7845590f7af48ef2fe27e4042', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_mill_then_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_mill_count":3,"etb_recursion_target":"land","etb_recursion_up_to_count":true,"target_constraints":{"card_types":["land"],"controller":"self","zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_classes":["MillCardsControllerEffect","ReturnCardChosenFromGraveyardEffect"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PotholeMole translated into ManaLoom runtime scope xmage_creature_etb_mill_then_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
),
matched_cards AS (
  SELECT
    p.normalized_name,
    p.card_name,
    p.oracle_hash,
    c.id AS card_id,
    c.name AS db_card_name
  FROM proposed p
  LEFT JOIN public.cards c
    ON (
         lower(c.name) = p.normalized_name
         OR split_part(lower(c.name), ' // ', 1) = p.normalized_name
       )
   AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
),
target_cards AS (
  SELECT
    normalized_name,
    card_name,
    oracle_hash,
    count(card_id) AS target_card_rows,
    min(card_id::text)::uuid AS canonical_card_id,
    min(db_card_name) AS canonical_card_name
  FROM matched_cards
  GROUP BY normalized_name, card_name, oracle_hash
),
rule_rows AS (
  SELECT p.normalized_name, count(r.*) AS existing_rule_rows
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
  GROUP BY p.normalized_name
),
expected_rows AS (
  SELECT p.normalized_name, count(r.*) AS expected_rule_rows_before
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key = p.logical_rule_key
  GROUP BY p.normalized_name
),
shadow_rows AS (
  SELECT p.normalized_name, count(r.*) AS would_deprecate_shadow_rows
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key <> p.logical_rule_key
   AND r.review_status NOT IN ('deprecated', 'rejected')
   AND r.execution_status <> 'disabled'
  GROUP BY p.normalized_name
)
SELECT
  p.card_name,
  p.normalized_name,
  p.oracle_hash,
  p.logical_rule_key,
  p.shadow_handling,
  tc.target_card_rows,
  tc.canonical_card_id,
  rr.existing_rule_rows,
  er.expected_rule_rows_before,
  sr.would_deprecate_shadow_rows
FROM proposed p
JOIN target_cards tc USING (normalized_name, card_name, oracle_hash)
JOIN rule_rows rr USING (normalized_name)
JOIN expected_rows er USING (normalized_name)
JOIN shadow_rows sr USING (normalized_name)
ORDER BY p.card_name;
