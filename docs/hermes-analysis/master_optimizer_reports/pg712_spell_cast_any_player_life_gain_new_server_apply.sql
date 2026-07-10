BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg712_spell_cast_any_player_life_gain_ne_20260710_175213 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('angel''s feather', 'demon''s horn', 'dragon''s claw', 'kraken''s eye', 'wurm''s tooth')
   OR normalized_name LIKE 'angel''s feather // %'
   OR normalized_name LIKE 'demon''s horn // %'
   OR normalized_name LIKE 'dragon''s claw // %'
   OR normalized_name LIKE 'kraken''s eye // %'
   OR normalized_name LIKE 'wurm''s tooth // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('angel''s feather', 'Angel''s Feather', 'ebb29991d0f1a0b0308b4aa8d2470bb6', 'battle_rule_v1:7f669b4064cd3aba79509b3719f22009', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_gain_life_v1","effect":"life_gain_engine","spell_cast_gain_life":true,"spell_cast_gain_life_amount":1,"spell_cast_gain_life_any_player":true,"spell_cast_gain_life_optional":true,"spell_cast_gain_life_required_colors":["W"],"trigger":"spell_cast","trigger_effect":"gain_life","xmage_ability_class":"SpellCastAllTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_gain_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AngelsFeather translated into ManaLoom runtime scope xmage_spell_cast_gain_life_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('demon''s horn', 'Demon''s Horn', '2e519ebb21b2192d902d05c674b66d8e', 'battle_rule_v1:99bad2d1c6a72913caa5a932afb8056d', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_gain_life_v1","effect":"life_gain_engine","spell_cast_gain_life":true,"spell_cast_gain_life_amount":1,"spell_cast_gain_life_any_player":true,"spell_cast_gain_life_optional":true,"spell_cast_gain_life_required_colors":["B"],"trigger":"spell_cast","trigger_effect":"gain_life","xmage_ability_class":"SpellCastAllTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_gain_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DemonsHorn translated into ManaLoom runtime scope xmage_spell_cast_gain_life_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dragon''s claw', 'Dragon''s Claw', '01106f0c718a60bba4eb37ee26b98bc5', 'battle_rule_v1:7c74d4b0b1816df66cdeceb8551b9cdb', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_gain_life_v1","effect":"life_gain_engine","spell_cast_gain_life":true,"spell_cast_gain_life_amount":1,"spell_cast_gain_life_any_player":true,"spell_cast_gain_life_optional":true,"spell_cast_gain_life_required_colors":["R"],"trigger":"spell_cast","trigger_effect":"gain_life","xmage_ability_class":"SpellCastAllTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_gain_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DragonsClaw translated into ManaLoom runtime scope xmage_spell_cast_gain_life_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kraken''s eye', 'Kraken''s Eye', '731908acaaf356b2801492a987f3fdf1', 'battle_rule_v1:d7025bc05f9319aef58aebd511653833', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_gain_life_v1","effect":"life_gain_engine","spell_cast_gain_life":true,"spell_cast_gain_life_amount":1,"spell_cast_gain_life_any_player":true,"spell_cast_gain_life_optional":true,"spell_cast_gain_life_required_colors":["U"],"trigger":"spell_cast","trigger_effect":"gain_life","xmage_ability_class":"KrakensEyeAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_gain_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KrakensEye translated into ManaLoom runtime scope xmage_spell_cast_gain_life_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wurm''s tooth', 'Wurm''s Tooth', '0bd81e8c2b91822db1c7bdd73798d944', 'battle_rule_v1:d9b0b164dd03d62a2e48b0b80af59bbc', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_gain_life_v1","effect":"life_gain_engine","spell_cast_gain_life":true,"spell_cast_gain_life_amount":1,"spell_cast_gain_life_any_player":true,"spell_cast_gain_life_optional":true,"spell_cast_gain_life_required_colors":["G"],"trigger":"spell_cast","trigger_effect":"gain_life","xmage_ability_class":"WurmsToothAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_gain_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WurmsTooth translated into ManaLoom runtime scope xmage_spell_cast_gain_life_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('angel''s feather', 'Angel''s Feather', 'ebb29991d0f1a0b0308b4aa8d2470bb6', 'battle_rule_v1:7f669b4064cd3aba79509b3719f22009', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_gain_life_v1","effect":"life_gain_engine","spell_cast_gain_life":true,"spell_cast_gain_life_amount":1,"spell_cast_gain_life_any_player":true,"spell_cast_gain_life_optional":true,"spell_cast_gain_life_required_colors":["W"],"trigger":"spell_cast","trigger_effect":"gain_life","xmage_ability_class":"SpellCastAllTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_gain_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AngelsFeather translated into ManaLoom runtime scope xmage_spell_cast_gain_life_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('demon''s horn', 'Demon''s Horn', '2e519ebb21b2192d902d05c674b66d8e', 'battle_rule_v1:99bad2d1c6a72913caa5a932afb8056d', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_gain_life_v1","effect":"life_gain_engine","spell_cast_gain_life":true,"spell_cast_gain_life_amount":1,"spell_cast_gain_life_any_player":true,"spell_cast_gain_life_optional":true,"spell_cast_gain_life_required_colors":["B"],"trigger":"spell_cast","trigger_effect":"gain_life","xmage_ability_class":"SpellCastAllTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_gain_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DemonsHorn translated into ManaLoom runtime scope xmage_spell_cast_gain_life_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dragon''s claw', 'Dragon''s Claw', '01106f0c718a60bba4eb37ee26b98bc5', 'battle_rule_v1:7c74d4b0b1816df66cdeceb8551b9cdb', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_gain_life_v1","effect":"life_gain_engine","spell_cast_gain_life":true,"spell_cast_gain_life_amount":1,"spell_cast_gain_life_any_player":true,"spell_cast_gain_life_optional":true,"spell_cast_gain_life_required_colors":["R"],"trigger":"spell_cast","trigger_effect":"gain_life","xmage_ability_class":"SpellCastAllTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_gain_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DragonsClaw translated into ManaLoom runtime scope xmage_spell_cast_gain_life_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kraken''s eye', 'Kraken''s Eye', '731908acaaf356b2801492a987f3fdf1', 'battle_rule_v1:d7025bc05f9319aef58aebd511653833', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_gain_life_v1","effect":"life_gain_engine","spell_cast_gain_life":true,"spell_cast_gain_life_amount":1,"spell_cast_gain_life_any_player":true,"spell_cast_gain_life_optional":true,"spell_cast_gain_life_required_colors":["U"],"trigger":"spell_cast","trigger_effect":"gain_life","xmage_ability_class":"KrakensEyeAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_gain_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KrakensEye translated into ManaLoom runtime scope xmage_spell_cast_gain_life_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wurm''s tooth', 'Wurm''s Tooth', '0bd81e8c2b91822db1c7bdd73798d944', 'battle_rule_v1:d9b0b164dd03d62a2e48b0b80af59bbc', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_gain_life_v1","effect":"life_gain_engine","spell_cast_gain_life":true,"spell_cast_gain_life_amount":1,"spell_cast_gain_life_any_player":true,"spell_cast_gain_life_optional":true,"spell_cast_gain_life_required_colors":["G"],"trigger":"spell_cast","trigger_effect":"gain_life","xmage_ability_class":"WurmsToothAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_gain_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WurmsTooth translated into ManaLoom runtime scope xmage_spell_cast_gain_life_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('angel''s feather', 'Angel''s Feather', 'ebb29991d0f1a0b0308b4aa8d2470bb6', 'battle_rule_v1:7f669b4064cd3aba79509b3719f22009', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_gain_life_v1","effect":"life_gain_engine","spell_cast_gain_life":true,"spell_cast_gain_life_amount":1,"spell_cast_gain_life_any_player":true,"spell_cast_gain_life_optional":true,"spell_cast_gain_life_required_colors":["W"],"trigger":"spell_cast","trigger_effect":"gain_life","xmage_ability_class":"SpellCastAllTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_gain_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AngelsFeather translated into ManaLoom runtime scope xmage_spell_cast_gain_life_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('demon''s horn', 'Demon''s Horn', '2e519ebb21b2192d902d05c674b66d8e', 'battle_rule_v1:99bad2d1c6a72913caa5a932afb8056d', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_gain_life_v1","effect":"life_gain_engine","spell_cast_gain_life":true,"spell_cast_gain_life_amount":1,"spell_cast_gain_life_any_player":true,"spell_cast_gain_life_optional":true,"spell_cast_gain_life_required_colors":["B"],"trigger":"spell_cast","trigger_effect":"gain_life","xmage_ability_class":"SpellCastAllTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_gain_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DemonsHorn translated into ManaLoom runtime scope xmage_spell_cast_gain_life_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dragon''s claw', 'Dragon''s Claw', '01106f0c718a60bba4eb37ee26b98bc5', 'battle_rule_v1:7c74d4b0b1816df66cdeceb8551b9cdb', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_gain_life_v1","effect":"life_gain_engine","spell_cast_gain_life":true,"spell_cast_gain_life_amount":1,"spell_cast_gain_life_any_player":true,"spell_cast_gain_life_optional":true,"spell_cast_gain_life_required_colors":["R"],"trigger":"spell_cast","trigger_effect":"gain_life","xmage_ability_class":"SpellCastAllTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_gain_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DragonsClaw translated into ManaLoom runtime scope xmage_spell_cast_gain_life_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kraken''s eye', 'Kraken''s Eye', '731908acaaf356b2801492a987f3fdf1', 'battle_rule_v1:d7025bc05f9319aef58aebd511653833', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_gain_life_v1","effect":"life_gain_engine","spell_cast_gain_life":true,"spell_cast_gain_life_amount":1,"spell_cast_gain_life_any_player":true,"spell_cast_gain_life_optional":true,"spell_cast_gain_life_required_colors":["U"],"trigger":"spell_cast","trigger_effect":"gain_life","xmage_ability_class":"KrakensEyeAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_gain_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KrakensEye translated into ManaLoom runtime scope xmage_spell_cast_gain_life_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wurm''s tooth', 'Wurm''s Tooth', '0bd81e8c2b91822db1c7bdd73798d944', 'battle_rule_v1:d9b0b164dd03d62a2e48b0b80af59bbc', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_gain_life_v1","effect":"life_gain_engine","spell_cast_gain_life":true,"spell_cast_gain_life_amount":1,"spell_cast_gain_life_any_player":true,"spell_cast_gain_life_optional":true,"spell_cast_gain_life_required_colors":["G"],"trigger":"spell_cast","trigger_effect":"gain_life","xmage_ability_class":"WurmsToothAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_gain_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WurmsTooth translated into ManaLoom runtime scope xmage_spell_cast_gain_life_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
