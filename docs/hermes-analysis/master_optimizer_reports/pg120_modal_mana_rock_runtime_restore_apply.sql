BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg120_modal_mana_rock_runtime_restore_20260623_224532 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('hedron archive', 'mind stone', 'stonespeaker crystal');

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('hedron archive', 'Hedron Archive', '0b901e920cec79011b3c835d55d3c859', 'battle_rule_v1:699a8966e4ddb5d8b8a54f57e243bf7f', '{"activated_self_sacrifice_draw":true,"activation_cost_generic":2,"activation_requires_tap":true,"battle_model_scope":"two_mana_rock_self_sacrifice_draw_two_v1","draw_on_self_sacrifice":2,"effect":"ramp_permanent","mana_produced":2,"produces":"C"}'::jsonb, '{"category":"ramp","effect":"ramp_permanent","subtype":"modal_mana_rock","timing":"activated"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class HedronArchive mapped to family modal_mana_rock; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('mind stone', 'Mind Stone', '8d1c9b62d7e5642df44a61a63de5e240', 'battle_rule_v1:3818b990dbad7de33216aee39fbb14c8', '{"activated_self_sacrifice_draw":true,"activation_cost_generic":1,"activation_requires_tap":true,"battle_model_scope":"mana_rock_self_sacrifice_draw_v1","effect":"ramp_permanent","mana_produced":1,"produces":"C"}'::jsonb, '{"category":"ramp","effect":"ramp_permanent","subtype":"modal_mana_rock","timing":"activated"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class MindStone mapped to family modal_mana_rock; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('stonespeaker crystal', 'Stonespeaker Crystal', '28a979e8676f38d3fa18b199d3f7802b', 'battle_rule_v1:3b749c5de073394f1c912fa43d8e7c02', '{"activated_exile_target_player_graveyards":true,"activated_self_sacrifice_draw":true,"activation_cost_generic":2,"activation_requires_tap":true,"battle_model_scope":"two_mana_rock_graveyard_hate_cantrip_v1","effect":"ramp_permanent","mana_produced":2,"produces":"C"}'::jsonb, '{"category":"ramp","effect":"ramp_permanent","subtype":"modal_mana_rock","timing":"activated"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class StonespeakerCrystal mapped to family modal_mana_rock; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
      ON lower(c.name) = p.normalized_name
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

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('hedron archive', 'Hedron Archive', '0b901e920cec79011b3c835d55d3c859', 'battle_rule_v1:699a8966e4ddb5d8b8a54f57e243bf7f', '{"activated_self_sacrifice_draw":true,"activation_cost_generic":2,"activation_requires_tap":true,"battle_model_scope":"two_mana_rock_self_sacrifice_draw_two_v1","draw_on_self_sacrifice":2,"effect":"ramp_permanent","mana_produced":2,"produces":"C"}'::jsonb, '{"category":"ramp","effect":"ramp_permanent","subtype":"modal_mana_rock","timing":"activated"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class HedronArchive mapped to family modal_mana_rock; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('mind stone', 'Mind Stone', '8d1c9b62d7e5642df44a61a63de5e240', 'battle_rule_v1:3818b990dbad7de33216aee39fbb14c8', '{"activated_self_sacrifice_draw":true,"activation_cost_generic":1,"activation_requires_tap":true,"battle_model_scope":"mana_rock_self_sacrifice_draw_v1","effect":"ramp_permanent","mana_produced":1,"produces":"C"}'::jsonb, '{"category":"ramp","effect":"ramp_permanent","subtype":"modal_mana_rock","timing":"activated"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class MindStone mapped to family modal_mana_rock; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('stonespeaker crystal', 'Stonespeaker Crystal', '28a979e8676f38d3fa18b199d3f7802b', 'battle_rule_v1:3b749c5de073394f1c912fa43d8e7c02', '{"activated_exile_target_player_graveyards":true,"activated_self_sacrifice_draw":true,"activation_cost_generic":2,"activation_requires_tap":true,"battle_model_scope":"two_mana_rock_graveyard_hate_cantrip_v1","effect":"ramp_permanent","mana_produced":2,"produces":"C"}'::jsonb, '{"category":"ramp","effect":"ramp_permanent","subtype":"modal_mana_rock","timing":"activated"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class StonespeakerCrystal mapped to family modal_mana_rock; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
),
deprecated AS (
  UPDATE public.card_battle_rules r
  SET
    review_status = 'deprecated',
    execution_status = 'disabled',
    updated_at = now(),
    notes = concat_ws(E'\n', nullif(r.notes, ''), 'XMage batch package: deprecated stale shadow before curated batch rule upsert.')
  FROM proposed p
  WHERE r.normalized_name = p.normalized_name
    AND r.logical_rule_key <> p.logical_rule_key
  RETURNING r.*
)
SELECT count(*) AS deprecated_shadow_rows FROM deprecated;

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('hedron archive', 'Hedron Archive', '0b901e920cec79011b3c835d55d3c859', 'battle_rule_v1:699a8966e4ddb5d8b8a54f57e243bf7f', '{"activated_self_sacrifice_draw":true,"activation_cost_generic":2,"activation_requires_tap":true,"battle_model_scope":"two_mana_rock_self_sacrifice_draw_two_v1","draw_on_self_sacrifice":2,"effect":"ramp_permanent","mana_produced":2,"produces":"C"}'::jsonb, '{"category":"ramp","effect":"ramp_permanent","subtype":"modal_mana_rock","timing":"activated"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class HedronArchive mapped to family modal_mana_rock; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('mind stone', 'Mind Stone', '8d1c9b62d7e5642df44a61a63de5e240', 'battle_rule_v1:3818b990dbad7de33216aee39fbb14c8', '{"activated_self_sacrifice_draw":true,"activation_cost_generic":1,"activation_requires_tap":true,"battle_model_scope":"mana_rock_self_sacrifice_draw_v1","effect":"ramp_permanent","mana_produced":1,"produces":"C"}'::jsonb, '{"category":"ramp","effect":"ramp_permanent","subtype":"modal_mana_rock","timing":"activated"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class MindStone mapped to family modal_mana_rock; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('stonespeaker crystal', 'Stonespeaker Crystal', '28a979e8676f38d3fa18b199d3f7802b', 'battle_rule_v1:3b749c5de073394f1c912fa43d8e7c02', '{"activated_exile_target_player_graveyards":true,"activated_self_sacrifice_draw":true,"activation_cost_generic":2,"activation_requires_tap":true,"battle_model_scope":"two_mana_rock_graveyard_hate_cantrip_v1","effect":"ramp_permanent","mana_produced":2,"produces":"C"}'::jsonb, '{"category":"ramp","effect":"ramp_permanent","subtype":"modal_mana_rock","timing":"activated"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class StonespeakerCrystal mapped to family modal_mana_rock; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
    ON lower(c.name) = p.normalized_name
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
    p.notes
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
