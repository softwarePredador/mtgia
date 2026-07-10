BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg711_dies_add_counters_new_server_20260710_172518 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('bile-vial boggart', 'festering mummy', 'goblin assault team', 'guul draz mucklord', 'lawless broker', 'sparring construct', 'spinal centipede', 'steadfast sentry', 'venerable knight')
   OR normalized_name LIKE 'bile-vial boggart // %'
   OR normalized_name LIKE 'festering mummy // %'
   OR normalized_name LIKE 'goblin assault team // %'
   OR normalized_name LIKE 'guul draz mucklord // %'
   OR normalized_name LIKE 'lawless broker // %'
   OR normalized_name LIKE 'sparring construct // %'
   OR normalized_name LIKE 'spinal centipede // %'
   OR normalized_name LIKE 'steadfast sentry // %'
   OR normalized_name LIKE 'venerable knight // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('bile-vial boggart', 'Bile-Vial Boggart', '765f9a0c55872371d4e69b2dea91632d', 'battle_rule_v1:d99ef6cb26e7f6879ee8558b6b1f24c6', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"-1/-1","dies_add_counters":true,"dies_add_counters_count":1,"dies_add_counters_counter_type":"-1/-1","dies_add_counters_target":"creature","effect":"creature","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count_max":1,"target_count_min":0,"trigger":"dies","trigger_effect":"add_counters","up_to_count":true,"xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BileVialBoggart translated into ManaLoom runtime scope xmage_creature_dies_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('festering mummy', 'Festering Mummy', '9e47de100c190411c8e30156312a120c', 'battle_rule_v1:500f0abd244b5b94191c9b4ff1243b01', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"-1/-1","dies_add_counters":true,"dies_add_counters_count":1,"dies_add_counters_counter_type":"-1/-1","dies_add_counters_optional":true,"dies_add_counters_target":"creature","effect":"creature","instant":false,"optional":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","trigger":"dies","trigger_effect":"add_counters","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FesteringMummy translated into ManaLoom runtime scope xmage_creature_dies_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('goblin assault team', 'Goblin Assault Team', '599e24538eeab1caa1dea482843a1802', 'battle_rule_v1:fdc0ed4e42df19e95b8f2b81f30c3963', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"+1/+1","dies_add_counters":true,"dies_add_counters_count":1,"dies_add_counters_counter_type":"+1/+1","dies_add_counters_target":"creature","effect":"creature","instant":false,"keywords":["haste"],"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"self"},"target_controller":"self","trigger":"dies","trigger_effect":"add_counters","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GoblinAssaultTeam translated into ManaLoom runtime scope xmage_creature_dies_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('guul draz mucklord', 'Guul Draz Mucklord', 'b2cf73bf78e0e5a7cd750ad498f2773e', 'battle_rule_v1:dc6d9eeb7537ceb1ad4b8351b1af12d8', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"+1/+1","dies_add_counters":true,"dies_add_counters_count":1,"dies_add_counters_counter_type":"+1/+1","dies_add_counters_target":"creature","effect":"creature","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"self"},"target_controller":"self","trigger":"dies","trigger_effect":"add_counters","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GuulDrazMucklord translated into ManaLoom runtime scope xmage_creature_dies_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lawless broker', 'Lawless Broker', 'b2cf73bf78e0e5a7cd750ad498f2773e', 'battle_rule_v1:dc6d9eeb7537ceb1ad4b8351b1af12d8', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"+1/+1","dies_add_counters":true,"dies_add_counters_count":1,"dies_add_counters_counter_type":"+1/+1","dies_add_counters_target":"creature","effect":"creature","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"self"},"target_controller":"self","trigger":"dies","trigger_effect":"add_counters","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LawlessBroker translated into ManaLoom runtime scope xmage_creature_dies_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sparring construct', 'Sparring Construct', 'b2cf73bf78e0e5a7cd750ad498f2773e', 'battle_rule_v1:dc6d9eeb7537ceb1ad4b8351b1af12d8', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"+1/+1","dies_add_counters":true,"dies_add_counters_count":1,"dies_add_counters_counter_type":"+1/+1","dies_add_counters_target":"creature","effect":"creature","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"self"},"target_controller":"self","trigger":"dies","trigger_effect":"add_counters","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SparringConstruct translated into ManaLoom runtime scope xmage_creature_dies_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('spinal centipede', 'Spinal Centipede', 'b2cf73bf78e0e5a7cd750ad498f2773e', 'battle_rule_v1:dc6d9eeb7537ceb1ad4b8351b1af12d8', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"+1/+1","dies_add_counters":true,"dies_add_counters_count":1,"dies_add_counters_counter_type":"+1/+1","dies_add_counters_target":"creature","effect":"creature","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"self"},"target_controller":"self","trigger":"dies","trigger_effect":"add_counters","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SpinalCentipede translated into ManaLoom runtime scope xmage_creature_dies_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('steadfast sentry', 'Steadfast Sentry', '5bd444489d885eeb73b0aec7c7f0609f', 'battle_rule_v1:741a080f18b880224c645da9fc305da1', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"+1/+1","dies_add_counters":true,"dies_add_counters_count":1,"dies_add_counters_counter_type":"+1/+1","dies_add_counters_target":"creature","effect":"creature","instant":false,"keywords":["vigilance"],"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"self"},"target_controller":"self","trigger":"dies","trigger_effect":"add_counters","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SteadfastSentry translated into ManaLoom runtime scope xmage_creature_dies_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('venerable knight', 'Venerable Knight', '27c7ab08136b9ceb9eca7963462af6c6', 'battle_rule_v1:44c3f8f7e38bf65029e832f0b8195111', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"+1/+1","dies_add_counters":true,"dies_add_counters_count":1,"dies_add_counters_counter_type":"+1/+1","dies_add_counters_target":"creature","effect":"creature","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"self","required_subtypes":["knight"]},"target_controller":"self","trigger":"dies","trigger_effect":"add_counters","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VenerableKnight translated into ManaLoom runtime scope xmage_creature_dies_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
),
  counts AS (
    SELECT
      p.card_name,
      p.normalized_name,
      p.oracle_hash,
      count(c.id) AS target_card_rows,
      min(c.id::text)::uuid AS canonical_card_id
    FROM proposed p
    LEFT JOIN public.cards c
      ON (
           lower(c.name) = p.normalized_name
           OR split_part(lower(c.name), ' // ', 1) = p.normalized_name
         )
     AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
    GROUP BY p.card_name, p.normalized_name, p.oracle_hash
  )
  SELECT jsonb_agg(counts ORDER BY card_name)
    INTO v_missing
  FROM counts
  WHERE target_card_rows < 1;

  IF v_missing IS NOT NULL THEN
    RAISE EXCEPTION 'XMage batch package abort: expected at least one Oracle-hash-matched card row for every proposed card: %', v_missing;
  END IF;
