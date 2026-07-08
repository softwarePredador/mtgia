BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg657_target_player_discard_triggers_new_20260708_132140 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('abyssal horror', 'black cat', 'blazing specter', 'brutal nightstalker', 'corrupt court official', 'deadbridge shaman', 'ebon dragon', 'ravenous rats', 'rottenheart ghoul', 'sanity gnawers')
   OR normalized_name LIKE 'abyssal horror // %'
   OR normalized_name LIKE 'black cat // %'
   OR normalized_name LIKE 'blazing specter // %'
   OR normalized_name LIKE 'brutal nightstalker // %'
   OR normalized_name LIKE 'corrupt court official // %'
   OR normalized_name LIKE 'deadbridge shaman // %'
   OR normalized_name LIKE 'ebon dragon // %'
   OR normalized_name LIKE 'ravenous rats // %'
   OR normalized_name LIKE 'rottenheart ghoul // %'
   OR normalized_name LIKE 'sanity gnawers // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('abyssal horror', 'Abyssal Horror', 'c16d9923d5aaca37e0c078e0f7e03088', 'battle_rule_v1:72fbea20c61c5a8664a823621e059d20', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_target_player_discard_v1","count":2,"discard_count":2,"discard_random":false,"effect":"creature","etb_discard_count":2,"etb_target_player_discard":true,"flying":true,"keywords":["flying"],"target_controller":"target_player","target_preference":"opponent","trigger":"enters_battlefield","trigger_effect":"target_player_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DiscardTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AbyssalHorror translated into ManaLoom runtime scope xmage_creature_etb_target_player_discard_v1. This row is package-ready only because the source signature is a narrow creature ETB triggered fixed target-player discard ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('black cat', 'Black Cat', '3f5e18e014e342645d0ecab60381cd04', 'battle_rule_v1:7f3271cd03557e2e025752643fcc9e33', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_target_player_discard_v1","count":1,"dies_discard_count":1,"dies_target_player_discard":true,"dies_trigger_effect":"target_player_discard","discard_count":1,"discard_random":true,"effect":"creature","target_controller":"target_opponent","target_preference":"opponent","trigger":"dies","trigger_effect":"target_player_discard","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DiscardTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BlackCat translated into ManaLoom runtime scope xmage_creature_dies_target_player_discard_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed target-player discard ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('blazing specter', 'Blazing Specter', 'fc0e7f6b3eb9fdd8f1382bd96476288a', 'battle_rule_v1:e1ef63a3c253e0ab1ad7e0018aec5521', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_combat_damage_target_player_discard_v1","combat_damage_discard_count":1,"combat_damage_player_discard":true,"count":1,"discard_count":1,"discard_random":false,"effect":"creature","flying":true,"haste":true,"keywords":["flying","haste"],"target_controller":"damaged_player","target_preference":"damaged_player","trigger":"combat_damage_to_player","trigger_effect":"target_player_discard","xmage_ability_class":"DealsCombatDamageToAPlayerTriggeredAbility","xmage_effect_class":"DiscardTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BlazingSpecter translated into ManaLoom runtime scope xmage_creature_combat_damage_target_player_discard_v1. This row is package-ready only because the source signature is a narrow creature combat-damage-to-player triggered fixed target-player discard ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('brutal nightstalker', 'Brutal Nightstalker', '2acfdd0ee96e113f65be9776e38a634b', 'battle_rule_v1:f020303c69f642760ad3ccf2150bf201', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_target_player_discard_v1","count":1,"discard_count":1,"discard_random":false,"effect":"creature","etb_discard_count":1,"etb_target_player_discard":true,"etb_target_player_discard_optional":true,"target_controller":"target_opponent","target_preference":"opponent","trigger":"enters_battlefield","trigger_effect":"target_player_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DiscardTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BrutalNightstalker translated into ManaLoom runtime scope xmage_creature_etb_target_player_discard_v1. This row is package-ready only because the source signature is a narrow creature ETB triggered fixed target-player discard ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('corrupt court official', 'Corrupt Court Official', '81b939ee0dc1fab11ffa9fe87d968fa2', 'battle_rule_v1:740765619169a04218ec484157e99989', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_target_player_discard_v1","count":1,"discard_count":1,"discard_random":false,"effect":"creature","etb_discard_count":1,"etb_target_player_discard":true,"target_controller":"target_opponent","target_preference":"opponent","trigger":"enters_battlefield","trigger_effect":"target_player_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DiscardTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CorruptCourtOfficial translated into ManaLoom runtime scope xmage_creature_etb_target_player_discard_v1. This row is package-ready only because the source signature is a narrow creature ETB triggered fixed target-player discard ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('deadbridge shaman', 'Deadbridge Shaman', 'a4bca977852f242f1722064feb2a9136', 'battle_rule_v1:b2125674b1aac8fd6dfafb74ed17c280', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_target_player_discard_v1","count":1,"dies_discard_count":1,"dies_target_player_discard":true,"dies_trigger_effect":"target_player_discard","discard_count":1,"discard_random":false,"effect":"creature","target_controller":"target_opponent","target_preference":"opponent","trigger":"dies","trigger_effect":"target_player_discard","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DiscardTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DeadbridgeShaman translated into ManaLoom runtime scope xmage_creature_dies_target_player_discard_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed target-player discard ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ebon dragon', 'Ebon Dragon', 'cfdf197c4f1722f3cef0fa5629380a0a', 'battle_rule_v1:7395367c4e0ccb1eb281ee5422476a18', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_target_player_discard_v1","count":1,"discard_count":1,"discard_random":false,"effect":"creature","etb_discard_count":1,"etb_target_player_discard":true,"etb_target_player_discard_optional":true,"flying":true,"keywords":["flying"],"target_controller":"target_opponent","target_preference":"opponent","trigger":"enters_battlefield","trigger_effect":"target_player_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DiscardTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EbonDragon translated into ManaLoom runtime scope xmage_creature_etb_target_player_discard_v1. This row is package-ready only because the source signature is a narrow creature ETB triggered fixed target-player discard ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ravenous rats', 'Ravenous Rats', '81b939ee0dc1fab11ffa9fe87d968fa2', 'battle_rule_v1:740765619169a04218ec484157e99989', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_target_player_discard_v1","count":1,"discard_count":1,"discard_random":false,"effect":"creature","etb_discard_count":1,"etb_target_player_discard":true,"target_controller":"target_opponent","target_preference":"opponent","trigger":"enters_battlefield","trigger_effect":"target_player_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DiscardTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RavenousRats translated into ManaLoom runtime scope xmage_creature_etb_target_player_discard_v1. This row is package-ready only because the source signature is a narrow creature ETB triggered fixed target-player discard ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rottenheart ghoul', 'Rottenheart Ghoul', 'f7ee9f344b38cbc4f158356352435147', 'battle_rule_v1:985b466d11034468e56d8bfe14712e94', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_target_player_discard_v1","count":1,"dies_discard_count":1,"dies_target_player_discard":true,"dies_trigger_effect":"target_player_discard","discard_count":1,"discard_random":false,"effect":"creature","target_controller":"target_player","target_preference":"opponent","trigger":"dies","trigger_effect":"target_player_discard","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DiscardTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RottenheartGhoul translated into ManaLoom runtime scope xmage_creature_dies_target_player_discard_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed target-player discard ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sanity gnawers', 'Sanity Gnawers', '6830e7df5723c4f0186d529081602cdb', 'battle_rule_v1:87b9ea000e05ba185ab812cf3f9304b4', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_target_player_discard_v1","count":1,"discard_count":1,"discard_random":true,"effect":"creature","etb_discard_count":1,"etb_target_player_discard":true,"target_controller":"target_player","target_preference":"opponent","trigger":"enters_battlefield","trigger_effect":"target_player_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DiscardTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SanityGnawers translated into ManaLoom runtime scope xmage_creature_etb_target_player_discard_v1. This row is package-ready only because the source signature is a narrow creature ETB triggered fixed target-player discard ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('abyssal horror', 'Abyssal Horror', 'c16d9923d5aaca37e0c078e0f7e03088', 'battle_rule_v1:72fbea20c61c5a8664a823621e059d20', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_target_player_discard_v1","count":2,"discard_count":2,"discard_random":false,"effect":"creature","etb_discard_count":2,"etb_target_player_discard":true,"flying":true,"keywords":["flying"],"target_controller":"target_player","target_preference":"opponent","trigger":"enters_battlefield","trigger_effect":"target_player_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DiscardTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AbyssalHorror translated into ManaLoom runtime scope xmage_creature_etb_target_player_discard_v1. This row is package-ready only because the source signature is a narrow creature ETB triggered fixed target-player discard ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('black cat', 'Black Cat', '3f5e18e014e342645d0ecab60381cd04', 'battle_rule_v1:7f3271cd03557e2e025752643fcc9e33', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_target_player_discard_v1","count":1,"dies_discard_count":1,"dies_target_player_discard":true,"dies_trigger_effect":"target_player_discard","discard_count":1,"discard_random":true,"effect":"creature","target_controller":"target_opponent","target_preference":"opponent","trigger":"dies","trigger_effect":"target_player_discard","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DiscardTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BlackCat translated into ManaLoom runtime scope xmage_creature_dies_target_player_discard_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed target-player discard ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('blazing specter', 'Blazing Specter', 'fc0e7f6b3eb9fdd8f1382bd96476288a', 'battle_rule_v1:e1ef63a3c253e0ab1ad7e0018aec5521', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_combat_damage_target_player_discard_v1","combat_damage_discard_count":1,"combat_damage_player_discard":true,"count":1,"discard_count":1,"discard_random":false,"effect":"creature","flying":true,"haste":true,"keywords":["flying","haste"],"target_controller":"damaged_player","target_preference":"damaged_player","trigger":"combat_damage_to_player","trigger_effect":"target_player_discard","xmage_ability_class":"DealsCombatDamageToAPlayerTriggeredAbility","xmage_effect_class":"DiscardTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BlazingSpecter translated into ManaLoom runtime scope xmage_creature_combat_damage_target_player_discard_v1. This row is package-ready only because the source signature is a narrow creature combat-damage-to-player triggered fixed target-player discard ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('brutal nightstalker', 'Brutal Nightstalker', '2acfdd0ee96e113f65be9776e38a634b', 'battle_rule_v1:f020303c69f642760ad3ccf2150bf201', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_target_player_discard_v1","count":1,"discard_count":1,"discard_random":false,"effect":"creature","etb_discard_count":1,"etb_target_player_discard":true,"etb_target_player_discard_optional":true,"target_controller":"target_opponent","target_preference":"opponent","trigger":"enters_battlefield","trigger_effect":"target_player_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DiscardTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BrutalNightstalker translated into ManaLoom runtime scope xmage_creature_etb_target_player_discard_v1. This row is package-ready only because the source signature is a narrow creature ETB triggered fixed target-player discard ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('corrupt court official', 'Corrupt Court Official', '81b939ee0dc1fab11ffa9fe87d968fa2', 'battle_rule_v1:740765619169a04218ec484157e99989', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_target_player_discard_v1","count":1,"discard_count":1,"discard_random":false,"effect":"creature","etb_discard_count":1,"etb_target_player_discard":true,"target_controller":"target_opponent","target_preference":"opponent","trigger":"enters_battlefield","trigger_effect":"target_player_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DiscardTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CorruptCourtOfficial translated into ManaLoom runtime scope xmage_creature_etb_target_player_discard_v1. This row is package-ready only because the source signature is a narrow creature ETB triggered fixed target-player discard ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('deadbridge shaman', 'Deadbridge Shaman', 'a4bca977852f242f1722064feb2a9136', 'battle_rule_v1:b2125674b1aac8fd6dfafb74ed17c280', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_target_player_discard_v1","count":1,"dies_discard_count":1,"dies_target_player_discard":true,"dies_trigger_effect":"target_player_discard","discard_count":1,"discard_random":false,"effect":"creature","target_controller":"target_opponent","target_preference":"opponent","trigger":"dies","trigger_effect":"target_player_discard","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DiscardTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DeadbridgeShaman translated into ManaLoom runtime scope xmage_creature_dies_target_player_discard_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed target-player discard ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ebon dragon', 'Ebon Dragon', 'cfdf197c4f1722f3cef0fa5629380a0a', 'battle_rule_v1:7395367c4e0ccb1eb281ee5422476a18', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_target_player_discard_v1","count":1,"discard_count":1,"discard_random":false,"effect":"creature","etb_discard_count":1,"etb_target_player_discard":true,"etb_target_player_discard_optional":true,"flying":true,"keywords":["flying"],"target_controller":"target_opponent","target_preference":"opponent","trigger":"enters_battlefield","trigger_effect":"target_player_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DiscardTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EbonDragon translated into ManaLoom runtime scope xmage_creature_etb_target_player_discard_v1. This row is package-ready only because the source signature is a narrow creature ETB triggered fixed target-player discard ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ravenous rats', 'Ravenous Rats', '81b939ee0dc1fab11ffa9fe87d968fa2', 'battle_rule_v1:740765619169a04218ec484157e99989', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_target_player_discard_v1","count":1,"discard_count":1,"discard_random":false,"effect":"creature","etb_discard_count":1,"etb_target_player_discard":true,"target_controller":"target_opponent","target_preference":"opponent","trigger":"enters_battlefield","trigger_effect":"target_player_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DiscardTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RavenousRats translated into ManaLoom runtime scope xmage_creature_etb_target_player_discard_v1. This row is package-ready only because the source signature is a narrow creature ETB triggered fixed target-player discard ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rottenheart ghoul', 'Rottenheart Ghoul', 'f7ee9f344b38cbc4f158356352435147', 'battle_rule_v1:985b466d11034468e56d8bfe14712e94', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_target_player_discard_v1","count":1,"dies_discard_count":1,"dies_target_player_discard":true,"dies_trigger_effect":"target_player_discard","discard_count":1,"discard_random":false,"effect":"creature","target_controller":"target_player","target_preference":"opponent","trigger":"dies","trigger_effect":"target_player_discard","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DiscardTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RottenheartGhoul translated into ManaLoom runtime scope xmage_creature_dies_target_player_discard_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed target-player discard ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sanity gnawers', 'Sanity Gnawers', '6830e7df5723c4f0186d529081602cdb', 'battle_rule_v1:87b9ea000e05ba185ab812cf3f9304b4', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_target_player_discard_v1","count":1,"discard_count":1,"discard_random":true,"effect":"creature","etb_discard_count":1,"etb_target_player_discard":true,"target_controller":"target_player","target_preference":"opponent","trigger":"enters_battlefield","trigger_effect":"target_player_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DiscardTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SanityGnawers translated into ManaLoom runtime scope xmage_creature_etb_target_player_discard_v1. This row is package-ready only because the source signature is a narrow creature ETB triggered fixed target-player discard ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('abyssal horror', 'Abyssal Horror', 'c16d9923d5aaca37e0c078e0f7e03088', 'battle_rule_v1:72fbea20c61c5a8664a823621e059d20', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_target_player_discard_v1","count":2,"discard_count":2,"discard_random":false,"effect":"creature","etb_discard_count":2,"etb_target_player_discard":true,"flying":true,"keywords":["flying"],"target_controller":"target_player","target_preference":"opponent","trigger":"enters_battlefield","trigger_effect":"target_player_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DiscardTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AbyssalHorror translated into ManaLoom runtime scope xmage_creature_etb_target_player_discard_v1. This row is package-ready only because the source signature is a narrow creature ETB triggered fixed target-player discard ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('black cat', 'Black Cat', '3f5e18e014e342645d0ecab60381cd04', 'battle_rule_v1:7f3271cd03557e2e025752643fcc9e33', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_target_player_discard_v1","count":1,"dies_discard_count":1,"dies_target_player_discard":true,"dies_trigger_effect":"target_player_discard","discard_count":1,"discard_random":true,"effect":"creature","target_controller":"target_opponent","target_preference":"opponent","trigger":"dies","trigger_effect":"target_player_discard","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DiscardTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BlackCat translated into ManaLoom runtime scope xmage_creature_dies_target_player_discard_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed target-player discard ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('blazing specter', 'Blazing Specter', 'fc0e7f6b3eb9fdd8f1382bd96476288a', 'battle_rule_v1:e1ef63a3c253e0ab1ad7e0018aec5521', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_combat_damage_target_player_discard_v1","combat_damage_discard_count":1,"combat_damage_player_discard":true,"count":1,"discard_count":1,"discard_random":false,"effect":"creature","flying":true,"haste":true,"keywords":["flying","haste"],"target_controller":"damaged_player","target_preference":"damaged_player","trigger":"combat_damage_to_player","trigger_effect":"target_player_discard","xmage_ability_class":"DealsCombatDamageToAPlayerTriggeredAbility","xmage_effect_class":"DiscardTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BlazingSpecter translated into ManaLoom runtime scope xmage_creature_combat_damage_target_player_discard_v1. This row is package-ready only because the source signature is a narrow creature combat-damage-to-player triggered fixed target-player discard ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('brutal nightstalker', 'Brutal Nightstalker', '2acfdd0ee96e113f65be9776e38a634b', 'battle_rule_v1:f020303c69f642760ad3ccf2150bf201', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_target_player_discard_v1","count":1,"discard_count":1,"discard_random":false,"effect":"creature","etb_discard_count":1,"etb_target_player_discard":true,"etb_target_player_discard_optional":true,"target_controller":"target_opponent","target_preference":"opponent","trigger":"enters_battlefield","trigger_effect":"target_player_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DiscardTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BrutalNightstalker translated into ManaLoom runtime scope xmage_creature_etb_target_player_discard_v1. This row is package-ready only because the source signature is a narrow creature ETB triggered fixed target-player discard ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('corrupt court official', 'Corrupt Court Official', '81b939ee0dc1fab11ffa9fe87d968fa2', 'battle_rule_v1:740765619169a04218ec484157e99989', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_target_player_discard_v1","count":1,"discard_count":1,"discard_random":false,"effect":"creature","etb_discard_count":1,"etb_target_player_discard":true,"target_controller":"target_opponent","target_preference":"opponent","trigger":"enters_battlefield","trigger_effect":"target_player_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DiscardTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CorruptCourtOfficial translated into ManaLoom runtime scope xmage_creature_etb_target_player_discard_v1. This row is package-ready only because the source signature is a narrow creature ETB triggered fixed target-player discard ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('deadbridge shaman', 'Deadbridge Shaman', 'a4bca977852f242f1722064feb2a9136', 'battle_rule_v1:b2125674b1aac8fd6dfafb74ed17c280', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_target_player_discard_v1","count":1,"dies_discard_count":1,"dies_target_player_discard":true,"dies_trigger_effect":"target_player_discard","discard_count":1,"discard_random":false,"effect":"creature","target_controller":"target_opponent","target_preference":"opponent","trigger":"dies","trigger_effect":"target_player_discard","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DiscardTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DeadbridgeShaman translated into ManaLoom runtime scope xmage_creature_dies_target_player_discard_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed target-player discard ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ebon dragon', 'Ebon Dragon', 'cfdf197c4f1722f3cef0fa5629380a0a', 'battle_rule_v1:7395367c4e0ccb1eb281ee5422476a18', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_target_player_discard_v1","count":1,"discard_count":1,"discard_random":false,"effect":"creature","etb_discard_count":1,"etb_target_player_discard":true,"etb_target_player_discard_optional":true,"flying":true,"keywords":["flying"],"target_controller":"target_opponent","target_preference":"opponent","trigger":"enters_battlefield","trigger_effect":"target_player_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DiscardTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EbonDragon translated into ManaLoom runtime scope xmage_creature_etb_target_player_discard_v1. This row is package-ready only because the source signature is a narrow creature ETB triggered fixed target-player discard ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ravenous rats', 'Ravenous Rats', '81b939ee0dc1fab11ffa9fe87d968fa2', 'battle_rule_v1:740765619169a04218ec484157e99989', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_target_player_discard_v1","count":1,"discard_count":1,"discard_random":false,"effect":"creature","etb_discard_count":1,"etb_target_player_discard":true,"target_controller":"target_opponent","target_preference":"opponent","trigger":"enters_battlefield","trigger_effect":"target_player_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DiscardTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RavenousRats translated into ManaLoom runtime scope xmage_creature_etb_target_player_discard_v1. This row is package-ready only because the source signature is a narrow creature ETB triggered fixed target-player discard ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rottenheart ghoul', 'Rottenheart Ghoul', 'f7ee9f344b38cbc4f158356352435147', 'battle_rule_v1:985b466d11034468e56d8bfe14712e94', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_target_player_discard_v1","count":1,"dies_discard_count":1,"dies_target_player_discard":true,"dies_trigger_effect":"target_player_discard","discard_count":1,"discard_random":false,"effect":"creature","target_controller":"target_player","target_preference":"opponent","trigger":"dies","trigger_effect":"target_player_discard","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DiscardTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RottenheartGhoul translated into ManaLoom runtime scope xmage_creature_dies_target_player_discard_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed target-player discard ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sanity gnawers', 'Sanity Gnawers', '6830e7df5723c4f0186d529081602cdb', 'battle_rule_v1:87b9ea000e05ba185ab812cf3f9304b4', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_target_player_discard_v1","count":1,"discard_count":1,"discard_random":true,"effect":"creature","etb_discard_count":1,"etb_target_player_discard":true,"target_controller":"target_player","target_preference":"opponent","trigger":"enters_battlefield","trigger_effect":"target_player_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DiscardTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SanityGnawers translated into ManaLoom runtime scope xmage_creature_etb_target_player_discard_v1. This row is package-ready only because the source signature is a narrow creature ETB triggered fixed target-player discard ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
