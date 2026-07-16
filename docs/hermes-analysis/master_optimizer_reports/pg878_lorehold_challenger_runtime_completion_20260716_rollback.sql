-- MUTATING ROLLBACK. Requires explicit PostgreSQL approval for this execution.
-- Refuses rollback unless the full PG878 poststate is unchanged.

BEGIN;
SET LOCAL statement_timeout = '60s';
SET LOCAL lock_timeout = '10s';

LOCK TABLE public.cards IN SHARE MODE;
LOCK TABLE public.card_battle_rules IN SHARE ROW EXCLUSIVE MODE;

DO $$
DECLARE
  v_count integer;
  v_hash text;
  v_diff integer;
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg878_lorehold_runtime_cards_pre_20260716') IS NULL
     OR to_regclass('manaloom_deploy_audit.pg878_lorehold_runtime_rules_pre_20260716') IS NULL
     OR to_regclass('manaloom_deploy_audit.pg878_lorehold_runtime_proposal_20260716') IS NULL
     OR to_regclass('manaloom_deploy_audit.pg878_lorehold_runtime_rules_post_20260716') IS NULL THEN
    RAISE EXCEPTION 'PG878 rollback abort: audit evidence is missing';
  END IF;

  SELECT count(*) INTO v_count
  FROM manaloom_deploy_audit.pg878_lorehold_runtime_cards_pre_20260716;
  IF v_count <> 3 THEN
    RAISE EXCEPTION 'PG878 rollback abort: card backup count=%', v_count;
  END IF;

  SELECT count(*), md5(string_agg(
      concat_ws('|', ordinal_position, column_name, udt_name, is_nullable,
                coalesce(column_default, '')),
      E'\n' ORDER BY ordinal_position))
    INTO v_count, v_hash
  FROM information_schema.columns
  WHERE table_schema = 'public' AND table_name = 'card_battle_rules';
  IF v_count <> 18 OR v_hash <> '22b9db71b43ac3cecf079dc716272d24' THEN
    RAISE EXCEPTION 'PG878 rollback abort: card_battle_rules schema drift count=% hash=%', v_count, v_hash;
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
    RAISE EXCEPTION 'PG878 rollback abort: target card lineage drift count=% hash=%', v_count, v_hash;
  END IF;

  SELECT count(*), md5(coalesce(string_agg(
      jsonb_build_array(
        normalized_name, card_id, card_name, effect_json, deck_role_json,
        source, confidence, review_status, rule_version, oracle_hash, notes,
        reviewed_by, reviewed_at, created_at, updated_at, last_seen_at,
        logical_rule_key, execution_status
      )::text,
      E'\n' ORDER BY normalized_name, logical_rule_key), ''))
    INTO v_count, v_hash
  FROM manaloom_deploy_audit.pg878_lorehold_runtime_rules_pre_20260716;
  IF v_count <> 11 OR v_hash <> '6edced874860dcadd35256813d3160a1' THEN
    RAISE EXCEPTION 'PG878 rollback abort: prestate backup drift count=% hash=%', v_count, v_hash;
  END IF;

  SELECT count(*), md5(string_agg(
      jsonb_build_array(
        normalized_name, card_name, oracle_hash, logical_rule_key, effect_json,
        deck_role_json, source, confidence, review_status, execution_status,
        rule_version, notes, reviewed_by
      )::text,
      E'\n' ORDER BY normalized_name, logical_rule_key))
    INTO v_count, v_hash
  FROM manaloom_deploy_audit.pg878_lorehold_runtime_proposal_20260716;
  IF v_count <> 3 OR v_hash <> '3ff2fb6259e01b96bbb8a932931f9c8a' THEN
    RAISE EXCEPTION 'PG878 rollback abort: proposal drift count=% hash=%', v_count, v_hash;
  END IF;

  SELECT count(*) INTO v_count
  FROM manaloom_deploy_audit.pg878_lorehold_runtime_rules_post_20260716;
  IF v_count <> 14 THEN
    RAISE EXCEPTION 'PG878 rollback abort: poststate snapshot count=%', v_count;
  END IF;

  SELECT count(*) INTO v_diff
  FROM (
    (SELECT * FROM manaloom_deploy_audit.pg878_lorehold_runtime_rules_post_20260716
     EXCEPT
     SELECT * FROM public.card_battle_rules
     WHERE normalized_name IN ('birgi, god of storytelling', 'underworld breach', 'mana vault')
        OR normalized_name LIKE 'birgi, god of storytelling // %')
    UNION ALL
    (SELECT * FROM public.card_battle_rules
     WHERE normalized_name IN ('birgi, god of storytelling', 'underworld breach', 'mana vault')
        OR normalized_name LIKE 'birgi, god of storytelling // %'
     EXCEPT
     SELECT * FROM manaloom_deploy_audit.pg878_lorehold_runtime_rules_post_20260716)
  ) diff;
  IF v_diff <> 0 THEN
    RAISE EXCEPTION 'PG878 rollback abort: exact poststate drifted diff=%', v_diff;
  END IF;

  SELECT count(*) INTO v_diff
  FROM manaloom_deploy_audit.pg878_lorehold_runtime_cards_pre_20260716 b
  FULL JOIN public.cards c USING (id)
  WHERE (c.id IS NULL OR b.id IS NULL OR to_jsonb(c) IS DISTINCT FROM to_jsonb(b))
    AND coalesce(lower(c.name), lower(b.name)) IN (
      'birgi, god of storytelling // harnfel, horn of bounty',
      'underworld breach', 'mana vault'
    );
  IF v_diff <> 0 THEN
    RAISE EXCEPTION 'PG878 rollback abort: target cards changed diff=%', v_diff;
  END IF;
