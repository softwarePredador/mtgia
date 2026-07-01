BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg326_xmage_recursion_fixed_target_wave_20260701_195645 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('boggart birth rite', 'death''s duet', 'reborn hope', 'revive')
   OR normalized_name LIKE 'boggart birth rite // %'
   OR normalized_name LIKE 'death''s duet // %'
   OR normalized_name LIKE 'reborn hope // %'
   OR normalized_name LIKE 'revive // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('boggart birth rite', 'Boggart Birth Rite', '433b473e3b4d788495487cdaccc58c3f', 'battle_rule_v1:e5fe8b55aaf40cc32c696da83b37d87e', '{"battle_model_scope":"xmage_return_target_graveyard_card_to_hand_spell_v1","count":1,"destination":"hand","effect":"recursion","instant":false,"sorcery":true,"target":"goblin_card","target_constraints":{"controller":"self","subtypes":["goblin"],"zone":"graveyard"},"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"goblin_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BoggartBirthRite translated into ManaLoom runtime scope xmage_return_target_graveyard_card_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('death''s duet', 'Death''s Duet', 'c37b16d6c2c8e0d993e7714a1625b70c', 'battle_rule_v1:0414220a4ec2f9a6997383d0b9b728e1', '{"battle_model_scope":"xmage_return_target_graveyard_card_to_hand_spell_v1","count":2,"destination":"hand","effect":"recursion","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DeathsDuet translated into ManaLoom runtime scope xmage_return_target_graveyard_card_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('reborn hope', 'Reborn Hope', '3916a80af120b01782f70419b4334271', 'battle_rule_v1:8b00072fef2e36205039b03f21044f1d', '{"battle_model_scope":"xmage_return_target_graveyard_card_to_hand_spell_v1","count":1,"destination":"hand","effect":"recursion","instant":false,"sorcery":true,"target":"multicolored_card","target_constraints":{"controller":"self","min_colors":2,"zone":"graveyard"},"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"multicolored_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RebornHope translated into ManaLoom runtime scope xmage_return_target_graveyard_card_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('revive', 'Revive', '19baafcc9f4b0da0129b72d41728a354', 'battle_rule_v1:bd174969a9568e932ead996951ee8ec8', '{"battle_model_scope":"xmage_return_target_graveyard_card_to_hand_spell_v1","count":1,"destination":"hand","effect":"recursion","instant":false,"sorcery":true,"target":"green_card","target_constraints":{"colors":["G"],"controller":"self","zone":"graveyard"},"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"green_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Revive translated into ManaLoom runtime scope xmage_return_target_graveyard_card_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('boggart birth rite', 'Boggart Birth Rite', '433b473e3b4d788495487cdaccc58c3f', 'battle_rule_v1:e5fe8b55aaf40cc32c696da83b37d87e', '{"battle_model_scope":"xmage_return_target_graveyard_card_to_hand_spell_v1","count":1,"destination":"hand","effect":"recursion","instant":false,"sorcery":true,"target":"goblin_card","target_constraints":{"controller":"self","subtypes":["goblin"],"zone":"graveyard"},"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"goblin_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BoggartBirthRite translated into ManaLoom runtime scope xmage_return_target_graveyard_card_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('death''s duet', 'Death''s Duet', 'c37b16d6c2c8e0d993e7714a1625b70c', 'battle_rule_v1:0414220a4ec2f9a6997383d0b9b728e1', '{"battle_model_scope":"xmage_return_target_graveyard_card_to_hand_spell_v1","count":2,"destination":"hand","effect":"recursion","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DeathsDuet translated into ManaLoom runtime scope xmage_return_target_graveyard_card_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('reborn hope', 'Reborn Hope', '3916a80af120b01782f70419b4334271', 'battle_rule_v1:8b00072fef2e36205039b03f21044f1d', '{"battle_model_scope":"xmage_return_target_graveyard_card_to_hand_spell_v1","count":1,"destination":"hand","effect":"recursion","instant":false,"sorcery":true,"target":"multicolored_card","target_constraints":{"controller":"self","min_colors":2,"zone":"graveyard"},"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"multicolored_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RebornHope translated into ManaLoom runtime scope xmage_return_target_graveyard_card_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('revive', 'Revive', '19baafcc9f4b0da0129b72d41728a354', 'battle_rule_v1:bd174969a9568e932ead996951ee8ec8', '{"battle_model_scope":"xmage_return_target_graveyard_card_to_hand_spell_v1","count":1,"destination":"hand","effect":"recursion","instant":false,"sorcery":true,"target":"green_card","target_constraints":{"colors":["G"],"controller":"self","zone":"graveyard"},"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"green_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Revive translated into ManaLoom runtime scope xmage_return_target_graveyard_card_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('boggart birth rite', 'Boggart Birth Rite', '433b473e3b4d788495487cdaccc58c3f', 'battle_rule_v1:e5fe8b55aaf40cc32c696da83b37d87e', '{"battle_model_scope":"xmage_return_target_graveyard_card_to_hand_spell_v1","count":1,"destination":"hand","effect":"recursion","instant":false,"sorcery":true,"target":"goblin_card","target_constraints":{"controller":"self","subtypes":["goblin"],"zone":"graveyard"},"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"goblin_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BoggartBirthRite translated into ManaLoom runtime scope xmage_return_target_graveyard_card_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('death''s duet', 'Death''s Duet', 'c37b16d6c2c8e0d993e7714a1625b70c', 'battle_rule_v1:0414220a4ec2f9a6997383d0b9b728e1', '{"battle_model_scope":"xmage_return_target_graveyard_card_to_hand_spell_v1","count":2,"destination":"hand","effect":"recursion","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DeathsDuet translated into ManaLoom runtime scope xmage_return_target_graveyard_card_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('reborn hope', 'Reborn Hope', '3916a80af120b01782f70419b4334271', 'battle_rule_v1:8b00072fef2e36205039b03f21044f1d', '{"battle_model_scope":"xmage_return_target_graveyard_card_to_hand_spell_v1","count":1,"destination":"hand","effect":"recursion","instant":false,"sorcery":true,"target":"multicolored_card","target_constraints":{"controller":"self","min_colors":2,"zone":"graveyard"},"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"multicolored_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RebornHope translated into ManaLoom runtime scope xmage_return_target_graveyard_card_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('revive', 'Revive', '19baafcc9f4b0da0129b72d41728a354', 'battle_rule_v1:bd174969a9568e932ead996951ee8ec8', '{"battle_model_scope":"xmage_return_target_graveyard_card_to_hand_spell_v1","count":1,"destination":"hand","effect":"recursion","instant":false,"sorcery":true,"target":"green_card","target_constraints":{"colors":["G"],"controller":"self","zone":"graveyard"},"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"green_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Revive translated into ManaLoom runtime scope xmage_return_target_graveyard_card_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
