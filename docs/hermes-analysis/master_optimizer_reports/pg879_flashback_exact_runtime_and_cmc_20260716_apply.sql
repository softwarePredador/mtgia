-- MUTATING. Requires explicit PostgreSQL approval for this execution.
-- PG879 corrects only Flashback.cmc 0.0 -> 1.0 and replaces two broad live
-- battle rules with one exact verified/auto rule. It does not sync Hermes.

BEGIN;
SET LOCAL statement_timeout = '60s';
SET LOCAL lock_timeout = '10s';

LOCK TABLE public.cards IN SHARE ROW EXCLUSIVE MODE;
LOCK TABLE public.card_battle_rules IN SHARE ROW EXCLUSIVE MODE;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
DECLARE
  v_count integer;
  v_hash text;
  v_live integer;
  v_disabled integer;
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg879_flashback_cards_pre_20260716') IS NOT NULL
     OR to_regclass('manaloom_deploy_audit.pg879_flashback_rules_pre_20260716') IS NOT NULL
     OR to_regclass('manaloom_deploy_audit.pg879_flashback_proposal_20260716') IS NOT NULL
     OR to_regclass('manaloom_deploy_audit.pg879_flashback_cards_post_20260716') IS NOT NULL
     OR to_regclass('manaloom_deploy_audit.pg879_flashback_rules_post_20260716') IS NOT NULL THEN
    RAISE EXCEPTION 'PG879 apply abort: an audit table already exists';
  END IF;

  SELECT count(*), md5(string_agg(
      concat_ws('|', ordinal_position, column_name, udt_name, is_nullable,
                coalesce(column_default, '')),
      E'\n' ORDER BY ordinal_position))
    INTO v_count, v_hash
  FROM information_schema.columns
  WHERE table_schema = 'public' AND table_name = 'cards';
  IF v_count <> 28 OR v_hash <> '03ef6ea64392bacd6db316eefe8c3896' THEN
    RAISE EXCEPTION 'PG879 apply abort: cards schema drift count=% hash=%', v_count, v_hash;
  END IF;

  SELECT count(*), md5(string_agg(
      concat_ws('|', ordinal_position, column_name, udt_name, is_nullable,
                coalesce(column_default, '')),
      E'\n' ORDER BY ordinal_position))
    INTO v_count, v_hash
  FROM information_schema.columns
  WHERE table_schema = 'public' AND table_name = 'card_battle_rules';
  IF v_count <> 18 OR v_hash <> '22b9db71b43ac3cecf079dc716272d24' THEN
    RAISE EXCEPTION 'PG879 apply abort: card_battle_rules schema drift count=% hash=%', v_count, v_hash;
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
    RAISE EXCEPTION 'PG879 apply abort: Flashback card prestate drift count=% hash=%', v_count, v_hash;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.cards
    WHERE id = 'd96a06bc-aa90-4837-b8ab-ad2be804641a'::uuid
      AND name = 'Flashback'
      AND mana_cost = '{R}'
      AND cmc = 0.0
      AND type_line = 'Instant'
      AND md5(coalesce(oracle_text, '')) = '552a1f4ae21306af7e3e4db346a6c3c4'
  ) THEN
    RAISE EXCEPTION 'PG879 apply abort: Flashback UUID/name/mana/cmc/type/oracle identity drift';
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
      'PG879 apply abort: rule prestate drift count=% hash=% live=% disabled=%',
      v_count, v_hash, v_live, v_disabled;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.card_battle_rules
    WHERE normalized_name = 'flashback'
      AND logical_rule_key = 'battle_rule_v1:f5b21163180f3254fa6b288d5ab0a95b'
  ) THEN
    RAISE EXCEPTION 'PG879 apply abort: exact proposal key already exists';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pg879_flashback_cards_pre_20260716 AS
SELECT *
FROM public.cards
WHERE id = 'd96a06bc-aa90-4837-b8ab-ad2be804641a'::uuid;

CREATE TABLE manaloom_deploy_audit.pg879_flashback_rules_pre_20260716 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name = 'flashback'
   OR card_id = 'd96a06bc-aa90-4837-b8ab-ad2be804641a'::uuid;

