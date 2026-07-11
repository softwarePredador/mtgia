BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg780_additional_sacrifice_cost_new_serv_20260711_181409 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('abjure', 'deprive', 'final vengeance', 'withering boon', 'worthy cost')
   OR normalized_name LIKE 'abjure // %'
   OR normalized_name LIKE 'deprive // %'
   OR normalized_name LIKE 'final vengeance // %'
   OR normalized_name LIKE 'withering boon // %'
   OR normalized_name LIKE 'worthy cost // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('abjure', 'Abjure', '0a7e7d9e29442406fc766b0ea6caf3ff', 'battle_rule_v1:9250bb2b3a29ae5e346c21a9595e7ae4', '{"additional_cost":"sacrifice_blue_permanent","battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","instant":true,"requires_sacrifice_blue_permanent":true,"sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"blue_permanent","xmage_effect_class":"CounterTargetEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Abjure translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('deprive', 'Deprive', 'bc846609002842e794f46a07dc460f8f', 'battle_rule_v1:12774540b14e5219d965992a5c6f9a80', '{"additional_cost":"return_land_to_hand","battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","instant":true,"requires_return_land_to_hand":true,"sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_additional_cost_class":"ReturnToHandChosenControlledPermanentCost","xmage_additional_cost_target":"land","xmage_effect_class":"CounterTargetEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Deprive translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('final vengeance', 'Final Vengeance', 'def643bf68fd3ac3a44d27b4206153a7', 'battle_rule_v1:3110b22c1c57654732339797967834ed', '{"additional_cost":"sacrifice_creature_or_enchantment","battle_model_scope":"xmage_exile_target_spell_v1","destination":"exile","effect":"remove_creature","instant":false,"requires_sacrifice_creature_or_enchantment":true,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"creature_or_enchantment","xmage_effect_class":"ExileTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FinalVengeance translated into ManaLoom runtime scope xmage_exile_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('withering boon', 'Withering Boon', '8b6c944bacfe7f394cbfdcffd018cb78', 'battle_rule_v1:b199f179852e5db033dc873dc00d0a34', '{"additional_cost":"pay_life","battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","instant":true,"pay_life_amount":3,"requires_pay_life":true,"sorcery":false,"target":"creature_spell","target_constraints":{"card_types":["creature"],"stack_object":"spell","zone":"stack"},"xmage_additional_cost_class":"PayLifeCost","xmage_effect_class":"CounterTargetEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"creature_spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WitheringBoon translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('worthy cost', 'Worthy Cost', '6d458eaafd61ee191e53f01f907a08a4', 'battle_rule_v1:108aae5f798042627c3c7888694b8c41', '{"additional_cost":"sacrifice_creature","battle_model_scope":"xmage_exile_target_spell_v1","destination":"exile","effect":"remove_permanent","instant":false,"requires_sacrifice_creature":true,"sorcery":true,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"creature","xmage_effect_class":"ExileTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"creature_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WorthyCost translated into ManaLoom runtime scope xmage_exile_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('abjure', 'Abjure', '0a7e7d9e29442406fc766b0ea6caf3ff', 'battle_rule_v1:9250bb2b3a29ae5e346c21a9595e7ae4', '{"additional_cost":"sacrifice_blue_permanent","battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","instant":true,"requires_sacrifice_blue_permanent":true,"sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"blue_permanent","xmage_effect_class":"CounterTargetEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Abjure translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('deprive', 'Deprive', 'bc846609002842e794f46a07dc460f8f', 'battle_rule_v1:12774540b14e5219d965992a5c6f9a80', '{"additional_cost":"return_land_to_hand","battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","instant":true,"requires_return_land_to_hand":true,"sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_additional_cost_class":"ReturnToHandChosenControlledPermanentCost","xmage_additional_cost_target":"land","xmage_effect_class":"CounterTargetEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Deprive translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('final vengeance', 'Final Vengeance', 'def643bf68fd3ac3a44d27b4206153a7', 'battle_rule_v1:3110b22c1c57654732339797967834ed', '{"additional_cost":"sacrifice_creature_or_enchantment","battle_model_scope":"xmage_exile_target_spell_v1","destination":"exile","effect":"remove_creature","instant":false,"requires_sacrifice_creature_or_enchantment":true,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"creature_or_enchantment","xmage_effect_class":"ExileTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FinalVengeance translated into ManaLoom runtime scope xmage_exile_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('withering boon', 'Withering Boon', '8b6c944bacfe7f394cbfdcffd018cb78', 'battle_rule_v1:b199f179852e5db033dc873dc00d0a34', '{"additional_cost":"pay_life","battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","instant":true,"pay_life_amount":3,"requires_pay_life":true,"sorcery":false,"target":"creature_spell","target_constraints":{"card_types":["creature"],"stack_object":"spell","zone":"stack"},"xmage_additional_cost_class":"PayLifeCost","xmage_effect_class":"CounterTargetEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"creature_spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WitheringBoon translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('worthy cost', 'Worthy Cost', '6d458eaafd61ee191e53f01f907a08a4', 'battle_rule_v1:108aae5f798042627c3c7888694b8c41', '{"additional_cost":"sacrifice_creature","battle_model_scope":"xmage_exile_target_spell_v1","destination":"exile","effect":"remove_permanent","instant":false,"requires_sacrifice_creature":true,"sorcery":true,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"creature","xmage_effect_class":"ExileTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"creature_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WorthyCost translated into ManaLoom runtime scope xmage_exile_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('abjure', 'Abjure', '0a7e7d9e29442406fc766b0ea6caf3ff', 'battle_rule_v1:9250bb2b3a29ae5e346c21a9595e7ae4', '{"additional_cost":"sacrifice_blue_permanent","battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","instant":true,"requires_sacrifice_blue_permanent":true,"sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"blue_permanent","xmage_effect_class":"CounterTargetEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Abjure translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('deprive', 'Deprive', 'bc846609002842e794f46a07dc460f8f', 'battle_rule_v1:12774540b14e5219d965992a5c6f9a80', '{"additional_cost":"return_land_to_hand","battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","instant":true,"requires_return_land_to_hand":true,"sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_additional_cost_class":"ReturnToHandChosenControlledPermanentCost","xmage_additional_cost_target":"land","xmage_effect_class":"CounterTargetEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Deprive translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('final vengeance', 'Final Vengeance', 'def643bf68fd3ac3a44d27b4206153a7', 'battle_rule_v1:3110b22c1c57654732339797967834ed', '{"additional_cost":"sacrifice_creature_or_enchantment","battle_model_scope":"xmage_exile_target_spell_v1","destination":"exile","effect":"remove_creature","instant":false,"requires_sacrifice_creature_or_enchantment":true,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"creature_or_enchantment","xmage_effect_class":"ExileTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FinalVengeance translated into ManaLoom runtime scope xmage_exile_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('withering boon', 'Withering Boon', '8b6c944bacfe7f394cbfdcffd018cb78', 'battle_rule_v1:b199f179852e5db033dc873dc00d0a34', '{"additional_cost":"pay_life","battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","instant":true,"pay_life_amount":3,"requires_pay_life":true,"sorcery":false,"target":"creature_spell","target_constraints":{"card_types":["creature"],"stack_object":"spell","zone":"stack"},"xmage_additional_cost_class":"PayLifeCost","xmage_effect_class":"CounterTargetEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"creature_spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WitheringBoon translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('worthy cost', 'Worthy Cost', '6d458eaafd61ee191e53f01f907a08a4', 'battle_rule_v1:108aae5f798042627c3c7888694b8c41', '{"additional_cost":"sacrifice_creature","battle_model_scope":"xmage_exile_target_spell_v1","destination":"exile","effect":"remove_permanent","instant":false,"requires_sacrifice_creature":true,"sorcery":true,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"creature","xmage_effect_class":"ExileTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"creature_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WorthyCost translated into ManaLoom runtime scope xmage_exile_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
