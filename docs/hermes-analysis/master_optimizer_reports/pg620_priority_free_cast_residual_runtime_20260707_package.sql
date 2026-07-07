BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg620_priority_free_cast_residual_runtime_20260707_backup AS
SELECT *
FROM public.card_battle_rules
WHERE (normalized_name, logical_rule_key) IN (
  ('hit the mother lode', 'battle_rule_v1:96918f32221fe2908cf49d33a457af2f'),
  ('hit the mother lode', 'battle_rule_v1:3c85508fc77f408ea77c6ad8c81cab34'),
  ('improvisation capstone', 'battle_rule_v1:4a001137f9a15f1a45b994a4d63f1689'),
  ('tibalt''s trickery', 'battle_rule_v1:c3821ae5e8f44d1820ba5c1ed48c3366')
);

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, logical_rule_key, battle_model_scope, oracle_hash) AS (
    VALUES
      ('hit the mother lode', 'Hit the Mother Lode', 'battle_rule_v1:96918f32221fe2908cf49d33a457af2f', 'discover_10_as_one_card_value_component_v1', '971773d66dc1e38d5cbb8465858998bd'),
      ('hit the mother lode', 'Hit the Mother Lode', 'battle_rule_v1:3c85508fc77f408ea77c6ad8c81cab34', 'discover_10_treasure_difference_average_v1', '971773d66dc1e38d5cbb8465858998bd'),
      ('improvisation capstone', 'Improvisation Capstone', 'battle_rule_v1:4a001137f9a15f1a45b994a4d63f1689', 'exile_value_free_casts_paradigm_annotation_v1', '211282705b9124c8f737b1eb351e13f0'),
      ('tibalt''s trickery', 'Tibalt''s Trickery', 'battle_rule_v1:c3821ae5e8f44d1820ba5c1ed48c3366', 'counterspell_with_random_replacement_annotation_v1', '4817af87412f9b1d481222c3da52ced5')
  ),
  checks AS (
    SELECT
      p.card_name,
      p.logical_rule_key,
      p.battle_model_scope,
      p.oracle_hash,
      r.review_status,
      r.execution_status,
      r.effect_json->>'battle_model_scope' AS actual_scope,
      r.oracle_hash AS actual_oracle_hash,
      c.id AS card_id,
      md5(COALESCE(c.oracle_text, '')) AS card_oracle_hash
    FROM proposed p
    LEFT JOIN public.card_battle_rules r
      ON r.normalized_name = p.normalized_name
     AND r.logical_rule_key = p.logical_rule_key
    LEFT JOIN public.cards c
      ON c.id = r.card_id
  )
  SELECT jsonb_agg(checks ORDER BY card_name, logical_rule_key)
    INTO v_missing
  FROM checks
  WHERE review_status IS NULL
     OR execution_status <> 'auto'
     OR actual_scope IS DISTINCT FROM battle_model_scope
     OR actual_oracle_hash IS DISTINCT FROM oracle_hash
     OR card_oracle_hash IS DISTINCT FROM oracle_hash;

  IF v_missing IS NOT NULL THEN
    RAISE EXCEPTION 'PG620 abort: residual priority runtime rows are missing or drifted: %', v_missing;
  END IF;
END $$;