CREATE TABLE manaloom_deploy_audit.pg879_flashback_proposal_20260716 AS
SELECT *
FROM (VALUES (
  'flashback'::text,
  'Flashback'::text,
  '552a1f4ae21306af7e3e4db346a6c3c4'::text,
  'battle_rule_v1:f5b21163180f3254fa6b288d5ab0a95b'::text,
  '{"ability_kind":"one_shot_targeted_continuous_permission","battle_model_scope":"target_instant_sorcery_graveyard_gains_mana_cost_flashback_until_eot_v1","cmc":1.0,"duration":"until_end_of_turn","effect":"graveyard_flashback_grant","flashback_cast_status":"runtime_executor_v1","flashback_cost_source":"target_printed_mana_cost","flashback_exile_on_leave_stack":true,"flashback_exile_status":"runtime_executor_v1","flashback_grant_status":"runtime_executor_v1","flashback_uses_normal_cast_pipeline":true,"grants_flashback_to":"target_instant_or_sorcery","instant":true,"oracle_runtime_scope":"target_one_own_graveyard_instant_sorcery_grant_printed_cost_flashback_until_eot_exile_after_stack_exact_v1","sorcery":false,"source_mana_cost":"{R}","source_type_line":"Instant","target":"instant_or_sorcery_card_in_your_graveyard","target_constraints":{"card_types":["instant","sorcery"],"controller_scope":"self","zone":"graveyard"},"target_controller":"self","target_count":1,"target_count_max":1,"target_count_min":1,"target_declared_on_cast":true,"target_legality_rechecked_on_resolution":true,"target_zone":"graveyard","targeted_flashback_grant":true,"xmage_ability_classes":[],"xmage_condition_classes":[],"xmage_cost_classes":[],"xmage_duration":"EndOfTurn","xmage_effect_classes":["GainFlashbackTargetEffect"],"xmage_filter_classes":[],"xmage_filter_constants":["StaticFilters.FILTER_CARD_INSTANT_OR_SORCERY"],"xmage_granted_ability_class":"FlashbackAbility","xmage_granted_ability_cost_source":"card.getManaCost()","xmage_target_classes":["TargetCardInYourGraveyard"]}'::jsonb,
  '{"category":"engine","effect":"graveyard_flashback_grant","functions":["targeted_graveyard_cast_permission","flashback_alternative_cost","flashback_stack_exile_replacement"],"subtype":"targeted_flashback_grant","target":"instant_or_sorcery_card_in_your_graveyard","timing":"instant"}'::jsonb,
  'curated'::text,
  0.98::numeric,
  'verified'::text,
  'auto'::text,
  3::integer,
  'PG879 exact native runtime: Flashback targets exactly one instant or sorcery card in its controller''s graveyard, grants flashback until end of turn with cost equal to that target''s printed mana cost, preserves normal timing, and exiles a flashback-cast spell whenever it leaves the stack. XMage 1.4.60 Flashback.java SHA-256 1fee8059282891aca6424a704e5f2c6bffaeecd97f440253c04a2ae8b504e12d; GainFlashbackTargetEffect.java SHA-256 a31c4c77af35bdd83e3e259a3d4546236e5017d4a9b037f92c309e2e8927beed; FlashbackAbility.java SHA-256 6a3cea9f6a49b61f425bf267cc280a991d4d1315322b11059cd0604e0dd76e87; CastFromGraveyardAbility.java SHA-256 d960ebf54f87db2baf2a23785c181bdfea863a60d493eb66707ba64becc77be9; TargetCardInYourGraveyard.java SHA-256 374eeaa08611b6b2db2fa3693325c8b50dad9b3b71dcbefd18e059c4403258f4.'::text,
  'codex-pg879-flashback-exact-runtime-cmc'::text
)) AS p(
  normalized_name, card_name, oracle_hash, logical_rule_key, effect_json,
  deck_role_json, source, confidence, review_status, execution_status,
  rule_version, notes, reviewed_by
);

DO $$
DECLARE
  v_count integer;
  v_hash text;
  v_updated integer;
  v_inserted integer;
