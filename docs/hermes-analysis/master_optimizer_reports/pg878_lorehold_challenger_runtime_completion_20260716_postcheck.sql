-- READ ONLY. Run only after an explicitly approved PG878 apply.

BEGIN TRANSACTION READ ONLY;
SET LOCAL statement_timeout = '30s';
SET LOCAL lock_timeout = '5s';

DO $$
DECLARE
  v_count integer;
  v_hash text;
  v_total integer;
  v_exact integer;
  v_live integer;
  v_disabled integer;
  v_diff integer;
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg878_lorehold_runtime_cards_pre_20260716') IS NULL
     OR to_regclass('manaloom_deploy_audit.pg878_lorehold_runtime_rules_pre_20260716') IS NULL
     OR to_regclass('manaloom_deploy_audit.pg878_lorehold_runtime_proposal_20260716') IS NULL
     OR to_regclass('manaloom_deploy_audit.pg878_lorehold_runtime_rules_post_20260716') IS NULL THEN
    RAISE EXCEPTION 'PG878 postcheck abort: audit evidence is missing';
  END IF;

  SELECT count(*) INTO v_count
  FROM manaloom_deploy_audit.pg878_lorehold_runtime_cards_pre_20260716;
  IF v_count <> 3 THEN
    RAISE EXCEPTION 'PG878 postcheck abort: card backup count=%', v_count;
  END IF;

  SELECT count(*) INTO v_count
  FROM manaloom_deploy_audit.pg878_lorehold_runtime_rules_post_20260716;
  IF v_count <> 14 THEN
    RAISE EXCEPTION 'PG878 postcheck abort: poststate snapshot count=%', v_count;
  END IF;

  SELECT count(*), md5(string_agg(
      concat_ws('|', ordinal_position, column_name, udt_name, is_nullable,
                coalesce(column_default, '')),
      E'\n' ORDER BY ordinal_position))
    INTO v_count, v_hash
  FROM information_schema.columns
  WHERE table_schema = 'public' AND table_name = 'card_battle_rules';
  IF v_count <> 18 OR v_hash <> '22b9db71b43ac3cecf079dc716272d24' THEN
    RAISE EXCEPTION 'PG878 postcheck abort: card_battle_rules schema drift count=% hash=%', v_count, v_hash;
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
    RAISE EXCEPTION 'PG878 postcheck abort: target card lineage drift count=% hash=%', v_count, v_hash;
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
    RAISE EXCEPTION 'PG878 postcheck abort: rule backup drift count=% hash=%', v_count, v_hash;
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
    RAISE EXCEPTION 'PG878 postcheck abort: proposal drift count=% hash=%', v_count, v_hash;
  END IF;

  SELECT count(*),
         count(*) FILTER (WHERE p.logical_rule_key IS NOT NULL),
         count(*) FILTER (
           WHERE r.review_status NOT IN ('deprecated', 'rejected')
              OR r.execution_status <> 'disabled'
         ),
         count(*) FILTER (
           WHERE r.review_status IN ('deprecated', 'rejected')
             AND r.execution_status = 'disabled'
         )
    INTO v_total, v_exact, v_live, v_disabled
  FROM public.card_battle_rules r
  LEFT JOIN manaloom_deploy_audit.pg878_lorehold_runtime_proposal_20260716 p
    USING (normalized_name, logical_rule_key)
  WHERE r.normalized_name IN (
      'birgi, god of storytelling', 'underworld breach', 'mana vault'
    )
     OR r.normalized_name LIKE 'birgi, god of storytelling // %';
  IF v_total <> 14 OR v_exact <> 3 OR v_live <> 3 OR v_disabled <> 11 THEN
    RAISE EXCEPTION
      'PG878 postcheck abort: counts drift total=% exact=% live=% disabled=%',
      v_total, v_exact, v_live, v_disabled;
  END IF;

  SELECT count(*) INTO v_diff
  FROM manaloom_deploy_audit.pg878_lorehold_runtime_proposal_20260716 p
  LEFT JOIN public.card_battle_rules r
    USING (normalized_name, logical_rule_key)
  WHERE r.logical_rule_key IS NULL
     OR r.card_name IS DISTINCT FROM p.card_name
     OR r.effect_json IS DISTINCT FROM p.effect_json
     OR r.deck_role_json IS DISTINCT FROM p.deck_role_json
     OR r.source IS DISTINCT FROM p.source
     OR r.confidence IS DISTINCT FROM p.confidence
     OR r.review_status IS DISTINCT FROM p.review_status
     OR r.rule_version IS DISTINCT FROM p.rule_version
     OR r.oracle_hash IS DISTINCT FROM p.oracle_hash
     OR r.notes IS DISTINCT FROM p.notes
     OR r.reviewed_by IS DISTINCT FROM p.reviewed_by
     OR r.execution_status IS DISTINCT FROM p.execution_status
     OR r.reviewed_at IS NULL OR r.created_at IS NULL OR r.updated_at IS NULL
     OR r.last_seen_at IS NULL;
  IF v_diff <> 0 THEN
    RAISE EXCEPTION 'PG878 postcheck abort: exact promoted row diff=%', v_diff;
  END IF;

  SELECT count(*) INTO v_diff
  FROM manaloom_deploy_audit.pg878_lorehold_runtime_rules_pre_20260716 b
  JOIN public.card_battle_rules r USING (normalized_name, logical_rule_key)
  WHERE b.review_status IN ('deprecated', 'rejected')
    AND b.execution_status = 'disabled'
    AND to_jsonb(r) IS DISTINCT FROM to_jsonb(b);
  IF v_diff <> 0 THEN
    RAISE EXCEPTION 'PG878 postcheck abort: historical disabled rows changed diff=%', v_diff;
  END IF;

  SELECT count(*) INTO v_diff
  FROM manaloom_deploy_audit.pg878_lorehold_runtime_rules_pre_20260716 b
  LEFT JOIN public.card_battle_rules r USING (normalized_name, logical_rule_key)
  WHERE (b.review_status NOT IN ('deprecated', 'rejected') OR b.execution_status <> 'disabled')
    AND (
      r.logical_rule_key IS NULL
      OR (to_jsonb(r) - ARRAY['review_status','execution_status','updated_at','notes']::text[])
         IS DISTINCT FROM
         (to_jsonb(b) - ARRAY['review_status','execution_status','updated_at','notes']::text[])
      OR r.review_status <> 'deprecated'
      OR r.execution_status <> 'disabled'
      OR r.updated_at < b.updated_at
      OR r.notes IS DISTINCT FROM concat_ws(
        E'\n', nullif(b.notes, ''),
        'PG878: disabled superseded partial/annotation/review row before exact native runtime promotion.'
      )
    );
  IF v_diff <> 0 THEN
    RAISE EXCEPTION 'PG878 postcheck abort: superseded row transform diff=%', v_diff;
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
    RAISE EXCEPTION 'PG878 postcheck abort: target cards changed diff=%', v_diff;
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
    RAISE EXCEPTION 'PG878 postcheck abort: exact post snapshot drift diff=%', v_diff;
  END IF;
END $$;

SELECT
  'PG878_POSTCHECK_PASS' AS status,
  3 AS exact_verified_auto_rows,
  11 AS disabled_historical_or_superseded_rows,
  14 AS total_target_rule_rows,
  'birgi_harnfel_modal_faces_exact_v1' AS birgi_harnfel_scope,
  'underworld_breach_escape_and_end_step_sacrifice_exact_v1' AS underworld_breach_scope,
  'mana_vault_exact_untap_draw_damage_mana_v1' AS mana_vault_scope;

ROLLBACK;
