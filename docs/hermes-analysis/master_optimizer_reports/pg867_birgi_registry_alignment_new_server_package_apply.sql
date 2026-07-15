BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg867_birgi_registry_alignment_new_serve_20260715_153348 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('birgi, god of storytelling')
   OR normalized_name LIKE 'birgi, god of storytelling // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('birgi, god of storytelling', 'Birgi, God of Storytelling // Harnfel, Horn of Bounty', '5f1ed696a63cd668fd46a2fe9971a54e', 'battle_rule_v1:c21762e62b990dbb474be0b5764d71a7', '{"ability_kind":"triggered","back_face_harnfel_discard_exile_two_play_this_turn":true,"back_face_status":"annotation_only","battle_model_scope":"spell_cast_red_mana_trigger_boast_harnfel_annotation_v1","boast_twice_each_turn":true,"boast_twice_status":"annotation_only","cmc":3.0,"effect":"ramp_engine","is_creature_permanent":true,"mana_persists_steps":true,"power":3,"produces":"R","spell_cast_add_mana":1,"spell_cast_mana_color":"R","toughness":3,"trigger":"spell_cast"}'::jsonb, '{"category":"ramp","effect":"ramp_engine","subtype":"spell_cast_mana_engine"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage-authoritative Birgi front-face spell-cast red mana engine; boast-twice and Harnfel remain explicit annotations.', 'deprecate_nonmatching_rows')
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
    ('birgi, god of storytelling', 'Birgi, God of Storytelling // Harnfel, Horn of Bounty', '5f1ed696a63cd668fd46a2fe9971a54e', 'battle_rule_v1:c21762e62b990dbb474be0b5764d71a7', '{"ability_kind":"triggered","back_face_harnfel_discard_exile_two_play_this_turn":true,"back_face_status":"annotation_only","battle_model_scope":"spell_cast_red_mana_trigger_boast_harnfel_annotation_v1","boast_twice_each_turn":true,"boast_twice_status":"annotation_only","cmc":3.0,"effect":"ramp_engine","is_creature_permanent":true,"mana_persists_steps":true,"power":3,"produces":"R","spell_cast_add_mana":1,"spell_cast_mana_color":"R","toughness":3,"trigger":"spell_cast"}'::jsonb, '{"category":"ramp","effect":"ramp_engine","subtype":"spell_cast_mana_engine"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage-authoritative Birgi front-face spell-cast red mana engine; boast-twice and Harnfel remain explicit annotations.', 'deprecate_nonmatching_rows')
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
    ('birgi, god of storytelling', 'Birgi, God of Storytelling // Harnfel, Horn of Bounty', '5f1ed696a63cd668fd46a2fe9971a54e', 'battle_rule_v1:c21762e62b990dbb474be0b5764d71a7', '{"ability_kind":"triggered","back_face_harnfel_discard_exile_two_play_this_turn":true,"back_face_status":"annotation_only","battle_model_scope":"spell_cast_red_mana_trigger_boast_harnfel_annotation_v1","boast_twice_each_turn":true,"boast_twice_status":"annotation_only","cmc":3.0,"effect":"ramp_engine","is_creature_permanent":true,"mana_persists_steps":true,"power":3,"produces":"R","spell_cast_add_mana":1,"spell_cast_mana_color":"R","toughness":3,"trigger":"spell_cast"}'::jsonb, '{"category":"ramp","effect":"ramp_engine","subtype":"spell_cast_mana_engine"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage-authoritative Birgi front-face spell-cast red mana engine; boast-twice and Harnfel remain explicit annotations.', 'deprecate_nonmatching_rows')
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
