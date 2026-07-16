-- MUTATING. Requires explicit PostgreSQL approval for this execution.
-- PG878 promotes three exact native Lorehold runtime rules and nothing else.

BEGIN;
SET LOCAL statement_timeout = '60s';
SET LOCAL lock_timeout = '10s';

LOCK TABLE public.cards IN SHARE MODE;
LOCK TABLE public.card_battle_rules IN SHARE ROW EXCLUSIVE MODE;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
DECLARE
  v_count integer;
  v_hash text;
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg878_lorehold_runtime_cards_pre_20260716') IS NOT NULL
     OR to_regclass('manaloom_deploy_audit.pg878_lorehold_runtime_rules_pre_20260716') IS NOT NULL
     OR to_regclass('manaloom_deploy_audit.pg878_lorehold_runtime_proposal_20260716') IS NOT NULL
     OR to_regclass('manaloom_deploy_audit.pg878_lorehold_runtime_rules_post_20260716') IS NOT NULL THEN
    RAISE EXCEPTION 'PG878 apply abort: an audit table already exists';
  END IF;

  SELECT count(*), md5(string_agg(
      concat_ws('|', ordinal_position, column_name, udt_name, is_nullable,
                coalesce(column_default, '')),
      E'\n' ORDER BY ordinal_position))
    INTO v_count, v_hash
  FROM information_schema.columns
  WHERE table_schema = 'public' AND table_name = 'cards';
  IF v_count <> 28 OR v_hash <> '03ef6ea64392bacd6db316eefe8c3896' THEN
    RAISE EXCEPTION 'PG878 apply abort: cards schema drift count=% hash=%', v_count, v_hash;
  END IF;

  SELECT count(*), md5(string_agg(
      concat_ws('|', ordinal_position, column_name, udt_name, is_nullable,
                coalesce(column_default, '')),
      E'\n' ORDER BY ordinal_position))
    INTO v_count, v_hash
  FROM information_schema.columns
  WHERE table_schema = 'public' AND table_name = 'card_battle_rules';
  IF v_count <> 18 OR v_hash <> '22b9db71b43ac3cecf079dc716272d24' THEN
    RAISE EXCEPTION 'PG878 apply abort: card_battle_rules schema drift count=% hash=%', v_count, v_hash;
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
    RAISE EXCEPTION 'PG878 apply abort: target card lineage drift count=% hash=%', v_count, v_hash;
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
  FROM public.card_battle_rules
  WHERE normalized_name IN (
      'birgi, god of storytelling', 'underworld breach', 'mana vault'
    )
     OR normalized_name LIKE 'birgi, god of storytelling // %';
  IF v_count <> 11 OR v_hash <> '6edced874860dcadd35256813d3160a1' THEN
    RAISE EXCEPTION 'PG878 apply abort: exact rule prestate drift count=% hash=%', v_count, v_hash;
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pg878_lorehold_runtime_cards_pre_20260716 AS
SELECT *
FROM public.cards
WHERE lower(name) IN (
    'birgi, god of storytelling',
    'birgi, god of storytelling // harnfel, horn of bounty',
    'underworld breach',
    'mana vault'
  )
   OR lower(name) LIKE 'birgi, god of storytelling // %';

CREATE TABLE manaloom_deploy_audit.pg878_lorehold_runtime_rules_pre_20260716 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN (
    'birgi, god of storytelling', 'underworld breach', 'mana vault'
  )
   OR normalized_name LIKE 'birgi, god of storytelling // %';

