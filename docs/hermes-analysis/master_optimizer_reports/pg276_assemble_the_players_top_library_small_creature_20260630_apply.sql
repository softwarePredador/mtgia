BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg276_assemble_the_players_top_library_small_creature_20 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('assemble the players')
   OR normalized_name LIKE 'assemble the players // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('assemble the players', 'Assemble the Players', 'ffdf411200b723c016fe9df0d85dd8e4', 'battle_rule_v1:692dcb8d1b5149bfef05a32ceb217882', '{"ability_kind":"static","battle_model_scope":"top_library_look_any_time_cast_creature_power_2_or_less_once_each_turn_pay_cost_v1","cmc":2.0,"effect":"topdeck_play","enchantment":true,"look_top_library_any_time":true,"mana_cost":"{1}{W}","top_library_cast_card_types":["creature"],"top_library_cast_once_each_turn":true,"top_library_cast_power_max":2,"top_library_cast_requires_pay_mana_cost":true}'::jsonb, '{"category":"engine","effect":"topdeck_play","subtype":"static_top_library_small_creature_cast_permission","timing":"main_phase_normal_timing"}'::jsonb, 'curated', 0.9, 'verified', 'auto', 'Oracle-reviewed on 2026-06-30 against local XMage AssembleThePlayers.java and PostgreSQL text: look at top card any time; once each turn, cast a creature spell with power 2 or less from top of library. Runtime focused test proves main-phase normal-cost cast from library top, power check, once-per-turn source tracking, replay, and decision trace.', 'deprecate_nonmatching_rows')
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
    ('assemble the players', 'Assemble the Players', 'ffdf411200b723c016fe9df0d85dd8e4', 'battle_rule_v1:692dcb8d1b5149bfef05a32ceb217882', '{"ability_kind":"static","battle_model_scope":"top_library_look_any_time_cast_creature_power_2_or_less_once_each_turn_pay_cost_v1","cmc":2.0,"effect":"topdeck_play","enchantment":true,"look_top_library_any_time":true,"mana_cost":"{1}{W}","top_library_cast_card_types":["creature"],"top_library_cast_once_each_turn":true,"top_library_cast_power_max":2,"top_library_cast_requires_pay_mana_cost":true}'::jsonb, '{"category":"engine","effect":"topdeck_play","subtype":"static_top_library_small_creature_cast_permission","timing":"main_phase_normal_timing"}'::jsonb, 'curated', 0.9, 'verified', 'auto', 'Oracle-reviewed on 2026-06-30 against local XMage AssembleThePlayers.java and PostgreSQL text: look at top card any time; once each turn, cast a creature spell with power 2 or less from top of library. Runtime focused test proves main-phase normal-cost cast from library top, power check, once-per-turn source tracking, replay, and decision trace.', 'deprecate_nonmatching_rows')
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
    ('assemble the players', 'Assemble the Players', 'ffdf411200b723c016fe9df0d85dd8e4', 'battle_rule_v1:692dcb8d1b5149bfef05a32ceb217882', '{"ability_kind":"static","battle_model_scope":"top_library_look_any_time_cast_creature_power_2_or_less_once_each_turn_pay_cost_v1","cmc":2.0,"effect":"topdeck_play","enchantment":true,"look_top_library_any_time":true,"mana_cost":"{1}{W}","top_library_cast_card_types":["creature"],"top_library_cast_once_each_turn":true,"top_library_cast_power_max":2,"top_library_cast_requires_pay_mana_cost":true}'::jsonb, '{"category":"engine","effect":"topdeck_play","subtype":"static_top_library_small_creature_cast_permission","timing":"main_phase_normal_timing"}'::jsonb, 'curated', 0.9, 'verified', 'auto', 'Oracle-reviewed on 2026-06-30 against local XMage AssembleThePlayers.java and PostgreSQL text: look at top card any time; once each turn, cast a creature spell with power 2 or less from top of library. Runtime focused test proves main-phase normal-cost cast from library top, power check, once-per-turn source tracking, replay, and decision trace.', 'deprecate_nonmatching_rows')
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
