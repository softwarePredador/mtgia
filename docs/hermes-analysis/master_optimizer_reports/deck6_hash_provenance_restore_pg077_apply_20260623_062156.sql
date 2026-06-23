BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg077_deck6_hash_provenance_restore_20260623_062156') IS NOT NULL THEN
    RAISE EXCEPTION 'PG077 deck6 hash provenance restore backup table already exists';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pg077_deck6_hash_provenance_restore_20260623_062156 AS
SELECT now() AS backed_up_at, to_jsonb(cbr) AS payload
FROM card_battle_rules cbr
WHERE cbr.normalized_name IN (
  'fellwar stone',
  'mana vault',
  'mox amber',
  'scroll rack',
  'seething song',
  'talisman of conviction',
  'unexpected windfall',
  'valakut awakening // valakut stoneforge'
);

DO $$
DECLARE
  v_target integer;
  v_with_oracle integer;
  v_missing_hash integer;
BEGIN
  WITH target_rules(normalized_name, logical_rule_key) AS (
    VALUES
      ('fellwar stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba'),
      ('mana vault', 'battle_rule_v1:5a2533694ffd19223d3cde1e25d258ff'),
      ('mox amber', 'battle_rule_v1:972703914ee50acd7a4e6f529fea1adf'),
      ('scroll rack', 'battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2'),
      ('seething song', 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7'),
      ('talisman of conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470'),
      ('unexpected windfall', 'battle_rule_v1:f9f98ea1925518eea7a7c94c21ef2dc4'),
      ('valakut awakening // valakut stoneforge', 'battle_rule_v1:6e1f3b876822abafe1de47610f46858d')
  )
  SELECT
    count(*),
    count(*) FILTER (WHERE c.oracle_text IS NOT NULL),
    count(*) FILTER (WHERE cbr.oracle_hash IS NULL)
  INTO v_target, v_with_oracle, v_missing_hash
  FROM target_rules t
  JOIN card_battle_rules cbr
    ON cbr.normalized_name = t.normalized_name
   AND cbr.logical_rule_key = t.logical_rule_key
  JOIN cards c
    ON c.id = cbr.card_id;

  IF v_target <> 8 THEN
    RAISE EXCEPTION 'PG077 deck6 hash provenance restore precondition failed: expected 8 target rules, got %', v_target;
  END IF;
  IF v_with_oracle <> 8 THEN
    RAISE EXCEPTION 'PG077 deck6 hash provenance restore precondition failed: expected 8 target oracle texts, got %', v_with_oracle;
  END IF;
  IF v_missing_hash <> 3 THEN
    RAISE EXCEPTION 'PG077 deck6 hash provenance restore precondition failed: expected 3 missing hashes, got %', v_missing_hash;
  END IF;
END $$;

DO $$
DECLARE
  v_updated integer;
BEGIN
  WITH target_rules(normalized_name, logical_rule_key) AS (
    VALUES
      ('fellwar stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba'),
      ('mana vault', 'battle_rule_v1:5a2533694ffd19223d3cde1e25d258ff'),
      ('mox amber', 'battle_rule_v1:972703914ee50acd7a4e6f529fea1adf'),
      ('scroll rack', 'battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2'),
      ('seething song', 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7'),
      ('talisman of conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470'),
      ('unexpected windfall', 'battle_rule_v1:f9f98ea1925518eea7a7c94c21ef2dc4'),
      ('valakut awakening // valakut stoneforge', 'battle_rule_v1:6e1f3b876822abafe1de47610f46858d')
  ),
  updated AS (
    UPDATE card_battle_rules cbr
    SET
      oracle_hash = md5(coalesce(c.oracle_text, '')),
      reviewed_by = 'codex-auditor',
      reviewed_at = now(),
      updated_at = now(),
      last_seen_at = now(),
      notes = concat_ws(
        E'\n',
        nullif(cbr.notes, ''),
        'PG077 addendum: restored deck 6 oracle_hash provenance for an already reviewed executable rule after PG077 sync exposed hash-only drift. No semantic runtime, effect_json, deck_role_json, or deck composition change.'
      )
    FROM target_rules t, cards c
    WHERE cbr.normalized_name = t.normalized_name
      AND cbr.logical_rule_key = t.logical_rule_key
      AND c.id = cbr.card_id
      AND cbr.oracle_hash IS DISTINCT FROM md5(coalesce(c.oracle_text, ''))
    RETURNING 1
  )
  SELECT count(*) INTO v_updated FROM updated;

  IF v_updated <> 3 THEN
    RAISE EXCEPTION 'PG077 deck6 hash provenance restore apply failed: expected 3 updated rows, got %', v_updated;
  END IF;
END $$;

COMMIT;
