-- MUTATING ROLLBACK. Requires explicit PostgreSQL approval for this execution.
-- Refuses rollback unless the complete PG879 card/rule poststate still equals
-- the immutable audit snapshots created by the approved apply.

BEGIN;
SET LOCAL statement_timeout = '60s';
SET LOCAL lock_timeout = '10s';

LOCK TABLE public.cards IN SHARE ROW EXCLUSIVE MODE;
LOCK TABLE public.card_battle_rules IN SHARE ROW EXCLUSIVE MODE;

DO $$
DECLARE
  v_count integer;
  v_hash text;
  v_diff integer;
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg879_flashback_cards_pre_20260716') IS NULL
     OR to_regclass('manaloom_deploy_audit.pg879_flashback_rules_pre_20260716') IS NULL
     OR to_regclass('manaloom_deploy_audit.pg879_flashback_proposal_20260716') IS NULL
     OR to_regclass('manaloom_deploy_audit.pg879_flashback_cards_post_20260716') IS NULL
     OR to_regclass('manaloom_deploy_audit.pg879_flashback_rules_post_20260716') IS NULL THEN
    RAISE EXCEPTION 'PG879 rollback abort: complete pre/proposal/post audit evidence is missing';
  END IF;

  SELECT count(*), md5(string_agg(
      concat_ws('|', ordinal_position, column_name, udt_name, is_nullable,
                coalesce(column_default, '')),
      E'\n' ORDER BY ordinal_position))
    INTO v_count, v_hash
  FROM information_schema.columns
  WHERE table_schema = 'public' AND table_name = 'cards';
  IF v_count <> 28 OR v_hash <> '03ef6ea64392bacd6db316eefe8c3896' THEN
    RAISE EXCEPTION 'PG879 rollback abort: cards schema drift count=% hash=%', v_count, v_hash;
  END IF;

  SELECT count(*), md5(string_agg(
      concat_ws('|', ordinal_position, column_name, udt_name, is_nullable,
                coalesce(column_default, '')),
      E'\n' ORDER BY ordinal_position))
    INTO v_count, v_hash
  FROM information_schema.columns
  WHERE table_schema = 'public' AND table_name = 'card_battle_rules';
  IF v_count <> 18 OR v_hash <> '22b9db71b43ac3cecf079dc716272d24' THEN
    RAISE EXCEPTION 'PG879 rollback abort: card_battle_rules schema drift count=% hash=%', v_count, v_hash;
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
    RAISE EXCEPTION 'PG879 rollback abort: card pre snapshot drift count=% hash=%', v_count, v_hash;
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
    RAISE EXCEPTION 'PG879 rollback abort: rule pre snapshot drift count=% hash=%', v_count, v_hash;
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
    RAISE EXCEPTION 'PG879 rollback abort: proposal drift count=% hash=%', v_count, v_hash;
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
    RAISE EXCEPTION 'PG879 rollback abort: card post snapshot drift count=% hash=%', v_count, v_hash;
  END IF;

  SELECT count(*) INTO v_count
  FROM manaloom_deploy_audit.pg879_flashback_rules_post_20260716;
  IF v_count <> 3 THEN
    RAISE EXCEPTION 'PG879 rollback abort: rule post snapshot count=%', v_count;
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
    RAISE EXCEPTION 'PG879 rollback abort: live card poststate drift count=% hash=%', v_count, v_hash;
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
    RAISE EXCEPTION 'PG879 rollback abort: exact card poststate drifted diff=%', v_diff;
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
    RAISE EXCEPTION 'PG879 rollback abort: exact rule poststate drifted diff=%', v_diff;
  END IF;
END $$;

DO $$
DECLARE
  v_deleted integer;
  v_restored integer;
  v_updated integer;
  v_count integer;
  v_hash text;
  v_live integer;
  v_disabled integer;
  v_diff integer;