END $$;

DO $$
DECLARE
  v_deleted integer;
  v_restored integer;
  v_count integer;
  v_hash text;
  v_live integer;
  v_disabled integer;
  v_diff integer;
BEGIN
  DELETE FROM public.card_battle_rules
  WHERE normalized_name IN (
      'birgi, god of storytelling', 'underworld breach', 'mana vault'
    )
     OR normalized_name LIKE 'birgi, god of storytelling // %';
  GET DIAGNOSTICS v_deleted = ROW_COUNT;
  IF v_deleted <> 14 THEN
    RAISE EXCEPTION 'PG878 rollback abort: expected 14 target rows deleted, got %', v_deleted;
  END IF;

  INSERT INTO public.card_battle_rules
  SELECT *
  FROM manaloom_deploy_audit.pg878_lorehold_runtime_rules_pre_20260716;
  GET DIAGNOSTICS v_restored = ROW_COUNT;
  IF v_restored <> 11 THEN
    RAISE EXCEPTION 'PG878 rollback abort: expected 11 rows restored, got %', v_restored;
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
      'PG878 rollback abort: restored prestate differs count=% hash=% live=% disabled=%',
      v_count, v_hash, v_live, v_disabled;
  END IF;

  SELECT count(*) INTO v_diff
  FROM (
    (SELECT * FROM manaloom_deploy_audit.pg878_lorehold_runtime_rules_pre_20260716
     EXCEPT
     SELECT * FROM public.card_battle_rules
     WHERE normalized_name IN ('birgi, god of storytelling', 'underworld breach', 'mana vault')
        OR normalized_name LIKE 'birgi, god of storytelling // %')
    UNION ALL
    (SELECT * FROM public.card_battle_rules
     WHERE normalized_name IN ('birgi, god of storytelling', 'underworld breach', 'mana vault')
        OR normalized_name LIKE 'birgi, god of storytelling // %'
     EXCEPT
     SELECT * FROM manaloom_deploy_audit.pg878_lorehold_runtime_rules_pre_20260716)
  ) diff;
  IF v_diff <> 0 THEN
    RAISE EXCEPTION 'PG878 rollback abort: restored row set differs diff=%', v_diff;
  END IF;
END $$;

COMMIT;

SELECT 'PG878_ROLLBACK_COMMITTED' AS status;
