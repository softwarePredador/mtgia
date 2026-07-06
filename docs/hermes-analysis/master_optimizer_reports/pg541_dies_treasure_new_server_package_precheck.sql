WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('common crook', 'Common Crook', '4ecd7b3c63f82113a4a6cf0fff0e719a', 'battle_rule_v1:3f60734db1f81ef3f3db0330478d6bd4', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_create_treasure_v1","dies_or_graveyard_from_battlefield_treasure":true,"dies_treasure_count":1,"dies_trigger_effect":"treasure_maker","effect":"creature","treasure_count":1,"treasure_recipient":"controller","treasure_trigger":"dies","trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"TreasureToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CommonCrook translated into ManaLoom runtime scope xmage_creature_dies_create_treasure_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed Treasure creation ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dire fleet hoarder', 'Dire Fleet Hoarder', '4ecd7b3c63f82113a4a6cf0fff0e719a', 'battle_rule_v1:3f60734db1f81ef3f3db0330478d6bd4', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_create_treasure_v1","dies_or_graveyard_from_battlefield_treasure":true,"dies_treasure_count":1,"dies_trigger_effect":"treasure_maker","effect":"creature","treasure_count":1,"treasure_recipient":"controller","treasure_trigger":"dies","trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"TreasureToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DireFleetHoarder translated into ManaLoom runtime scope xmage_creature_dies_create_treasure_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed Treasure creation ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('gleaming barrier', 'Gleaming Barrier', 'c6f82a18e52f76576a5b561153641e7f', 'battle_rule_v1:4b9bead4d691a3d01fc4ff09e291d0a2', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_create_treasure_v1","defender":true,"dies_or_graveyard_from_battlefield_treasure":true,"dies_treasure_count":1,"dies_trigger_effect":"treasure_maker","effect":"creature","keywords":["defender"],"treasure_count":1,"treasure_recipient":"controller","treasure_trigger":"dies","trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"TreasureToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GleamingBarrier translated into ManaLoom runtime scope xmage_creature_dies_create_treasure_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed Treasure creation ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jewel-eyed cobra', 'Jewel-Eyed Cobra', 'ab78078547fc4b0f1454608df265691e', 'battle_rule_v1:1a315e264d967f5fcb1a414a841a516f', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_create_treasure_v1","deathtouch":true,"dies_or_graveyard_from_battlefield_treasure":true,"dies_treasure_count":1,"dies_trigger_effect":"treasure_maker","effect":"creature","keywords":["deathtouch"],"treasure_count":1,"treasure_recipient":"controller","treasure_trigger":"dies","trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"TreasureToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JewelEyedCobra translated into ManaLoom runtime scope xmage_creature_dies_create_treasure_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed Treasure creation ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('piggy bank', 'Piggy Bank', '4ecd7b3c63f82113a4a6cf0fff0e719a', 'battle_rule_v1:3f60734db1f81ef3f3db0330478d6bd4', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_create_treasure_v1","dies_or_graveyard_from_battlefield_treasure":true,"dies_treasure_count":1,"dies_trigger_effect":"treasure_maker","effect":"creature","treasure_count":1,"treasure_recipient":"controller","treasure_trigger":"dies","trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"TreasureToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PiggyBank translated into ManaLoom runtime scope xmage_creature_dies_create_treasure_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed Treasure creation ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
