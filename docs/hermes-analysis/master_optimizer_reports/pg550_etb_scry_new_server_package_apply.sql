BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg550_etb_scry_new_server_etb_scry_new_s_20260706_044550 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('automatic librarian', 'chrome cat', 'galadhrim guide', 'lost legion', 'octoprophet', 'omenspeaker', 'prophet of the peak', 'rumbling sentry', 'sage''s row savant')
   OR normalized_name LIKE 'automatic librarian // %'
   OR normalized_name LIKE 'chrome cat // %'
   OR normalized_name LIKE 'galadhrim guide // %'
   OR normalized_name LIKE 'lost legion // %'
   OR normalized_name LIKE 'octoprophet // %'
   OR normalized_name LIKE 'omenspeaker // %'
   OR normalized_name LIKE 'prophet of the peak // %'
   OR normalized_name LIKE 'rumbling sentry // %'
   OR normalized_name LIKE 'sage''s row savant // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('automatic librarian', 'Automatic Librarian', '91b6e9b9d7a202215da5ac166ffca6c2', 'battle_rule_v1:ca42913baa856009e5da562479d1a4e1', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":2,"etb_trigger_effect":"scry","scry_count":2,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":2,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AutomaticLibrarian translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('chrome cat', 'Chrome Cat', '17bde51cf2fc1eb8f0bbbdff2363c864', 'battle_rule_v1:0a639e63e1f6566d56a772ef264e2bb8', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":1,"etb_trigger_effect":"scry","scry_count":1,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":1,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ChromeCat translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('galadhrim guide', 'Galadhrim Guide', '065b614b72df33d771426db0ab60e75d', 'battle_rule_v1:ca42913baa856009e5da562479d1a4e1', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":2,"etb_trigger_effect":"scry","scry_count":2,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":2,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GaladhrimGuide translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lost legion', 'Lost Legion', '91b6e9b9d7a202215da5ac166ffca6c2', 'battle_rule_v1:ca42913baa856009e5da562479d1a4e1', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":2,"etb_trigger_effect":"scry","scry_count":2,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":2,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LostLegion translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('octoprophet', 'Octoprophet', '91b6e9b9d7a202215da5ac166ffca6c2', 'battle_rule_v1:ca42913baa856009e5da562479d1a4e1', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":2,"etb_trigger_effect":"scry","scry_count":2,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":2,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Octoprophet translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('omenspeaker', 'Omenspeaker', '91b6e9b9d7a202215da5ac166ffca6c2', 'battle_rule_v1:ca42913baa856009e5da562479d1a4e1', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":2,"etb_trigger_effect":"scry","scry_count":2,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":2,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Omenspeaker translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('prophet of the peak', 'Prophet of the Peak', '91b6e9b9d7a202215da5ac166ffca6c2', 'battle_rule_v1:ca42913baa856009e5da562479d1a4e1', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":2,"etb_trigger_effect":"scry","scry_count":2,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":2,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ProphetOfThePeak translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rumbling sentry', 'Rumbling Sentry', '17bde51cf2fc1eb8f0bbbdff2363c864', 'battle_rule_v1:0a639e63e1f6566d56a772ef264e2bb8', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":1,"etb_trigger_effect":"scry","scry_count":1,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":1,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RumblingSentry translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sage''s row savant', 'Sage''s Row Savant', '065b614b72df33d771426db0ab60e75d', 'battle_rule_v1:ca42913baa856009e5da562479d1a4e1', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":2,"etb_trigger_effect":"scry","scry_count":2,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":2,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SagesRowSavant translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('automatic librarian', 'Automatic Librarian', '91b6e9b9d7a202215da5ac166ffca6c2', 'battle_rule_v1:ca42913baa856009e5da562479d1a4e1', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":2,"etb_trigger_effect":"scry","scry_count":2,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":2,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AutomaticLibrarian translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('chrome cat', 'Chrome Cat', '17bde51cf2fc1eb8f0bbbdff2363c864', 'battle_rule_v1:0a639e63e1f6566d56a772ef264e2bb8', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":1,"etb_trigger_effect":"scry","scry_count":1,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":1,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ChromeCat translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('galadhrim guide', 'Galadhrim Guide', '065b614b72df33d771426db0ab60e75d', 'battle_rule_v1:ca42913baa856009e5da562479d1a4e1', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":2,"etb_trigger_effect":"scry","scry_count":2,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":2,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GaladhrimGuide translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lost legion', 'Lost Legion', '91b6e9b9d7a202215da5ac166ffca6c2', 'battle_rule_v1:ca42913baa856009e5da562479d1a4e1', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":2,"etb_trigger_effect":"scry","scry_count":2,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":2,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LostLegion translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('octoprophet', 'Octoprophet', '91b6e9b9d7a202215da5ac166ffca6c2', 'battle_rule_v1:ca42913baa856009e5da562479d1a4e1', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":2,"etb_trigger_effect":"scry","scry_count":2,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":2,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Octoprophet translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('omenspeaker', 'Omenspeaker', '91b6e9b9d7a202215da5ac166ffca6c2', 'battle_rule_v1:ca42913baa856009e5da562479d1a4e1', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":2,"etb_trigger_effect":"scry","scry_count":2,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":2,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Omenspeaker translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('prophet of the peak', 'Prophet of the Peak', '91b6e9b9d7a202215da5ac166ffca6c2', 'battle_rule_v1:ca42913baa856009e5da562479d1a4e1', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":2,"etb_trigger_effect":"scry","scry_count":2,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":2,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ProphetOfThePeak translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rumbling sentry', 'Rumbling Sentry', '17bde51cf2fc1eb8f0bbbdff2363c864', 'battle_rule_v1:0a639e63e1f6566d56a772ef264e2bb8', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":1,"etb_trigger_effect":"scry","scry_count":1,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":1,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RumblingSentry translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sage''s row savant', 'Sage''s Row Savant', '065b614b72df33d771426db0ab60e75d', 'battle_rule_v1:ca42913baa856009e5da562479d1a4e1', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":2,"etb_trigger_effect":"scry","scry_count":2,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":2,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SagesRowSavant translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('automatic librarian', 'Automatic Librarian', '91b6e9b9d7a202215da5ac166ffca6c2', 'battle_rule_v1:ca42913baa856009e5da562479d1a4e1', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":2,"etb_trigger_effect":"scry","scry_count":2,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":2,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AutomaticLibrarian translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('chrome cat', 'Chrome Cat', '17bde51cf2fc1eb8f0bbbdff2363c864', 'battle_rule_v1:0a639e63e1f6566d56a772ef264e2bb8', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":1,"etb_trigger_effect":"scry","scry_count":1,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":1,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ChromeCat translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('galadhrim guide', 'Galadhrim Guide', '065b614b72df33d771426db0ab60e75d', 'battle_rule_v1:ca42913baa856009e5da562479d1a4e1', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":2,"etb_trigger_effect":"scry","scry_count":2,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":2,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GaladhrimGuide translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lost legion', 'Lost Legion', '91b6e9b9d7a202215da5ac166ffca6c2', 'battle_rule_v1:ca42913baa856009e5da562479d1a4e1', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":2,"etb_trigger_effect":"scry","scry_count":2,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":2,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LostLegion translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('octoprophet', 'Octoprophet', '91b6e9b9d7a202215da5ac166ffca6c2', 'battle_rule_v1:ca42913baa856009e5da562479d1a4e1', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":2,"etb_trigger_effect":"scry","scry_count":2,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":2,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Octoprophet translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('omenspeaker', 'Omenspeaker', '91b6e9b9d7a202215da5ac166ffca6c2', 'battle_rule_v1:ca42913baa856009e5da562479d1a4e1', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":2,"etb_trigger_effect":"scry","scry_count":2,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":2,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Omenspeaker translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('prophet of the peak', 'Prophet of the Peak', '91b6e9b9d7a202215da5ac166ffca6c2', 'battle_rule_v1:ca42913baa856009e5da562479d1a4e1', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":2,"etb_trigger_effect":"scry","scry_count":2,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":2,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ProphetOfThePeak translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rumbling sentry', 'Rumbling Sentry', '17bde51cf2fc1eb8f0bbbdff2363c864', 'battle_rule_v1:0a639e63e1f6566d56a772ef264e2bb8', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":1,"etb_trigger_effect":"scry","scry_count":1,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":1,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RumblingSentry translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sage''s row savant', 'Sage''s Row Savant', '065b614b72df33d771426db0ab60e75d', 'battle_rule_v1:ca42913baa856009e5da562479d1a4e1', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":2,"etb_trigger_effect":"scry","scry_count":2,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":2,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SagesRowSavant translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
