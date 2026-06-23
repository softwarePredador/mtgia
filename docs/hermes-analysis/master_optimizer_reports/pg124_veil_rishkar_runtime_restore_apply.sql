BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg124_veil_rishkar_runtime_restore_20260623_234800 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('rishkar, peema renegade', 'veil of summer');

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('rishkar, peema renegade', 'Rishkar, Peema Renegade', 'f8292a28b5787943930f045618fcb8c9', 'battle_rule_v1:3e4f3afe97ce898401c128885bdf6fc3', '{"ability_kind":"triggered","battle_model_scope":"rishkar_counter_mana_creature_waiver_v1","countered_creatures_tap_for_mana":true,"effect":"creature","etb_plus_one_counter_targets":2,"power":2,"produces":"G","toughness":2}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class RishkarPeemaRenegade mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('veil of summer', 'Veil of Summer', '2de390b3ac2c9680e9c3b8b5fe09d103', 'battle_rule_v1:345e8a0b063c6d805551bfb85618f0f6', '{"ability_kind":"one_shot","battle_model_scope":"veil_of_summer_draw_and_protection_waiver_v1","conditional_draw_if_opponent_cast_blue_or_black_spell_this_turn":true,"controller_and_permanents_hexproof_from_colors_until_eot":["U","B"],"count":1,"effect":"draw_cards","instant":true,"spells_you_control_cant_be_countered_this_turn":true}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class VeilOfSummer mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
    ('rishkar, peema renegade', 'Rishkar, Peema Renegade', 'f8292a28b5787943930f045618fcb8c9', 'battle_rule_v1:3e4f3afe97ce898401c128885bdf6fc3', '{"ability_kind":"triggered","battle_model_scope":"rishkar_counter_mana_creature_waiver_v1","countered_creatures_tap_for_mana":true,"effect":"creature","etb_plus_one_counter_targets":2,"power":2,"produces":"G","toughness":2}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class RishkarPeemaRenegade mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('veil of summer', 'Veil of Summer', '2de390b3ac2c9680e9c3b8b5fe09d103', 'battle_rule_v1:345e8a0b063c6d805551bfb85618f0f6', '{"ability_kind":"one_shot","battle_model_scope":"veil_of_summer_draw_and_protection_waiver_v1","conditional_draw_if_opponent_cast_blue_or_black_spell_this_turn":true,"controller_and_permanents_hexproof_from_colors_until_eot":["U","B"],"count":1,"effect":"draw_cards","instant":true,"spells_you_control_cant_be_countered_this_turn":true}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class VeilOfSummer mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
    ('rishkar, peema renegade', 'Rishkar, Peema Renegade', 'f8292a28b5787943930f045618fcb8c9', 'battle_rule_v1:3e4f3afe97ce898401c128885bdf6fc3', '{"ability_kind":"triggered","battle_model_scope":"rishkar_counter_mana_creature_waiver_v1","countered_creatures_tap_for_mana":true,"effect":"creature","etb_plus_one_counter_targets":2,"power":2,"produces":"G","toughness":2}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class RishkarPeemaRenegade mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('veil of summer', 'Veil of Summer', '2de390b3ac2c9680e9c3b8b5fe09d103', 'battle_rule_v1:345e8a0b063c6d805551bfb85618f0f6', '{"ability_kind":"one_shot","battle_model_scope":"veil_of_summer_draw_and_protection_waiver_v1","conditional_draw_if_opponent_cast_blue_or_black_spell_this_turn":true,"controller_and_permanents_hexproof_from_colors_until_eot":["U","B"],"count":1,"effect":"draw_cards","instant":true,"spells_you_control_cant_be_countered_this_turn":true}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class VeilOfSummer mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
