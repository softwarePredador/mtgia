BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg109_benders_waterskin_victory_chimes_20260623_171938 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('bender''s waterskin', 'victory chimes');

DO $$
DECLARE
  v_bad_count integer;
BEGIN
  WITH wanted(normalized_name, expected_hash) AS (
    VALUES
      ('bender''s waterskin', '1bd371e1f09ed8b48837c3fc5cd2a2ff'),
      ('victory chimes', '8ca84e1f2e9f3efd1fe740d16d216105')
  ),
  matched AS (
    SELECT w.normalized_name, count(c.id) AS matched_rows
    FROM wanted w
    LEFT JOIN public.cards c
      ON lower(c.name) = w.normalized_name
     AND md5(coalesce(c.oracle_text, '')) = w.expected_hash
    GROUP BY w.normalized_name
  )
  SELECT count(*)
    INTO v_bad_count
  FROM matched
  WHERE matched_rows <> 1;

  IF v_bad_count <> 0 THEN
    RAISE EXCEPTION 'PG109 abort: expected exactly one Oracle-hash-matched card row for each target, bad target count %', v_bad_count;
  END IF;
END $$;

WITH deprecated AS (
  UPDATE public.card_battle_rules r
  SET
    review_status = 'deprecated',
    execution_status = 'disabled',
    updated_at = now(),
    notes = concat_ws(
      E'\n',
      nullif(r.notes, ''),
      'PG109: deprecated stale broad/wrong row after Oracle/XMage-backed mana artifact rule was promoted with hash and model scope.'
    )
  WHERE r.normalized_name IN ('bender''s waterskin', 'victory chimes')
    AND r.logical_rule_key NOT IN (
      'battle_rule_v1:cf94f06a51a48080913a6c01290c7be2',
      'battle_rule_v1:85d354bb1522e745de9e1bac865fd5e0'
    )
  RETURNING r.*
)
SELECT count(*) AS deprecated_shadow_rows
FROM deprecated;

WITH target_cards AS (
  SELECT lower(name) AS normalized_name, id, name, md5(coalesce(oracle_text, '')) AS oracle_hash
  FROM public.cards
  WHERE lower(name) IN ('bender''s waterskin', 'victory chimes')
),
payloads AS (
  SELECT
    'bender''s waterskin'::text AS normalized_name,
    'battle_rule_v1:cf94f06a51a48080913a6c01290c7be2'::text AS logical_rule_key,
    '{"battle_model_scope":"artifact_any_color_mana_rock_untaps_each_opponent_untap_step_v1","cmc":3.0,"effect":"ramp_permanent","mana_produced":1,"produces":"WUBRG","untaps_each_opponent_untap":true}'::jsonb AS effect_json,
    '{"category":"ramp","effect":"ramp_permanent","subtype":"any_color_mana_rock"}'::jsonb AS deck_role_json,
    0.96::numeric AS confidence,
    '1bd371e1f09ed8b48837c3fc5cd2a2ff'::text AS oracle_hash,
    'PG109: Oracle/XMage-backed Bender''s Waterskin rule. Mana behavior is one mana of any color via wildcard; multiplayer untap cadence is preserved as model-scope metadata.'::text AS notes
  UNION ALL
  SELECT
    'victory chimes'::text,
    'battle_rule_v1:85d354bb1522e745de9e1bac865fd5e0'::text,
    '{"battle_model_scope":"political_colorless_mana_rock_multiplayer_untap_v1","cmc":3.0,"effect":"ramp_permanent","mana_produced":1,"produces":"C","untaps_each_opponent_untap":true}'::jsonb,
    '{"category":"ramp","effect":"ramp_permanent","subtype":"political_colorless_mana_rock"}'::jsonb,
    0.96::numeric,
    '8ca84e1f2e9f3efd1fe740d16d216105'::text,
    'PG109: Oracle/XMage-backed Victory Chimes rule. Runtime treats it as colorless mana support, not draw_engine; political player choice and multiplayer untap cadence are preserved as scope metadata.'
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
    p.normalized_name,
    tc.id,
    tc.name,
    p.effect_json,
    p.deck_role_json,
    'curated',
    p.confidence,
    'verified',
    2,
    p.oracle_hash,
    p.notes,
    'codex-pg109',
    now(),
    now(),
    now(),
    now(),
    p.logical_rule_key,
    'auto'
  FROM payloads p
  JOIN target_cards tc ON tc.normalized_name = p.normalized_name AND tc.oracle_hash = p.oracle_hash
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
SELECT count(*) AS upserted_rows
FROM upserted;

COMMIT;
