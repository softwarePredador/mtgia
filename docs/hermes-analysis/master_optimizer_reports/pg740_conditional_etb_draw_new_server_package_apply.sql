BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg740_conditional_etb_draw_new_server_20260711_041438 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('donatello, turtle techie', 'opal lake gatekeepers', 'resistance squad', 'rhox meditant', 'scholar of stars', 'settlement blacksmith')
   OR normalized_name LIKE 'donatello, turtle techie // %'
   OR normalized_name LIKE 'opal lake gatekeepers // %'
   OR normalized_name LIKE 'resistance squad // %'
   OR normalized_name LIKE 'rhox meditant // %'
   OR normalized_name LIKE 'scholar of stars // %'
   OR normalized_name LIKE 'settlement blacksmith // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('donatello, turtle techie', 'Donatello, Turtle Techie', 'eda48af85c5a2d0650124fee42bc6db7', 'battle_rule_v1:1aad34391a400d2e31b1d03c367eab8b', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_cards_v1","effect":"creature","etb_draw_condition":"controller_controls_matching_permanent","etb_draw_condition_card_types":["artifact"],"etb_draw_condition_min_count":1,"etb_draw_condition_status":"runtime_executor_v1","etb_draw_count":1,"trigger":"enters_battlefield","trigger_effect":"draw_cards","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DonatelloTurtleTechie translated into ManaLoom runtime scope xmage_creature_etb_draw_cards_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('opal lake gatekeepers', 'Opal Lake Gatekeepers', 'de09ec948a338bab499e6c6b39445b73', 'battle_rule_v1:2bb5212efd94973b17869d451eb3b392', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_cards_v1","effect":"creature","etb_draw_condition":"controller_controls_matching_permanent","etb_draw_condition_min_count":2,"etb_draw_condition_status":"runtime_executor_v1","etb_draw_condition_subtypes":["gate"],"etb_draw_count":1,"etb_draw_optional":true,"trigger":"enters_battlefield","trigger_effect":"draw_cards","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OpalLakeGatekeepers translated into ManaLoom runtime scope xmage_creature_etb_draw_cards_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('resistance squad', 'Resistance Squad', '8b3c1ca7c447f3805edf9378bc24ad85', 'battle_rule_v1:a0d576366fc549ff6443caf99a1da039', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_cards_v1","effect":"creature","etb_draw_condition":"controller_controls_matching_permanent","etb_draw_condition_exclude_source":true,"etb_draw_condition_min_count":1,"etb_draw_condition_status":"runtime_executor_v1","etb_draw_condition_subtypes":["human"],"etb_draw_count":1,"trigger":"enters_battlefield","trigger_effect":"draw_cards","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ResistanceSquad translated into ManaLoom runtime scope xmage_creature_etb_draw_cards_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rhox meditant', 'Rhox Meditant', '3cff932a1bf7c11de356754ab1633d37', 'battle_rule_v1:f0c2ed710efb1593ae4104b739f7dde9', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_cards_v1","effect":"creature","etb_draw_condition":"controller_controls_matching_permanent","etb_draw_condition_colors":["green"],"etb_draw_condition_min_count":1,"etb_draw_condition_status":"runtime_executor_v1","etb_draw_count":1,"trigger":"enters_battlefield","trigger_effect":"draw_cards","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RhoxMeditant translated into ManaLoom runtime scope xmage_creature_etb_draw_cards_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('scholar of stars', 'Scholar of Stars', 'aaa80647de08038783b0262987df6cd6', 'battle_rule_v1:1aad34391a400d2e31b1d03c367eab8b', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_cards_v1","effect":"creature","etb_draw_condition":"controller_controls_matching_permanent","etb_draw_condition_card_types":["artifact"],"etb_draw_condition_min_count":1,"etb_draw_condition_status":"runtime_executor_v1","etb_draw_count":1,"trigger":"enters_battlefield","trigger_effect":"draw_cards","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ScholarOfStars translated into ManaLoom runtime scope xmage_creature_etb_draw_cards_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('settlement blacksmith', 'Settlement Blacksmith', 'c1650f7bacfb0f78846e1cffce33d7e8', 'battle_rule_v1:e1dbd39a50c39509f45c6daa06064062', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_cards_v1","effect":"creature","etb_draw_condition":"controller_controls_matching_permanent","etb_draw_condition_min_count":1,"etb_draw_condition_status":"runtime_executor_v1","etb_draw_condition_subtypes":["equipment"],"etb_draw_count":1,"trigger":"enters_battlefield","trigger_effect":"draw_cards","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SettlementBlacksmith translated into ManaLoom runtime scope xmage_creature_etb_draw_cards_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('donatello, turtle techie', 'Donatello, Turtle Techie', 'eda48af85c5a2d0650124fee42bc6db7', 'battle_rule_v1:1aad34391a400d2e31b1d03c367eab8b', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_cards_v1","effect":"creature","etb_draw_condition":"controller_controls_matching_permanent","etb_draw_condition_card_types":["artifact"],"etb_draw_condition_min_count":1,"etb_draw_condition_status":"runtime_executor_v1","etb_draw_count":1,"trigger":"enters_battlefield","trigger_effect":"draw_cards","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DonatelloTurtleTechie translated into ManaLoom runtime scope xmage_creature_etb_draw_cards_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('opal lake gatekeepers', 'Opal Lake Gatekeepers', 'de09ec948a338bab499e6c6b39445b73', 'battle_rule_v1:2bb5212efd94973b17869d451eb3b392', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_cards_v1","effect":"creature","etb_draw_condition":"controller_controls_matching_permanent","etb_draw_condition_min_count":2,"etb_draw_condition_status":"runtime_executor_v1","etb_draw_condition_subtypes":["gate"],"etb_draw_count":1,"etb_draw_optional":true,"trigger":"enters_battlefield","trigger_effect":"draw_cards","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OpalLakeGatekeepers translated into ManaLoom runtime scope xmage_creature_etb_draw_cards_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('resistance squad', 'Resistance Squad', '8b3c1ca7c447f3805edf9378bc24ad85', 'battle_rule_v1:a0d576366fc549ff6443caf99a1da039', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_cards_v1","effect":"creature","etb_draw_condition":"controller_controls_matching_permanent","etb_draw_condition_exclude_source":true,"etb_draw_condition_min_count":1,"etb_draw_condition_status":"runtime_executor_v1","etb_draw_condition_subtypes":["human"],"etb_draw_count":1,"trigger":"enters_battlefield","trigger_effect":"draw_cards","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ResistanceSquad translated into ManaLoom runtime scope xmage_creature_etb_draw_cards_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rhox meditant', 'Rhox Meditant', '3cff932a1bf7c11de356754ab1633d37', 'battle_rule_v1:f0c2ed710efb1593ae4104b739f7dde9', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_cards_v1","effect":"creature","etb_draw_condition":"controller_controls_matching_permanent","etb_draw_condition_colors":["green"],"etb_draw_condition_min_count":1,"etb_draw_condition_status":"runtime_executor_v1","etb_draw_count":1,"trigger":"enters_battlefield","trigger_effect":"draw_cards","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RhoxMeditant translated into ManaLoom runtime scope xmage_creature_etb_draw_cards_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('scholar of stars', 'Scholar of Stars', 'aaa80647de08038783b0262987df6cd6', 'battle_rule_v1:1aad34391a400d2e31b1d03c367eab8b', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_cards_v1","effect":"creature","etb_draw_condition":"controller_controls_matching_permanent","etb_draw_condition_card_types":["artifact"],"etb_draw_condition_min_count":1,"etb_draw_condition_status":"runtime_executor_v1","etb_draw_count":1,"trigger":"enters_battlefield","trigger_effect":"draw_cards","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ScholarOfStars translated into ManaLoom runtime scope xmage_creature_etb_draw_cards_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('settlement blacksmith', 'Settlement Blacksmith', 'c1650f7bacfb0f78846e1cffce33d7e8', 'battle_rule_v1:e1dbd39a50c39509f45c6daa06064062', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_cards_v1","effect":"creature","etb_draw_condition":"controller_controls_matching_permanent","etb_draw_condition_min_count":1,"etb_draw_condition_status":"runtime_executor_v1","etb_draw_condition_subtypes":["equipment"],"etb_draw_count":1,"trigger":"enters_battlefield","trigger_effect":"draw_cards","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SettlementBlacksmith translated into ManaLoom runtime scope xmage_creature_etb_draw_cards_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('donatello, turtle techie', 'Donatello, Turtle Techie', 'eda48af85c5a2d0650124fee42bc6db7', 'battle_rule_v1:1aad34391a400d2e31b1d03c367eab8b', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_cards_v1","effect":"creature","etb_draw_condition":"controller_controls_matching_permanent","etb_draw_condition_card_types":["artifact"],"etb_draw_condition_min_count":1,"etb_draw_condition_status":"runtime_executor_v1","etb_draw_count":1,"trigger":"enters_battlefield","trigger_effect":"draw_cards","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DonatelloTurtleTechie translated into ManaLoom runtime scope xmage_creature_etb_draw_cards_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('opal lake gatekeepers', 'Opal Lake Gatekeepers', 'de09ec948a338bab499e6c6b39445b73', 'battle_rule_v1:2bb5212efd94973b17869d451eb3b392', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_cards_v1","effect":"creature","etb_draw_condition":"controller_controls_matching_permanent","etb_draw_condition_min_count":2,"etb_draw_condition_status":"runtime_executor_v1","etb_draw_condition_subtypes":["gate"],"etb_draw_count":1,"etb_draw_optional":true,"trigger":"enters_battlefield","trigger_effect":"draw_cards","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OpalLakeGatekeepers translated into ManaLoom runtime scope xmage_creature_etb_draw_cards_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('resistance squad', 'Resistance Squad', '8b3c1ca7c447f3805edf9378bc24ad85', 'battle_rule_v1:a0d576366fc549ff6443caf99a1da039', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_cards_v1","effect":"creature","etb_draw_condition":"controller_controls_matching_permanent","etb_draw_condition_exclude_source":true,"etb_draw_condition_min_count":1,"etb_draw_condition_status":"runtime_executor_v1","etb_draw_condition_subtypes":["human"],"etb_draw_count":1,"trigger":"enters_battlefield","trigger_effect":"draw_cards","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ResistanceSquad translated into ManaLoom runtime scope xmage_creature_etb_draw_cards_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rhox meditant', 'Rhox Meditant', '3cff932a1bf7c11de356754ab1633d37', 'battle_rule_v1:f0c2ed710efb1593ae4104b739f7dde9', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_cards_v1","effect":"creature","etb_draw_condition":"controller_controls_matching_permanent","etb_draw_condition_colors":["green"],"etb_draw_condition_min_count":1,"etb_draw_condition_status":"runtime_executor_v1","etb_draw_count":1,"trigger":"enters_battlefield","trigger_effect":"draw_cards","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RhoxMeditant translated into ManaLoom runtime scope xmage_creature_etb_draw_cards_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('scholar of stars', 'Scholar of Stars', 'aaa80647de08038783b0262987df6cd6', 'battle_rule_v1:1aad34391a400d2e31b1d03c367eab8b', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_cards_v1","effect":"creature","etb_draw_condition":"controller_controls_matching_permanent","etb_draw_condition_card_types":["artifact"],"etb_draw_condition_min_count":1,"etb_draw_condition_status":"runtime_executor_v1","etb_draw_count":1,"trigger":"enters_battlefield","trigger_effect":"draw_cards","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ScholarOfStars translated into ManaLoom runtime scope xmage_creature_etb_draw_cards_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('settlement blacksmith', 'Settlement Blacksmith', 'c1650f7bacfb0f78846e1cffce33d7e8', 'battle_rule_v1:e1dbd39a50c39509f45c6daa06064062', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_cards_v1","effect":"creature","etb_draw_condition":"controller_controls_matching_permanent","etb_draw_condition_min_count":1,"etb_draw_condition_status":"runtime_executor_v1","etb_draw_condition_subtypes":["equipment"],"etb_draw_count":1,"trigger":"enters_battlefield","trigger_effect":"draw_cards","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SettlementBlacksmith translated into ManaLoom runtime scope xmage_creature_etb_draw_cards_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
