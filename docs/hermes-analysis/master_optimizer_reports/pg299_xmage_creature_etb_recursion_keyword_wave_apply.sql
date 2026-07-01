BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg299_xmage_creature_etb_recursion_keyword_wave_20260701 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('cadaver imp', 'griffin dreamfinder', 'mnemonic wall', 'sanctum gargoyle')
   OR normalized_name LIKE 'cadaver imp // %'
   OR normalized_name LIKE 'griffin dreamfinder // %'
   OR normalized_name LIKE 'mnemonic wall // %'
   OR normalized_name LIKE 'sanctum gargoyle // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('cadaver imp', 'Cadaver Imp', '910ed751dff9fb80f8a7c8281e8128b9', 'battle_rule_v1:1f62355235258125d70850193a57c376', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_target":"creature","flying":true,"keywords":["flying"],"target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CadaverImp translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('griffin dreamfinder', 'Griffin Dreamfinder', '93eb7869756f2660ce3687dbed245a4f', 'battle_rule_v1:665bf5d3bac2c2881c49ec01c4963243', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_target":"enchantment","flying":true,"keywords":["flying"],"target_constraints":{"card_types":["enchantment"],"controller":"self","zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GriffinDreamfinder translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mnemonic wall', 'Mnemonic Wall', '38990ed649f59ec9b0756b3b7d437c1e', 'battle_rule_v1:51142803b38be588b3f2eddebf47fa6d', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_hand_v1","defender":true,"effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_target":"instant_or_sorcery","keywords":["defender"],"target_constraints":{"card_types":["instant","sorcery"],"controller":"self","zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MnemonicWall translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sanctum gargoyle', 'Sanctum Gargoyle', '1ab85b577dff1ec22a95fab98e61eed4', 'battle_rule_v1:9f727b3670308479674b28e324c1a8b2', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_target":"artifact","flying":true,"keywords":["flying"],"target_constraints":{"card_types":["artifact"],"controller":"self","zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SanctumGargoyle translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('cadaver imp', 'Cadaver Imp', '910ed751dff9fb80f8a7c8281e8128b9', 'battle_rule_v1:1f62355235258125d70850193a57c376', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_target":"creature","flying":true,"keywords":["flying"],"target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CadaverImp translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('griffin dreamfinder', 'Griffin Dreamfinder', '93eb7869756f2660ce3687dbed245a4f', 'battle_rule_v1:665bf5d3bac2c2881c49ec01c4963243', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_target":"enchantment","flying":true,"keywords":["flying"],"target_constraints":{"card_types":["enchantment"],"controller":"self","zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GriffinDreamfinder translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mnemonic wall', 'Mnemonic Wall', '38990ed649f59ec9b0756b3b7d437c1e', 'battle_rule_v1:51142803b38be588b3f2eddebf47fa6d', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_hand_v1","defender":true,"effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_target":"instant_or_sorcery","keywords":["defender"],"target_constraints":{"card_types":["instant","sorcery"],"controller":"self","zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MnemonicWall translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sanctum gargoyle', 'Sanctum Gargoyle', '1ab85b577dff1ec22a95fab98e61eed4', 'battle_rule_v1:9f727b3670308479674b28e324c1a8b2', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_target":"artifact","flying":true,"keywords":["flying"],"target_constraints":{"card_types":["artifact"],"controller":"self","zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SanctumGargoyle translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('cadaver imp', 'Cadaver Imp', '910ed751dff9fb80f8a7c8281e8128b9', 'battle_rule_v1:1f62355235258125d70850193a57c376', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_target":"creature","flying":true,"keywords":["flying"],"target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CadaverImp translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('griffin dreamfinder', 'Griffin Dreamfinder', '93eb7869756f2660ce3687dbed245a4f', 'battle_rule_v1:665bf5d3bac2c2881c49ec01c4963243', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_target":"enchantment","flying":true,"keywords":["flying"],"target_constraints":{"card_types":["enchantment"],"controller":"self","zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GriffinDreamfinder translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mnemonic wall', 'Mnemonic Wall', '38990ed649f59ec9b0756b3b7d437c1e', 'battle_rule_v1:51142803b38be588b3f2eddebf47fa6d', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_hand_v1","defender":true,"effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_target":"instant_or_sorcery","keywords":["defender"],"target_constraints":{"card_types":["instant","sorcery"],"controller":"self","zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MnemonicWall translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sanctum gargoyle', 'Sanctum Gargoyle', '1ab85b577dff1ec22a95fab98e61eed4', 'battle_rule_v1:9f727b3670308479674b28e324c1a8b2', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_target":"artifact","flying":true,"keywords":["flying"],"target_constraints":{"card_types":["artifact"],"controller":"self","zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SanctumGargoyle translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
