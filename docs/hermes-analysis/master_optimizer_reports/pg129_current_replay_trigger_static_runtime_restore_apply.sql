BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg129_current_replay_trigger_static_runtime_restore_2026 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('faerie mastermind', 'vexing bauble', 'nezahal, primal tide');

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('faerie mastermind', 'Faerie Mastermind', '92f520c17a15390fa0d0ea1b1272bc6c', 'battle_rule_v1:d71dbf6903f52abd4bfe443bab1dc0a9', '{"ability_kind":"triggered","activated_each_player_draw_cost":"{3}{U}","activated_each_player_draw_count":1,"battle_model_scope":"flash_flying_second_opponent_draw_draw_one_and_activated_each_player_draw_v1","effect":"creature","flash":true,"flying":true,"opponent_second_card_each_turn_draw":1,"power":2,"toughness":1}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class FaerieMastermind mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('vexing bauble', 'Vexing Bauble', '020e696ec9560830bb82bf0244595d69', 'battle_rule_v1:ad19691a7b388a47b6775f5e16275403', '{"ability_kind":"triggered","activated_generic_one_tap_sacrifice_draw":1,"battle_model_scope":"counter_no_mana_spent_spells_and_cantrip_sacrifice_v1","effect":"artifact","trigger_counter_spell_if_no_mana_was_spent":true}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class VexingBauble mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('nezahal, primal tide', 'Nezahal, Primal Tide', '64ff656e777df4caae96816eccf5a387', 'battle_rule_v1:7b908a525415c4da327930f6d4b29aba', '{"ability_kind":"triggered","activated_discard_cards_to_exile_and_return_tapped_count":3,"battle_model_scope":"cant_be_countered_no_max_hand_opponent_noncreature_cast_draw_exile_blink_v1","cant_be_countered":true,"effect":"creature","no_maximum_hand_size":true,"opponent_casts_noncreature_draw":1,"power":7,"toughness":7}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class NezahalPrimalTide mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
    ('faerie mastermind', 'Faerie Mastermind', '92f520c17a15390fa0d0ea1b1272bc6c', 'battle_rule_v1:d71dbf6903f52abd4bfe443bab1dc0a9', '{"ability_kind":"triggered","activated_each_player_draw_cost":"{3}{U}","activated_each_player_draw_count":1,"battle_model_scope":"flash_flying_second_opponent_draw_draw_one_and_activated_each_player_draw_v1","effect":"creature","flash":true,"flying":true,"opponent_second_card_each_turn_draw":1,"power":2,"toughness":1}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class FaerieMastermind mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('vexing bauble', 'Vexing Bauble', '020e696ec9560830bb82bf0244595d69', 'battle_rule_v1:ad19691a7b388a47b6775f5e16275403', '{"ability_kind":"triggered","activated_generic_one_tap_sacrifice_draw":1,"battle_model_scope":"counter_no_mana_spent_spells_and_cantrip_sacrifice_v1","effect":"artifact","trigger_counter_spell_if_no_mana_was_spent":true}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class VexingBauble mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('nezahal, primal tide', 'Nezahal, Primal Tide', '64ff656e777df4caae96816eccf5a387', 'battle_rule_v1:7b908a525415c4da327930f6d4b29aba', '{"ability_kind":"triggered","activated_discard_cards_to_exile_and_return_tapped_count":3,"battle_model_scope":"cant_be_countered_no_max_hand_opponent_noncreature_cast_draw_exile_blink_v1","cant_be_countered":true,"effect":"creature","no_maximum_hand_size":true,"opponent_casts_noncreature_draw":1,"power":7,"toughness":7}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class NezahalPrimalTide mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
    ('faerie mastermind', 'Faerie Mastermind', '92f520c17a15390fa0d0ea1b1272bc6c', 'battle_rule_v1:d71dbf6903f52abd4bfe443bab1dc0a9', '{"ability_kind":"triggered","activated_each_player_draw_cost":"{3}{U}","activated_each_player_draw_count":1,"battle_model_scope":"flash_flying_second_opponent_draw_draw_one_and_activated_each_player_draw_v1","effect":"creature","flash":true,"flying":true,"opponent_second_card_each_turn_draw":1,"power":2,"toughness":1}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class FaerieMastermind mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('vexing bauble', 'Vexing Bauble', '020e696ec9560830bb82bf0244595d69', 'battle_rule_v1:ad19691a7b388a47b6775f5e16275403', '{"ability_kind":"triggered","activated_generic_one_tap_sacrifice_draw":1,"battle_model_scope":"counter_no_mana_spent_spells_and_cantrip_sacrifice_v1","effect":"artifact","trigger_counter_spell_if_no_mana_was_spent":true}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class VexingBauble mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('nezahal, primal tide', 'Nezahal, Primal Tide', '64ff656e777df4caae96816eccf5a387', 'battle_rule_v1:7b908a525415c4da327930f6d4b29aba', '{"ability_kind":"triggered","activated_discard_cards_to_exile_and_return_tapped_count":3,"battle_model_scope":"cant_be_countered_no_max_hand_opponent_noncreature_cast_draw_exile_blink_v1","cant_be_countered":true,"effect":"creature","no_maximum_hand_size":true,"opponent_casts_noncreature_draw":1,"power":7,"toughness":7}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class NezahalPrimalTide mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
