-- READ ONLY. PG878 Lorehold challenger runtime-completion precheck.
-- Prepared on 2026-07-16 from live PostgreSQL; this file never authorizes apply.

BEGIN TRANSACTION READ ONLY;
SET LOCAL statement_timeout = '30s';
SET LOCAL lock_timeout = '5s';

DO $$
DECLARE
  v_count integer;
  v_hash text;
  v_live integer;
  v_disabled integer;
  v_existing_exact integer;
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg878_lorehold_runtime_cards_pre_20260716') IS NOT NULL
     OR to_regclass('manaloom_deploy_audit.pg878_lorehold_runtime_rules_pre_20260716') IS NOT NULL
     OR to_regclass('manaloom_deploy_audit.pg878_lorehold_runtime_proposal_20260716') IS NOT NULL
     OR to_regclass('manaloom_deploy_audit.pg878_lorehold_runtime_rules_post_20260716') IS NOT NULL THEN
    RAISE EXCEPTION 'PG878 precheck abort: an audit table already exists';
  END IF;

  SELECT count(*), md5(string_agg(
      concat_ws('|', ordinal_position, column_name, udt_name, is_nullable,
                coalesce(column_default, '')),
      E'\n' ORDER BY ordinal_position))
    INTO v_count, v_hash
  FROM information_schema.columns
  WHERE table_schema = 'public' AND table_name = 'cards';
  IF v_count <> 28 OR v_hash <> '03ef6ea64392bacd6db316eefe8c3896' THEN
    RAISE EXCEPTION 'PG878 precheck abort: cards schema drift count=% hash=%', v_count, v_hash;
  END IF;

  SELECT count(*), md5(string_agg(
      concat_ws('|', ordinal_position, column_name, udt_name, is_nullable,
                coalesce(column_default, '')),
      E'\n' ORDER BY ordinal_position))
    INTO v_count, v_hash
  FROM information_schema.columns
  WHERE table_schema = 'public' AND table_name = 'card_battle_rules';
  IF v_count <> 18 OR v_hash <> '22b9db71b43ac3cecf079dc716272d24' THEN
    RAISE EXCEPTION 'PG878 precheck abort: card_battle_rules schema drift count=% hash=%', v_count, v_hash;
  END IF;

  SELECT count(*), md5(coalesce(string_agg(
      jsonb_build_array(
        id, scryfall_id, oracle_id, name, mana_cost, cmc, type_line,
        oracle_text, colors, color_identity, power, toughness, keywords,
        layout, card_faces_json, set_code, collector_number
      )::text,
      E'\n' ORDER BY lower(name), id::text), ''))
    INTO v_count, v_hash
  FROM public.cards
  WHERE lower(name) IN (
      'birgi, god of storytelling',
      'birgi, god of storytelling // harnfel, horn of bounty',
      'underworld breach',
      'mana vault'
    )
     OR lower(name) LIKE 'birgi, god of storytelling // %';
  IF v_count <> 3 OR v_hash <> 'd047e689c2f3bea43ff9a0179114f12b' THEN
    RAISE EXCEPTION 'PG878 precheck abort: target card lineage drift count=% hash=%', v_count, v_hash;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.cards
    WHERE id = 'e715bdfc-8bc4-4da8-b7bf-1d6f48d5fc85'::uuid
      AND name = 'Birgi, God of Storytelling // Harnfel, Horn of Bounty'
      AND md5(coalesce(oracle_text, '')) = '5f1ed696a63cd668fd46a2fe9971a54e'
  ) OR NOT EXISTS (
    SELECT 1 FROM public.cards
    WHERE id = '1ecaad2c-0ab0-4d9d-9115-31a8078e09b0'::uuid
      AND name = 'Underworld Breach'
      AND md5(coalesce(oracle_text, '')) = 'a98ca5777789e48c44daff97999f2beb'
  ) OR NOT EXISTS (
    SELECT 1 FROM public.cards
    WHERE id = 'd2f38c20-79e2-4330-b6ae-ded990a465e4'::uuid
      AND name = 'Mana Vault'
      AND md5(coalesce(oracle_text, '')) = '35e3fd94c8453c0e326033af49ae18c8'
  ) THEN
    RAISE EXCEPTION 'PG878 precheck abort: target UUID/name/oracle hash identity drift';
  END IF;

  SELECT count(*), md5(coalesce(string_agg(
      jsonb_build_array(
        normalized_name, card_id, card_name, effect_json, deck_role_json,
        source, confidence, review_status, rule_version, oracle_hash, notes,
        reviewed_by, reviewed_at, created_at, updated_at, last_seen_at,
        logical_rule_key, execution_status
      )::text,
      E'\n' ORDER BY normalized_name, logical_rule_key), '')),
      count(*) FILTER (
        WHERE review_status NOT IN ('deprecated', 'rejected')
           OR execution_status <> 'disabled'
      ),
      count(*) FILTER (
        WHERE review_status IN ('deprecated', 'rejected')
          AND execution_status = 'disabled'
      )
    INTO v_count, v_hash, v_live, v_disabled
  FROM public.card_battle_rules
  WHERE normalized_name IN (
      'birgi, god of storytelling', 'underworld breach', 'mana vault'
    )
     OR normalized_name LIKE 'birgi, god of storytelling // %';
  IF v_count <> 11
     OR v_hash <> '6edced874860dcadd35256813d3160a1'
     OR v_live <> 5
     OR v_disabled <> 6 THEN
    RAISE EXCEPTION
      'PG878 precheck abort: rule prestate drift count=% hash=% live=% disabled=%',
      v_count, v_hash, v_live, v_disabled;
  END IF;

  SELECT count(*) INTO v_existing_exact
  FROM public.card_battle_rules
  WHERE (normalized_name, logical_rule_key) IN (
    ('birgi, god of storytelling', 'battle_rule_v1:e27d00eff7b686d7c8aab1426c621635'),
    ('underworld breach', 'battle_rule_v1:a38468ecbf8f6ff1512b3b52674a3d0c'),
    ('mana vault', 'battle_rule_v1:d43496777c4b1e36b1c9a5111133acf4')
  );
  IF v_existing_exact <> 0 THEN
    RAISE EXCEPTION 'PG878 precheck abort: exact proposal keys already exist count=%', v_existing_exact;
  END IF;
END $$;

SELECT
  'PG878_PRECHECK_PASS' AS status,
  3 AS target_card_rows,
  11 AS pre_rule_rows,
  5 AS live_rows_to_deprecate,
  6 AS historical_disabled_rows_to_preserve,
  3 AS exact_rows_to_insert,
  'd047e689c2f3bea43ff9a0179114f12b' AS target_card_hash,
  '6edced874860dcadd35256813d3160a1' AS pre_rule_hash,
  '3ff2fb6259e01b96bbb8a932931f9c8a' AS proposal_hash;

ROLLBACK;
