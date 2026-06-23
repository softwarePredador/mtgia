\pset pager off

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg082_deck6_silence_hash_restore_20260623_082754') IS NOT NULL THEN
    RAISE EXCEPTION 'PG082 Silence hash restore backup table already exists';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pg082_deck6_silence_hash_restore_20260623_082754 AS
SELECT *
FROM card_battle_rules
WHERE normalized_name = 'silence'
  AND logical_rule_key = 'battle_rule_v1:74b210b77b004a677906e0216d44e445';

DO $$
DECLARE
  v_target integer;
  v_oracle integer;
  v_missing integer;
BEGIN
  SELECT
    count(*),
    count(*) FILTER (WHERE md5(coalesce(c.oracle_text, '')) = 'a0ca3c09a7db091c435ab31adb9c1780'),
    count(*) FILTER (WHERE cbr.oracle_hash IS NULL OR cbr.oracle_hash = '')
  INTO v_target, v_oracle, v_missing
  FROM cards c
  JOIN card_battle_rules cbr
    ON cbr.card_id = c.id
  WHERE c.name = 'Silence'
    AND cbr.normalized_name = 'silence'
    AND cbr.logical_rule_key = 'battle_rule_v1:74b210b77b004a677906e0216d44e445'
    AND cbr.review_status = 'verified'
    AND cbr.execution_status = 'auto';

  IF v_target <> 1 THEN
    RAISE EXCEPTION 'PG082 precondition failed: expected 1 trusted Silence target, got %', v_target;
  END IF;
  IF v_oracle <> 1 THEN
    RAISE EXCEPTION 'PG082 precondition failed: Silence current oracle hash mismatch, got %', v_oracle;
  END IF;
  IF v_missing <> 1 THEN
    RAISE EXCEPTION 'PG082 precondition failed: expected 1 missing hash row, got %', v_missing;
  END IF;
END $$;

UPDATE card_battle_rules
SET
  oracle_hash = 'a0ca3c09a7db091c435ab31adb9c1780',
  effect_json = effect_json || '{"oracle_runtime_scope":"opponent_spell_cast_lock_until_eot_runtime"}'::jsonb,
  confidence = 0.970,
  review_status = 'verified',
  execution_status = 'auto',
  rule_version = greatest(rule_version, 2),
  reviewed_by = 'codex-auditor',
  reviewed_at = now(),
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(E'\n', nullif(notes, ''), 'PG082: restored Silence oracle_hash/runtime scope after PG sync exposed missing trusted-rule hash; no effect semantics changed.')
WHERE normalized_name = 'silence'
  AND logical_rule_key = 'battle_rule_v1:74b210b77b004a677906e0216d44e445'
  AND review_status = 'verified'
  AND execution_status = 'auto';

COMMIT;