BEGIN
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
    RAISE EXCEPTION 'PG879 apply abort: proposal drift count=% hash=%', v_count, v_hash;
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
    RAISE EXCEPTION 'PG879 apply abort: card snapshot drift count=% hash=%', v_count, v_hash;
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
    RAISE EXCEPTION 'PG879 apply abort: rule snapshot drift count=% hash=%', v_count, v_hash;
  END IF;

  UPDATE public.cards
  SET cmc = 1.0
  WHERE id = 'd96a06bc-aa90-4837-b8ab-ad2be804641a'::uuid
    AND name = 'Flashback'
    AND mana_cost = '{R}'
    AND cmc = 0.0
    AND type_line = 'Instant'
    AND md5(coalesce(oracle_text, '')) = '552a1f4ae21306af7e3e4db346a6c3c4';
  GET DIAGNOSTICS v_updated = ROW_COUNT;
  IF v_updated <> 1 THEN
    RAISE EXCEPTION 'PG879 apply abort: expected exactly 1 cards.cmc update, got %', v_updated;
  END IF;

  UPDATE public.card_battle_rules
  SET review_status = 'deprecated',
      execution_status = 'disabled',
      updated_at = CURRENT_TIMESTAMP,
      notes = concat_ws(
        E'\n', nullif(notes, ''),
        'PG879: disabled superseded broad recursion row before exact targeted flashback runtime promotion.'
      )
  WHERE (normalized_name = 'flashback'
         OR card_id = 'd96a06bc-aa90-4837-b8ab-ad2be804641a'::uuid)
    AND (review_status NOT IN ('deprecated', 'rejected')
         OR execution_status <> 'disabled')
    AND logical_rule_key <> 'battle_rule_v1:f5b21163180f3254fa6b288d5ab0a95b';
  GET DIAGNOSTICS v_updated = ROW_COUNT;
  IF v_updated <> 2 THEN
    RAISE EXCEPTION 'PG879 apply abort: expected exactly 2 live rules disabled, got %', v_updated;
  END IF;

  INSERT INTO public.card_battle_rules (
    normalized_name, card_id, card_name, effect_json, deck_role_json, source,
    confidence, review_status, rule_version, oracle_hash, notes, reviewed_by,
    reviewed_at, created_at, updated_at, last_seen_at, logical_rule_key,
    execution_status
  )
  SELECT
    p.normalized_name,
    'd96a06bc-aa90-4837-b8ab-ad2be804641a'::uuid,
    p.card_name,
    p.effect_json,
    p.deck_role_json,
    p.source,
    p.confidence,
    p.review_status,
    p.rule_version,
    p.oracle_hash,
    p.notes,
    p.reviewed_by,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP,
    p.logical_rule_key,
    p.execution_status
  FROM manaloom_deploy_audit.pg879_flashback_proposal_20260716 p;
  GET DIAGNOSTICS v_inserted = ROW_COUNT;
  IF v_inserted <> 1 THEN
    RAISE EXCEPTION 'PG879 apply abort: expected exactly 1 exact rule inserted, got %', v_inserted;
  END IF;
END $$;

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
    RAISE EXCEPTION 'PG879 apply abort: card poststate drift count=% hash=%', v_count, v_hash;
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
    RAISE EXCEPTION 'PG879 apply abort: cards changed outside cmc 0.0 -> 1.0 diff=%', v_diff;
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
      'PG879 apply abort: rule post counts drift total=% exact=% live=% disabled=%',
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
    RAISE EXCEPTION 'PG879 apply abort: exact promoted row diff=%', v_diff;
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
    RAISE EXCEPTION 'PG879 apply abort: superseded rule transform diff=%', v_diff;
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pg879_flashback_cards_post_20260716 AS
SELECT *
FROM public.cards
WHERE id = 'd96a06bc-aa90-4837-b8ab-ad2be804641a'::uuid;

CREATE TABLE manaloom_deploy_audit.pg879_flashback_rules_post_20260716 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name = 'flashback'
   OR card_id = 'd96a06bc-aa90-4837-b8ab-ad2be804641a'::uuid;

DO $$
DECLARE
  v_count integer;
  v_hash text;
  v_diff integer;
BEGIN
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
    RAISE EXCEPTION 'PG879 apply abort: card post snapshot drift count=% hash=%', v_count, v_hash;
  END IF;

  SELECT count(*) INTO v_count
  FROM manaloom_deploy_audit.pg879_flashback_rules_post_20260716;
  IF v_count <> 3 THEN
    RAISE EXCEPTION 'PG879 apply abort: rule post snapshot count=%', v_count;
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
    RAISE EXCEPTION 'PG879 apply abort: exact card post snapshot diff=%', v_diff;
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
    RAISE EXCEPTION 'PG879 apply abort: exact rule post snapshot diff=%', v_diff;
  END IF;
END $$;

COMMIT;

SELECT
  'PG879_APPLY_COMMITTED' AS status,
  '5b3d349754c594360b6315db018b0f96' AS target_card_post_hash,
  (SELECT md5(string_agg(to_jsonb(r)::text, E'\n' ORDER BY logical_rule_key))
   FROM manaloom_deploy_audit.pg879_flashback_rules_post_20260716 r)
    AS exact_rule_post_snapshot_hash;