BEGIN
  DELETE FROM public.card_battle_rules
  WHERE normalized_name = 'flashback'
     OR card_id = 'd96a06bc-aa90-4837-b8ab-ad2be804641a'::uuid;
  GET DIAGNOSTICS v_deleted = ROW_COUNT;
  IF v_deleted <> 3 THEN
    RAISE EXCEPTION 'PG879 rollback abort: expected exactly 3 poststate rules deleted, got %', v_deleted;
  END IF;

  INSERT INTO public.card_battle_rules
  SELECT *
  FROM manaloom_deploy_audit.pg879_flashback_rules_pre_20260716;
  GET DIAGNOSTICS v_restored = ROW_COUNT;
  IF v_restored <> 2 THEN
    RAISE EXCEPTION 'PG879 rollback abort: expected exactly 2 prestate rules restored, got %', v_restored;
  END IF;

  UPDATE public.cards c
  SET cmc = b.cmc
  FROM manaloom_deploy_audit.pg879_flashback_cards_pre_20260716 b
  WHERE c.id = b.id
    AND c.id = 'd96a06bc-aa90-4837-b8ab-ad2be804641a'::uuid
    AND c.cmc = 1.0
    AND b.cmc = 0.0
    AND (to_jsonb(c) - 'cmc') = (to_jsonb(b) - 'cmc');
  GET DIAGNOSTICS v_updated = ROW_COUNT;
  IF v_updated <> 1 THEN
    RAISE EXCEPTION 'PG879 rollback abort: expected exactly 1 cards.cmc restore, got %', v_updated;
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
  IF v_count <> 1 OR v_hash <> 'a5ac34f8c716be13f6ea72aea4ef39a2' THEN
    RAISE EXCEPTION 'PG879 rollback abort: restored card prestate drift count=% hash=%', v_count, v_hash;
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
  WHERE normalized_name = 'flashback'
     OR card_id = 'd96a06bc-aa90-4837-b8ab-ad2be804641a'::uuid;
  IF v_count <> 2
     OR v_hash <> '368225ebe6470d5da54dbfbb31d733b2'
     OR v_live <> 2
     OR v_disabled <> 0 THEN
    RAISE EXCEPTION
      'PG879 rollback abort: restored rule prestate drift count=% hash=% live=% disabled=%',
      v_count, v_hash, v_live, v_disabled;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.card_battle_rules
    WHERE normalized_name = 'flashback'
      AND logical_rule_key = 'battle_rule_v1:f5b21163180f3254fa6b288d5ab0a95b'
  ) THEN
    RAISE EXCEPTION 'PG879 rollback abort: exact proposal row survived restore';
  END IF;

  SELECT count(*) INTO v_diff
  FROM (
    (SELECT * FROM manaloom_deploy_audit.pg879_flashback_cards_pre_20260716
     EXCEPT
     SELECT * FROM public.cards
     WHERE id = 'd96a06bc-aa90-4837-b8ab-ad2be804641a'::uuid)
    UNION ALL
    (SELECT * FROM public.cards
     WHERE id = 'd96a06bc-aa90-4837-b8ab-ad2be804641a'::uuid
     EXCEPT
     SELECT * FROM manaloom_deploy_audit.pg879_flashback_cards_pre_20260716)
  ) diff;
  IF v_diff <> 0 THEN
    RAISE EXCEPTION 'PG879 rollback abort: restored card row set differs diff=%', v_diff;
  END IF;

  SELECT count(*) INTO v_diff
  FROM (
    (SELECT * FROM manaloom_deploy_audit.pg879_flashback_rules_pre_20260716
     EXCEPT
     SELECT * FROM public.card_battle_rules
     WHERE normalized_name = 'flashback'
        OR card_id = 'd96a06bc-aa90-4837-b8ab-ad2be804641a'::uuid)
    UNION ALL
    (SELECT * FROM public.card_battle_rules
     WHERE normalized_name = 'flashback'
        OR card_id = 'd96a06bc-aa90-4837-b8ab-ad2be804641a'::uuid
     EXCEPT
     SELECT * FROM manaloom_deploy_audit.pg879_flashback_rules_pre_20260716)
  ) diff;
  IF v_diff <> 0 THEN
    RAISE EXCEPTION 'PG879 rollback abort: restored rule row set differs diff=%', v_diff;
  END IF;
END $$;

COMMIT;

SELECT
  'PG879_ROLLBACK_COMMITTED' AS status,
  'a5ac34f8c716be13f6ea72aea4ef39a2' AS restored_card_hash,
  '368225ebe6470d5da54dbfbb31d733b2' AS restored_rule_hash;
