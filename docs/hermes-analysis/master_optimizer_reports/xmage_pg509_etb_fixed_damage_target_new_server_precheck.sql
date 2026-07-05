WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('geistcatcher''s rig', 'Geistcatcher''s Rig', 'db3e02163c294694a172feeaf45d88ea', 'battle_rule_v1:9c5990d7e2bffaaa3f9c312f0f11781c', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":4,"etb_damage_target":"flying_creature","target":"flying_creature","target_constraints":{"card_types":["creature"],"required_keywords":["flying"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"flying_creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GeistcatchersRig translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('goretusk firebeast', 'Goretusk Firebeast', '3b2c41e97bcd2e61e7b16ba8797227ad', 'battle_rule_v1:0b3bbe5604fd9bf374462e470c31d1d4', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":4,"etb_damage_target":"player_or_planeswalker","target":"player_or_planeswalker","target_constraints":{"scope":"player_or_planeswalker"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"player_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GoretuskFirebeast translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('unsparing boltcaster', 'Unsparing Boltcaster', '9a46e09738ecdb690d12258849179c96', 'battle_rule_v1:050b3a24d030eff42eae7a9910ac3ce6', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":5,"etb_damage_target":"creature","target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"opponent","damaged_this_turn":true},"target_controller":"opponent","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class UnsparingBoltcaster translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('viashino pyromancer', 'Viashino Pyromancer', '0b7677080966557d281ce2381e6ba675', 'battle_rule_v1:60d41dd048c092bca317332544334052', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":2,"etb_damage_target":"player_or_planeswalker","target":"player_or_planeswalker","target_constraints":{"scope":"player_or_planeswalker"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"player_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ViashinoPyromancer translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('whiptail moloch', 'Whiptail Moloch', 'de709bf2a4de7400cb14e793e6eb0357', 'battle_rule_v1:6d3c745c30c6578b608c0e39feadd8c5', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":3,"etb_damage_target":"creature","target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"self"},"target_controller":"self","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WhiptailMoloch translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
