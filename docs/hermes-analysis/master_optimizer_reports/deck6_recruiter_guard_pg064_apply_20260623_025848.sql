-- PG064 deck6 Recruiter of the Guard apply.
-- Promotes an oracle-specific ETB toughness-2-or-less creature tutor runtime rule.

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg064_deck6_recruiter_guard_20260623_025848') IS NOT NULL THEN
    RAISE EXCEPTION 'Backup table manaloom_deploy_audit.pg064_deck6_recruiter_guard_20260623_025848 already exists';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pg064_deck6_recruiter_guard_20260623_025848 AS
SELECT *
FROM card_battle_rules
WHERE normalized_name = 'recruiter of the guard';

DO $$
DECLARE
  v_backup_rows integer;
  v_target_cards integer;
  v_deck6_cards integer;
  v_hash_matches integer;
BEGIN
  SELECT count(*) INTO v_backup_rows
  FROM manaloom_deploy_audit.pg064_deck6_recruiter_guard_20260623_025848;

  SELECT count(*) INTO v_target_cards
  FROM cards
  WHERE lower(name) = 'recruiter of the guard';

  SELECT count(*) INTO v_deck6_cards
  FROM deck_cards dc
  JOIN cards c ON c.id = dc.card_id
  WHERE dc.deck_id = '528c877f-f829-4207-95e6-73981776c323'::uuid
    AND lower(c.name) = 'recruiter of the guard';

  SELECT count(*) INTO v_hash_matches
  FROM cards
  WHERE lower(name) = 'recruiter of the guard'
    AND md5(coalesce(oracle_text, '')) = 'aaa06784ff51d908d553ccc81d6854cd';

  IF v_backup_rows <> 2 THEN
    RAISE EXCEPTION 'PG064 precondition failed: backup_rows=% expected 2', v_backup_rows;
  END IF;
  IF v_target_cards <> 1 THEN
    RAISE EXCEPTION 'PG064 precondition failed: target_cards=% expected 1', v_target_cards;
  END IF;
  IF v_deck6_cards <> 1 THEN
    RAISE EXCEPTION 'PG064 precondition failed: deck6_cards=% expected 1', v_deck6_cards;
  END IF;
  IF v_hash_matches <> 1 THEN
    RAISE EXCEPTION 'PG064 precondition failed: oracle hash match rows=% expected 1', v_hash_matches;
  END IF;
END $$;

WITH target_rule(
  normalized_name,
  card_name,
  logical_rule_key,
  expected_oracle_hash,
  effect_json,
  deck_role_json,
  notes
) AS (
  VALUES (
    'recruiter of the guard',
    'Recruiter of the Guard',
    'battle_rule_v1:423a8aa67b5cf450f4c4fb47ca50ae46',
    'aaa06784ff51d908d553ccc81d6854cd',
    '{"effect":"creature","cmc":3.0,"is_creature_permanent":true,"power":1,"toughness":1,"etb_tutor_target":"creature_toughness_lte_2","etb_tutor_destination":"hand","reveals_tutored_card":true,"battle_model_scope":"recruiter_guard_etb_toughness2_creature_to_hand_v1","oracle_runtime_scope":"creature_etb_toughness_lte_2_creature_reveal_shuffle_to_hand_runtime","pg064_tutor_family":"deck6_recruiter_guard_toughness_tutor"}'::jsonb,
    '{"category":"tutor","effect":"creature","subtype":"etb_small_toughness_creature_tutor","target":"creature_toughness_lte_2","destination":"hand","deck_package":"deck6_recruiter_guard_tutor"}'::jsonb,
    'PG064 2026-06-23: Recruiter of the Guard modeled as creature with ETB creature-toughness-2-or-less reveal-to-hand tutor. This replaces the prior small_creature placeholder and disables the generated any-card tutor shadow.'
  )
),
resolved AS (
  SELECT tr.*, c.id AS card_id, md5(coalesce(c.oracle_text, '')) AS live_oracle_hash
  FROM target_rule tr
  JOIN cards c ON lower(c.name) = tr.normalized_name
)
INSERT INTO card_battle_rules (
  normalized_name,
  logical_rule_key,
  card_id,
  card_name,
  effect_json,
  deck_role_json,
  source,
  confidence,
  review_status,
  execution_status,
  rule_version,
  oracle_hash,
  notes,
  reviewed_by,
  reviewed_at,
  created_at,
  updated_at,
  last_seen_at
)
SELECT
  normalized_name,
  logical_rule_key,
  card_id,
  card_name,
  effect_json,
  deck_role_json,
  'curated',
  0.930,
  'active',
  'auto',
  1,
  expected_oracle_hash,
  notes,
  'codex_central_auditor_pg064',
  now(),
  now(),
  now(),
  now()
FROM resolved
WHERE live_oracle_hash = expected_oracle_hash
ON CONFLICT (normalized_name, logical_rule_key) DO UPDATE SET
  card_id = EXCLUDED.card_id,
  card_name = EXCLUDED.card_name,
  effect_json = EXCLUDED.effect_json,
  deck_role_json = EXCLUDED.deck_role_json,
  source = EXCLUDED.source,
  confidence = EXCLUDED.confidence,
  review_status = EXCLUDED.review_status,
  execution_status = EXCLUDED.execution_status,
  rule_version = EXCLUDED.rule_version,
  oracle_hash = EXCLUDED.oracle_hash,
  notes = EXCLUDED.notes,
  reviewed_by = EXCLUDED.reviewed_by,
  reviewed_at = EXCLUDED.reviewed_at,
  updated_at = now(),
  last_seen_at = now();

UPDATE card_battle_rules cbr
SET
  review_status = 'deprecated',
  execution_status = 'disabled',
  notes = concat_ws(
    E'\n',
    nullif(cbr.notes, ''),
    'PG064 2026-06-23: Disabled superseded broad/shadow Recruiter of the Guard row after promoting oracle-specific toughness-2-or-less ETB tutor runtime rule.'
  ),
  updated_at = now(),
  last_seen_at = now()
WHERE cbr.normalized_name = 'recruiter of the guard'
  AND cbr.logical_rule_key <> 'battle_rule_v1:423a8aa67b5cf450f4c4fb47ca50ae46'
  AND cbr.review_status NOT IN ('deprecated', 'rejected')
  AND cbr.execution_status IN ('auto', 'executable', 'review_only');

COMMIT;
