WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('barrow witches', 'Barrow Witches', '03af5cf8599d458694ed320773b1eb7f', 'battle_rule_v1:4034cd73665465654057f3c53931944c', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_target":"knight_card","target_constraints":{"controller":"self","subtypes":["knight"],"zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BarrowWitches translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('disciple of the sun', 'Disciple of the Sun', 'ae730f1553235bf86c19b2f5a2a0d9eb', 'battle_rule_v1:ffdf833d17e0bd16f63882d13bbc3e2e', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_mana_value_max":3,"etb_recursion_target":"permanent","keywords":["lifelink"],"lifelink":true,"target_constraints":{"card_types":["artifact","creature","enchantment","planeswalker","battle","land"],"controller":"self","mana_value_max":3,"zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DiscipleOfTheSun translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('leonin squire', 'Leonin Squire', '2b39f6f71e298b5b3d7f3958183b2fec', 'battle_rule_v1:a357028acccc67acecfe58b809750fb2', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_mana_value_max":1,"etb_recursion_target":"artifact","target_constraints":{"card_types":["artifact"],"controller":"self","mana_value_max":1,"zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LeoninSquire translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pillardrop rescuer', 'Pillardrop Rescuer', '8856c25207818ab8189baf9fd3421354', 'battle_rule_v1:95e527e379975372965a66647a9a3378', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_mana_value_max":3,"etb_recursion_target":"creature","flying":true,"keywords":["flying"],"target_constraints":{"card_types":["creature"],"controller":"self","mana_value_max":3,"zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PillardropRescuer translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ragamuffin raptor', 'Ragamuffin Raptor', 'd1562c3e3fda218dcb8826c953cf91af', 'battle_rule_v1:e6a9f76c33f0301dab3bc1f741d19657', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_target":"creature_or_food","etb_recursion_up_to_count":true,"target_constraints":{"any_of":[{"card_types":["creature"]},{"subtypes":["food"]}],"controller":"self","zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RagamuffinRaptor translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('scholar of the ages', 'Scholar of the Ages', 'be6352a59faefe53242ea84fe3104b52', 'battle_rule_v1:69611c1df9c53b61f286a860e1008758', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":2,"etb_recursion_destination":"hand","etb_recursion_target":"instant_or_sorcery","etb_recursion_up_to_count":true,"target_constraints":{"card_types":["instant","sorcery"],"controller":"self","zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ScholarOfTheAges translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('strongarm thug', 'Strongarm Thug', 'b14be76cbbac1d5a404dda8205132377', 'battle_rule_v1:f46d50601f25d4153e9c7fa2c460ebcd', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_target":"mercenary_card","target_constraints":{"controller":"self","subtypes":["mercenary"],"zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StrongarmThug translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
