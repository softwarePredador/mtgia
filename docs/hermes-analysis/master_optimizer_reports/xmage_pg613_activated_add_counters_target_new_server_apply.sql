BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg613_activated_add_counters_target_new_20260707_120118 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('dragon blood', 'fevered convulsions', 'gnarled effigy')
   OR normalized_name LIKE 'dragon blood // %'
   OR normalized_name LIKE 'fevered convulsions // %'
   OR normalized_name LIKE 'gnarled effigy // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('dragon blood', 'Dragon Blood', '5a9ddd93f19673d19055cef4d28fabef', 'battle_rule_v1:7d7e66ad44970bb4b01eaf1c24ee22ea', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_add_counters":true,"activated_add_counters_count":1,"activated_add_counters_counter_type":"+1/+1","activated_add_counters_target":"creature","activated_effect":"add_counters","activation_cost_colors":[],"activation_cost_generic":3,"activation_cost_mana":"{3}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"+1/+1","effect":"add_counters","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"AddCountersTargetEffect"}],"ability_kind":"static_and_activated","activated_add_counters":true,"activated_add_counters_count":1,"activated_add_counters_counter_type":"+1/+1","activated_add_counters_target":"creature","activated_battle_model_scope":"xmage_permanent_simple_activated_add_counters_target_creature_v1","activated_effect":"add_counters","activation_cost_colors":[],"activation_cost_generic":3,"activation_cost_mana":"{3}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"+1/+1","effect":"artifact","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"artifact","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DragonBlood translated into ManaLoom runtime scope xmage_permanent_simple_activated_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fevered convulsions', 'Fevered Convulsions', '7c2478a8c06702e016f780e590c8e77f', 'battle_rule_v1:098a4dbc87403ab533c6a2a34790dd1c', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_add_counters":true,"activated_add_counters_count":1,"activated_add_counters_counter_type":"-1/-1","activated_add_counters_target":"creature","activated_effect":"add_counters","activation_cost_colors":["B","B"],"activation_cost_generic":2,"activation_cost_mana":"{2}{B}{B}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"-1/-1","effect":"add_counters","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"AddCountersTargetEffect"}],"ability_kind":"static_and_activated","activated_add_counters":true,"activated_add_counters_count":1,"activated_add_counters_counter_type":"-1/-1","activated_add_counters_target":"creature","activated_battle_model_scope":"xmage_permanent_simple_activated_add_counters_target_creature_v1","activated_effect":"add_counters","activation_cost_colors":["B","B"],"activation_cost_generic":2,"activation_cost_mana":"{2}{B}{B}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"-1/-1","effect":"enchantment","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"enchantment","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FeveredConvulsions translated into ManaLoom runtime scope xmage_permanent_simple_activated_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('gnarled effigy', 'Gnarled Effigy', 'a8fbb1ed07606e88c3e38453bd1854ae', 'battle_rule_v1:b2810c952a67dfca35dcc5c41e2ed248', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_add_counters":true,"activated_add_counters_count":1,"activated_add_counters_counter_type":"-1/-1","activated_add_counters_target":"creature","activated_effect":"add_counters","activation_cost_colors":[],"activation_cost_generic":4,"activation_cost_mana":"{4}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"-1/-1","effect":"add_counters","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"AddCountersTargetEffect"}],"ability_kind":"static_and_activated","activated_add_counters":true,"activated_add_counters_count":1,"activated_add_counters_counter_type":"-1/-1","activated_add_counters_target":"creature","activated_battle_model_scope":"xmage_permanent_simple_activated_add_counters_target_creature_v1","activated_effect":"add_counters","activation_cost_colors":[],"activation_cost_generic":4,"activation_cost_mana":"{4}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"-1/-1","effect":"artifact","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"artifact","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GnarledEffigy translated into ManaLoom runtime scope xmage_permanent_simple_activated_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    RAISE EXCEPTION 'XMage batch package abort: expected at least one Oracle-hash-matched card row for every proposed card: %', v_missing;
  END IF;
END $$;

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('dragon blood', 'Dragon Blood', '5a9ddd93f19673d19055cef4d28fabef', 'battle_rule_v1:7d7e66ad44970bb4b01eaf1c24ee22ea', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_add_counters":true,"activated_add_counters_count":1,"activated_add_counters_counter_type":"+1/+1","activated_add_counters_target":"creature","activated_effect":"add_counters","activation_cost_colors":[],"activation_cost_generic":3,"activation_cost_mana":"{3}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"+1/+1","effect":"add_counters","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"AddCountersTargetEffect"}],"ability_kind":"static_and_activated","activated_add_counters":true,"activated_add_counters_count":1,"activated_add_counters_counter_type":"+1/+1","activated_add_counters_target":"creature","activated_battle_model_scope":"xmage_permanent_simple_activated_add_counters_target_creature_v1","activated_effect":"add_counters","activation_cost_colors":[],"activation_cost_generic":3,"activation_cost_mana":"{3}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"+1/+1","effect":"artifact","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"artifact","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DragonBlood translated into ManaLoom runtime scope xmage_permanent_simple_activated_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fevered convulsions', 'Fevered Convulsions', '7c2478a8c06702e016f780e590c8e77f', 'battle_rule_v1:098a4dbc87403ab533c6a2a34790dd1c', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_add_counters":true,"activated_add_counters_count":1,"activated_add_counters_counter_type":"-1/-1","activated_add_counters_target":"creature","activated_effect":"add_counters","activation_cost_colors":["B","B"],"activation_cost_generic":2,"activation_cost_mana":"{2}{B}{B}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"-1/-1","effect":"add_counters","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"AddCountersTargetEffect"}],"ability_kind":"static_and_activated","activated_add_counters":true,"activated_add_counters_count":1,"activated_add_counters_counter_type":"-1/-1","activated_add_counters_target":"creature","activated_battle_model_scope":"xmage_permanent_simple_activated_add_counters_target_creature_v1","activated_effect":"add_counters","activation_cost_colors":["B","B"],"activation_cost_generic":2,"activation_cost_mana":"{2}{B}{B}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"-1/-1","effect":"enchantment","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"enchantment","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FeveredConvulsions translated into ManaLoom runtime scope xmage_permanent_simple_activated_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('gnarled effigy', 'Gnarled Effigy', 'a8fbb1ed07606e88c3e38453bd1854ae', 'battle_rule_v1:b2810c952a67dfca35dcc5c41e2ed248', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_add_counters":true,"activated_add_counters_count":1,"activated_add_counters_counter_type":"-1/-1","activated_add_counters_target":"creature","activated_effect":"add_counters","activation_cost_colors":[],"activation_cost_generic":4,"activation_cost_mana":"{4}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"-1/-1","effect":"add_counters","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"AddCountersTargetEffect"}],"ability_kind":"static_and_activated","activated_add_counters":true,"activated_add_counters_count":1,"activated_add_counters_counter_type":"-1/-1","activated_add_counters_target":"creature","activated_battle_model_scope":"xmage_permanent_simple_activated_add_counters_target_creature_v1","activated_effect":"add_counters","activation_cost_colors":[],"activation_cost_generic":4,"activation_cost_mana":"{4}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"-1/-1","effect":"artifact","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"artifact","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GnarledEffigy translated into ManaLoom runtime scope xmage_permanent_simple_activated_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
),
deprecated AS (
  UPDATE public.card_battle_rules r
  SET
    review_status = 'deprecated',
    execution_status = 'disabled',
    updated_at = now(),
    notes = concat_ws(E'\n', nullif(r.notes, ''), 'XMage batch package: deprecated stale shadow before curated batch rule upsert.')
  FROM proposed p
  WHERE (
        r.normalized_name = p.normalized_name
        OR r.normalized_name LIKE p.normalized_name || ' // %'
      )
    AND p.shadow_handling <> 'preserve_existing_rows'
    AND r.logical_rule_key <> p.logical_rule_key
  RETURNING r.*
)
SELECT count(*) AS deprecated_shadow_rows FROM deprecated;

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('dragon blood', 'Dragon Blood', '5a9ddd93f19673d19055cef4d28fabef', 'battle_rule_v1:7d7e66ad44970bb4b01eaf1c24ee22ea', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_add_counters":true,"activated_add_counters_count":1,"activated_add_counters_counter_type":"+1/+1","activated_add_counters_target":"creature","activated_effect":"add_counters","activation_cost_colors":[],"activation_cost_generic":3,"activation_cost_mana":"{3}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"+1/+1","effect":"add_counters","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"AddCountersTargetEffect"}],"ability_kind":"static_and_activated","activated_add_counters":true,"activated_add_counters_count":1,"activated_add_counters_counter_type":"+1/+1","activated_add_counters_target":"creature","activated_battle_model_scope":"xmage_permanent_simple_activated_add_counters_target_creature_v1","activated_effect":"add_counters","activation_cost_colors":[],"activation_cost_generic":3,"activation_cost_mana":"{3}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"+1/+1","effect":"artifact","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"artifact","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DragonBlood translated into ManaLoom runtime scope xmage_permanent_simple_activated_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fevered convulsions', 'Fevered Convulsions', '7c2478a8c06702e016f780e590c8e77f', 'battle_rule_v1:098a4dbc87403ab533c6a2a34790dd1c', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_add_counters":true,"activated_add_counters_count":1,"activated_add_counters_counter_type":"-1/-1","activated_add_counters_target":"creature","activated_effect":"add_counters","activation_cost_colors":["B","B"],"activation_cost_generic":2,"activation_cost_mana":"{2}{B}{B}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"-1/-1","effect":"add_counters","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"AddCountersTargetEffect"}],"ability_kind":"static_and_activated","activated_add_counters":true,"activated_add_counters_count":1,"activated_add_counters_counter_type":"-1/-1","activated_add_counters_target":"creature","activated_battle_model_scope":"xmage_permanent_simple_activated_add_counters_target_creature_v1","activated_effect":"add_counters","activation_cost_colors":["B","B"],"activation_cost_generic":2,"activation_cost_mana":"{2}{B}{B}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"-1/-1","effect":"enchantment","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"enchantment","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FeveredConvulsions translated into ManaLoom runtime scope xmage_permanent_simple_activated_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('gnarled effigy', 'Gnarled Effigy', 'a8fbb1ed07606e88c3e38453bd1854ae', 'battle_rule_v1:b2810c952a67dfca35dcc5c41e2ed248', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_add_counters":true,"activated_add_counters_count":1,"activated_add_counters_counter_type":"-1/-1","activated_add_counters_target":"creature","activated_effect":"add_counters","activation_cost_colors":[],"activation_cost_generic":4,"activation_cost_mana":"{4}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"-1/-1","effect":"add_counters","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"AddCountersTargetEffect"}],"ability_kind":"static_and_activated","activated_add_counters":true,"activated_add_counters_count":1,"activated_add_counters_counter_type":"-1/-1","activated_add_counters_target":"creature","activated_battle_model_scope":"xmage_permanent_simple_activated_add_counters_target_creature_v1","activated_effect":"add_counters","activation_cost_colors":[],"activation_cost_generic":4,"activation_cost_mana":"{4}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"-1/-1","effect":"artifact","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"artifact","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GnarledEffigy translated into ManaLoom runtime scope xmage_permanent_simple_activated_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    'codex-xmage-batch',
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