WITH proposed(normalized_name, logical_rule_key, runtime_notes) AS (
  VALUES
    (
      'hit the mother lode',
      'battle_rule_v1:96918f32221fe2908cf49d33a457af2f',
      'Oracle-reviewed on 2026-06-22 against local Scryfall/PostgreSQL cache: Discover 10 and create tapped Treasures for the difference if the discovered card costs less than 10. Runtime verification on 2026-07-07 resolves discover by revealing/exiling until a valid hit, free-casting or putting the hit into hand, bottoming revealed misses randomly, and creating the exact Treasure difference.'
    ),
    (
      'hit the mother lode',
      'battle_rule_v1:3c85508fc77f408ea77c6ad8c81cab34',
      'Oracle-reviewed on 2026-06-22 against local Scryfall/PostgreSQL cache: Discover 10 and create tapped Treasures for the difference if the discovered card costs less than 10. Runtime verification on 2026-07-07 resolves discover by revealing/exiling until a valid hit, free-casting or putting the hit into hand, bottoming revealed misses randomly, and creating the exact Treasure difference.'
    ),
    (
      'improvisation capstone',
      'battle_rule_v1:4a001137f9a15f1a45b994a4d63f1689',
      'Oracle-reviewed on 2026-06-22 against local Scryfall/PostgreSQL cache: exile cards until total mana value 4 or greater and cast any number for free; Paradigm repeats later. Runtime verification on 2026-07-07 exiles until the nonland total mana value threshold is met, free-casts supported exiled spells, and retains Paradigm as repeat metadata.'
    ),
    (
      'tibalt''s trickery',
      'battle_rule_v1:c3821ae5e8f44d1820ba5c1ed48c3366',
      'Oracle-reviewed on 2026-06-22 against local Scryfall/PostgreSQL cache: counters target spell, then gives that controller a random replacement-cast line. Runtime verification on 2026-07-07 counters the spell, mills a deterministic random 1-3 cards for the target controller, reveals to a different-name nonland replacement spell, free-casts supported hits, and bottoms revealed misses randomly.'
    )
),
updated AS (
  UPDATE public.card_battle_rules r
  SET
    review_status = 'verified',
    execution_status = 'auto',
    notes = p.runtime_notes,
    reviewed_by = 'codex_pg620_priority_free_cast_residual_runtime_2026_07_07',
    reviewed_at = CURRENT_TIMESTAMP,
    updated_at = CURRENT_TIMESTAMP,
    last_seen_at = CURRENT_TIMESTAMP
  FROM proposed p
  WHERE r.normalized_name = p.normalized_name
    AND r.logical_rule_key = p.logical_rule_key
  RETURNING r.*
)
SELECT
  count(*) AS promoted_rows,
  count(*) FILTER (WHERE review_status = 'verified' AND execution_status = 'auto') AS verified_auto_rows
FROM updated;

DO $$
DECLARE
  v_bad_count integer;
BEGIN
  WITH target(normalized_name, logical_rule_key) AS (
    VALUES
      ('hit the mother lode', 'battle_rule_v1:96918f32221fe2908cf49d33a457af2f'),
      ('hit the mother lode', 'battle_rule_v1:3c85508fc77f408ea77c6ad8c81cab34'),
      ('improvisation capstone', 'battle_rule_v1:4a001137f9a15f1a45b994a4d63f1689'),
      ('tibalt''s trickery', 'battle_rule_v1:c3821ae5e8f44d1820ba5c1ed48c3366')
  )
  SELECT count(*)
    INTO v_bad_count
  FROM target t
  LEFT JOIN public.card_battle_rules r
    ON r.normalized_name = t.normalized_name
   AND r.logical_rule_key = t.logical_rule_key
  WHERE r.review_status <> 'verified'
     OR r.execution_status <> 'auto'
     OR r.oracle_hash IS NULL;

  IF v_bad_count <> 0 THEN
    RAISE EXCEPTION 'PG620 abort: post-update verification failed for % target rows', v_bad_count;
  END IF;
END $$;

COMMIT;

-- Rollback, if required after apply:
-- BEGIN;
-- UPDATE public.card_battle_rules r
-- SET
--   card_id = b.card_id,
--   card_name = b.card_name,
--   effect_json = b.effect_json,
--   deck_role_json = b.deck_role_json,
--   source = b.source,
--   confidence = b.confidence,
--   review_status = b.review_status,
--   rule_version = b.rule_version,
--   oracle_hash = b.oracle_hash,
--   notes = b.notes,
--   reviewed_by = b.reviewed_by,
--   reviewed_at = b.reviewed_at,
--   updated_at = CURRENT_TIMESTAMP,
--   last_seen_at = b.last_seen_at,
--   execution_status = b.execution_status
-- FROM manaloom_deploy_audit.pg620_priority_free_cast_residual_runtime_20260707_backup b
-- WHERE r.normalized_name = b.normalized_name
--   AND r.logical_rule_key = b.logical_rule_key;
-- COMMIT;
