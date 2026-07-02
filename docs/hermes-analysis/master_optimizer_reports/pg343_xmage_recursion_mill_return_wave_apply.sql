BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg343_xmage_recursion_mill_return_wave_20260702_012603 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('acolyte of affliction', 'corpse churn', 'eccentric farmer', 'grapple with the past', 'pothole mole')
   OR normalized_name LIKE 'acolyte of affliction // %'
   OR normalized_name LIKE 'corpse churn // %'
   OR normalized_name LIKE 'eccentric farmer // %'
   OR normalized_name LIKE 'grapple with the past // %'
   OR normalized_name LIKE 'pothole mole // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('acolyte of affliction', 'Acolyte of Affliction', '1065260768af491ce6b27a5e9f634035', 'battle_rule_v1:313c45d8db9d3044d3f2d6151dc0a49d', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_mill_then_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_mill_count":2,"etb_recursion_target":"permanent","etb_recursion_up_to_count":true,"target_constraints":{"card_types":["artifact","creature","enchantment","planeswalker","battle","land"],"controller":"self","zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_classes":["MillCardsControllerEffect","ReturnCardChosenFromGraveyardEffect"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AcolyteOfAffliction translated into ManaLoom runtime scope xmage_creature_etb_mill_then_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('corpse churn', 'Corpse Churn', 'e89e2255330f3db9a8acfef47365aa36', 'battle_rule_v1:2a926d8f6e5d6d3947f2167ddbbbf450', '{"battle_model_scope":"xmage_mill_then_return_graveyard_card_to_hand_spell_v1","count":1,"destination":"hand","effect":"recursion","instant":true,"pre_recursion_mill_count":3,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","up_to_count":true,"xmage_effect_classes":["MillCardsControllerEffect","ReturnCardChosenFromGraveyardEffect"]}'::jsonb, '{"category":"engine","effect":"recursion","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CorpseChurn translated into ManaLoom runtime scope xmage_mill_then_return_graveyard_card_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('eccentric farmer', 'Eccentric Farmer', '93c7e9b37205b9ff286a1f6c48cc55fe', 'battle_rule_v1:8f1112c7845590f7af48ef2fe27e4042', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_mill_then_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_mill_count":3,"etb_recursion_target":"land","etb_recursion_up_to_count":true,"target_constraints":{"card_types":["land"],"controller":"self","zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_classes":["MillCardsControllerEffect","ReturnCardChosenFromGraveyardEffect"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EccentricFarmer translated into ManaLoom runtime scope xmage_creature_etb_mill_then_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('grapple with the past', 'Grapple with the Past', '05436728f69b35f7b1e8b0c3c0c468b1', 'battle_rule_v1:a6c4cee416262412bedfb007466f57cf', '{"battle_model_scope":"xmage_mill_then_return_graveyard_card_to_hand_spell_v1","count":1,"destination":"hand","effect":"recursion","instant":true,"pre_recursion_mill_count":3,"sorcery":false,"target":"creature_or_land","target_constraints":{"card_types":["creature","land"],"controller":"self","zone":"graveyard"},"target_controller":"self","up_to_count":true,"xmage_effect_classes":["MillCardsControllerEffect","ReturnCardChosenFromGraveyardEffect"]}'::jsonb, '{"category":"engine","effect":"recursion","target":"creature_or_land","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GrappleWithThePast translated into ManaLoom runtime scope xmage_mill_then_return_graveyard_card_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pothole mole', 'Pothole Mole', '93c7e9b37205b9ff286a1f6c48cc55fe', 'battle_rule_v1:8f1112c7845590f7af48ef2fe27e4042', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_mill_then_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_mill_count":3,"etb_recursion_target":"land","etb_recursion_up_to_count":true,"target_constraints":{"card_types":["land"],"controller":"self","zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_classes":["MillCardsControllerEffect","ReturnCardChosenFromGraveyardEffect"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PotholeMole translated into ManaLoom runtime scope xmage_creature_etb_mill_then_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('acolyte of affliction', 'Acolyte of Affliction', '1065260768af491ce6b27a5e9f634035', 'battle_rule_v1:313c45d8db9d3044d3f2d6151dc0a49d', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_mill_then_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_mill_count":2,"etb_recursion_target":"permanent","etb_recursion_up_to_count":true,"target_constraints":{"card_types":["artifact","creature","enchantment","planeswalker","battle","land"],"controller":"self","zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_classes":["MillCardsControllerEffect","ReturnCardChosenFromGraveyardEffect"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AcolyteOfAffliction translated into ManaLoom runtime scope xmage_creature_etb_mill_then_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('corpse churn', 'Corpse Churn', 'e89e2255330f3db9a8acfef47365aa36', 'battle_rule_v1:2a926d8f6e5d6d3947f2167ddbbbf450', '{"battle_model_scope":"xmage_mill_then_return_graveyard_card_to_hand_spell_v1","count":1,"destination":"hand","effect":"recursion","instant":true,"pre_recursion_mill_count":3,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","up_to_count":true,"xmage_effect_classes":["MillCardsControllerEffect","ReturnCardChosenFromGraveyardEffect"]}'::jsonb, '{"category":"engine","effect":"recursion","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CorpseChurn translated into ManaLoom runtime scope xmage_mill_then_return_graveyard_card_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('eccentric farmer', 'Eccentric Farmer', '93c7e9b37205b9ff286a1f6c48cc55fe', 'battle_rule_v1:8f1112c7845590f7af48ef2fe27e4042', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_mill_then_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_mill_count":3,"etb_recursion_target":"land","etb_recursion_up_to_count":true,"target_constraints":{"card_types":["land"],"controller":"self","zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_classes":["MillCardsControllerEffect","ReturnCardChosenFromGraveyardEffect"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EccentricFarmer translated into ManaLoom runtime scope xmage_creature_etb_mill_then_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('grapple with the past', 'Grapple with the Past', '05436728f69b35f7b1e8b0c3c0c468b1', 'battle_rule_v1:a6c4cee416262412bedfb007466f57cf', '{"battle_model_scope":"xmage_mill_then_return_graveyard_card_to_hand_spell_v1","count":1,"destination":"hand","effect":"recursion","instant":true,"pre_recursion_mill_count":3,"sorcery":false,"target":"creature_or_land","target_constraints":{"card_types":["creature","land"],"controller":"self","zone":"graveyard"},"target_controller":"self","up_to_count":true,"xmage_effect_classes":["MillCardsControllerEffect","ReturnCardChosenFromGraveyardEffect"]}'::jsonb, '{"category":"engine","effect":"recursion","target":"creature_or_land","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GrappleWithThePast translated into ManaLoom runtime scope xmage_mill_then_return_graveyard_card_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pothole mole', 'Pothole Mole', '93c7e9b37205b9ff286a1f6c48cc55fe', 'battle_rule_v1:8f1112c7845590f7af48ef2fe27e4042', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_mill_then_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_mill_count":3,"etb_recursion_target":"land","etb_recursion_up_to_count":true,"target_constraints":{"card_types":["land"],"controller":"self","zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_classes":["MillCardsControllerEffect","ReturnCardChosenFromGraveyardEffect"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PotholeMole translated into ManaLoom runtime scope xmage_creature_etb_mill_then_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('acolyte of affliction', 'Acolyte of Affliction', '1065260768af491ce6b27a5e9f634035', 'battle_rule_v1:313c45d8db9d3044d3f2d6151dc0a49d', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_mill_then_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_mill_count":2,"etb_recursion_target":"permanent","etb_recursion_up_to_count":true,"target_constraints":{"card_types":["artifact","creature","enchantment","planeswalker","battle","land"],"controller":"self","zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_classes":["MillCardsControllerEffect","ReturnCardChosenFromGraveyardEffect"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AcolyteOfAffliction translated into ManaLoom runtime scope xmage_creature_etb_mill_then_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('corpse churn', 'Corpse Churn', 'e89e2255330f3db9a8acfef47365aa36', 'battle_rule_v1:2a926d8f6e5d6d3947f2167ddbbbf450', '{"battle_model_scope":"xmage_mill_then_return_graveyard_card_to_hand_spell_v1","count":1,"destination":"hand","effect":"recursion","instant":true,"pre_recursion_mill_count":3,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","up_to_count":true,"xmage_effect_classes":["MillCardsControllerEffect","ReturnCardChosenFromGraveyardEffect"]}'::jsonb, '{"category":"engine","effect":"recursion","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CorpseChurn translated into ManaLoom runtime scope xmage_mill_then_return_graveyard_card_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('eccentric farmer', 'Eccentric Farmer', '93c7e9b37205b9ff286a1f6c48cc55fe', 'battle_rule_v1:8f1112c7845590f7af48ef2fe27e4042', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_mill_then_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_mill_count":3,"etb_recursion_target":"land","etb_recursion_up_to_count":true,"target_constraints":{"card_types":["land"],"controller":"self","zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_classes":["MillCardsControllerEffect","ReturnCardChosenFromGraveyardEffect"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EccentricFarmer translated into ManaLoom runtime scope xmage_creature_etb_mill_then_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('grapple with the past', 'Grapple with the Past', '05436728f69b35f7b1e8b0c3c0c468b1', 'battle_rule_v1:a6c4cee416262412bedfb007466f57cf', '{"battle_model_scope":"xmage_mill_then_return_graveyard_card_to_hand_spell_v1","count":1,"destination":"hand","effect":"recursion","instant":true,"pre_recursion_mill_count":3,"sorcery":false,"target":"creature_or_land","target_constraints":{"card_types":["creature","land"],"controller":"self","zone":"graveyard"},"target_controller":"self","up_to_count":true,"xmage_effect_classes":["MillCardsControllerEffect","ReturnCardChosenFromGraveyardEffect"]}'::jsonb, '{"category":"engine","effect":"recursion","target":"creature_or_land","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GrappleWithThePast translated into ManaLoom runtime scope xmage_mill_then_return_graveyard_card_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pothole mole', 'Pothole Mole', '93c7e9b37205b9ff286a1f6c48cc55fe', 'battle_rule_v1:8f1112c7845590f7af48ef2fe27e4042', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_mill_then_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_mill_count":3,"etb_recursion_target":"land","etb_recursion_up_to_count":true,"target_constraints":{"card_types":["land"],"controller":"self","zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_classes":["MillCardsControllerEffect","ReturnCardChosenFromGraveyardEffect"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PotholeMole translated into ManaLoom runtime scope xmage_creature_etb_mill_then_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
