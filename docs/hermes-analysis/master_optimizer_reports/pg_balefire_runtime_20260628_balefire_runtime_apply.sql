BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg_balefire_runtime_20260628_balefire_runtime_20260628_1 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('balefire liege')
   OR normalized_name LIKE 'balefire liege // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('balefire liege', 'Balefire Liege', '467dd11263f2854e2d9fc487a127ced6', 'battle_rule_v1:0d0c24a976d267410f08eb69efa9d3d7', '{"ability_kind":"triggered","battle_model_scope":"red_spell_damage_white_spell_lifegain_static_creature_boost_v1","cmc":5.0,"effect":"creature","power":2,"red_spell_trigger_damage":3,"red_spell_trigger_damage_target":"player_or_planeswalker","static_boost_other_red_creatures_you_control":{"power":1,"toughness":1},"static_boost_other_white_creatures_you_control":{"power":1,"toughness":1},"toughness":4,"trigger":"spell_cast","trigger_effect":"spell_color_damage_life","white_spell_trigger_gain_life":3}'::jsonb, '{"category":"burn_lifegain_engine","effect":"spell_color_damage_life","subtype":"red_spell_damage_white_spell_lifegain","timing":"static_and_triggered"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class BalefireLiege mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows')
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
    ('balefire liege', 'Balefire Liege', '467dd11263f2854e2d9fc487a127ced6', 'battle_rule_v1:0d0c24a976d267410f08eb69efa9d3d7', '{"ability_kind":"triggered","battle_model_scope":"red_spell_damage_white_spell_lifegain_static_creature_boost_v1","cmc":5.0,"effect":"creature","power":2,"red_spell_trigger_damage":3,"red_spell_trigger_damage_target":"player_or_planeswalker","static_boost_other_red_creatures_you_control":{"power":1,"toughness":1},"static_boost_other_white_creatures_you_control":{"power":1,"toughness":1},"toughness":4,"trigger":"spell_cast","trigger_effect":"spell_color_damage_life","white_spell_trigger_gain_life":3}'::jsonb, '{"category":"burn_lifegain_engine","effect":"spell_color_damage_life","subtype":"red_spell_damage_white_spell_lifegain","timing":"static_and_triggered"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class BalefireLiege mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows')
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
    ('balefire liege', 'Balefire Liege', '467dd11263f2854e2d9fc487a127ced6', 'battle_rule_v1:0d0c24a976d267410f08eb69efa9d3d7', '{"ability_kind":"triggered","battle_model_scope":"red_spell_damage_white_spell_lifegain_static_creature_boost_v1","cmc":5.0,"effect":"creature","power":2,"red_spell_trigger_damage":3,"red_spell_trigger_damage_target":"player_or_planeswalker","static_boost_other_red_creatures_you_control":{"power":1,"toughness":1},"static_boost_other_white_creatures_you_control":{"power":1,"toughness":1},"toughness":4,"trigger":"spell_cast","trigger_effect":"spell_color_damage_life","white_spell_trigger_gain_life":3}'::jsonb, '{"category":"burn_lifegain_engine","effect":"spell_color_damage_life","subtype":"red_spell_damage_white_spell_lifegain","timing":"static_and_triggered"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class BalefireLiege mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows')
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
