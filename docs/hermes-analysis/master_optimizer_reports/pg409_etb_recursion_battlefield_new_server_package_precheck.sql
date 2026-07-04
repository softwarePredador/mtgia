WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('bloodline necromancer', 'Bloodline Necromancer', 'e713552fc98c793350f82c31624b470d', 'battle_rule_v1:2b7be1f5d59767be6bb2844a144e788e', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_battlefield_v1","battlefield_controller":"self","destination":"battlefield","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"battlefield","etb_recursion_target":"vampire_or_wizard_creature","keywords":["lifelink"],"lifelink":true,"target":"vampire_or_wizard_creature","target_constraints":{"card_types":["creature"],"controller":"self","subtypes":["vampire","wizard"],"zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"vampire_or_wizard_creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BloodlineNecromancer translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_battlefield_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('quarry beetle', 'Quarry Beetle', '4819c64ce86068970b8382c00989c0e6', 'battle_rule_v1:0d34c60d7e646ad88946ab4f21adea4a', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_battlefield_v1","battlefield_controller":"self","destination":"battlefield","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"battlefield","etb_recursion_target":"land","target":"land","target_constraints":{"card_types":["land"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"land"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class QuarryBeetle translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_battlefield_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sharuum the hegemon', 'Sharuum the Hegemon', 'bc8850d8a71aa330bebf823f85e5314f', 'battle_rule_v1:1eda23314f8caeb65cf14584c5ec2f2b', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_battlefield_v1","battlefield_controller":"self","destination":"battlefield","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"battlefield","etb_recursion_target":"artifact","flying":true,"keywords":["flying"],"target":"artifact","target_constraints":{"card_types":["artifact"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"artifact"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SharuumTheHegemon translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_battlefield_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
