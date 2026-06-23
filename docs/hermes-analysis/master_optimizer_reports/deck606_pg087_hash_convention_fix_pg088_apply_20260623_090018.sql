\pset pager off

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg088_deck606_pg087_hash_convention_fix_20260623_090018') IS NOT NULL THEN
    RAISE EXCEPTION 'PG088 backup table already exists';
  END IF;
END $$;

CREATE TEMP TABLE pg088_expected_hashes AS
SELECT *
FROM (VALUES
  ('hexing squelcher', 'battle_rule_v1:c6587e309bfd402ee1b98b4848abc6d3', 'ed00818e6ca804b7d1a3ef47c29277ea', '6d80ef23b5d6ea0bf67915e13696ecea'),
  ('ragavan, nimble pilferer', 'battle_rule_v1:3e0569d6bae4ed8b6e6e4289ea75084e', 'e337b9515b6984af8a1572db48f47eec', 'f6cbf3510c580b30fd12924102f60c23'),
  ('skyclave apparition', 'battle_rule_v1:4f29c7a4bbe21a160f28452406153846', '4d0c162906712b2c428b754ad2f0b3a0', 'd836e2ea0841430311033eceee434516'),
  ('underworld breach', 'battle_rule_v1:3f9f5259b05245670ee19b357aa2e999', 'a98ca5777789e48c44daff97999f2beb', '25c7dace100adb2e15b64b0b889b961c')
) AS t(normalized_name, logical_rule_key, raw_oracle_hash, normalized_oracle_hash);

CREATE TABLE manaloom_deploy_audit.pg088_deck606_pg087_hash_convention_fix_20260623_090018 AS
SELECT cbr.*
FROM pg088_expected_hashes e
JOIN card_battle_rules cbr
  ON cbr.normalized_name = e.normalized_name
 AND cbr.logical_rule_key = e.logical_rule_key;

DO $$
DECLARE
  v_target integer;
  v_raw_input_match integer;
  v_current_normalized integer;
  v_trusted integer;
BEGIN
  SELECT
    count(*),
    count(*) FILTER (WHERE md5(coalesce(c.oracle_text, '')) = e.raw_oracle_hash),
    count(*) FILTER (WHERE cbr.oracle_hash = e.normalized_oracle_hash),
    count(*) FILTER (WHERE cbr.review_status = 'verified' AND cbr.execution_status = 'auto')
  INTO v_target, v_raw_input_match, v_current_normalized, v_trusted
  FROM pg088_expected_hashes e
  JOIN cards c ON lower(c.name) = e.normalized_name
  JOIN card_battle_rules cbr
    ON cbr.card_id = c.id
   AND cbr.logical_rule_key = e.logical_rule_key;

  IF v_target <> 4 OR v_raw_input_match <> 4 OR v_current_normalized <> 4 OR v_trusted <> 4 THEN
    RAISE EXCEPTION 'PG088 precondition failed target=% raw_match=% normalized_current=% trusted=%',
      v_target, v_raw_input_match, v_current_normalized, v_trusted;
  END IF;
END $$;

UPDATE card_battle_rules cbr
SET
  oracle_hash = e.raw_oracle_hash,
  reviewed_by = 'codex-auditor',
  reviewed_at = now(),
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(E'\n', nullif(cbr.notes, ''), 'PG088: corrected PG087 oracle_hash convention from whitespace-normalized oracle text hash to raw oracle_text md5 used by prior PostgreSQL packages.')
FROM pg088_expected_hashes e
WHERE cbr.normalized_name = e.normalized_name
  AND cbr.logical_rule_key = e.logical_rule_key;

COMMIT;
