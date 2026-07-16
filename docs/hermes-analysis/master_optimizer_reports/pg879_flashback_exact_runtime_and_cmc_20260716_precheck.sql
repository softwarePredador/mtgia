-- READ ONLY. PG879 Flashback exact-runtime and mana-value metadata precheck.
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
  IF to_regclass('manaloom_deploy_audit.pg879_flashback_cards_pre_20260716') IS NOT NULL
     OR to_regclass('manaloom_deploy_audit.pg879_flashback_rules_pre_20260716') IS NOT NULL
     OR to_regclass('manaloom_deploy_audit.pg879_flashback_proposal_20260716') IS NOT NULL
     OR to_regclass('manaloom_deploy_audit.pg879_flashback_cards_post_20260716') IS NOT NULL
     OR to_regclass('manaloom_deploy_audit.pg879_flashback_rules_post_20260716') IS NOT NULL THEN
    RAISE EXCEPTION 'PG879 precheck abort: an audit table already exists';
  END IF;

  SELECT count(*), md5(string_agg(
      concat_ws('|', ordinal_position, column_name, udt_name, is_nullable,
                coalesce(column_default, '')),
      E'\n' ORDER BY ordinal_position))
    INTO v_count, v_hash
  FROM information_schema.columns
  WHERE table_schema = 'public' AND table_name = 'cards';
  IF v_count <> 28 OR v_hash <> '03ef6ea64392bacd6db316eefe8c3896' THEN
    RAISE EXCEPTION 'PG879 precheck abort: cards schema drift count=% hash=%', v_count, v_hash;
  END IF;

  SELECT count(*), md5(string_agg(
      concat_ws('|', ordinal_position, column_name, udt_name, is_nullable,
                coalesce(column_default, '')),
      E'\n' ORDER BY ordinal_position))
    INTO v_count, v_hash
  FROM information_schema.columns
  WHERE table_schema = 'public' AND table_name = 'card_battle_rules';
  IF v_count <> 18 OR v_hash <> '22b9db71b43ac3cecf079dc716272d24' THEN
    RAISE EXCEPTION 'PG879 precheck abort: card_battle_rules schema drift count=% hash=%', v_count, v_hash;
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
    RAISE EXCEPTION 'PG879 precheck abort: Flashback card prestate drift count=% hash=%', v_count, v_hash;
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
    RAISE EXCEPTION 'PG879 precheck abort: Flashback UUID/name/mana/cmc/type/oracle identity drift';
  END IF;

  -- Project the exact storage representation of cards.cmc after the proposed
  -- numeric(4,1) update. This is read-only and prevents a display/coercion
  -- mismatch from reaching the mutating package.
  SELECT count(*), md5(coalesce(string_agg(
      jsonb_build_array(
        id, scryfall_id, oracle_id, name, mana_cost,
        1.0::numeric(4,1), type_line, oracle_text, colors, color_identity,
        power, toughness, keywords, layout, card_faces_json, set_code,
        collector_number
      )::text,
      E'\n' ORDER BY lower(name), id::text), ''))
    INTO v_count, v_hash
  FROM public.cards
  WHERE id = 'd96a06bc-aa90-4837-b8ab-ad2be804641a'::uuid;
  IF v_count <> 1 OR v_hash <> '5b3d349754c594360b6315db018b0f96' THEN
    RAISE EXCEPTION
      'PG879 precheck abort: projected Flashback card poststate drift count=% hash=%',
      v_count, v_hash;
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
      'PG879 precheck abort: rule prestate drift count=% hash=% live=% disabled=%',
      v_count, v_hash, v_live, v_disabled;
  END IF;

  SELECT count(*) INTO v_existing_exact
  FROM public.card_battle_rules
  WHERE normalized_name = 'flashback'
    AND logical_rule_key = 'battle_rule_v1:f5b21163180f3254fa6b288d5ab0a95b';
  IF v_existing_exact <> 0 THEN
    RAISE EXCEPTION 'PG879 precheck abort: exact proposal key already exists count=%', v_existing_exact;
  END IF;

  SELECT count(*), md5(string_agg(
      jsonb_build_array(
        normalized_name, card_name, oracle_hash, logical_rule_key, effect_json,
        deck_role_json, source, confidence, review_status, execution_status,
        rule_version, notes, reviewed_by
      )::text,
      E'\n' ORDER BY normalized_name, logical_rule_key))
    INTO v_count, v_hash
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
  IF v_count <> 1 OR v_hash <> '1a7fac705bdac60ec3c062960daecff6' THEN
    RAISE EXCEPTION 'PG879 precheck abort: proposal drift count=% hash=%', v_count, v_hash;
  END IF;
END $$;

SELECT
  'PG879_PRECHECK_PASS' AS status,
  1 AS target_card_rows,
  2 AS pre_rule_rows,
  2 AS live_rows_to_deprecate,
  0 AS historical_disabled_rows_to_preserve,
  1 AS exact_rows_to_insert,
  'a5ac34f8c716be13f6ea72aea4ef39a2' AS target_card_pre_hash,
  '5b3d349754c594360b6315db018b0f96' AS target_card_projected_post_hash,
  '368225ebe6470d5da54dbfbb31d733b2' AS pre_rule_hash,
  '1a7fac705bdac60ec3c062960daecff6' AS proposal_hash;

ROLLBACK;
