BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg783_orcost_pay_generic_spell_cost_new_20260711_191856 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('annihilating glare', 'deadly precision', 'lash of the balrog', 'lightning axe', 'pumpkin bombardment')
   OR normalized_name LIKE 'annihilating glare // %'
   OR normalized_name LIKE 'deadly precision // %'
   OR normalized_name LIKE 'lash of the balrog // %'
   OR normalized_name LIKE 'lightning axe // %'
   OR normalized_name LIKE 'pumpkin bombardment // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('annihilating glare', 'Annihilating Glare', '052006cb3d6f1f1e367184e4aaef7fc2', 'battle_rule_v1:0c659eb3371016f8ae5aa11bdab3fb36', '{"additional_cost":"choose_pay_generic_or_sacrifice_artifact_or_creature","additional_cost_options":[{"cost":"pay_generic","pay_generic_amount":4,"requires_pay_generic":true},{"cost":"sacrifice_artifact_or_creature","requires_sacrifice_artifact_or_creature":true,"xmage_additional_cost_target":"artifact_or_creature"}],"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_permanent","instant":false,"requires_one_additional_cost_option":true,"sorcery":true,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_additional_cost_class":"OrCost","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"creature_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AnnihilatingGlare translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('deadly precision', 'Deadly Precision', 'cc5f6c4cd7a27bdff8d87afac5e2584a', 'battle_rule_v1:7c424b775d1c33dfb798c380c1fa358a', '{"additional_cost":"choose_pay_generic_or_sacrifice_artifact_or_creature","additional_cost_options":[{"cost":"pay_generic","pay_generic_amount":4,"requires_pay_generic":true},{"cost":"sacrifice_artifact_or_creature","requires_sacrifice_artifact_or_creature":true,"xmage_additional_cost_target":"artifact_or_creature"}],"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":false,"requires_one_additional_cost_option":true,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_additional_cost_class":"OrCost","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DeadlyPrecision translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lash of the balrog', 'Lash of the Balrog', '3c626b87ad61938c72288ccc50ae07b6', 'battle_rule_v1:7a15a26745011ba967578b75c118531f', '{"additional_cost":"choose_sacrifice_creature_or_pay_generic","additional_cost_options":[{"cost":"sacrifice_creature","requires_sacrifice_creature":true,"xmage_additional_cost_target":"creature"},{"cost":"pay_generic","pay_generic_amount":4,"requires_pay_generic":true}],"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":false,"requires_one_additional_cost_option":true,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_additional_cost_class":"OrCost","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LashOfTheBalrog translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lightning axe', 'Lightning Axe', '2d756dc855b92af19e72842859dbfb5d', 'battle_rule_v1:7da25f92bcb8da5c8045c963e630cd28', '{"additional_cost":"choose_discard_card_or_pay_generic","additional_cost_options":[{"cost":"discard_card","requires_discard_card":true},{"cost":"pay_generic","pay_generic_amount":5,"requires_pay_generic":true}],"amount":5,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","damage":5,"effect":"direct_damage","instant":true,"requires_one_additional_cost_option":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_additional_cost_class":"OrCost","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LightningAxe translated into ManaLoom runtime scope xmage_fixed_damage_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pumpkin bombardment', 'Pumpkin Bombardment', 'e1144cbe56a6a9dd971af2e1795e123b', 'battle_rule_v1:81e4e488312dbfd27bed89b9f17cdec8', '{"additional_cost":"choose_discard_card_or_pay_generic","additional_cost_options":[{"cost":"discard_card","requires_discard_card":true},{"cost":"pay_generic","pay_generic_amount":2,"requires_pay_generic":true}],"amount":3,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","damage":3,"effect":"direct_damage","instant":false,"requires_one_additional_cost_option":true,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_additional_cost_class":"OrCost","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PumpkinBombardment translated into ManaLoom runtime scope xmage_fixed_damage_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('annihilating glare', 'Annihilating Glare', '052006cb3d6f1f1e367184e4aaef7fc2', 'battle_rule_v1:0c659eb3371016f8ae5aa11bdab3fb36', '{"additional_cost":"choose_pay_generic_or_sacrifice_artifact_or_creature","additional_cost_options":[{"cost":"pay_generic","pay_generic_amount":4,"requires_pay_generic":true},{"cost":"sacrifice_artifact_or_creature","requires_sacrifice_artifact_or_creature":true,"xmage_additional_cost_target":"artifact_or_creature"}],"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_permanent","instant":false,"requires_one_additional_cost_option":true,"sorcery":true,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_additional_cost_class":"OrCost","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"creature_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AnnihilatingGlare translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('deadly precision', 'Deadly Precision', 'cc5f6c4cd7a27bdff8d87afac5e2584a', 'battle_rule_v1:7c424b775d1c33dfb798c380c1fa358a', '{"additional_cost":"choose_pay_generic_or_sacrifice_artifact_or_creature","additional_cost_options":[{"cost":"pay_generic","pay_generic_amount":4,"requires_pay_generic":true},{"cost":"sacrifice_artifact_or_creature","requires_sacrifice_artifact_or_creature":true,"xmage_additional_cost_target":"artifact_or_creature"}],"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":false,"requires_one_additional_cost_option":true,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_additional_cost_class":"OrCost","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DeadlyPrecision translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lash of the balrog', 'Lash of the Balrog', '3c626b87ad61938c72288ccc50ae07b6', 'battle_rule_v1:7a15a26745011ba967578b75c118531f', '{"additional_cost":"choose_sacrifice_creature_or_pay_generic","additional_cost_options":[{"cost":"sacrifice_creature","requires_sacrifice_creature":true,"xmage_additional_cost_target":"creature"},{"cost":"pay_generic","pay_generic_amount":4,"requires_pay_generic":true}],"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":false,"requires_one_additional_cost_option":true,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_additional_cost_class":"OrCost","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LashOfTheBalrog translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lightning axe', 'Lightning Axe', '2d756dc855b92af19e72842859dbfb5d', 'battle_rule_v1:7da25f92bcb8da5c8045c963e630cd28', '{"additional_cost":"choose_discard_card_or_pay_generic","additional_cost_options":[{"cost":"discard_card","requires_discard_card":true},{"cost":"pay_generic","pay_generic_amount":5,"requires_pay_generic":true}],"amount":5,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","damage":5,"effect":"direct_damage","instant":true,"requires_one_additional_cost_option":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_additional_cost_class":"OrCost","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LightningAxe translated into ManaLoom runtime scope xmage_fixed_damage_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pumpkin bombardment', 'Pumpkin Bombardment', 'e1144cbe56a6a9dd971af2e1795e123b', 'battle_rule_v1:81e4e488312dbfd27bed89b9f17cdec8', '{"additional_cost":"choose_discard_card_or_pay_generic","additional_cost_options":[{"cost":"discard_card","requires_discard_card":true},{"cost":"pay_generic","pay_generic_amount":2,"requires_pay_generic":true}],"amount":3,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","damage":3,"effect":"direct_damage","instant":false,"requires_one_additional_cost_option":true,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_additional_cost_class":"OrCost","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PumpkinBombardment translated into ManaLoom runtime scope xmage_fixed_damage_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('annihilating glare', 'Annihilating Glare', '052006cb3d6f1f1e367184e4aaef7fc2', 'battle_rule_v1:0c659eb3371016f8ae5aa11bdab3fb36', '{"additional_cost":"choose_pay_generic_or_sacrifice_artifact_or_creature","additional_cost_options":[{"cost":"pay_generic","pay_generic_amount":4,"requires_pay_generic":true},{"cost":"sacrifice_artifact_or_creature","requires_sacrifice_artifact_or_creature":true,"xmage_additional_cost_target":"artifact_or_creature"}],"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_permanent","instant":false,"requires_one_additional_cost_option":true,"sorcery":true,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_additional_cost_class":"OrCost","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"creature_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AnnihilatingGlare translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('deadly precision', 'Deadly Precision', 'cc5f6c4cd7a27bdff8d87afac5e2584a', 'battle_rule_v1:7c424b775d1c33dfb798c380c1fa358a', '{"additional_cost":"choose_pay_generic_or_sacrifice_artifact_or_creature","additional_cost_options":[{"cost":"pay_generic","pay_generic_amount":4,"requires_pay_generic":true},{"cost":"sacrifice_artifact_or_creature","requires_sacrifice_artifact_or_creature":true,"xmage_additional_cost_target":"artifact_or_creature"}],"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":false,"requires_one_additional_cost_option":true,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_additional_cost_class":"OrCost","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DeadlyPrecision translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lash of the balrog', 'Lash of the Balrog', '3c626b87ad61938c72288ccc50ae07b6', 'battle_rule_v1:7a15a26745011ba967578b75c118531f', '{"additional_cost":"choose_sacrifice_creature_or_pay_generic","additional_cost_options":[{"cost":"sacrifice_creature","requires_sacrifice_creature":true,"xmage_additional_cost_target":"creature"},{"cost":"pay_generic","pay_generic_amount":4,"requires_pay_generic":true}],"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":false,"requires_one_additional_cost_option":true,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_additional_cost_class":"OrCost","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LashOfTheBalrog translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lightning axe', 'Lightning Axe', '2d756dc855b92af19e72842859dbfb5d', 'battle_rule_v1:7da25f92bcb8da5c8045c963e630cd28', '{"additional_cost":"choose_discard_card_or_pay_generic","additional_cost_options":[{"cost":"discard_card","requires_discard_card":true},{"cost":"pay_generic","pay_generic_amount":5,"requires_pay_generic":true}],"amount":5,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","damage":5,"effect":"direct_damage","instant":true,"requires_one_additional_cost_option":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_additional_cost_class":"OrCost","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LightningAxe translated into ManaLoom runtime scope xmage_fixed_damage_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pumpkin bombardment', 'Pumpkin Bombardment', 'e1144cbe56a6a9dd971af2e1795e123b', 'battle_rule_v1:81e4e488312dbfd27bed89b9f17cdec8', '{"additional_cost":"choose_discard_card_or_pay_generic","additional_cost_options":[{"cost":"discard_card","requires_discard_card":true},{"cost":"pay_generic","pay_generic_amount":2,"requires_pay_generic":true}],"amount":3,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","damage":3,"effect":"direct_damage","instant":false,"requires_one_additional_cost_option":true,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_additional_cost_class":"OrCost","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PumpkinBombardment translated into ManaLoom runtime scope xmage_fixed_damage_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
