WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('akoum boulderfoot', 'Akoum Boulderfoot', '45281fde9e9ca072507cc0f3396ef1f8', 'battle_rule_v1:10ed26189f39de99d282a85334cead7d', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":1,"etb_damage_target":"any_target","target":"any_target","target_constraints":{"scope":"any_target"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AkoumBoulderfoot translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('blisterstick shaman', 'Blisterstick Shaman', '45281fde9e9ca072507cc0f3396ef1f8', 'battle_rule_v1:10ed26189f39de99d282a85334cead7d', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":1,"etb_damage_target":"any_target","target":"any_target","target_constraints":{"scope":"any_target"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BlisterstickShaman translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('corrupt eunuchs', 'Corrupt Eunuchs', '6cb7c3a573c3fc76d7a0275462aba0e4', 'battle_rule_v1:0ec21fb7926cc051327c2aef53549b01', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":2,"etb_damage_target":"creature","target":"creature","target_constraints":{"card_types":["creature"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CorruptEunuchs translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fire imp', 'Fire Imp', '6cb7c3a573c3fc76d7a0275462aba0e4', 'battle_rule_v1:0ec21fb7926cc051327c2aef53549b01', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":2,"etb_damage_target":"creature","target":"creature","target_constraints":{"card_types":["creature"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FireImp translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('flametongue kavu', 'Flametongue Kavu', 'f158afdf97fc5a10935820ec11da373b', 'battle_rule_v1:22463a20fe885e7421278c4535de33b3', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":4,"etb_damage_target":"creature","target":"creature","target_constraints":{"card_types":["creature"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FlametongueKavu translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('goblin commando', 'Goblin Commando', '6cb7c3a573c3fc76d7a0275462aba0e4', 'battle_rule_v1:0ec21fb7926cc051327c2aef53549b01', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":2,"etb_damage_target":"creature","target":"creature","target_constraints":{"card_types":["creature"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GoblinCommando translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('skeleton archer', 'Skeleton Archer', '45281fde9e9ca072507cc0f3396ef1f8', 'battle_rule_v1:10ed26189f39de99d282a85334cead7d', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":1,"etb_damage_target":"any_target","target":"any_target","target_constraints":{"scope":"any_target"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SkeletonArcher translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sparkmage apprentice', 'Sparkmage Apprentice', '45281fde9e9ca072507cc0f3396ef1f8', 'battle_rule_v1:10ed26189f39de99d282a85334cead7d', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":1,"etb_damage_target":"any_target","target":"any_target","target_constraints":{"scope":"any_target"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SparkmageApprentice translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
