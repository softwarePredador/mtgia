BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg705_destroy_or_pay_life_additional_cos_20260710_145650 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('bitter triumph', 'bone shards', 'final payment', 'fumarole')
   OR normalized_name LIKE 'bitter triumph // %'
   OR normalized_name LIKE 'bone shards // %'
   OR normalized_name LIKE 'final payment // %'
   OR normalized_name LIKE 'fumarole // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('bitter triumph', 'Bitter Triumph', '5dde73aa35c4313affb424c96291d82e', 'battle_rule_v1:c7de8f5e0f2505279a40bbaf2e61833d', '{"additional_cost":"choose_discard_card_or_pay_life","additional_cost_options":[{"cost":"discard_card","requires_discard_card":true},{"cost":"pay_life","pay_life_amount":3,"requires_pay_life":true}],"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_permanent","instant":true,"requires_one_additional_cost_option":true,"sorcery":false,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_additional_cost_class":"OrCost","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"creature_or_planeswalker","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BitterTriumph translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('bone shards', 'Bone Shards', 'b363168a99a08d80861b1ef4c06f5cd2', 'battle_rule_v1:891f9f844a0a1eeecf75ab101d862213', '{"additional_cost":"choose_sacrifice_creature_or_discard_card","additional_cost_options":[{"cost":"sacrifice_creature","requires_sacrifice_creature":true,"xmage_additional_cost_target":"creature"},{"cost":"discard_card","requires_discard_card":true}],"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_permanent","instant":false,"requires_one_additional_cost_option":true,"sorcery":true,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_additional_cost_class":"OrCost","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"creature_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BoneShards translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('final payment', 'Final Payment', 'bc569926e43ff7832d9949b8da1245f7', 'battle_rule_v1:88aedd014ee74ec75c59d7b3e816336f', '{"additional_cost":"choose_pay_life_or_sacrifice_creature_or_enchantment","additional_cost_options":[{"cost":"pay_life","pay_life_amount":5,"requires_pay_life":true},{"cost":"sacrifice_creature_or_enchantment","requires_sacrifice_creature_or_enchantment":true,"xmage_additional_cost_target":"creature_or_enchantment"}],"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"requires_one_additional_cost_option":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_additional_cost_class":"OrCost","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FinalPayment translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fumarole', 'Fumarole', '3503e0474089775318620b7b48f5e89f', 'battle_rule_v1:f19f673e79ed6be70af42520fd54cf05', '{"additional_cost":"pay_life","battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":false,"pay_life_amount":3,"requires_pay_life":true,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_additional_cost_class":"PayLifeCost","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Fumarole translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('bitter triumph', 'Bitter Triumph', '5dde73aa35c4313affb424c96291d82e', 'battle_rule_v1:c7de8f5e0f2505279a40bbaf2e61833d', '{"additional_cost":"choose_discard_card_or_pay_life","additional_cost_options":[{"cost":"discard_card","requires_discard_card":true},{"cost":"pay_life","pay_life_amount":3,"requires_pay_life":true}],"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_permanent","instant":true,"requires_one_additional_cost_option":true,"sorcery":false,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_additional_cost_class":"OrCost","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"creature_or_planeswalker","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BitterTriumph translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('bone shards', 'Bone Shards', 'b363168a99a08d80861b1ef4c06f5cd2', 'battle_rule_v1:891f9f844a0a1eeecf75ab101d862213', '{"additional_cost":"choose_sacrifice_creature_or_discard_card","additional_cost_options":[{"cost":"sacrifice_creature","requires_sacrifice_creature":true,"xmage_additional_cost_target":"creature"},{"cost":"discard_card","requires_discard_card":true}],"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_permanent","instant":false,"requires_one_additional_cost_option":true,"sorcery":true,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_additional_cost_class":"OrCost","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"creature_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BoneShards translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('final payment', 'Final Payment', 'bc569926e43ff7832d9949b8da1245f7', 'battle_rule_v1:88aedd014ee74ec75c59d7b3e816336f', '{"additional_cost":"choose_pay_life_or_sacrifice_creature_or_enchantment","additional_cost_options":[{"cost":"pay_life","pay_life_amount":5,"requires_pay_life":true},{"cost":"sacrifice_creature_or_enchantment","requires_sacrifice_creature_or_enchantment":true,"xmage_additional_cost_target":"creature_or_enchantment"}],"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"requires_one_additional_cost_option":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_additional_cost_class":"OrCost","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FinalPayment translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fumarole', 'Fumarole', '3503e0474089775318620b7b48f5e89f', 'battle_rule_v1:f19f673e79ed6be70af42520fd54cf05', '{"additional_cost":"pay_life","battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":false,"pay_life_amount":3,"requires_pay_life":true,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_additional_cost_class":"PayLifeCost","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Fumarole translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('bitter triumph', 'Bitter Triumph', '5dde73aa35c4313affb424c96291d82e', 'battle_rule_v1:c7de8f5e0f2505279a40bbaf2e61833d', '{"additional_cost":"choose_discard_card_or_pay_life","additional_cost_options":[{"cost":"discard_card","requires_discard_card":true},{"cost":"pay_life","pay_life_amount":3,"requires_pay_life":true}],"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_permanent","instant":true,"requires_one_additional_cost_option":true,"sorcery":false,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_additional_cost_class":"OrCost","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"creature_or_planeswalker","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BitterTriumph translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('bone shards', 'Bone Shards', 'b363168a99a08d80861b1ef4c06f5cd2', 'battle_rule_v1:891f9f844a0a1eeecf75ab101d862213', '{"additional_cost":"choose_sacrifice_creature_or_discard_card","additional_cost_options":[{"cost":"sacrifice_creature","requires_sacrifice_creature":true,"xmage_additional_cost_target":"creature"},{"cost":"discard_card","requires_discard_card":true}],"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_permanent","instant":false,"requires_one_additional_cost_option":true,"sorcery":true,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_additional_cost_class":"OrCost","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"creature_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BoneShards translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('final payment', 'Final Payment', 'bc569926e43ff7832d9949b8da1245f7', 'battle_rule_v1:88aedd014ee74ec75c59d7b3e816336f', '{"additional_cost":"choose_pay_life_or_sacrifice_creature_or_enchantment","additional_cost_options":[{"cost":"pay_life","pay_life_amount":5,"requires_pay_life":true},{"cost":"sacrifice_creature_or_enchantment","requires_sacrifice_creature_or_enchantment":true,"xmage_additional_cost_target":"creature_or_enchantment"}],"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"requires_one_additional_cost_option":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_additional_cost_class":"OrCost","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FinalPayment translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fumarole', 'Fumarole', '3503e0474089775318620b7b48f5e89f', 'battle_rule_v1:f19f673e79ed6be70af42520fd54cf05', '{"additional_cost":"pay_life","battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":false,"pay_life_amount":3,"requires_pay_life":true,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_additional_cost_class":"PayLifeCost","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Fumarole translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
