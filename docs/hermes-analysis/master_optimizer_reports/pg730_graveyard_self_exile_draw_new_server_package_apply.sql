BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg730_graveyard_self_exile_draw_new_serv_20260711_002716 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('cobbled lancer', 'maestros initiate')
   OR normalized_name LIKE 'cobbled lancer // %'
   OR normalized_name LIKE 'maestros initiate // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('cobbled lancer', 'Cobbled Lancer', '965eb892d89598dcd8397d1c3a72e0a0', 'battle_rule_v1:fd90e2f58196771de6296762a5978d7b', '{"ability_kind":"activated","activated_draw":true,"activated_draw_count":1,"activated_effect":"draw_cards","activation_cost_colors":["U"],"activation_cost_generic":3,"activation_cost_mana":"{3}{U}","activation_requires_exile_source_from_graveyard":true,"activation_requires_sacrifice":false,"activation_requires_tap":false,"activation_zone":"graveyard","battle_model_scope":"xmage_permanent_simple_activated_draw_v1","count":1,"effect":"draw_engine","permanent_type":"creature","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CobbledLancer translated into ManaLoom runtime scope xmage_permanent_simple_activated_draw_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated draw ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('maestros initiate', 'Maestros Initiate', 'd0d9bfb862fb4711bc005520811ded79', 'battle_rule_v1:0e3c9c3f262ff70d066ffde1d9c555df', '{"ability_kind":"activated","activated_discard_count":1,"activated_draw_count":2,"activated_draw_discard":true,"activated_effect":"draw_discard","activation_cost_colors":["U/R"],"activation_cost_generic":4,"activation_cost_mana":"{4}{U/R}","activation_requires_exile_source_from_graveyard":true,"activation_requires_sacrifice":false,"activation_requires_tap":false,"activation_zone":"graveyard","battle_model_scope":"xmage_permanent_simple_activated_draw_discard_v1","count":2,"discard_count":1,"draw_count":2,"effect":"draw_engine","permanent_type":"creature","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DrawDiscardControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MaestrosInitiate translated into ManaLoom runtime scope xmage_permanent_simple_activated_draw_discard_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated draw-then-discard ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('cobbled lancer', 'Cobbled Lancer', '965eb892d89598dcd8397d1c3a72e0a0', 'battle_rule_v1:fd90e2f58196771de6296762a5978d7b', '{"ability_kind":"activated","activated_draw":true,"activated_draw_count":1,"activated_effect":"draw_cards","activation_cost_colors":["U"],"activation_cost_generic":3,"activation_cost_mana":"{3}{U}","activation_requires_exile_source_from_graveyard":true,"activation_requires_sacrifice":false,"activation_requires_tap":false,"activation_zone":"graveyard","battle_model_scope":"xmage_permanent_simple_activated_draw_v1","count":1,"effect":"draw_engine","permanent_type":"creature","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CobbledLancer translated into ManaLoom runtime scope xmage_permanent_simple_activated_draw_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated draw ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('maestros initiate', 'Maestros Initiate', 'd0d9bfb862fb4711bc005520811ded79', 'battle_rule_v1:0e3c9c3f262ff70d066ffde1d9c555df', '{"ability_kind":"activated","activated_discard_count":1,"activated_draw_count":2,"activated_draw_discard":true,"activated_effect":"draw_discard","activation_cost_colors":["U/R"],"activation_cost_generic":4,"activation_cost_mana":"{4}{U/R}","activation_requires_exile_source_from_graveyard":true,"activation_requires_sacrifice":false,"activation_requires_tap":false,"activation_zone":"graveyard","battle_model_scope":"xmage_permanent_simple_activated_draw_discard_v1","count":2,"discard_count":1,"draw_count":2,"effect":"draw_engine","permanent_type":"creature","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DrawDiscardControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MaestrosInitiate translated into ManaLoom runtime scope xmage_permanent_simple_activated_draw_discard_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated draw-then-discard ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('cobbled lancer', 'Cobbled Lancer', '965eb892d89598dcd8397d1c3a72e0a0', 'battle_rule_v1:fd90e2f58196771de6296762a5978d7b', '{"ability_kind":"activated","activated_draw":true,"activated_draw_count":1,"activated_effect":"draw_cards","activation_cost_colors":["U"],"activation_cost_generic":3,"activation_cost_mana":"{3}{U}","activation_requires_exile_source_from_graveyard":true,"activation_requires_sacrifice":false,"activation_requires_tap":false,"activation_zone":"graveyard","battle_model_scope":"xmage_permanent_simple_activated_draw_v1","count":1,"effect":"draw_engine","permanent_type":"creature","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CobbledLancer translated into ManaLoom runtime scope xmage_permanent_simple_activated_draw_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated draw ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('maestros initiate', 'Maestros Initiate', 'd0d9bfb862fb4711bc005520811ded79', 'battle_rule_v1:0e3c9c3f262ff70d066ffde1d9c555df', '{"ability_kind":"activated","activated_discard_count":1,"activated_draw_count":2,"activated_draw_discard":true,"activated_effect":"draw_discard","activation_cost_colors":["U/R"],"activation_cost_generic":4,"activation_cost_mana":"{4}{U/R}","activation_requires_exile_source_from_graveyard":true,"activation_requires_sacrifice":false,"activation_requires_tap":false,"activation_zone":"graveyard","battle_model_scope":"xmage_permanent_simple_activated_draw_discard_v1","count":2,"discard_count":1,"draw_count":2,"effect":"draw_engine","permanent_type":"creature","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DrawDiscardControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MaestrosInitiate translated into ManaLoom runtime scope xmage_permanent_simple_activated_draw_discard_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated draw-then-discard ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
