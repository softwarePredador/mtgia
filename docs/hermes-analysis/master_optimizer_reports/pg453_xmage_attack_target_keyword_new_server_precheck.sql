WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('aerial guide', 'Aerial Guide', '359dc35b02c01fd10a6820d8dde25980', 'battle_rule_v1:12b85a7674e4bb9e3f0d2aa2fb3a57ae', '{"_keywords_are_self":true,"ability_kind":"triggered","attack_trigger_optional":false,"attack_trigger_target_keyword":true,"battle_model_scope":"xmage_creature_attack_grant_keyword_target_creature_until_eot_v1","duration":"until_end_of_turn","effect":"creature","flying":true,"granted_keywords_until_eot":["flying"],"keywords":["flying"],"power_delta":0,"target":"creature","target_constraints":{"card_types":["creature"],"combat_state":"attacking","exclude_source":true},"target_controller":"any","toughness_delta":0,"trigger":"attack","trigger_effect":"target_keyword_until_eot","xmage_ability_class":"AttacksTriggeredAbility","xmage_effect_class":"GainAbilityTargetEffect","xmage_granted_ability_class":"FlyingAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AerialGuide translated into ManaLoom runtime scope xmage_creature_attack_grant_keyword_target_creature_until_eot_v1. This row is package-ready only because the source signature is a narrow creature attack trigger grants a target creature a keyword until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('chasm drake', 'Chasm Drake', 'e4d468a8984897ccfa30beecdf24acd8', 'battle_rule_v1:9ad55b4397b12dbadea41d4cfa871303', '{"_keywords_are_self":true,"ability_kind":"triggered","attack_trigger_optional":false,"attack_trigger_target_keyword":true,"battle_model_scope":"xmage_creature_attack_grant_keyword_target_creature_until_eot_v1","duration":"until_end_of_turn","effect":"creature","flying":true,"granted_keywords_until_eot":["flying"],"keywords":["flying"],"power_delta":0,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"self","toughness_delta":0,"trigger":"attack","trigger_effect":"target_keyword_until_eot","xmage_ability_class":"AttacksTriggeredAbility","xmage_effect_class":"GainAbilityTargetEffect","xmage_granted_ability_class":"FlyingAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ChasmDrake translated into ManaLoom runtime scope xmage_creature_attack_grant_keyword_target_creature_until_eot_v1. This row is package-ready only because the source signature is a narrow creature attack trigger grants a target creature a keyword until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('garrison griffin', 'Garrison Griffin', 'cd663e02090ca20aca08c426e43ea1a6', 'battle_rule_v1:1ba8a066eb595bfa68fa0f7ac649110e', '{"_keywords_are_self":true,"ability_kind":"triggered","attack_trigger_optional":false,"attack_trigger_target_keyword":true,"battle_model_scope":"xmage_creature_attack_grant_keyword_target_creature_until_eot_v1","duration":"until_end_of_turn","effect":"creature","flying":true,"granted_keywords_until_eot":["flying"],"keywords":["flying"],"power_delta":0,"target":"creature","target_constraints":{"card_types":["creature"],"target_subtypes":["knight"]},"target_controller":"self","toughness_delta":0,"trigger":"attack","trigger_effect":"target_keyword_until_eot","xmage_ability_class":"AttacksTriggeredAbility","xmage_effect_class":"GainAbilityTargetEffect","xmage_granted_ability_class":"FlyingAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GarrisonGriffin translated into ManaLoom runtime scope xmage_creature_attack_grant_keyword_target_creature_until_eot_v1. This row is package-ready only because the source signature is a narrow creature attack trigger grants a target creature a keyword until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('heavenly qilin', 'Heavenly Qilin', '13953e4a3d0fdf170153301322a294cd', 'battle_rule_v1:3952493f0cdb04be711443c2c17cedf8', '{"_keywords_are_self":true,"ability_kind":"triggered","attack_trigger_optional":false,"attack_trigger_target_keyword":true,"battle_model_scope":"xmage_creature_attack_grant_keyword_target_creature_until_eot_v1","duration":"until_end_of_turn","effect":"creature","flying":true,"granted_keywords_until_eot":["flying"],"keywords":["flying"],"power_delta":0,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_source":true},"target_controller":"self","toughness_delta":0,"trigger":"attack","trigger_effect":"target_keyword_until_eot","xmage_ability_class":"AttacksTriggeredAbility","xmage_effect_class":"GainAbilityTargetEffect","xmage_granted_ability_class":"FlyingAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HeavenlyQilin translated into ManaLoom runtime scope xmage_creature_attack_grant_keyword_target_creature_until_eot_v1. This row is package-ready only because the source signature is a narrow creature attack trigger grants a target creature a keyword until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kinsbaile balloonist', 'Kinsbaile Balloonist', 'bdc2c420cceff82e0249aadb336da4f2', 'battle_rule_v1:cb7b0244b42311b6450eaaeae4f608b8', '{"_keywords_are_self":true,"ability_kind":"triggered","attack_trigger_optional":true,"attack_trigger_target_keyword":true,"battle_model_scope":"xmage_creature_attack_grant_keyword_target_creature_until_eot_v1","duration":"until_end_of_turn","effect":"creature","flying":true,"granted_keywords_until_eot":["flying"],"keywords":["flying"],"power_delta":0,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_delta":0,"trigger":"attack","trigger_effect":"target_keyword_until_eot","xmage_ability_class":"AttacksTriggeredAbility","xmage_effect_class":"GainAbilityTargetEffect","xmage_granted_ability_class":"FlyingAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KinsbaileBalloonist translated into ManaLoom runtime scope xmage_creature_attack_grant_keyword_target_creature_until_eot_v1. This row is package-ready only because the source signature is a narrow creature attack trigger grants a target creature a keyword until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('majestic heliopterus', 'Majestic Heliopterus', '789df848e690eb4720490ba73b04608e', 'battle_rule_v1:58b134e8facaa8950c16c360702ef77b', '{"_keywords_are_self":true,"ability_kind":"triggered","attack_trigger_optional":false,"attack_trigger_target_keyword":true,"battle_model_scope":"xmage_creature_attack_grant_keyword_target_creature_until_eot_v1","duration":"until_end_of_turn","effect":"creature","flying":true,"granted_keywords_until_eot":["flying"],"keywords":["flying"],"power_delta":0,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_source":true,"target_subtypes":["dinosaur"]},"target_controller":"self","toughness_delta":0,"trigger":"attack","trigger_effect":"target_keyword_until_eot","xmage_ability_class":"AttacksTriggeredAbility","xmage_effect_class":"GainAbilityTargetEffect","xmage_granted_ability_class":"FlyingAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MajesticHeliopterus translated into ManaLoom runtime scope xmage_creature_attack_grant_keyword_target_creature_until_eot_v1. This row is package-ready only because the source signature is a narrow creature attack trigger grants a target creature a keyword until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pegasus courser', 'Pegasus Courser', '359dc35b02c01fd10a6820d8dde25980', 'battle_rule_v1:12b85a7674e4bb9e3f0d2aa2fb3a57ae', '{"_keywords_are_self":true,"ability_kind":"triggered","attack_trigger_optional":false,"attack_trigger_target_keyword":true,"battle_model_scope":"xmage_creature_attack_grant_keyword_target_creature_until_eot_v1","duration":"until_end_of_turn","effect":"creature","flying":true,"granted_keywords_until_eot":["flying"],"keywords":["flying"],"power_delta":0,"target":"creature","target_constraints":{"card_types":["creature"],"combat_state":"attacking","exclude_source":true},"target_controller":"any","toughness_delta":0,"trigger":"attack","trigger_effect":"target_keyword_until_eot","xmage_ability_class":"AttacksTriggeredAbility","xmage_effect_class":"GainAbilityTargetEffect","xmage_granted_ability_class":"FlyingAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PegasusCourser translated into ManaLoom runtime scope xmage_creature_attack_grant_keyword_target_creature_until_eot_v1. This row is package-ready only because the source signature is a narrow creature attack trigger grants a target creature a keyword until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('roc charger', 'Roc Charger', 'ad767ca9ad8c91ba639f3bc0c6f871e1', 'battle_rule_v1:b9129a702bfa00117bb569f97997384d', '{"_keywords_are_self":true,"ability_kind":"triggered","attack_trigger_optional":false,"attack_trigger_target_keyword":true,"battle_model_scope":"xmage_creature_attack_grant_keyword_target_creature_until_eot_v1","duration":"until_end_of_turn","effect":"creature","flying":true,"granted_keywords_until_eot":["flying"],"keywords":["flying"],"power_delta":0,"target":"creature","target_constraints":{"card_types":["creature"],"combat_state":"attacking","excluded_keywords":["flying"]},"target_controller":"any","toughness_delta":0,"trigger":"attack","trigger_effect":"target_keyword_until_eot","xmage_ability_class":"AttacksTriggeredAbility","xmage_effect_class":"GainAbilityTargetEffect","xmage_granted_ability_class":"FlyingAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RocCharger translated into ManaLoom runtime scope xmage_creature_attack_grant_keyword_target_creature_until_eot_v1. This row is package-ready only because the source signature is a narrow creature attack trigger grants a target creature a keyword until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('trained condor', 'Trained Condor', '9f01e8733bf327bbeb7ab09cc5023979', 'battle_rule_v1:3952493f0cdb04be711443c2c17cedf8', '{"_keywords_are_self":true,"ability_kind":"triggered","attack_trigger_optional":false,"attack_trigger_target_keyword":true,"battle_model_scope":"xmage_creature_attack_grant_keyword_target_creature_until_eot_v1","duration":"until_end_of_turn","effect":"creature","flying":true,"granted_keywords_until_eot":["flying"],"keywords":["flying"],"power_delta":0,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_source":true},"target_controller":"self","toughness_delta":0,"trigger":"attack","trigger_effect":"target_keyword_until_eot","xmage_ability_class":"AttacksTriggeredAbility","xmage_effect_class":"GainAbilityTargetEffect","xmage_granted_ability_class":"FlyingAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TrainedCondor translated into ManaLoom runtime scope xmage_creature_attack_grant_keyword_target_creature_until_eot_v1. This row is package-ready only because the source signature is a narrow creature attack trigger grants a target creature a keyword until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('trusted pegasus', 'Trusted Pegasus', 'de5a2fde355df00b1c8c5cd5dcb5cdb5', 'battle_rule_v1:b9129a702bfa00117bb569f97997384d', '{"_keywords_are_self":true,"ability_kind":"triggered","attack_trigger_optional":false,"attack_trigger_target_keyword":true,"battle_model_scope":"xmage_creature_attack_grant_keyword_target_creature_until_eot_v1","duration":"until_end_of_turn","effect":"creature","flying":true,"granted_keywords_until_eot":["flying"],"keywords":["flying"],"power_delta":0,"target":"creature","target_constraints":{"card_types":["creature"],"combat_state":"attacking","excluded_keywords":["flying"]},"target_controller":"any","toughness_delta":0,"trigger":"attack","trigger_effect":"target_keyword_until_eot","xmage_ability_class":"AttacksTriggeredAbility","xmage_effect_class":"GainAbilityTargetEffect","xmage_granted_ability_class":"FlyingAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TrustedPegasus translated into ManaLoom runtime scope xmage_creature_attack_grant_keyword_target_creature_until_eot_v1. This row is package-ready only because the source signature is a narrow creature attack trigger grants a target creature a keyword until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
