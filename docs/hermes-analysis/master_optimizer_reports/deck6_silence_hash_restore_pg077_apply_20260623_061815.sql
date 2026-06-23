BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg077_silence_hash_restore_20260623_061815') IS NOT NULL THEN
    RAISE EXCEPTION 'PG077 Silence hash restore backup table already exists';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pg077_silence_hash_restore_20260623_061815 AS
SELECT now() AS backed_up_at, to_jsonb(cbr) AS payload
FROM card_battle_rules cbr
WHERE cbr.normalized_name = 'silence';

DO $$
DECLARE
  v_card integer;
  v_rule integer;
BEGIN
  SELECT count(*)
  INTO v_card
  FROM cards
  WHERE name = 'Silence'
    AND md5(coalesce(oracle_text, '')) = 'a0ca3c09a7db091c435ab31adb9c1780';

  SELECT count(*)
  INTO v_rule
  FROM card_battle_rules
  WHERE normalized_name = 'silence'
    AND logical_rule_key = 'battle_rule_v1:74b210b77b004a677906e0216d44e445';

  IF v_card <> 1 THEN
    RAISE EXCEPTION 'PG077 Silence hash restore precondition failed: expected 1 Silence card with current oracle hash, got %', v_card;
  END IF;
  IF v_rule <> 1 THEN
    RAISE EXCEPTION 'PG077 Silence hash restore precondition failed: expected 1 target rule, got %', v_rule;
  END IF;
END $$;

UPDATE card_battle_rules
SET
  oracle_hash = 'a0ca3c09a7db091c435ab31adb9c1780',
  confidence = 0.970,
  reviewed_by = 'codex-auditor',
  reviewed_at = now(),
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(
    E'\n',
    nullif(notes, ''),
    'PG077 addendum: restored Silence oracle_hash required by the PG054 silence-lock runtime provenance gate after PG077 sync exposed the missing hash again. No semantic runtime change.'
  )
WHERE normalized_name = 'silence'
  AND logical_rule_key = 'battle_rule_v1:74b210b77b004a677906e0216d44e445';

COMMIT;
