BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg220_erode_sundering_destroy_exact_20260626_030046 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('erode', 'sundering eruption // volcanic fissure')
   OR normalized_name LIKE 'erode // %'
   OR normalized_name LIKE 'sundering eruption // volcanic fissure // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('erode', 'Erode', 'fade62a3cbc3e6987d7988b711a5a834', 'battle_rule_v1:dd175af9c77feea940de97138a916fe3', '{"ability_kind":"one_shot","basic_land_compensation_status":"annotation_only","battle_model_scope":"destroy_creature_or_planeswalker_target_controller_basic_land_tapped_annotation_v1","effect":"remove_permanent","instant":true,"target":"creature_or_planeswalker","target_controller_basic_land_tapped":true}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Erode mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('sundering eruption // volcanic fissure', 'Sundering Eruption // Volcanic Fissure', '09148a5a6f4d14c04a30bf19819e20b8', 'battle_rule_v1:98d0006543fc622cfc1d82991bd5a66a', '{"ability_kind":"one_shot","basic_land_compensation_status":"annotation_only","battle_model_scope":"destroy_target_land_target_controller_basic_land_tapped_nonfliers_cant_block_or_tapped_red_land_v1","cant_block_mode_status":"annotation_only","cant_block_target_restriction":"creatures_without_flying","effect":"remove_permanent","land_side_add_mana":"R","land_side_pay_three_life_else_tapped":true,"sorcery":true,"target":"land","target_controller_basic_land_tapped":true}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class SunderingEruption mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows')
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
    ('erode', 'Erode', 'fade62a3cbc3e6987d7988b711a5a834', 'battle_rule_v1:dd175af9c77feea940de97138a916fe3', '{"ability_kind":"one_shot","basic_land_compensation_status":"annotation_only","battle_model_scope":"destroy_creature_or_planeswalker_target_controller_basic_land_tapped_annotation_v1","effect":"remove_permanent","instant":true,"target":"creature_or_planeswalker","target_controller_basic_land_tapped":true}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Erode mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('sundering eruption // volcanic fissure', 'Sundering Eruption // Volcanic Fissure', '09148a5a6f4d14c04a30bf19819e20b8', 'battle_rule_v1:98d0006543fc622cfc1d82991bd5a66a', '{"ability_kind":"one_shot","basic_land_compensation_status":"annotation_only","battle_model_scope":"destroy_target_land_target_controller_basic_land_tapped_nonfliers_cant_block_or_tapped_red_land_v1","cant_block_mode_status":"annotation_only","cant_block_target_restriction":"creatures_without_flying","effect":"remove_permanent","land_side_add_mana":"R","land_side_pay_three_life_else_tapped":true,"sorcery":true,"target":"land","target_controller_basic_land_tapped":true}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class SunderingEruption mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows')
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
    ('erode', 'Erode', 'fade62a3cbc3e6987d7988b711a5a834', 'battle_rule_v1:dd175af9c77feea940de97138a916fe3', '{"ability_kind":"one_shot","basic_land_compensation_status":"annotation_only","battle_model_scope":"destroy_creature_or_planeswalker_target_controller_basic_land_tapped_annotation_v1","effect":"remove_permanent","instant":true,"target":"creature_or_planeswalker","target_controller_basic_land_tapped":true}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Erode mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('sundering eruption // volcanic fissure', 'Sundering Eruption // Volcanic Fissure', '09148a5a6f4d14c04a30bf19819e20b8', 'battle_rule_v1:98d0006543fc622cfc1d82991bd5a66a', '{"ability_kind":"one_shot","basic_land_compensation_status":"annotation_only","battle_model_scope":"destroy_target_land_target_controller_basic_land_tapped_nonfliers_cant_block_or_tapped_red_land_v1","cant_block_mode_status":"annotation_only","cant_block_target_restriction":"creatures_without_flying","effect":"remove_permanent","land_side_add_mana":"R","land_side_pay_three_life_else_tapped":true,"sorcery":true,"target":"land","target_controller_basic_land_tapped":true}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class SunderingEruption mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows')
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
