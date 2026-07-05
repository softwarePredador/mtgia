BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.xmage_pg522_token_parser_followup_new_se_20260705_182136 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('symbiotic beast', 'symbiotic elf', 'symbiotic wurm', 'the hive')
   OR normalized_name LIKE 'symbiotic beast // %'
   OR normalized_name LIKE 'symbiotic elf // %'
   OR normalized_name LIKE 'symbiotic wurm // %'
   OR normalized_name LIKE 'the hive // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('symbiotic beast', 'Symbiotic Beast', '1e47570a233b7b0fbe43940691324279', 'battle_rule_v1:a95b6d95a126ded98f6213ae483deadd', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_create_tokens_v1","dies_token_colors":["G"],"dies_token_count":4,"dies_token_name":"Insect Token","dies_token_power":1,"dies_token_subtype":"Insect","dies_token_toughness":1,"dies_trigger_effect":"token_maker","effect":"creature","token_description":"1/1 green Insect creature token","trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"InsectToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SymbioticBeast translated into ManaLoom runtime scope xmage_creature_dies_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('symbiotic elf', 'Symbiotic Elf', '3271de0234185d4113bce43e9e7a6953', 'battle_rule_v1:02e0b94c03be332462d3a5e83c8b47b4', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_create_tokens_v1","dies_token_colors":["G"],"dies_token_count":2,"dies_token_name":"Insect Token","dies_token_power":1,"dies_token_subtype":"Insect","dies_token_toughness":1,"dies_trigger_effect":"token_maker","effect":"creature","token_description":"1/1 green Insect creature token","trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"InsectToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SymbioticElf translated into ManaLoom runtime scope xmage_creature_dies_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('symbiotic wurm', 'Symbiotic Wurm', '480e3f57d3e6acaad92b73b54f1ee160', 'battle_rule_v1:147dbbe5c7544a2f09a560ed375a5334', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_create_tokens_v1","dies_token_colors":["G"],"dies_token_count":7,"dies_token_name":"Insect Token","dies_token_power":1,"dies_token_subtype":"Insect","dies_token_toughness":1,"dies_trigger_effect":"token_maker","effect":"creature","token_description":"1/1 green Insect creature token","trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"InsectToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SymbioticWurm translated into ManaLoom runtime scope xmage_creature_dies_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('the hive', 'The Hive', '4bbec4580c29dd078fa15ce8f91ba9e9', 'battle_rule_v1:a35cd7f0279ed12043dd267d16d726f6', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"token_maker","activation_cost_colors":[],"activation_cost_generic":5,"activation_cost_mana":"{5}","activation_requires_sacrifice":false,"activation_requires_tap":true,"artifact_tokens":true,"battle_model_scope":"xmage_permanent_simple_activated_create_token_v1","effect":"token_maker","token_count":1,"token_description":"1/1 colorless Insect artifact creature token with flying named Wasp","token_flying":true,"token_keywords":["flying"],"token_name":"Wasp","token_power":1,"token_subtype":"Insect","token_toughness":1,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"WaspToken"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_create_token_v1","activated_create_token":true,"activated_effect":"token_maker","activation_cost_colors":[],"activation_cost_generic":5,"activation_cost_mana":"{5}","activation_requires_sacrifice":false,"activation_requires_tap":true,"artifact_tokens":true,"battle_model_scope":"xmage_permanent_simple_activated_create_token_v1","effect":"artifact","token_count":1,"token_description":"1/1 colorless Insect artifact creature token with flying named Wasp","token_flying":true,"token_keywords":["flying"],"token_name":"Wasp","token_power":1,"token_subtype":"Insect","token_toughness":1,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"WaspToken"}'::jsonb, '{"category":"unknown","effect":"artifact"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TheHive translated into ManaLoom runtime scope xmage_permanent_simple_activated_create_token_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('symbiotic beast', 'Symbiotic Beast', '1e47570a233b7b0fbe43940691324279', 'battle_rule_v1:a95b6d95a126ded98f6213ae483deadd', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_create_tokens_v1","dies_token_colors":["G"],"dies_token_count":4,"dies_token_name":"Insect Token","dies_token_power":1,"dies_token_subtype":"Insect","dies_token_toughness":1,"dies_trigger_effect":"token_maker","effect":"creature","token_description":"1/1 green Insect creature token","trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"InsectToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SymbioticBeast translated into ManaLoom runtime scope xmage_creature_dies_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('symbiotic elf', 'Symbiotic Elf', '3271de0234185d4113bce43e9e7a6953', 'battle_rule_v1:02e0b94c03be332462d3a5e83c8b47b4', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_create_tokens_v1","dies_token_colors":["G"],"dies_token_count":2,"dies_token_name":"Insect Token","dies_token_power":1,"dies_token_subtype":"Insect","dies_token_toughness":1,"dies_trigger_effect":"token_maker","effect":"creature","token_description":"1/1 green Insect creature token","trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"InsectToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SymbioticElf translated into ManaLoom runtime scope xmage_creature_dies_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('symbiotic wurm', 'Symbiotic Wurm', '480e3f57d3e6acaad92b73b54f1ee160', 'battle_rule_v1:147dbbe5c7544a2f09a560ed375a5334', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_create_tokens_v1","dies_token_colors":["G"],"dies_token_count":7,"dies_token_name":"Insect Token","dies_token_power":1,"dies_token_subtype":"Insect","dies_token_toughness":1,"dies_trigger_effect":"token_maker","effect":"creature","token_description":"1/1 green Insect creature token","trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"InsectToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SymbioticWurm translated into ManaLoom runtime scope xmage_creature_dies_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('the hive', 'The Hive', '4bbec4580c29dd078fa15ce8f91ba9e9', 'battle_rule_v1:a35cd7f0279ed12043dd267d16d726f6', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"token_maker","activation_cost_colors":[],"activation_cost_generic":5,"activation_cost_mana":"{5}","activation_requires_sacrifice":false,"activation_requires_tap":true,"artifact_tokens":true,"battle_model_scope":"xmage_permanent_simple_activated_create_token_v1","effect":"token_maker","token_count":1,"token_description":"1/1 colorless Insect artifact creature token with flying named Wasp","token_flying":true,"token_keywords":["flying"],"token_name":"Wasp","token_power":1,"token_subtype":"Insect","token_toughness":1,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"WaspToken"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_create_token_v1","activated_create_token":true,"activated_effect":"token_maker","activation_cost_colors":[],"activation_cost_generic":5,"activation_cost_mana":"{5}","activation_requires_sacrifice":false,"activation_requires_tap":true,"artifact_tokens":true,"battle_model_scope":"xmage_permanent_simple_activated_create_token_v1","effect":"artifact","token_count":1,"token_description":"1/1 colorless Insect artifact creature token with flying named Wasp","token_flying":true,"token_keywords":["flying"],"token_name":"Wasp","token_power":1,"token_subtype":"Insect","token_toughness":1,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"WaspToken"}'::jsonb, '{"category":"unknown","effect":"artifact"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TheHive translated into ManaLoom runtime scope xmage_permanent_simple_activated_create_token_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('symbiotic beast', 'Symbiotic Beast', '1e47570a233b7b0fbe43940691324279', 'battle_rule_v1:a95b6d95a126ded98f6213ae483deadd', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_create_tokens_v1","dies_token_colors":["G"],"dies_token_count":4,"dies_token_name":"Insect Token","dies_token_power":1,"dies_token_subtype":"Insect","dies_token_toughness":1,"dies_trigger_effect":"token_maker","effect":"creature","token_description":"1/1 green Insect creature token","trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"InsectToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SymbioticBeast translated into ManaLoom runtime scope xmage_creature_dies_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('symbiotic elf', 'Symbiotic Elf', '3271de0234185d4113bce43e9e7a6953', 'battle_rule_v1:02e0b94c03be332462d3a5e83c8b47b4', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_create_tokens_v1","dies_token_colors":["G"],"dies_token_count":2,"dies_token_name":"Insect Token","dies_token_power":1,"dies_token_subtype":"Insect","dies_token_toughness":1,"dies_trigger_effect":"token_maker","effect":"creature","token_description":"1/1 green Insect creature token","trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"InsectToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SymbioticElf translated into ManaLoom runtime scope xmage_creature_dies_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('symbiotic wurm', 'Symbiotic Wurm', '480e3f57d3e6acaad92b73b54f1ee160', 'battle_rule_v1:147dbbe5c7544a2f09a560ed375a5334', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_create_tokens_v1","dies_token_colors":["G"],"dies_token_count":7,"dies_token_name":"Insect Token","dies_token_power":1,"dies_token_subtype":"Insect","dies_token_toughness":1,"dies_trigger_effect":"token_maker","effect":"creature","token_description":"1/1 green Insect creature token","trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"InsectToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SymbioticWurm translated into ManaLoom runtime scope xmage_creature_dies_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('the hive', 'The Hive', '4bbec4580c29dd078fa15ce8f91ba9e9', 'battle_rule_v1:a35cd7f0279ed12043dd267d16d726f6', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"token_maker","activation_cost_colors":[],"activation_cost_generic":5,"activation_cost_mana":"{5}","activation_requires_sacrifice":false,"activation_requires_tap":true,"artifact_tokens":true,"battle_model_scope":"xmage_permanent_simple_activated_create_token_v1","effect":"token_maker","token_count":1,"token_description":"1/1 colorless Insect artifact creature token with flying named Wasp","token_flying":true,"token_keywords":["flying"],"token_name":"Wasp","token_power":1,"token_subtype":"Insect","token_toughness":1,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"WaspToken"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_create_token_v1","activated_create_token":true,"activated_effect":"token_maker","activation_cost_colors":[],"activation_cost_generic":5,"activation_cost_mana":"{5}","activation_requires_sacrifice":false,"activation_requires_tap":true,"artifact_tokens":true,"battle_model_scope":"xmage_permanent_simple_activated_create_token_v1","effect":"artifact","token_count":1,"token_description":"1/1 colorless Insect artifact creature token with flying named Wasp","token_flying":true,"token_keywords":["flying"],"token_name":"Wasp","token_power":1,"token_subtype":"Insect","token_toughness":1,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"WaspToken"}'::jsonb, '{"category":"unknown","effect":"artifact"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TheHive translated into ManaLoom runtime scope xmage_permanent_simple_activated_create_token_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
