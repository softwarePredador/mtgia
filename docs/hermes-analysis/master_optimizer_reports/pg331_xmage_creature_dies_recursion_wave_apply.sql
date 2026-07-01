BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg331_xmage_creature_dies_recursion_wave_20260701_210836 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('dutiful attendant', 'elderfang ritualist', 'living lightning', 'myr retriever', 'workshop assistant')
   OR normalized_name LIKE 'dutiful attendant // %'
   OR normalized_name LIKE 'elderfang ritualist // %'
   OR normalized_name LIKE 'living lightning // %'
   OR normalized_name LIKE 'myr retriever // %'
   OR normalized_name LIKE 'workshop assistant // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('dutiful attendant', 'Dutiful Attendant', '1577a7542791cf72d3e107b851620556', 'battle_rule_v1:ac4691be75a5b00ae0e0be9a325705da', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_return_graveyard_card_to_hand_v1","dies_recursion_count":1,"dies_recursion_destination":"hand","dies_recursion_exclude_self":true,"dies_recursion_target":"creature","effect":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DutifulAttendant translated into ManaLoom runtime scope xmage_creature_dies_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature dies triggered graveyard-to-hand ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('elderfang ritualist', 'Elderfang Ritualist', '4bbafbe06b30d21e09a9a41d7c4a2bf0', 'battle_rule_v1:3306f4d5219e782160daf1385d92f499', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_return_graveyard_card_to_hand_v1","dies_recursion_count":1,"dies_recursion_destination":"hand","dies_recursion_exclude_self":true,"dies_recursion_target":"elf_card","effect":"creature","target_constraints":{"controller":"self","subtypes":["elf"],"zone":"graveyard"},"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ElderfangRitualist translated into ManaLoom runtime scope xmage_creature_dies_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature dies triggered graveyard-to-hand ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('living lightning', 'Living Lightning', '49cf6ad10d1f7f69263bd280ce851120', 'battle_rule_v1:28eac3740a610b2b39f04e52527943c0', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_return_graveyard_card_to_hand_v1","dies_recursion_count":1,"dies_recursion_destination":"hand","dies_recursion_target":"instant_or_sorcery","effect":"creature","target_constraints":{"card_types":["instant","sorcery"],"controller":"self","zone":"graveyard"},"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LivingLightning translated into ManaLoom runtime scope xmage_creature_dies_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature dies triggered graveyard-to-hand ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('myr retriever', 'Myr Retriever', '29d416587cbec9bf97bdd4d20b730802', 'battle_rule_v1:4437ef138e8d93691f9e19eac9dc08f5', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_return_graveyard_card_to_hand_v1","dies_recursion_count":1,"dies_recursion_destination":"hand","dies_recursion_exclude_self":true,"dies_recursion_target":"artifact","effect":"creature","target_constraints":{"card_types":["artifact"],"controller":"self","zone":"graveyard"},"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MyrRetriever translated into ManaLoom runtime scope xmage_creature_dies_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature dies triggered graveyard-to-hand ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('workshop assistant', 'Workshop Assistant', '29d416587cbec9bf97bdd4d20b730802', 'battle_rule_v1:4437ef138e8d93691f9e19eac9dc08f5', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_return_graveyard_card_to_hand_v1","dies_recursion_count":1,"dies_recursion_destination":"hand","dies_recursion_exclude_self":true,"dies_recursion_target":"artifact","effect":"creature","target_constraints":{"card_types":["artifact"],"controller":"self","zone":"graveyard"},"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WorkshopAssistant translated into ManaLoom runtime scope xmage_creature_dies_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature dies triggered graveyard-to-hand ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('dutiful attendant', 'Dutiful Attendant', '1577a7542791cf72d3e107b851620556', 'battle_rule_v1:ac4691be75a5b00ae0e0be9a325705da', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_return_graveyard_card_to_hand_v1","dies_recursion_count":1,"dies_recursion_destination":"hand","dies_recursion_exclude_self":true,"dies_recursion_target":"creature","effect":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DutifulAttendant translated into ManaLoom runtime scope xmage_creature_dies_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature dies triggered graveyard-to-hand ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('elderfang ritualist', 'Elderfang Ritualist', '4bbafbe06b30d21e09a9a41d7c4a2bf0', 'battle_rule_v1:3306f4d5219e782160daf1385d92f499', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_return_graveyard_card_to_hand_v1","dies_recursion_count":1,"dies_recursion_destination":"hand","dies_recursion_exclude_self":true,"dies_recursion_target":"elf_card","effect":"creature","target_constraints":{"controller":"self","subtypes":["elf"],"zone":"graveyard"},"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ElderfangRitualist translated into ManaLoom runtime scope xmage_creature_dies_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature dies triggered graveyard-to-hand ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('living lightning', 'Living Lightning', '49cf6ad10d1f7f69263bd280ce851120', 'battle_rule_v1:28eac3740a610b2b39f04e52527943c0', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_return_graveyard_card_to_hand_v1","dies_recursion_count":1,"dies_recursion_destination":"hand","dies_recursion_target":"instant_or_sorcery","effect":"creature","target_constraints":{"card_types":["instant","sorcery"],"controller":"self","zone":"graveyard"},"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LivingLightning translated into ManaLoom runtime scope xmage_creature_dies_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature dies triggered graveyard-to-hand ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('myr retriever', 'Myr Retriever', '29d416587cbec9bf97bdd4d20b730802', 'battle_rule_v1:4437ef138e8d93691f9e19eac9dc08f5', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_return_graveyard_card_to_hand_v1","dies_recursion_count":1,"dies_recursion_destination":"hand","dies_recursion_exclude_self":true,"dies_recursion_target":"artifact","effect":"creature","target_constraints":{"card_types":["artifact"],"controller":"self","zone":"graveyard"},"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MyrRetriever translated into ManaLoom runtime scope xmage_creature_dies_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature dies triggered graveyard-to-hand ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('workshop assistant', 'Workshop Assistant', '29d416587cbec9bf97bdd4d20b730802', 'battle_rule_v1:4437ef138e8d93691f9e19eac9dc08f5', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_return_graveyard_card_to_hand_v1","dies_recursion_count":1,"dies_recursion_destination":"hand","dies_recursion_exclude_self":true,"dies_recursion_target":"artifact","effect":"creature","target_constraints":{"card_types":["artifact"],"controller":"self","zone":"graveyard"},"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WorkshopAssistant translated into ManaLoom runtime scope xmage_creature_dies_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature dies triggered graveyard-to-hand ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('dutiful attendant', 'Dutiful Attendant', '1577a7542791cf72d3e107b851620556', 'battle_rule_v1:ac4691be75a5b00ae0e0be9a325705da', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_return_graveyard_card_to_hand_v1","dies_recursion_count":1,"dies_recursion_destination":"hand","dies_recursion_exclude_self":true,"dies_recursion_target":"creature","effect":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DutifulAttendant translated into ManaLoom runtime scope xmage_creature_dies_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature dies triggered graveyard-to-hand ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('elderfang ritualist', 'Elderfang Ritualist', '4bbafbe06b30d21e09a9a41d7c4a2bf0', 'battle_rule_v1:3306f4d5219e782160daf1385d92f499', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_return_graveyard_card_to_hand_v1","dies_recursion_count":1,"dies_recursion_destination":"hand","dies_recursion_exclude_self":true,"dies_recursion_target":"elf_card","effect":"creature","target_constraints":{"controller":"self","subtypes":["elf"],"zone":"graveyard"},"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ElderfangRitualist translated into ManaLoom runtime scope xmage_creature_dies_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature dies triggered graveyard-to-hand ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('living lightning', 'Living Lightning', '49cf6ad10d1f7f69263bd280ce851120', 'battle_rule_v1:28eac3740a610b2b39f04e52527943c0', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_return_graveyard_card_to_hand_v1","dies_recursion_count":1,"dies_recursion_destination":"hand","dies_recursion_target":"instant_or_sorcery","effect":"creature","target_constraints":{"card_types":["instant","sorcery"],"controller":"self","zone":"graveyard"},"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LivingLightning translated into ManaLoom runtime scope xmage_creature_dies_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature dies triggered graveyard-to-hand ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('myr retriever', 'Myr Retriever', '29d416587cbec9bf97bdd4d20b730802', 'battle_rule_v1:4437ef138e8d93691f9e19eac9dc08f5', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_return_graveyard_card_to_hand_v1","dies_recursion_count":1,"dies_recursion_destination":"hand","dies_recursion_exclude_self":true,"dies_recursion_target":"artifact","effect":"creature","target_constraints":{"card_types":["artifact"],"controller":"self","zone":"graveyard"},"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MyrRetriever translated into ManaLoom runtime scope xmage_creature_dies_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature dies triggered graveyard-to-hand ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('workshop assistant', 'Workshop Assistant', '29d416587cbec9bf97bdd4d20b730802', 'battle_rule_v1:4437ef138e8d93691f9e19eac9dc08f5', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_return_graveyard_card_to_hand_v1","dies_recursion_count":1,"dies_recursion_destination":"hand","dies_recursion_exclude_self":true,"dies_recursion_target":"artifact","effect":"creature","target_constraints":{"card_types":["artifact"],"controller":"self","zone":"graveyard"},"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WorkshopAssistant translated into ManaLoom runtime scope xmage_creature_dies_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature dies triggered graveyard-to-hand ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
