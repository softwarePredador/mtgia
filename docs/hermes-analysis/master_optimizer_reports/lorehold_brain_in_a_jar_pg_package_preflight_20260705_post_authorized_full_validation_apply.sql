BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.lorehold_brain_in_a_jar_pg_package_20260705_post_authorized_full_validation_backup AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name = 'brain in a jar'
   OR normalized_name LIKE 'brain in a jar // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('brain in a jar', 'Brain in a Jar', '41468898bf6400763de517269fdeb456', 'battle_rule_v1:aedfa4929249f55c1d607effe109f3f3', '{"ability_kind":"activated","activated_add_counters":true,"activated_add_counters_count":1,"activated_add_counters_counter_type":"charge","activated_add_counters_target":"self","activation_cost_generic":1,"activation_cost_mana":"{1}","activation_requires_tap":true,"additional_costs_policy":"runtime_followup_required_for_nontrivial_additional_costs","alternative_costs_payable":false,"battle_model_scope":"xmage_brain_in_a_jar_charge_counter_free_cast_scry_v1","brain_in_a_jar_free_cast":true,"cast_without_paying_mana_cost":true,"effect":"topdeck_manipulation","free_cast_card_types":["instant","sorcery"],"free_cast_exactly_one_card":true,"free_cast_from_zone":"hand","free_cast_mana_value_match":"source_charge_counters_after_add","free_cast_max_cards":1,"free_cast_optional":true,"free_cast_timing":"during_brain_in_a_jar_ability_resolution","replay_required_fields":["activation_kind","charge_counters_before","charge_counters_after","eligible_spell_names","selected_spell","selected_spell_mana_value","cast_without_paying_mana_cost","removed_charge_counters","scry_count","scry_looked_at","scry_kept_on_top","scry_bottomed","scry_top_after"],"secondary_activation_cost_generic":3,"secondary_activation_cost_mana":"{3}","secondary_activation_remove_counter_type":"charge","secondary_activation_remove_x_counters":true,"secondary_activation_requires_tap":true,"secondary_activation_scry_count_source":"removed_charge_counters","source_card":"Brain in a Jar","x_value_default_when_cast_without_paying_mana_cost":0,"xmage_cost_classes":["GenericManaCost","TapSourceCost","RemoveVariableCountersSourceCost"],"xmage_effect_classes":["AddCountersSourceEffect","BrainInAJarCastEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"topdeck_manipulation","lane":"topdeck_miracle_engine","package":"topdeck_miracle_access"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'Brain in a Jar exact runtime package: local XMage class plus ManaLoom adapter for add charge counter, exact mana-value free-cast from hand, and remove X charge counters to scry X. Package is prepared only; apply requires explicit PostgreSQL approval.', 'preserve_existing_rows')
),
  counts AS (
    SELECT
      p.card_name,
      p.normalized_name,
      p.oracle_hash,
      count(c.id) AS target_card_rows,
      min(c.id::text)::uuid AS canonical_card_id
    FROM proposed p
    LEFT JOIN public.cards c
      ON (
           lower(c.name) = p.normalized_name
           OR split_part(lower(c.name), ' // ', 1) = p.normalized_name
         )
     AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
    GROUP BY p.card_name, p.normalized_name, p.oracle_hash
  )
  SELECT jsonb_agg(counts ORDER BY card_name)
    INTO v_missing
  FROM counts
  WHERE target_card_rows < 1;

  IF v_missing IS NOT NULL THEN
    RAISE EXCEPTION 'Brain in a Jar package abort: expected at least one Oracle-hash-matched public.cards row: %', v_missing;
  END IF;
END $$;

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('brain in a jar', 'Brain in a Jar', '41468898bf6400763de517269fdeb456', 'battle_rule_v1:aedfa4929249f55c1d607effe109f3f3', '{"ability_kind":"activated","activated_add_counters":true,"activated_add_counters_count":1,"activated_add_counters_counter_type":"charge","activated_add_counters_target":"self","activation_cost_generic":1,"activation_cost_mana":"{1}","activation_requires_tap":true,"additional_costs_policy":"runtime_followup_required_for_nontrivial_additional_costs","alternative_costs_payable":false,"battle_model_scope":"xmage_brain_in_a_jar_charge_counter_free_cast_scry_v1","brain_in_a_jar_free_cast":true,"cast_without_paying_mana_cost":true,"effect":"topdeck_manipulation","free_cast_card_types":["instant","sorcery"],"free_cast_exactly_one_card":true,"free_cast_from_zone":"hand","free_cast_mana_value_match":"source_charge_counters_after_add","free_cast_max_cards":1,"free_cast_optional":true,"free_cast_timing":"during_brain_in_a_jar_ability_resolution","replay_required_fields":["activation_kind","charge_counters_before","charge_counters_after","eligible_spell_names","selected_spell","selected_spell_mana_value","cast_without_paying_mana_cost","removed_charge_counters","scry_count","scry_looked_at","scry_kept_on_top","scry_bottomed","scry_top_after"],"secondary_activation_cost_generic":3,"secondary_activation_cost_mana":"{3}","secondary_activation_remove_counter_type":"charge","secondary_activation_remove_x_counters":true,"secondary_activation_requires_tap":true,"secondary_activation_scry_count_source":"removed_charge_counters","source_card":"Brain in a Jar","x_value_default_when_cast_without_paying_mana_cost":0,"xmage_cost_classes":["GenericManaCost","TapSourceCost","RemoveVariableCountersSourceCost"],"xmage_effect_classes":["AddCountersSourceEffect","BrainInAJarCastEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"topdeck_manipulation","lane":"topdeck_miracle_engine","package":"topdeck_miracle_access"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'Brain in a Jar exact runtime package: local XMage class plus ManaLoom adapter for add charge counter, exact mana-value free-cast from hand, and remove X charge counters to scry X. Package is prepared only; apply requires explicit PostgreSQL approval.', 'preserve_existing_rows')
),
matched_cards AS (
  SELECT
    p.normalized_name,
    p.card_name,
    p.oracle_hash,
    c.id AS card_id,
    c.name AS db_card_name
  FROM proposed p
  JOIN public.cards c
    ON (
         lower(c.name) = p.normalized_name
         OR split_part(lower(c.name), ' // ', 1) = p.normalized_name
       )
   AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
),
canonical_target_cards AS (
  SELECT
    p.*,
    min(m.card_id::text)::uuid AS card_id,
    min(m.db_card_name) AS db_card_name
  FROM proposed p
  JOIN matched_cards m
    USING (normalized_name, card_name, oracle_hash)
  GROUP BY
    p.normalized_name,
    p.card_name,
    p.oracle_hash,
    p.logical_rule_key,
    p.effect_json,
    p.deck_role_json,
    p.source,
    p.confidence,
    p.review_status,
    p.execution_status,
    p.notes,
    p.shadow_handling
),
upserted AS (
  INSERT INTO public.card_battle_rules (
    normalized_name,
    card_id,
    card_name,
    effect_json,
    deck_role_json,
    source,
    confidence,
    review_status,
    rule_version,
    oracle_hash,
    notes,
    reviewed_by,
    reviewed_at,
    created_at,
    updated_at,
    last_seen_at,
    logical_rule_key,
    execution_status
  )
  SELECT
    normalized_name,
    card_id,
    db_card_name,
    effect_json,
    deck_role_json,
    source,
    confidence,
    review_status,
    2,
    oracle_hash,
    notes,
    'codex-brain-in-a-jar',
    now(),
    now(),
    now(),
    now(),
    logical_rule_key,
    execution_status
  FROM canonical_target_cards
  ON CONFLICT (normalized_name, logical_rule_key) DO UPDATE
  SET
    card_id = EXCLUDED.card_id,
    card_name = EXCLUDED.card_name,
    effect_json = EXCLUDED.effect_json,
    deck_role_json = EXCLUDED.deck_role_json,
    source = EXCLUDED.source,
    confidence = EXCLUDED.confidence,
    review_status = EXCLUDED.review_status,
    rule_version = EXCLUDED.rule_version,
    oracle_hash = EXCLUDED.oracle_hash,
    notes = EXCLUDED.notes,
    reviewed_by = EXCLUDED.reviewed_by,
    reviewed_at = EXCLUDED.reviewed_at,
    updated_at = EXCLUDED.updated_at,
    last_seen_at = EXCLUDED.last_seen_at,
    execution_status = EXCLUDED.execution_status
  RETURNING *
)
SELECT count(*) AS upserted_rows FROM upserted;

COMMIT;
