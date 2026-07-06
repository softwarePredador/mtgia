BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg541_dies_treasure_new_server_pg541_die_20260706_013556 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('common crook', 'dire fleet hoarder', 'gleaming barrier', 'jewel-eyed cobra', 'piggy bank')
   OR normalized_name LIKE 'common crook // %'
   OR normalized_name LIKE 'dire fleet hoarder // %'
   OR normalized_name LIKE 'gleaming barrier // %'
   OR normalized_name LIKE 'jewel-eyed cobra // %'
   OR normalized_name LIKE 'piggy bank // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('common crook', 'Common Crook', '4ecd7b3c63f82113a4a6cf0fff0e719a', 'battle_rule_v1:3f60734db1f81ef3f3db0330478d6bd4', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_create_treasure_v1","dies_or_graveyard_from_battlefield_treasure":true,"dies_treasure_count":1,"dies_trigger_effect":"treasure_maker","effect":"creature","treasure_count":1,"treasure_recipient":"controller","treasure_trigger":"dies","trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"TreasureToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CommonCrook translated into ManaLoom runtime scope xmage_creature_dies_create_treasure_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed Treasure creation ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dire fleet hoarder', 'Dire Fleet Hoarder', '4ecd7b3c63f82113a4a6cf0fff0e719a', 'battle_rule_v1:3f60734db1f81ef3f3db0330478d6bd4', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_create_treasure_v1","dies_or_graveyard_from_battlefield_treasure":true,"dies_treasure_count":1,"dies_trigger_effect":"treasure_maker","effect":"creature","treasure_count":1,"treasure_recipient":"controller","treasure_trigger":"dies","trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"TreasureToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DireFleetHoarder translated into ManaLoom runtime scope xmage_creature_dies_create_treasure_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed Treasure creation ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('gleaming barrier', 'Gleaming Barrier', 'c6f82a18e52f76576a5b561153641e7f', 'battle_rule_v1:4b9bead4d691a3d01fc4ff09e291d0a2', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_create_treasure_v1","defender":true,"dies_or_graveyard_from_battlefield_treasure":true,"dies_treasure_count":1,"dies_trigger_effect":"treasure_maker","effect":"creature","keywords":["defender"],"treasure_count":1,"treasure_recipient":"controller","treasure_trigger":"dies","trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"TreasureToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GleamingBarrier translated into ManaLoom runtime scope xmage_creature_dies_create_treasure_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed Treasure creation ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jewel-eyed cobra', 'Jewel-Eyed Cobra', 'ab78078547fc4b0f1454608df265691e', 'battle_rule_v1:1a315e264d967f5fcb1a414a841a516f', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_create_treasure_v1","deathtouch":true,"dies_or_graveyard_from_battlefield_treasure":true,"dies_treasure_count":1,"dies_trigger_effect":"treasure_maker","effect":"creature","keywords":["deathtouch"],"treasure_count":1,"treasure_recipient":"controller","treasure_trigger":"dies","trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"TreasureToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JewelEyedCobra translated into ManaLoom runtime scope xmage_creature_dies_create_treasure_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed Treasure creation ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('piggy bank', 'Piggy Bank', '4ecd7b3c63f82113a4a6cf0fff0e719a', 'battle_rule_v1:3f60734db1f81ef3f3db0330478d6bd4', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_create_treasure_v1","dies_or_graveyard_from_battlefield_treasure":true,"dies_treasure_count":1,"dies_trigger_effect":"treasure_maker","effect":"creature","treasure_count":1,"treasure_recipient":"controller","treasure_trigger":"dies","trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"TreasureToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PiggyBank translated into ManaLoom runtime scope xmage_creature_dies_create_treasure_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed Treasure creation ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('common crook', 'Common Crook', '4ecd7b3c63f82113a4a6cf0fff0e719a', 'battle_rule_v1:3f60734db1f81ef3f3db0330478d6bd4', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_create_treasure_v1","dies_or_graveyard_from_battlefield_treasure":true,"dies_treasure_count":1,"dies_trigger_effect":"treasure_maker","effect":"creature","treasure_count":1,"treasure_recipient":"controller","treasure_trigger":"dies","trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"TreasureToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CommonCrook translated into ManaLoom runtime scope xmage_creature_dies_create_treasure_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed Treasure creation ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dire fleet hoarder', 'Dire Fleet Hoarder', '4ecd7b3c63f82113a4a6cf0fff0e719a', 'battle_rule_v1:3f60734db1f81ef3f3db0330478d6bd4', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_create_treasure_v1","dies_or_graveyard_from_battlefield_treasure":true,"dies_treasure_count":1,"dies_trigger_effect":"treasure_maker","effect":"creature","treasure_count":1,"treasure_recipient":"controller","treasure_trigger":"dies","trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"TreasureToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DireFleetHoarder translated into ManaLoom runtime scope xmage_creature_dies_create_treasure_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed Treasure creation ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('gleaming barrier', 'Gleaming Barrier', 'c6f82a18e52f76576a5b561153641e7f', 'battle_rule_v1:4b9bead4d691a3d01fc4ff09e291d0a2', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_create_treasure_v1","defender":true,"dies_or_graveyard_from_battlefield_treasure":true,"dies_treasure_count":1,"dies_trigger_effect":"treasure_maker","effect":"creature","keywords":["defender"],"treasure_count":1,"treasure_recipient":"controller","treasure_trigger":"dies","trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"TreasureToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GleamingBarrier translated into ManaLoom runtime scope xmage_creature_dies_create_treasure_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed Treasure creation ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jewel-eyed cobra', 'Jewel-Eyed Cobra', 'ab78078547fc4b0f1454608df265691e', 'battle_rule_v1:1a315e264d967f5fcb1a414a841a516f', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_create_treasure_v1","deathtouch":true,"dies_or_graveyard_from_battlefield_treasure":true,"dies_treasure_count":1,"dies_trigger_effect":"treasure_maker","effect":"creature","keywords":["deathtouch"],"treasure_count":1,"treasure_recipient":"controller","treasure_trigger":"dies","trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"TreasureToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JewelEyedCobra translated into ManaLoom runtime scope xmage_creature_dies_create_treasure_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed Treasure creation ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('piggy bank', 'Piggy Bank', '4ecd7b3c63f82113a4a6cf0fff0e719a', 'battle_rule_v1:3f60734db1f81ef3f3db0330478d6bd4', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_create_treasure_v1","dies_or_graveyard_from_battlefield_treasure":true,"dies_treasure_count":1,"dies_trigger_effect":"treasure_maker","effect":"creature","treasure_count":1,"treasure_recipient":"controller","treasure_trigger":"dies","trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"TreasureToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PiggyBank translated into ManaLoom runtime scope xmage_creature_dies_create_treasure_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed Treasure creation ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('common crook', 'Common Crook', '4ecd7b3c63f82113a4a6cf0fff0e719a', 'battle_rule_v1:3f60734db1f81ef3f3db0330478d6bd4', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_create_treasure_v1","dies_or_graveyard_from_battlefield_treasure":true,"dies_treasure_count":1,"dies_trigger_effect":"treasure_maker","effect":"creature","treasure_count":1,"treasure_recipient":"controller","treasure_trigger":"dies","trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"TreasureToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CommonCrook translated into ManaLoom runtime scope xmage_creature_dies_create_treasure_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed Treasure creation ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dire fleet hoarder', 'Dire Fleet Hoarder', '4ecd7b3c63f82113a4a6cf0fff0e719a', 'battle_rule_v1:3f60734db1f81ef3f3db0330478d6bd4', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_create_treasure_v1","dies_or_graveyard_from_battlefield_treasure":true,"dies_treasure_count":1,"dies_trigger_effect":"treasure_maker","effect":"creature","treasure_count":1,"treasure_recipient":"controller","treasure_trigger":"dies","trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"TreasureToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DireFleetHoarder translated into ManaLoom runtime scope xmage_creature_dies_create_treasure_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed Treasure creation ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('gleaming barrier', 'Gleaming Barrier', 'c6f82a18e52f76576a5b561153641e7f', 'battle_rule_v1:4b9bead4d691a3d01fc4ff09e291d0a2', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_create_treasure_v1","defender":true,"dies_or_graveyard_from_battlefield_treasure":true,"dies_treasure_count":1,"dies_trigger_effect":"treasure_maker","effect":"creature","keywords":["defender"],"treasure_count":1,"treasure_recipient":"controller","treasure_trigger":"dies","trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"TreasureToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GleamingBarrier translated into ManaLoom runtime scope xmage_creature_dies_create_treasure_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed Treasure creation ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jewel-eyed cobra', 'Jewel-Eyed Cobra', 'ab78078547fc4b0f1454608df265691e', 'battle_rule_v1:1a315e264d967f5fcb1a414a841a516f', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_create_treasure_v1","deathtouch":true,"dies_or_graveyard_from_battlefield_treasure":true,"dies_treasure_count":1,"dies_trigger_effect":"treasure_maker","effect":"creature","keywords":["deathtouch"],"treasure_count":1,"treasure_recipient":"controller","treasure_trigger":"dies","trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"TreasureToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JewelEyedCobra translated into ManaLoom runtime scope xmage_creature_dies_create_treasure_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed Treasure creation ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('piggy bank', 'Piggy Bank', '4ecd7b3c63f82113a4a6cf0fff0e719a', 'battle_rule_v1:3f60734db1f81ef3f3db0330478d6bd4', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_create_treasure_v1","dies_or_graveyard_from_battlefield_treasure":true,"dies_treasure_count":1,"dies_trigger_effect":"treasure_maker","effect":"creature","treasure_count":1,"treasure_recipient":"controller","treasure_trigger":"dies","trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"TreasureToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PiggyBank translated into ManaLoom runtime scope xmage_creature_dies_create_treasure_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed Treasure creation ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
