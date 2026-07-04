BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg409_etb_recursion_battlefield_new_server_etb_recursion AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('bloodline necromancer', 'quarry beetle', 'sharuum the hegemon')
   OR normalized_name LIKE 'bloodline necromancer // %'
   OR normalized_name LIKE 'quarry beetle // %'
   OR normalized_name LIKE 'sharuum the hegemon // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('bloodline necromancer', 'Bloodline Necromancer', 'e713552fc98c793350f82c31624b470d', 'battle_rule_v1:2b7be1f5d59767be6bb2844a144e788e', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_battlefield_v1","battlefield_controller":"self","destination":"battlefield","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"battlefield","etb_recursion_target":"vampire_or_wizard_creature","keywords":["lifelink"],"lifelink":true,"target":"vampire_or_wizard_creature","target_constraints":{"card_types":["creature"],"controller":"self","subtypes":["vampire","wizard"],"zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"vampire_or_wizard_creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BloodlineNecromancer translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_battlefield_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('quarry beetle', 'Quarry Beetle', '4819c64ce86068970b8382c00989c0e6', 'battle_rule_v1:0d34c60d7e646ad88946ab4f21adea4a', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_battlefield_v1","battlefield_controller":"self","destination":"battlefield","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"battlefield","etb_recursion_target":"land","target":"land","target_constraints":{"card_types":["land"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"land"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class QuarryBeetle translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_battlefield_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sharuum the hegemon', 'Sharuum the Hegemon', 'bc8850d8a71aa330bebf823f85e5314f', 'battle_rule_v1:1eda23314f8caeb65cf14584c5ec2f2b', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_battlefield_v1","battlefield_controller":"self","destination":"battlefield","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"battlefield","etb_recursion_target":"artifact","flying":true,"keywords":["flying"],"target":"artifact","target_constraints":{"card_types":["artifact"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"artifact"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SharuumTheHegemon translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_battlefield_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('bloodline necromancer', 'Bloodline Necromancer', 'e713552fc98c793350f82c31624b470d', 'battle_rule_v1:2b7be1f5d59767be6bb2844a144e788e', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_battlefield_v1","battlefield_controller":"self","destination":"battlefield","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"battlefield","etb_recursion_target":"vampire_or_wizard_creature","keywords":["lifelink"],"lifelink":true,"target":"vampire_or_wizard_creature","target_constraints":{"card_types":["creature"],"controller":"self","subtypes":["vampire","wizard"],"zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"vampire_or_wizard_creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BloodlineNecromancer translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_battlefield_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('quarry beetle', 'Quarry Beetle', '4819c64ce86068970b8382c00989c0e6', 'battle_rule_v1:0d34c60d7e646ad88946ab4f21adea4a', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_battlefield_v1","battlefield_controller":"self","destination":"battlefield","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"battlefield","etb_recursion_target":"land","target":"land","target_constraints":{"card_types":["land"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"land"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class QuarryBeetle translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_battlefield_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sharuum the hegemon', 'Sharuum the Hegemon', 'bc8850d8a71aa330bebf823f85e5314f', 'battle_rule_v1:1eda23314f8caeb65cf14584c5ec2f2b', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_battlefield_v1","battlefield_controller":"self","destination":"battlefield","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"battlefield","etb_recursion_target":"artifact","flying":true,"keywords":["flying"],"target":"artifact","target_constraints":{"card_types":["artifact"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"artifact"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SharuumTheHegemon translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_battlefield_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('bloodline necromancer', 'Bloodline Necromancer', 'e713552fc98c793350f82c31624b470d', 'battle_rule_v1:2b7be1f5d59767be6bb2844a144e788e', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_battlefield_v1","battlefield_controller":"self","destination":"battlefield","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"battlefield","etb_recursion_target":"vampire_or_wizard_creature","keywords":["lifelink"],"lifelink":true,"target":"vampire_or_wizard_creature","target_constraints":{"card_types":["creature"],"controller":"self","subtypes":["vampire","wizard"],"zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"vampire_or_wizard_creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BloodlineNecromancer translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_battlefield_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('quarry beetle', 'Quarry Beetle', '4819c64ce86068970b8382c00989c0e6', 'battle_rule_v1:0d34c60d7e646ad88946ab4f21adea4a', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_battlefield_v1","battlefield_controller":"self","destination":"battlefield","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"battlefield","etb_recursion_target":"land","target":"land","target_constraints":{"card_types":["land"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"land"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class QuarryBeetle translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_battlefield_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sharuum the hegemon', 'Sharuum the Hegemon', 'bc8850d8a71aa330bebf823f85e5314f', 'battle_rule_v1:1eda23314f8caeb65cf14584c5ec2f2b', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_battlefield_v1","battlefield_controller":"self","destination":"battlefield","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"battlefield","etb_recursion_target":"artifact","flying":true,"keywords":["flying"],"target":"artifact","target_constraints":{"card_types":["artifact"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"artifact"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SharuumTheHegemon translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_battlefield_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
