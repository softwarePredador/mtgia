BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg174_copy_spell_engines_20260624_124529 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('double vision', 'swarm intelligence')
   OR normalized_name LIKE 'double vision // %'
   OR normalized_name LIKE 'swarm intelligence // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('double vision', 'Double Vision', '1106bfd584470ed10401167bf452f0a4', 'battle_rule_v1:6b73ccf8b05f7853dcfeae1825b70708', '{"ability_kind":"triggered","battle_model_scope":"first_instant_sorcery_cast_each_turn_copy_own_spell_v1","choose_new_targets_status":"may","effect":"copy_spell","may_choose_new_targets":true,"target":"own_instant_or_sorcery_on_stack","trigger":"instant_sorcery_cast","trigger_effect":"copy_spell","trigger_first_instant_or_sorcery_each_turn":true}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class DoubleVision mapped to family copy_spell_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('swarm intelligence', 'Swarm Intelligence', '1acd382841c8fabf16162bd47f9e4a03', 'battle_rule_v1:9f1ee8ecd68dad5bf39139de17c013eb', '{"ability_kind":"triggered","battle_model_scope":"instant_sorcery_cast_copy_own_spell_v1","choose_new_targets_status":"may","effect":"copy_spell","may_choose_new_targets":true,"target":"own_instant_or_sorcery_on_stack","trigger":"instant_sorcery_cast","trigger_effect":"copy_spell"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class SwarmIntelligence mapped to family copy_spell_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
    ('double vision', 'Double Vision', '1106bfd584470ed10401167bf452f0a4', 'battle_rule_v1:6b73ccf8b05f7853dcfeae1825b70708', '{"ability_kind":"triggered","battle_model_scope":"first_instant_sorcery_cast_each_turn_copy_own_spell_v1","choose_new_targets_status":"may","effect":"copy_spell","may_choose_new_targets":true,"target":"own_instant_or_sorcery_on_stack","trigger":"instant_sorcery_cast","trigger_effect":"copy_spell","trigger_first_instant_or_sorcery_each_turn":true}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class DoubleVision mapped to family copy_spell_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('swarm intelligence', 'Swarm Intelligence', '1acd382841c8fabf16162bd47f9e4a03', 'battle_rule_v1:9f1ee8ecd68dad5bf39139de17c013eb', '{"ability_kind":"triggered","battle_model_scope":"instant_sorcery_cast_copy_own_spell_v1","choose_new_targets_status":"may","effect":"copy_spell","may_choose_new_targets":true,"target":"own_instant_or_sorcery_on_stack","trigger":"instant_sorcery_cast","trigger_effect":"copy_spell"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class SwarmIntelligence mapped to family copy_spell_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
    ('double vision', 'Double Vision', '1106bfd584470ed10401167bf452f0a4', 'battle_rule_v1:6b73ccf8b05f7853dcfeae1825b70708', '{"ability_kind":"triggered","battle_model_scope":"first_instant_sorcery_cast_each_turn_copy_own_spell_v1","choose_new_targets_status":"may","effect":"copy_spell","may_choose_new_targets":true,"target":"own_instant_or_sorcery_on_stack","trigger":"instant_sorcery_cast","trigger_effect":"copy_spell","trigger_first_instant_or_sorcery_each_turn":true}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class DoubleVision mapped to family copy_spell_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('swarm intelligence', 'Swarm Intelligence', '1acd382841c8fabf16162bd47f9e4a03', 'battle_rule_v1:9f1ee8ecd68dad5bf39139de17c013eb', '{"ability_kind":"triggered","battle_model_scope":"instant_sorcery_cast_copy_own_spell_v1","choose_new_targets_status":"may","effect":"copy_spell","may_choose_new_targets":true,"target":"own_instant_or_sorcery_on_stack","trigger":"instant_sorcery_cast","trigger_effect":"copy_spell"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class SwarmIntelligence mapped to family copy_spell_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
