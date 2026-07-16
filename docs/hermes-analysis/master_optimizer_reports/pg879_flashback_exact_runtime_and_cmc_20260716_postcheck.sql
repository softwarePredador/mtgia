-- READ ONLY. Run only after an explicitly approved PG879 apply.

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
  IF to_regclass('manaloom_deploy_audit.pg879_flashback_cards_pre_20260716') IS NULL
     OR to_regclass('manaloom_deploy_audit.pg879_flashback_rules_pre_20260716') IS NULL
     OR to_regclass('manaloom_deploy_audit.pg879_flashback_proposal_20260716') IS NULL
     OR to_regclass('manaloom_deploy_audit.pg879_flashback_cards_post_20260716') IS NULL
     OR to_regclass('manaloom_deploy_audit.pg879_flashback_rules_post_20260716') IS NULL THEN
    RAISE EXCEPTION 'PG879 postcheck abort: complete pre/proposal/post audit evidence is missing';
  END IF;

  SELECT count(*), md5(string_agg(
      concat_ws('|', ordinal_position, column_name, udt_name, is_nullable,
                coalesce(column_default, '')),
      E'\n' ORDER BY ordinal_position))
    INTO v_count, v_hash
  FROM information_schema.columns
  WHERE table_schema = 'public' AND table_name = 'cards';
  IF v_count <> 28 OR v_hash <> '03ef6ea64392bacd6db316eefe8c3896' THEN
    RAISE EXCEPTION 'PG879 postcheck abort: cards schema drift count=% hash=%', v_count, v_hash;
  END IF;

  SELECT count(*), md5(string_agg(
      concat_ws('|', ordinal_position, column_name, udt_name, is_nullable,
                coalesce(column_default, '')),
      E'\n' ORDER BY ordinal_position))
    INTO v_count, v_hash
  FROM information_schema.columns
  WHERE table_schema = 'public' AND table_name = 'card_battle_rules';
  IF v_count <> 18 OR v_hash <> '22b9db71b43ac3cecf079dc716272d24' THEN
    RAISE EXCEPTION 'PG879 postcheck abort: card_battle_rules schema drift count=% hash=%', v_count, v_hash;
  END IF;

  SELECT count(*), md5(coalesce(string_agg(
      jsonb_build_array(
        id, scryfall_id, oracle_id, name, mana_cost, cmc, type_line,
        oracle_text, colors, color_identity, power, toughness, keywords,
        layout, card_faces_json, set_code, collector_number
      )::text,
      E'\n' ORDER BY lower(name), id::text), ''))
    INTO v_count, v_hash
  FROM manaloom_deploy_audit.pg879_flashback_cards_pre_20260716;
  IF v_count <> 1 OR v_hash <> 'a5ac34f8c716be13f6ea72aea4ef39a2' THEN
    RAISE EXCEPTION 'PG879 postcheck abort: card pre snapshot drift count=% hash=%', v_count, v_hash;
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
  FROM manaloom_deploy_audit.pg879_flashback_rules_pre_20260716;
  IF v_count <> 2 OR v_hash <> '368225ebe6470d5da54dbfbb31d733b2' THEN
    RAISE EXCEPTION 'PG879 postcheck abort: rule pre snapshot drift count=% hash=%', v_count, v_hash;
  END IF;

  SELECT count(*), md5(string_agg(
      jsonb_build_array(
        normalized_name, card_name, oracle_hash, logical_rule_key, effect_json,
        deck_role_json, source, confidence, review_status, execution_status,
        rule_version, notes, reviewed_by
      )::text,
      E'\n' ORDER BY normalized_name, logical_rule_key))
    INTO v_count, v_hash
  FROM manaloom_deploy_audit.pg879_flashback_proposal_20260716;
  IF v_count <> 1 OR v_hash <> '1a7fac705bdac60ec3c062960daecff6' THEN
    RAISE EXCEPTION 'PG879 postcheck abort: proposal drift count=% hash=%', v_count, v_hash;
  END IF;

  SELECT count(*), md5(coalesce(string_agg(
      jsonb_build_array(
        id, scryfall_id, oracle_id, name, mana_cost, cmc, type_line,
        oracle_text, colors, color_identity, power, toughness, keywords,
        layout, card_faces_json, set_code, collector_number
      )::text,
      E'\n' ORDER BY lower(name), id::text), ''))
    INTO v_count, v_hash
  FROM manaloom_deploy_audit.pg879_flashback_cards_post_20260716;
  IF v_count <> 1 OR v_hash <> '5b3d349754c594360b6315db018b0f96' THEN
    RAISE EXCEPTION 'PG879 postcheck abort: card post snapshot drift count=% hash=%', v_count, v_hash;
  END IF;

  SELECT count(*) INTO v_count
  FROM manaloom_deploy_audit.pg879_flashback_rules_post_20260716;
  IF v_count <> 3 THEN
    RAISE EXCEPTION 'PG879 postcheck abort: rule post snapshot count=%', v_count;
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
  WHERE id = 'd96a06bc-aa90-4837-b8ab-ad2be804641a'::uuid;
  IF v_count <> 1 OR v_hash <> '5b3d349754c594360b6315db018b0f96' THEN
    RAISE EXCEPTION 'PG879 postcheck abort: live card poststate drift count=% hash=%', v_count, v_hash;
  END IF;

  SELECT count(*) INTO v_diff
  FROM manaloom_deploy_audit.pg879_flashback_cards_pre_20260716 b
  FULL JOIN (
    SELECT *
    FROM public.cards
    WHERE id = 'd96a06bc-aa90-4837-b8ab-ad2be804641a'::uuid
  ) c USING (id)
  WHERE c.id IS NULL
     OR b.id IS NULL
     OR b.cmc IS DISTINCT FROM 0.0
     OR c.cmc IS DISTINCT FROM 1.0
     OR (to_jsonb(c) - 'cmc') IS DISTINCT FROM (to_jsonb(b) - 'cmc');
  IF v_diff <> 0 THEN
    RAISE EXCEPTION 'PG879 postcheck abort: cards changed outside cmc 0.0 -> 1.0 diff=%', v_diff;
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
  LEFT JOIN manaloom_deploy_audit.pg879_flashback_proposal_20260716 p
    USING (normalized_name, logical_rule_key)
  WHERE r.normalized_name = 'flashback'
     OR r.card_id = 'd96a06bc-aa90-4837-b8ab-ad2be804641a'::uuid;
  IF v_total <> 3 OR v_exact <> 1 OR v_live <> 1 OR v_disabled <> 2 THEN
    RAISE EXCEPTION
      'PG879 postcheck abort: counts drift total=% exact=% live=% disabled=%',
      v_total, v_exact, v_live, v_disabled;
  END IF;

  SELECT count(*) INTO v_diff
  FROM manaloom_deploy_audit.pg879_flashback_proposal_20260716 p
  LEFT JOIN public.card_battle_rules r
    USING (normalized_name, logical_rule_key)
  WHERE r.logical_rule_key IS NULL
     OR r.card_id IS DISTINCT FROM 'd96a06bc-aa90-4837-b8ab-ad2be804641a'::uuid
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
     OR r.reviewed_at IS NULL
     OR r.created_at IS NULL
     OR r.updated_at IS NULL
     OR r.last_seen_at IS NULL;
  IF v_diff <> 0 THEN
    RAISE EXCEPTION 'PG879 postcheck abort: exact promoted row diff=%', v_diff;
  END IF;

  SELECT count(*) INTO v_diff
  FROM manaloom_deploy_audit.pg879_flashback_rules_pre_20260716 b
  LEFT JOIN public.card_battle_rules r USING (normalized_name, logical_rule_key)
  WHERE r.logical_rule_key IS NULL
     OR (to_jsonb(r) - ARRAY['review_status','execution_status','updated_at','notes']::text[])
        IS DISTINCT FROM
        (to_jsonb(b) - ARRAY['review_status','execution_status','updated_at','notes']::text[])
     OR r.review_status <> 'deprecated'
     OR r.execution_status <> 'disabled'
     OR r.updated_at IS NULL
     OR r.updated_at <= b.updated_at
     OR r.notes IS DISTINCT FROM concat_ws(
       E'\n', nullif(b.notes, ''),
       'PG879: disabled superseded broad recursion row before exact targeted flashback runtime promotion.'
     );
  IF v_diff <> 0 THEN
    RAISE EXCEPTION 'PG879 postcheck abort: superseded rule transform diff=%', v_diff;
  END IF;

  SELECT count(*) INTO v_diff
  FROM (
    (SELECT * FROM manaloom_deploy_audit.pg879_flashback_cards_post_20260716
     EXCEPT
     SELECT * FROM public.cards
     WHERE id = 'd96a06bc-aa90-4837-b8ab-ad2be804641a'::uuid)
    UNION ALL
    (SELECT * FROM public.cards
     WHERE id = 'd96a06bc-aa90-4837-b8ab-ad2be804641a'::uuid
     EXCEPT
     SELECT * FROM manaloom_deploy_audit.pg879_flashback_cards_post_20260716)
  ) diff;
  IF v_diff <> 0 THEN
    RAISE EXCEPTION 'PG879 postcheck abort: exact card post snapshot drift diff=%', v_diff;
  END IF;

  SELECT count(*) INTO v_diff
  FROM (
    (SELECT * FROM manaloom_deploy_audit.pg879_flashback_rules_post_20260716
     EXCEPT
     SELECT * FROM public.card_battle_rules
     WHERE normalized_name = 'flashback'
        OR card_id = 'd96a06bc-aa90-4837-b8ab-ad2be804641a'::uuid)
    UNION ALL
    (SELECT * FROM public.card_battle_rules
     WHERE normalized_name = 'flashback'
        OR card_id = 'd96a06bc-aa90-4837-b8ab-ad2be804641a'::uuid
     EXCEPT
     SELECT * FROM manaloom_deploy_audit.pg879_flashback_rules_post_20260716)
  ) diff;
  IF v_diff <> 0 THEN
    RAISE EXCEPTION 'PG879 postcheck abort: exact rule post snapshot drift diff=%', v_diff;
  END IF;
END $$;

SELECT
  'PG879_POSTCHECK_PASS' AS status,
  1 AS cards_cmc_rows_corrected,
  1 AS exact_verified_auto_rows,
  2 AS disabled_superseded_rows,
  3 AS total_target_rule_rows,
  '5b3d349754c594360b6315db018b0f96' AS target_card_post_hash,
  '1a7fac705bdac60ec3c062960daecff6' AS proposal_hash,
  (SELECT md5(string_agg(to_jsonb(r)::text, E'\n' ORDER BY logical_rule_key))
   FROM manaloom_deploy_audit.pg879_flashback_rules_post_20260716 r)
    AS exact_rule_post_snapshot_hash;

ROLLBACK;
