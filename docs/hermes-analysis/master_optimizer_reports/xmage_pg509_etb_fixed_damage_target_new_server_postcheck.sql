WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('geistcatcher''s rig', 'Geistcatcher''s Rig', 'db3e02163c294694a172feeaf45d88ea', 'battle_rule_v1:9c5990d7e2bffaaa3f9c312f0f11781c', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":4,"etb_damage_target":"flying_creature","target":"flying_creature","target_constraints":{"card_types":["creature"],"required_keywords":["flying"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"flying_creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GeistcatchersRig translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('goretusk firebeast', 'Goretusk Firebeast', '3b2c41e97bcd2e61e7b16ba8797227ad', 'battle_rule_v1:0b3bbe5604fd9bf374462e470c31d1d4', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":4,"etb_damage_target":"player_or_planeswalker","target":"player_or_planeswalker","target_constraints":{"scope":"player_or_planeswalker"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"player_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GoretuskFirebeast translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('unsparing boltcaster', 'Unsparing Boltcaster', '9a46e09738ecdb690d12258849179c96', 'battle_rule_v1:050b3a24d030eff42eae7a9910ac3ce6', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":5,"etb_damage_target":"creature","target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"opponent","damaged_this_turn":true},"target_controller":"opponent","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class UnsparingBoltcaster translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('viashino pyromancer', 'Viashino Pyromancer', '0b7677080966557d281ce2381e6ba675', 'battle_rule_v1:60d41dd048c092bca317332544334052', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":2,"etb_damage_target":"player_or_planeswalker","target":"player_or_planeswalker","target_constraints":{"scope":"player_or_planeswalker"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"player_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ViashinoPyromancer translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('whiptail moloch', 'Whiptail Moloch', 'de709bf2a4de7400cb14e793e6eb0357', 'battle_rule_v1:6d3c745c30c6578b608c0e39feadd8c5', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":3,"etb_damage_target":"creature","target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"self"},"target_controller":"self","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WhiptailMoloch translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg509_xmage_pg509_etb_fixed_damage_targe_20260705_134357) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
