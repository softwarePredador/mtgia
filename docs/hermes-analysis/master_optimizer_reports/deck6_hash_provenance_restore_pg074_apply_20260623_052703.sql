BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg074_deck6_hash_provenance_restore_20260623_052703') IS NOT NULL THEN
    RAISE EXCEPTION 'PG074 backup table already exists';
  END IF;
END $$;

CREATE TEMP TABLE pg074_targets(normalized_name text, logical_rule_key text);

INSERT INTO pg074_targets(normalized_name, logical_rule_key)
VALUES
  ('fellwar stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba'),
  ('mana vault', 'battle_rule_v1:5a2533694ffd19223d3cde1e25d258ff'),
  ('mox amber', 'battle_rule_v1:972703914ee50acd7a4e6f529fea1adf'),
  ('scroll rack', 'battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2'),
  ('seething song', 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7'),
  ('talisman of conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470'),
  ('unexpected windfall', 'battle_rule_v1:f9f98ea1925518eea7a7c94c21ef2dc4'),
  ('valakut awakening // valakut stoneforge', 'battle_rule_v1:6e1f3b876822abafe1de47610f46858d');

CREATE TABLE manaloom_deploy_audit.pg074_deck6_hash_provenance_restore_20260623_052703 AS
SELECT now() AS backed_up_at, to_jsonb(cbr) AS payload
FROM card_battle_rules cbr
JOIN pg074_targets t
  ON t.normalized_name = cbr.normalized_name
 AND t.logical_rule_key = cbr.logical_rule_key;

DO $$
DECLARE
  v_rules integer;
  v_missing_scope integer;
BEGIN
  SELECT count(*)
  INTO v_rules
  FROM card_battle_rules cbr
  JOIN pg074_targets t
    ON t.normalized_name = cbr.normalized_name
   AND t.logical_rule_key = cbr.logical_rule_key;

  SELECT count(*)
  INTO v_missing_scope
  FROM card_battle_rules cbr
  JOIN pg074_targets t
    ON t.normalized_name = cbr.normalized_name
   AND t.logical_rule_key = cbr.logical_rule_key
  WHERE cbr.effect_json->>'battle_model_scope' IS NULL
     OR cbr.effect_json->>'battle_model_scope' = '';

  IF v_rules <> 8 THEN
    RAISE EXCEPTION 'PG074 precondition failed: expected 8 target rules, got %', v_rules;
  END IF;
  IF v_missing_scope <> 0 THEN
    RAISE EXCEPTION 'PG074 precondition failed: expected no target rules missing scope, got %', v_missing_scope;
  END IF;
END $$;

UPDATE card_battle_rules cbr
SET
  oracle_hash = md5(coalesce(c.oracle_text, '')),
  reviewed_by = coalesce(cbr.reviewed_by, 'codex-auditor'),
  reviewed_at = coalesce(cbr.reviewed_at, now()),
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(
    E'\n',
    nullif(cbr.notes, ''),
    'PG074: restored current oracle_hash provenance only; no effect_json/deck_role_json/runtime semantic change.'
  )
FROM pg074_targets t, cards c
WHERE cbr.normalized_name = t.normalized_name
  AND cbr.logical_rule_key = t.logical_rule_key
  AND c.id = cbr.card_id;

COMMIT;
