BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg147_eldrazi_confluence_20260624_063723 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('eldrazi confluence')
   OR normalized_name LIKE 'eldrazi confluence // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('eldrazi confluence', 'Eldrazi Confluence', '62340dc75c903ea4f9936ac536cc0a76', 'battle_rule_v1:14c689c3a27f3fb564fd4f2741c1be3a', '{"ability_kind":"one_shot","battle_model_scope":"choose_three_pump_blink_tapped_or_create_eldrazi_scion_v1","effect":"modal_spell","instant":true,"modal_choose_count":3,"modal_may_repeat_modes":true,"mode_blink_target_nonland_permanent_tapped":true,"mode_create_eldrazi_scion":true,"mode_target_creature_plus_three_minus_three":true,"token_colors":[],"token_name":"Eldrazi Scion Token","token_power":1,"token_sacrifice_for_colorless_mana":true,"token_subtype":"Eldrazi Scion","token_toughness":1}'::jsonb, '{"category":"interaction","effect":"modal_spell","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class EldraziConfluence mapped to family modal_spell; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
    ('eldrazi confluence', 'Eldrazi Confluence', '62340dc75c903ea4f9936ac536cc0a76', 'battle_rule_v1:14c689c3a27f3fb564fd4f2741c1be3a', '{"ability_kind":"one_shot","battle_model_scope":"choose_three_pump_blink_tapped_or_create_eldrazi_scion_v1","effect":"modal_spell","instant":true,"modal_choose_count":3,"modal_may_repeat_modes":true,"mode_blink_target_nonland_permanent_tapped":true,"mode_create_eldrazi_scion":true,"mode_target_creature_plus_three_minus_three":true,"token_colors":[],"token_name":"Eldrazi Scion Token","token_power":1,"token_sacrifice_for_colorless_mana":true,"token_subtype":"Eldrazi Scion","token_toughness":1}'::jsonb, '{"category":"interaction","effect":"modal_spell","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class EldraziConfluence mapped to family modal_spell; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
    ('eldrazi confluence', 'Eldrazi Confluence', '62340dc75c903ea4f9936ac536cc0a76', 'battle_rule_v1:14c689c3a27f3fb564fd4f2741c1be3a', '{"ability_kind":"one_shot","battle_model_scope":"choose_three_pump_blink_tapped_or_create_eldrazi_scion_v1","effect":"modal_spell","instant":true,"modal_choose_count":3,"modal_may_repeat_modes":true,"mode_blink_target_nonland_permanent_tapped":true,"mode_create_eldrazi_scion":true,"mode_target_creature_plus_three_minus_three":true,"token_colors":[],"token_name":"Eldrazi Scion Token","token_power":1,"token_sacrifice_for_colorless_mana":true,"token_subtype":"Eldrazi Scion","token_toughness":1}'::jsonb, '{"category":"interaction","effect":"modal_spell","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class EldraziConfluence mapped to family modal_spell; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
