BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg185_fury_storm_copy_spell_20260624_201931 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('fury storm')
   OR normalized_name LIKE 'fury storm // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('fury storm', 'Fury Storm', '5a7a4b3e044452c015ecd91bc9897680', 'battle_rule_v1:1c5fc8fcfccde45171603a1ff05f4f05', '{"ability_kind":"one_shot","battle_model_scope":"copy_target_instant_or_sorcery_spell_may_choose_new_targets_v1","choose_new_targets_status":"may","commander_storm":true,"effect":"copy_spell","instant":true,"may_choose_new_targets":true,"target":"instant_or_sorcery_spell"}'::jsonb, '{"category":"combo_value","effect":"copy_spell","subtype":"stack_copy","timing":"resolution_or_trigger"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class FuryStorm mapped to family copy_spell_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('fury storm', 'Fury Storm', '5a7a4b3e044452c015ecd91bc9897680', 'battle_rule_v1:1c5fc8fcfccde45171603a1ff05f4f05', '{"ability_kind":"one_shot","battle_model_scope":"copy_target_instant_or_sorcery_spell_may_choose_new_targets_v1","choose_new_targets_status":"may","commander_storm":true,"effect":"copy_spell","instant":true,"may_choose_new_targets":true,"target":"instant_or_sorcery_spell"}'::jsonb, '{"category":"combo_value","effect":"copy_spell","subtype":"stack_copy","timing":"resolution_or_trigger"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class FuryStorm mapped to family copy_spell_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
    AND r.logical_rule_key <> p.logical_rule_key
  RETURNING r.*
)
SELECT count(*) AS deprecated_shadow_rows FROM deprecated;

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('fury storm', 'Fury Storm', '5a7a4b3e044452c015ecd91bc9897680', 'battle_rule_v1:1c5fc8fcfccde45171603a1ff05f4f05', '{"ability_kind":"one_shot","battle_model_scope":"copy_target_instant_or_sorcery_spell_may_choose_new_targets_v1","choose_new_targets_status":"may","commander_storm":true,"effect":"copy_spell","instant":true,"may_choose_new_targets":true,"target":"instant_or_sorcery_spell"}'::jsonb, '{"category":"combo_value","effect":"copy_spell","subtype":"stack_copy","timing":"resolution_or_trigger"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class FuryStorm mapped to family copy_spell_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
