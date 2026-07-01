WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('backup agent', 'Backup Agent', '0ff0cf34f727891d39b4bf442a64daee', 'battle_rule_v1:79cfdb710b6cb24de6e123f5c89d4e5a', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_add_counters_target_creature_v1","counter_count":1,"counter_type":"+1/+1","effect":"creature","etb_add_counters_count":1,"etb_add_counters_counter_type":"+1/+1","etb_add_counters_target":"creature","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BackupAgent translated into ManaLoom runtime scope xmage_creature_etb_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('bond beetle', 'Bond Beetle', '0ff0cf34f727891d39b4bf442a64daee', 'battle_rule_v1:79cfdb710b6cb24de6e123f5c89d4e5a', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_add_counters_target_creature_v1","counter_count":1,"counter_type":"+1/+1","effect":"creature","etb_add_counters_count":1,"etb_add_counters_counter_type":"+1/+1","etb_add_counters_target":"creature","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BondBeetle translated into ManaLoom runtime scope xmage_creature_etb_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('cultbrand cinder', 'Cultbrand Cinder', '0d42483b15b32006a643cdf851b984e9', 'battle_rule_v1:87bb5098acfdc36d67b255b2346e4460', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_add_counters_target_creature_v1","counter_count":1,"counter_type":"-1/-1","effect":"creature","etb_add_counters_count":1,"etb_add_counters_counter_type":"-1/-1","etb_add_counters_target":"creature","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CultbrandCinder translated into ManaLoom runtime scope xmage_creature_etb_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dauntless survivor', 'Dauntless Survivor', '0ff0cf34f727891d39b4bf442a64daee', 'battle_rule_v1:79cfdb710b6cb24de6e123f5c89d4e5a', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_add_counters_target_creature_v1","counter_count":1,"counter_type":"+1/+1","effect":"creature","etb_add_counters_count":1,"etb_add_counters_counter_type":"+1/+1","etb_add_counters_target":"creature","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DauntlessSurvivor translated into ManaLoom runtime scope xmage_creature_etb_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('iron bully', 'Iron Bully', 'aba0ad0f016850655d66b0657e8579ea', 'battle_rule_v1:7f47be2bf0ed5ba799787dbd6cd91821', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_add_counters_target_creature_v1","counter_count":1,"counter_type":"+1/+1","effect":"creature","etb_add_counters_count":1,"etb_add_counters_counter_type":"+1/+1","etb_add_counters_target":"creature","instant":false,"keywords":["menace"],"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class IronBully translated into ManaLoom runtime scope xmage_creature_etb_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ironpaw aspirant', 'Ironpaw Aspirant', '0ff0cf34f727891d39b4bf442a64daee', 'battle_rule_v1:79cfdb710b6cb24de6e123f5c89d4e5a', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_add_counters_target_creature_v1","counter_count":1,"counter_type":"+1/+1","effect":"creature","etb_add_counters_count":1,"etb_add_counters_counter_type":"+1/+1","etb_add_counters_target":"creature","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class IronpawAspirant translated into ManaLoom runtime scope xmage_creature_etb_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ironshell beetle', 'Ironshell Beetle', '0ff0cf34f727891d39b4bf442a64daee', 'battle_rule_v1:79cfdb710b6cb24de6e123f5c89d4e5a', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_add_counters_target_creature_v1","counter_count":1,"counter_type":"+1/+1","effect":"creature","etb_add_counters_count":1,"etb_add_counters_counter_type":"+1/+1","etb_add_counters_target":"creature","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class IronshellBeetle translated into ManaLoom runtime scope xmage_creature_etb_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jeong jeong''s deserters', 'Jeong Jeong''s Deserters', '0ff0cf34f727891d39b4bf442a64daee', 'battle_rule_v1:79cfdb710b6cb24de6e123f5c89d4e5a', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_add_counters_target_creature_v1","counter_count":1,"counter_type":"+1/+1","effect":"creature","etb_add_counters_count":1,"etb_add_counters_counter_type":"+1/+1","etb_add_counters_target":"creature","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JeongJeongsDeserters translated into ManaLoom runtime scope xmage_creature_etb_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pith driller', 'Pith Driller', 'fe4fc466b098a3cb9e97ae5f0b1082ff', 'battle_rule_v1:87bb5098acfdc36d67b255b2346e4460', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_add_counters_target_creature_v1","counter_count":1,"counter_type":"-1/-1","effect":"creature","etb_add_counters_count":1,"etb_add_counters_counter_type":"-1/-1","etb_add_counters_target":"creature","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PithDriller translated into ManaLoom runtime scope xmage_creature_etb_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('satyr grovedancer', 'Satyr Grovedancer', '0ff0cf34f727891d39b4bf442a64daee', 'battle_rule_v1:79cfdb710b6cb24de6e123f5c89d4e5a', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_add_counters_target_creature_v1","counter_count":1,"counter_type":"+1/+1","effect":"creature","etb_add_counters_count":1,"etb_add_counters_counter_type":"+1/+1","etb_add_counters_target":"creature","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SatyrGrovedancer translated into ManaLoom runtime scope xmage_creature_etb_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('supply-line cranes', 'Supply-Line Cranes', '66ab7b835a56ca4b092bb75abee91a0f', 'battle_rule_v1:d5caf0ce251c182b57cd9ca9d74d8b2a', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_add_counters_target_creature_v1","counter_count":1,"counter_type":"+1/+1","effect":"creature","etb_add_counters_count":1,"etb_add_counters_counter_type":"+1/+1","etb_add_counters_target":"creature","instant":false,"keywords":["flying"],"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SupplyLineCranes translated into ManaLoom runtime scope xmage_creature_etb_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