END $$;

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('bile-vial boggart', 'Bile-Vial Boggart', '765f9a0c55872371d4e69b2dea91632d', 'battle_rule_v1:d99ef6cb26e7f6879ee8558b6b1f24c6', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"-1/-1","dies_add_counters":true,"dies_add_counters_count":1,"dies_add_counters_counter_type":"-1/-1","dies_add_counters_target":"creature","effect":"creature","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count_max":1,"target_count_min":0,"trigger":"dies","trigger_effect":"add_counters","up_to_count":true,"xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BileVialBoggart translated into ManaLoom runtime scope xmage_creature_dies_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('festering mummy', 'Festering Mummy', '9e47de100c190411c8e30156312a120c', 'battle_rule_v1:500f0abd244b5b94191c9b4ff1243b01', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"-1/-1","dies_add_counters":true,"dies_add_counters_count":1,"dies_add_counters_counter_type":"-1/-1","dies_add_counters_optional":true,"dies_add_counters_target":"creature","effect":"creature","instant":false,"optional":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","trigger":"dies","trigger_effect":"add_counters","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FesteringMummy translated into ManaLoom runtime scope xmage_creature_dies_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('goblin assault team', 'Goblin Assault Team', '599e24538eeab1caa1dea482843a1802', 'battle_rule_v1:fdc0ed4e42df19e95b8f2b81f30c3963', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"+1/+1","dies_add_counters":true,"dies_add_counters_count":1,"dies_add_counters_counter_type":"+1/+1","dies_add_counters_target":"creature","effect":"creature","instant":false,"keywords":["haste"],"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"self"},"target_controller":"self","trigger":"dies","trigger_effect":"add_counters","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GoblinAssaultTeam translated into ManaLoom runtime scope xmage_creature_dies_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('guul draz mucklord', 'Guul Draz Mucklord', 'b2cf73bf78e0e5a7cd750ad498f2773e', 'battle_rule_v1:dc6d9eeb7537ceb1ad4b8351b1af12d8', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"+1/+1","dies_add_counters":true,"dies_add_counters_count":1,"dies_add_counters_counter_type":"+1/+1","dies_add_counters_target":"creature","effect":"creature","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"self"},"target_controller":"self","trigger":"dies","trigger_effect":"add_counters","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GuulDrazMucklord translated into ManaLoom runtime scope xmage_creature_dies_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lawless broker', 'Lawless Broker', 'b2cf73bf78e0e5a7cd750ad498f2773e', 'battle_rule_v1:dc6d9eeb7537ceb1ad4b8351b1af12d8', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"+1/+1","dies_add_counters":true,"dies_add_counters_count":1,"dies_add_counters_counter_type":"+1/+1","dies_add_counters_target":"creature","effect":"creature","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"self"},"target_controller":"self","trigger":"dies","trigger_effect":"add_counters","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LawlessBroker translated into ManaLoom runtime scope xmage_creature_dies_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sparring construct', 'Sparring Construct', 'b2cf73bf78e0e5a7cd750ad498f2773e', 'battle_rule_v1:dc6d9eeb7537ceb1ad4b8351b1af12d8', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"+1/+1","dies_add_counters":true,"dies_add_counters_count":1,"dies_add_counters_counter_type":"+1/+1","dies_add_counters_target":"creature","effect":"creature","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"self"},"target_controller":"self","trigger":"dies","trigger_effect":"add_counters","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SparringConstruct translated into ManaLoom runtime scope xmage_creature_dies_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('spinal centipede', 'Spinal Centipede', 'b2cf73bf78e0e5a7cd750ad498f2773e', 'battle_rule_v1:dc6d9eeb7537ceb1ad4b8351b1af12d8', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"+1/+1","dies_add_counters":true,"dies_add_counters_count":1,"dies_add_counters_counter_type":"+1/+1","dies_add_counters_target":"creature","effect":"creature","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"self"},"target_controller":"self","trigger":"dies","trigger_effect":"add_counters","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SpinalCentipede translated into ManaLoom runtime scope xmage_creature_dies_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('steadfast sentry', 'Steadfast Sentry', '5bd444489d885eeb73b0aec7c7f0609f', 'battle_rule_v1:741a080f18b880224c645da9fc305da1', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"+1/+1","dies_add_counters":true,"dies_add_counters_count":1,"dies_add_counters_counter_type":"+1/+1","dies_add_counters_target":"creature","effect":"creature","instant":false,"keywords":["vigilance"],"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"self"},"target_controller":"self","trigger":"dies","trigger_effect":"add_counters","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SteadfastSentry translated into ManaLoom runtime scope xmage_creature_dies_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('venerable knight', 'Venerable Knight', '27c7ab08136b9ceb9eca7963462af6c6', 'battle_rule_v1:44c3f8f7e38bf65029e832f0b8195111', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"+1/+1","dies_add_counters":true,"dies_add_counters_count":1,"dies_add_counters_counter_type":"+1/+1","dies_add_counters_target":"creature","effect":"creature","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"self","required_subtypes":["knight"]},"target_controller":"self","trigger":"dies","trigger_effect":"add_counters","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VenerableKnight translated into ManaLoom runtime scope xmage_creature_dies_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
),
deprecated AS (
  UPDATE public.card_battle_rules r
  SET
    review_status = 'deprecated',
    execution_status = 'disabled',
    updated_at = now(),
    notes = concat_ws(E'\n', nullif(r.notes, ''), 'XMage batch package: deprecated stale shadow before curated batch rule upsert.')
  FROM proposed p
  WHERE (
        r.normalized_name = p.normalized_name
        OR r.normalized_name LIKE p.normalized_name || ' // %'
      )
    AND p.shadow_handling <> 'preserve_existing_rows'
    AND r.logical_rule_key <> p.logical_rule_key
  RETURNING r.*
)
SELECT count(*) AS deprecated_shadow_rows FROM deprecated;

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('bile-vial boggart', 'Bile-Vial Boggart', '765f9a0c55872371d4e69b2dea91632d', 'battle_rule_v1:d99ef6cb26e7f6879ee8558b6b1f24c6', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"-1/-1","dies_add_counters":true,"dies_add_counters_count":1,"dies_add_counters_counter_type":"-1/-1","dies_add_counters_target":"creature","effect":"creature","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count_max":1,"target_count_min":0,"trigger":"dies","trigger_effect":"add_counters","up_to_count":true,"xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BileVialBoggart translated into ManaLoom runtime scope xmage_creature_dies_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('festering mummy', 'Festering Mummy', '9e47de100c190411c8e30156312a120c', 'battle_rule_v1:500f0abd244b5b94191c9b4ff1243b01', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"-1/-1","dies_add_counters":true,"dies_add_counters_count":1,"dies_add_counters_counter_type":"-1/-1","dies_add_counters_optional":true,"dies_add_counters_target":"creature","effect":"creature","instant":false,"optional":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","trigger":"dies","trigger_effect":"add_counters","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FesteringMummy translated into ManaLoom runtime scope xmage_creature_dies_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('goblin assault team', 'Goblin Assault Team', '599e24538eeab1caa1dea482843a1802', 'battle_rule_v1:fdc0ed4e42df19e95b8f2b81f30c3963', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"+1/+1","dies_add_counters":true,"dies_add_counters_count":1,"dies_add_counters_counter_type":"+1/+1","dies_add_counters_target":"creature","effect":"creature","instant":false,"keywords":["haste"],"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"self"},"target_controller":"self","trigger":"dies","trigger_effect":"add_counters","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GoblinAssaultTeam translated into ManaLoom runtime scope xmage_creature_dies_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('guul draz mucklord', 'Guul Draz Mucklord', 'b2cf73bf78e0e5a7cd750ad498f2773e', 'battle_rule_v1:dc6d9eeb7537ceb1ad4b8351b1af12d8', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"+1/+1","dies_add_counters":true,"dies_add_counters_count":1,"dies_add_counters_counter_type":"+1/+1","dies_add_counters_target":"creature","effect":"creature","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"self"},"target_controller":"self","trigger":"dies","trigger_effect":"add_counters","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GuulDrazMucklord translated into ManaLoom runtime scope xmage_creature_dies_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lawless broker', 'Lawless Broker', 'b2cf73bf78e0e5a7cd750ad498f2773e', 'battle_rule_v1:dc6d9eeb7537ceb1ad4b8351b1af12d8', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"+1/+1","dies_add_counters":true,"dies_add_counters_count":1,"dies_add_counters_counter_type":"+1/+1","dies_add_counters_target":"creature","effect":"creature","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"self"},"target_controller":"self","trigger":"dies","trigger_effect":"add_counters","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LawlessBroker translated into ManaLoom runtime scope xmage_creature_dies_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sparring construct', 'Sparring Construct', 'b2cf73bf78e0e5a7cd750ad498f2773e', 'battle_rule_v1:dc6d9eeb7537ceb1ad4b8351b1af12d8', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"+1/+1","dies_add_counters":true,"dies_add_counters_count":1,"dies_add_counters_counter_type":"+1/+1","dies_add_counters_target":"creature","effect":"creature","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"self"},"target_controller":"self","trigger":"dies","trigger_effect":"add_counters","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SparringConstruct translated into ManaLoom runtime scope xmage_creature_dies_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('spinal centipede', 'Spinal Centipede', 'b2cf73bf78e0e5a7cd750ad498f2773e', 'battle_rule_v1:dc6d9eeb7537ceb1ad4b8351b1af12d8', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"+1/+1","dies_add_counters":true,"dies_add_counters_count":1,"dies_add_counters_counter_type":"+1/+1","dies_add_counters_target":"creature","effect":"creature","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"self"},"target_controller":"self","trigger":"dies","trigger_effect":"add_counters","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SpinalCentipede translated into ManaLoom runtime scope xmage_creature_dies_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('steadfast sentry', 'Steadfast Sentry', '5bd444489d885eeb73b0aec7c7f0609f', 'battle_rule_v1:741a080f18b880224c645da9fc305da1', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"+1/+1","dies_add_counters":true,"dies_add_counters_count":1,"dies_add_counters_counter_type":"+1/+1","dies_add_counters_target":"creature","effect":"creature","instant":false,"keywords":["vigilance"],"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"self"},"target_controller":"self","trigger":"dies","trigger_effect":"add_counters","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SteadfastSentry translated into ManaLoom runtime scope xmage_creature_dies_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('venerable knight', 'Venerable Knight', '27c7ab08136b9ceb9eca7963462af6c6', 'battle_rule_v1:44c3f8f7e38bf65029e832f0b8195111', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"+1/+1","dies_add_counters":true,"dies_add_counters_count":1,"dies_add_counters_counter_type":"+1/+1","dies_add_counters_target":"creature","effect":"creature","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"self","required_subtypes":["knight"]},"target_controller":"self","trigger":"dies","trigger_effect":"add_counters","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VenerableKnight translated into ManaLoom runtime scope xmage_creature_dies_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
),
matched_cards AS (
  SELECT
    p.normalized_name,
    p.card_name,
    p.oracle_hash,
    c.id AS card_id,
    c.name AS db_card_name
  FROM proposed p
  JOIN public.cards c
    ON (
         lower(c.name) = p.normalized_name
         OR split_part(lower(c.name), ' // ', 1) = p.normalized_name
       )
   AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
),
canonical_target_cards AS (
  SELECT
    p.*,
    min(m.card_id::text)::uuid AS card_id,
    min(m.db_card_name) AS db_card_name
  FROM proposed p
  JOIN matched_cards m
    USING (normalized_name, card_name, oracle_hash)
  GROUP BY
    p.normalized_name,
    p.card_name,
    p.oracle_hash,
    p.logical_rule_key,
    p.effect_json,
    p.deck_role_json,
    p.source,
    p.confidence,
    p.review_status,
    p.execution_status,
    p.notes,
    p.shadow_handling
),
upserted AS (
  INSERT INTO public.card_battle_rules (
    normalized_name,
    card_id,
    card_name,
    effect_json,
    deck_role_json,
    source,
    confidence,
    review_status,
    rule_version,
    oracle_hash,
    notes,
    reviewed_by,
    reviewed_at,
    created_at,
    updated_at,
    last_seen_at,
    logical_rule_key,
    execution_status
  )
  SELECT
    normalized_name,
    card_id,
    db_card_name,
    effect_json,
    deck_role_json,
    source,
    confidence,
    review_status,
    2,
    oracle_hash,
    notes,
    'codex-xmage-batch',
    now(),
    now(),
    now(),
    now(),
    logical_rule_key,
    execution_status
  FROM canonical_target_cards
  ON CONFLICT (normalized_name, logical_rule_key) DO UPDATE
  SET
    card_id = EXCLUDED.card_id,
    card_name = EXCLUDED.card_name,
    effect_json = EXCLUDED.effect_json,
    deck_role_json = EXCLUDED.deck_role_json,
    source = EXCLUDED.source,
    confidence = EXCLUDED.confidence,
    review_status = EXCLUDED.review_status,
    rule_version = EXCLUDED.rule_version,
    oracle_hash = EXCLUDED.oracle_hash,
    notes = EXCLUDED.notes,
    reviewed_by = EXCLUDED.reviewed_by,
    reviewed_at = EXCLUDED.reviewed_at,
    updated_at = EXCLUDED.updated_at,
    last_seen_at = EXCLUDED.last_seen_at,
    execution_status = EXCLUDED.execution_status
  RETURNING *
)
SELECT count(*) AS upserted_rows FROM upserted;

COMMIT;