CREATE TABLE manaloom_deploy_audit.pg878_lorehold_runtime_proposal_20260716 AS
SELECT *
FROM (VALUES
  (
    'birgi, god of storytelling'::text,
    'Birgi, God of Storytelling // Harnfel, Horn of Bounty'::text,
    '5f1ed696a63cd668fd46a2fe9971a54e'::text,
    'battle_rule_v1:e27d00eff7b686d7c8aab1426c621635'::text,
    '{"ability_kind":"triggered_and_activated_modal_dfc","back_face":{"activated_discard_count":1,"activated_discard_exile_top_count":2,"cmc":5,"mana_cost":"{4}{R}","name":"Harnfel, Horn of Bounty","oracle_text":"Discard a card: Exile the top two cards of your library. You may play those cards this turn.","play_exiled_until":"end_of_turn","runtime_status":"runtime_executor_v1","type_line":"Legendary Artifact"},"back_face_harnfel_discard_exile_two_play_this_turn":true,"back_face_runtime_status":"runtime_executor_v1","back_face_status":"runtime_executor_v1","battle_model_scope":"birgi_harnfel_modal_faces_exact_v1","boast_twice_each_turn":true,"boast_twice_status":"annotation_only","cmc":3.0,"effect":"ramp_engine","front_face_mana_cost":"{2}{R}","front_face_name":"Birgi, God of Storytelling","is_creature_permanent":true,"mana_persists_steps":true,"modal_dfc":true,"oracle_runtime_scope":"birgi_front_spell_cast_red_mana_and_harnfel_back_discard_exile_two_play_this_turn_exact_v1","power":3,"produces":"R","spell_cast_add_mana":1,"spell_cast_mana_color":"R","toughness":3,"trigger":"spell_cast"}'::jsonb,
    '{"category":"ramp","effect":"ramp_engine","functions":["spell_cast_mana_engine","modal_back_face_impulse_play"],"subtype":"spell_cast_mana_and_impulse_play_modal_engine"}'::jsonb,
    'curated'::text, 0.98::numeric, 'verified'::text, 'auto'::text, 3::integer,
    'PG878 exact native runtime: Birgi front spell-cast red mana and Harnfel back-face cast/discard/exile-two/play-this-turn are executable. Boast-twice remains explicitly annotation-only. XMage 1.4.60 BirgiGodOfStorytelling.java SHA-256 9cb100723cd36ca66a89724ead11e57c423e987688cde10479ebfda65d430e37.'::text,
    'codex-pg878-lorehold-runtime-completion'::text
  ),
  (
    'underworld breach'::text, 'Underworld Breach'::text,
    'a98ca5777789e48c44daff97999f2beb'::text,
    'battle_rule_v1:a38468ecbf8f6ff1512b3b52674a3d0c'::text,
    '{"battle_model_scope":"underworld_breach_escape_and_end_step_sacrifice_exact_v1","cmc":2.0,"effect":"passive","end_step_sacrifice_status":"runtime_executor_v1","escape_additional_cost_exile_other_graveyard_cards":3,"escape_can_be_repeated":true,"escape_cost_model":"printed_mana_cost_plus_exile_three_other_cards","escape_grant_status":"runtime_executor_v1","escape_requires_nonland":true,"escape_requires_printed_mana_cost":true,"escape_uses_normal_cast_pipeline":true,"grants_escape_to_nonland_cards_in_graveyard":true,"is_enchantment_permanent":true,"oracle_runtime_scope":"nonland_graveyard_escape_printed_mana_cost_exile_three_other_and_beginning_end_step_sacrifice_exact_v1","sacrifice_at_beginning_of_end_step":true}'::jsonb,
    '{"category":"recursion","effect":"passive","functions":["escape_grant","graveyard_cast_permission","end_step_sacrifice"],"runtime_modes":["passive_enchantment","graveyard_cast_permission","beginning_end_step_trigger"]}'::jsonb,
    'curated'::text, 0.98::numeric, 'verified'::text, 'auto'::text, 3::integer,
    'PG878 exact native runtime: nonland graveyard escape uses the printed mana cost plus exile three other graveyard cards through the normal cast pipeline, and the beginning-of-end-step sacrifice is executable. XMage 1.4.60 UnderworldBreach.java SHA-256 99de025b840d7fb4f2875e4ba76a7fbfb6a8c0ab34d19f00251ff6b578fe36c1.'::text,
    'codex-pg878-lorehold-runtime-completion'::text
  ),
  (
    'mana vault'::text, 'Mana Vault'::text,
    '35e3fd94c8453c0e326033af49ae18c8'::text,
    'battle_rule_v1:d43496777c4b1e36b1c9a5111133acf4'::text,
    '{"ability_kind":"static_triggered_and_activated_mana","activation_requires_tap":true,"battle_model_scope":"mana_vault_exact_untap_draw_damage_mana_v1","cmc":1.0,"does_not_untap_in_untap_step":true,"does_not_untap_normally":true,"draw_step_damage_status":"runtime_executor_v1","effect":"ramp_permanent","is_mana_source":true,"mana_ability_requires_tap":true,"mana_ability_status":"runtime_executor_v1","mana_activation_requires_tap":true,"mana_produced":3,"mana_vault_runtime_status":"runtime_executor_v1","oracle_runtime_scope":"no_normal_untap_optional_upkeep_pay_four_draw_step_tapped_damage_one_tap_add_three_colorless_exact_v1","permanent_type":"artifact","produced_mana_symbols":["C","C","C"],"produces":"C","source_mana_cost":"{1}","source_type_line":"Artifact","tapped_draw_step_damage":1,"untap_step_restriction_status":"runtime_executor_v1","upkeep_optional_untap_cost_generic":4,"upkeep_optional_untap_status":"runtime_executor_v1","xmage_ability_classes":["BeginningOfDrawTriggeredAbility","BeginningOfUpkeepTriggeredAbility","SimpleManaAbility","SimpleStaticAbility"],"xmage_condition_classes":["SourceTappedCondition"],"xmage_cost_classes":["GenericManaCost","TapSourceCost"],"xmage_effect_classes":["DamageControllerEffect","DontUntapInControllersUntapStepSourceEffect","UntapSourceEffect"],"xmage_filter_classes":[],"xmage_mana_ability_classes":["SimpleManaAbility"],"xmage_target_classes":[]}'::jsonb,
    '{"category":"ramp","effect":"ramp_permanent","functions":["fast_mana","optional_upkeep_untap","tapped_draw_step_damage"],"subtype":"fast_mana_with_untap_and_damage_runtime"}'::jsonb,
    'curated'::text, 0.98::numeric, 'verified'::text, 'auto'::text, 3::integer,
    'PG878 exact native runtime: Mana Vault does not untap in the normal untap step, may untap for {4} at upkeep, deals one damage at draw step only while tapped, and taps for three colorless mana. XMage 1.4.60 ManaVault.java SHA-256 139e81625a2a030bcf80e613ede72b7bde7693c22c72b9900798aa4ab939e571.'::text,
    'codex-pg878-lorehold-runtime-completion'::text
  )
) AS p(
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
  FROM manaloom_deploy_audit.pg878_lorehold_runtime_proposal_20260716;
  IF v_count <> 3 OR v_hash <> '3ff2fb6259e01b96bbb8a932931f9c8a' THEN
    RAISE EXCEPTION 'PG878 apply abort: proposal drift count=% hash=%', v_count, v_hash;
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
    RAISE EXCEPTION 'PG878 apply abort: rule backup drift count=% hash=%', v_count, v_hash;
  END IF;

  UPDATE public.card_battle_rules r
  SET review_status = 'deprecated',
      execution_status = 'disabled',
      updated_at = now(),
      notes = concat_ws(
        E'\n', nullif(r.notes, ''),
        'PG878: disabled superseded partial/annotation/review row before exact native runtime promotion.'
      )
  WHERE (
      r.normalized_name IN (
        'birgi, god of storytelling', 'underworld breach', 'mana vault'
      )
      OR r.normalized_name LIKE 'birgi, god of storytelling // %'
    )
    AND NOT EXISTS (
      SELECT 1
      FROM manaloom_deploy_audit.pg878_lorehold_runtime_proposal_20260716 p
      WHERE p.normalized_name = r.normalized_name
        AND p.logical_rule_key = r.logical_rule_key
    )
    AND (
      r.review_status NOT IN ('deprecated', 'rejected')
      OR r.execution_status <> 'disabled'
    );
  GET DIAGNOSTICS v_updated = ROW_COUNT;
  IF v_updated <> 5 THEN
    RAISE EXCEPTION 'PG878 apply abort: expected 5 competing rows updated, got %', v_updated;
  END IF;

  INSERT INTO public.card_battle_rules (
    normalized_name, card_id, card_name, effect_json, deck_role_json, source,
    confidence, review_status, rule_version, oracle_hash, notes, reviewed_by,
    reviewed_at, created_at, updated_at, last_seen_at, logical_rule_key,
    execution_status
  )
  SELECT
    p.normalized_name, c.id, c.name, p.effect_json, p.deck_role_json, p.source,
    p.confidence, p.review_status, p.rule_version, p.oracle_hash, p.notes,
    p.reviewed_by, now(), now(), now(), now(), p.logical_rule_key,
    p.execution_status
  FROM manaloom_deploy_audit.pg878_lorehold_runtime_proposal_20260716 p
  JOIN public.cards c
    ON (
      lower(c.name) = p.normalized_name
      OR split_part(lower(c.name), ' // ', 1) = p.normalized_name
    )
   AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash;
  GET DIAGNOSTICS v_inserted = ROW_COUNT;
  IF v_inserted <> 3 THEN
    RAISE EXCEPTION 'PG878 apply abort: expected 3 exact rows inserted, got %', v_inserted;
  END IF;
END $$;

DO $$
DECLARE
  v_total integer;
  v_exact integer;
  v_live integer;
  v_disabled integer;
  v_diff integer;
BEGIN
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
      'PG878 apply abort: post counts drift total=% exact=% live=% disabled=%',
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
    RAISE EXCEPTION 'PG878 apply abort: exact promoted row diff=%', v_diff;
  END IF;

  SELECT count(*) INTO v_diff
  FROM manaloom_deploy_audit.pg878_lorehold_runtime_rules_pre_20260716 b
  JOIN public.card_battle_rules r USING (normalized_name, logical_rule_key)
  WHERE b.review_status IN ('deprecated', 'rejected')
    AND b.execution_status = 'disabled'
    AND to_jsonb(r) IS DISTINCT FROM to_jsonb(b);
  IF v_diff <> 0 THEN
    RAISE EXCEPTION 'PG878 apply abort: historical disabled rows changed diff=%', v_diff;
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
    RAISE EXCEPTION 'PG878 apply abort: superseded row transform diff=%', v_diff;
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
    RAISE EXCEPTION 'PG878 apply abort: target cards changed diff=%', v_diff;
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pg878_lorehold_runtime_rules_post_20260716 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN (
    'birgi, god of storytelling', 'underworld breach', 'mana vault'
  )
   OR normalized_name LIKE 'birgi, god of storytelling // %';

DO $$
DECLARE
  v_count integer;
  v_diff integer;
BEGIN
  SELECT count(*) INTO v_count
  FROM manaloom_deploy_audit.pg878_lorehold_runtime_rules_post_20260716;
  IF v_count <> 14 THEN
    RAISE EXCEPTION 'PG878 apply abort: exact post snapshot count=%', v_count;
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
    RAISE EXCEPTION 'PG878 apply abort: exact post snapshot diff=%', v_diff;
  END IF;
END $$;

COMMIT;

SELECT 'PG878_APPLY_COMMITTED' AS status;
