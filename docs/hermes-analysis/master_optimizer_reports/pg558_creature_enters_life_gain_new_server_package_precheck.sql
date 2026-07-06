WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('ajani''s welcome', 'Ajani''s Welcome', '6d09a37bd5c0505506c94b6f2d94a7a5', 'battle_rule_v1:089f3a0bad3917be07c2b3be1816798a', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_life_gain_trigger_v1","effect":"enchantment","trigger":"creature_you_control_enters","trigger_another_creature_enters":false,"trigger_controller_scope":"self","trigger_effect":"gain_life","trigger_entering_card_types":["creature"],"trigger_gain_life":1,"trigger_optional":false,"xmage_ability_class":"EntersBattlefieldControlledTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"enchantment"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AjanisWelcome translated into ManaLoom runtime scope xmage_creature_enters_life_gain_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller gains life with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('bogwater lumaret', 'Bogwater Lumaret', '4f1dcd5e34ac1dcc36285db8ea88fe55', 'battle_rule_v1:f7abc667a056e8f3a9e9f532c8e2d71b', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_life_gain_trigger_v1","effect":"creature","trigger":"creature_you_control_enters","trigger_another_creature_enters":false,"trigger_controller_scope":"self","trigger_effect":"gain_life","trigger_entering_card_types":["creature"],"trigger_gain_life":1,"trigger_optional":false,"xmage_ability_class":"EntersBattlefieldThisOrAnotherTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BogwaterLumaret translated into ManaLoom runtime scope xmage_creature_enters_life_gain_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller gains life with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('essence warden', 'Essence Warden', '541ce650961d6205c6983a80f0de26c8', 'battle_rule_v1:d872267cd94ffd18d01759dffea4b534', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_life_gain_trigger_v1","effect":"creature","trigger":"creature_enters","trigger_another_creature_enters":true,"trigger_controller_scope":"any","trigger_effect":"gain_life","trigger_entering_card_types":["creature"],"trigger_gain_life":1,"trigger_optional":false,"xmage_ability_class":"EntersBattlefieldAllTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EssenceWarden translated into ManaLoom runtime scope xmage_creature_enters_life_gain_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller gains life with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('healer of the pride', 'Healer of the Pride', '1a8c83b7c87404d6374a48479a91191f', 'battle_rule_v1:633cd660f33c0fbfd62a2b44e3885178', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_life_gain_trigger_v1","effect":"creature","trigger":"creature_you_control_enters","trigger_another_creature_enters":true,"trigger_controller_scope":"self","trigger_effect":"gain_life","trigger_entering_card_types":["creature"],"trigger_gain_life":2,"trigger_optional":false,"xmage_ability_class":"EntersBattlefieldControlledTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HealerOfThePride translated into ManaLoom runtime scope xmage_creature_enters_life_gain_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller gains life with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hinterland sanctifier', 'Hinterland Sanctifier', 'e7a0375eed54098f412273247b5f1092', 'battle_rule_v1:e8bfae58e56b3d8549356753d856f890', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_life_gain_trigger_v1","effect":"creature","trigger":"creature_you_control_enters","trigger_another_creature_enters":true,"trigger_controller_scope":"self","trigger_effect":"gain_life","trigger_entering_card_types":["creature"],"trigger_gain_life":1,"trigger_optional":false,"xmage_ability_class":"EntersBattlefieldAllTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HinterlandSanctifier translated into ManaLoom runtime scope xmage_creature_enters_life_gain_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller gains life with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('impassioned orator', 'Impassioned Orator', 'e7a0375eed54098f412273247b5f1092', 'battle_rule_v1:e7b144f63b6e37e3970f3ca0753d00f8', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_life_gain_trigger_v1","effect":"creature","trigger":"creature_you_control_enters","trigger_another_creature_enters":true,"trigger_controller_scope":"self","trigger_effect":"gain_life","trigger_entering_card_types":["creature"],"trigger_gain_life":1,"trigger_optional":false,"xmage_ability_class":"EntersBattlefieldControlledTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ImpassionedOrator translated into ManaLoom runtime scope xmage_creature_enters_life_gain_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller gains life with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kor celebrant', 'Kor Celebrant', '4f1dcd5e34ac1dcc36285db8ea88fe55', 'battle_rule_v1:f7abc667a056e8f3a9e9f532c8e2d71b', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_life_gain_trigger_v1","effect":"creature","trigger":"creature_you_control_enters","trigger_another_creature_enters":false,"trigger_controller_scope":"self","trigger_effect":"gain_life","trigger_entering_card_types":["creature"],"trigger_gain_life":1,"trigger_optional":false,"xmage_ability_class":"EntersBattlefieldThisOrAnotherTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KorCelebrant translated into ManaLoom runtime scope xmage_creature_enters_life_gain_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller gains life with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('soul warden', 'Soul Warden', '541ce650961d6205c6983a80f0de26c8', 'battle_rule_v1:d872267cd94ffd18d01759dffea4b534', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_life_gain_trigger_v1","effect":"creature","trigger":"creature_enters","trigger_another_creature_enters":true,"trigger_controller_scope":"any","trigger_effect":"gain_life","trigger_entering_card_types":["creature"],"trigger_gain_life":1,"trigger_optional":false,"xmage_ability_class":"EntersBattlefieldAllTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SoulWarden translated into ManaLoom runtime scope xmage_creature_enters_life_gain_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller gains life with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('soul''s attendant', 'Soul''s Attendant', '62c289d4ca14a9ac8ace7faa3460b6a6', 'battle_rule_v1:9a4743d4ac2cab2cf9ef969669b9606c', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_life_gain_trigger_v1","effect":"creature","trigger":"creature_enters","trigger_another_creature_enters":true,"trigger_controller_scope":"any","trigger_effect":"gain_life","trigger_entering_card_types":["creature"],"trigger_gain_life":1,"trigger_optional":true,"xmage_ability_class":"EntersBattlefieldAllTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SoulsAttendant translated into ManaLoom runtime scope xmage_creature_enters_life_gain_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller gains life with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
