BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg621_command_tower_commander_identity_mana_20260707_backup AS
SELECT *
FROM public.card_battle_rules
WHERE logical_rule_key = 'battle_rule_v1:603c776839827f2f21cef8b62e22a1be'
  AND normalized_name IN ('command tower', 'command tower // command tower');

DO $$
DECLARE
  v_bad jsonb;
  v_target_count integer;
BEGIN
  WITH target AS (
    SELECT
      r.normalized_name,
      r.card_name,
      r.logical_rule_key,
      r.review_status,
      r.execution_status,
      r.oracle_hash,
      md5(COALESCE(c.oracle_text, '')) AS card_oracle_hash
    FROM public.card_battle_rules r
    LEFT JOIN public.cards c ON c.id = r.card_id
    WHERE r.logical_rule_key = 'battle_rule_v1:603c776839827f2f21cef8b62e22a1be'
      AND r.normalized_name IN ('command tower', 'command tower // command tower')
  )
  SELECT jsonb_agg(target ORDER BY normalized_name)
    INTO v_bad
  FROM target
  WHERE review_status <> 'verified'
     OR execution_status <> 'auto'
     OR oracle_hash IS DISTINCT FROM 'df826611f7a0a91ba8781558b346e7af'
     OR card_oracle_hash IS DISTINCT FROM 'df826611f7a0a91ba8781558b346e7af';

  SELECT count(*)
    INTO v_target_count
  FROM public.card_battle_rules r
  WHERE r.logical_rule_key = 'battle_rule_v1:603c776839827f2f21cef8b62e22a1be'
    AND r.normalized_name IN ('command tower', 'command tower // command tower');

  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'PG621 abort: Command Tower verified row drifted before update: %', v_bad;
  END IF;

  IF v_target_count <> 2 THEN
    RAISE EXCEPTION 'PG621 abort: expected 2 Command Tower executable rows, found %', v_target_count;
  END IF;
END $$;

WITH updated AS (
  UPDATE public.card_battle_rules r
  SET
    effect_json = '{
      "cmc": 0.0,
      "effect": "land",
      "produces": "WUBRGC",
      "mana_produced": 1,
      "commander_identity_mana_source": true,
      "battle_model_scope": "commander_identity_land_mana_source_v1"
    }'::jsonb,
    deck_role_json = '{
      "category": "land",
      "effect": "land",
      "subtype": "commander_identity_fixing"
    }'::jsonb,
    confidence = 0.99,
    review_status = 'verified',
    execution_status = 'auto',
    oracle_hash = 'df826611f7a0a91ba8781558b346e7af',
    notes = 'Oracle-reviewed against PostgreSQL/Scryfall text: Command Tower taps for one mana of any color in the commander''s color identity. Runtime verification on 2026-07-07 uses commander_identity_mana_source to expose only the active commander''s colors, with WUBRGC retained as metadata fallback.',
    reviewed_by = 'codex_pg621_command_tower_commander_identity_mana_2026_07_07',
    reviewed_at = CURRENT_TIMESTAMP,
    updated_at = CURRENT_TIMESTAMP,
    last_seen_at = CURRENT_TIMESTAMP
  WHERE r.logical_rule_key = 'battle_rule_v1:603c776839827f2f21cef8b62e22a1be'
    AND r.normalized_name IN ('command tower', 'command tower // command tower')
  RETURNING r.*
)
SELECT
  count(*) AS updated_rows,
  count(*) FILTER (
    WHERE review_status = 'verified'
      AND execution_status = 'auto'
      AND effect_json->>'battle_model_scope' = 'commander_identity_land_mana_source_v1'
      AND effect_json->>'commander_identity_mana_source' = 'true'
  ) AS verified_scope_rows
FROM updated;

DO $$
DECLARE
  v_bad_count integer;
BEGIN
  SELECT count(*)
    INTO v_bad_count
  FROM public.card_battle_rules r
  WHERE r.logical_rule_key = 'battle_rule_v1:603c776839827f2f21cef8b62e22a1be'
    AND r.normalized_name IN ('command tower', 'command tower // command tower')
    AND (
      r.review_status <> 'verified'
      OR r.execution_status <> 'auto'
      OR r.effect_json->>'battle_model_scope' <> 'commander_identity_land_mana_source_v1'
      OR r.effect_json->>'commander_identity_mana_source' <> 'true'
      OR r.oracle_hash IS DISTINCT FROM 'df826611f7a0a91ba8781558b346e7af'
    );

  IF v_bad_count <> 0 THEN
    RAISE EXCEPTION 'PG621 abort: post-update verification failed for % Command Tower rows', v_bad_count;
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
-- FROM manaloom_deploy_audit.pg621_command_tower_commander_identity_mana_20260707_backup b
-- WHERE r.normalized_name = b.normalized_name
--   AND r.logical_rule_key = b.logical_rule_key;
-- COMMIT;
