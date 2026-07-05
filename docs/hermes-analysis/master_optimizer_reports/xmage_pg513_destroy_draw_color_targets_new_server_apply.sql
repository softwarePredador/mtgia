BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg513_xmage_pg513_destroy_draw_color_tar_20260705_150547 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('annihilate', 'eastern paladin', 'execute', 'slay')
   OR normalized_name LIKE 'annihilate // %'
   OR normalized_name LIKE 'eastern paladin // %'
   OR normalized_name LIKE 'execute // %'
   OR normalized_name LIKE 'slay // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('annihilate', 'Annihilate', 'f578a7712e3dd990d0a0e92f96df9057', 'battle_rule_v1:c8e5c579f97351f53716b06514fe211e', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"],"exclude_colors":["B"]},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_destroy_target_and_draw_card_spell_v1","count":1,"destination":"graveyard","draw_count":1,"effect":"composite_resolution","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_colors":["B"]},"xmage_effect_classes":["DestroyTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Annihilate translated into ManaLoom runtime scope xmage_destroy_target_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('eastern paladin', 'Eastern Paladin', '2c989a30d9f4f99a9648dc54163ca4ef', 'battle_rule_v1:afea40681a2aa92731b0434232adf3a3', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"destroy_target","activated_remove_effect":"remove_creature","activated_remove_target":"green_creature","activation_cost_colors":["B","B"],"activation_cost_generic":0,"activation_cost_mana":"{B}{B}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"],"target_colors":["G"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","activated_effect":"destroy_target","activated_remove_effect":"remove_creature","activated_remove_target":"green_creature","activation_cost_colors":["B","B"],"activation_cost_generic":0,"activation_cost_mana":"{B}{B}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"creature","target":"creature","target_constraints":{"card_types":["creature"],"target_colors":["G"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EasternPaladin translated into ManaLoom runtime scope xmage_permanent_simple_activated_destroy_target_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated destroy-target ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('execute', 'Execute', '47b93b5f7240d9a4fc489bd64b5d0db3', 'battle_rule_v1:1f93b52c9ed6de8e93a4fa5dc105e255', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"],"target_colors":["W"]},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_destroy_target_and_draw_card_spell_v1","count":1,"destination":"graveyard","draw_count":1,"effect":"composite_resolution","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"target_colors":["W"]},"xmage_effect_classes":["DestroyTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Execute translated into ManaLoom runtime scope xmage_destroy_target_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('slay', 'Slay', '309a7db610e0746acd2928c7633def47', 'battle_rule_v1:1d35c73183c4187e06a9e033352a52ab', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"],"target_colors":["G"]},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_destroy_target_and_draw_card_spell_v1","count":1,"destination":"graveyard","draw_count":1,"effect":"composite_resolution","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"target_colors":["G"]},"xmage_effect_classes":["DestroyTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Slay translated into ManaLoom runtime scope xmage_destroy_target_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('annihilate', 'Annihilate', 'f578a7712e3dd990d0a0e92f96df9057', 'battle_rule_v1:c8e5c579f97351f53716b06514fe211e', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"],"exclude_colors":["B"]},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_destroy_target_and_draw_card_spell_v1","count":1,"destination":"graveyard","draw_count":1,"effect":"composite_resolution","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_colors":["B"]},"xmage_effect_classes":["DestroyTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Annihilate translated into ManaLoom runtime scope xmage_destroy_target_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('eastern paladin', 'Eastern Paladin', '2c989a30d9f4f99a9648dc54163ca4ef', 'battle_rule_v1:afea40681a2aa92731b0434232adf3a3', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"destroy_target","activated_remove_effect":"remove_creature","activated_remove_target":"green_creature","activation_cost_colors":["B","B"],"activation_cost_generic":0,"activation_cost_mana":"{B}{B}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"],"target_colors":["G"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","activated_effect":"destroy_target","activated_remove_effect":"remove_creature","activated_remove_target":"green_creature","activation_cost_colors":["B","B"],"activation_cost_generic":0,"activation_cost_mana":"{B}{B}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"creature","target":"creature","target_constraints":{"card_types":["creature"],"target_colors":["G"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EasternPaladin translated into ManaLoom runtime scope xmage_permanent_simple_activated_destroy_target_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated destroy-target ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('execute', 'Execute', '47b93b5f7240d9a4fc489bd64b5d0db3', 'battle_rule_v1:1f93b52c9ed6de8e93a4fa5dc105e255', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"],"target_colors":["W"]},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_destroy_target_and_draw_card_spell_v1","count":1,"destination":"graveyard","draw_count":1,"effect":"composite_resolution","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"target_colors":["W"]},"xmage_effect_classes":["DestroyTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Execute translated into ManaLoom runtime scope xmage_destroy_target_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('slay', 'Slay', '309a7db610e0746acd2928c7633def47', 'battle_rule_v1:1d35c73183c4187e06a9e033352a52ab', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"],"target_colors":["G"]},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_destroy_target_and_draw_card_spell_v1","count":1,"destination":"graveyard","draw_count":1,"effect":"composite_resolution","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"target_colors":["G"]},"xmage_effect_classes":["DestroyTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Slay translated into ManaLoom runtime scope xmage_destroy_target_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('annihilate', 'Annihilate', 'f578a7712e3dd990d0a0e92f96df9057', 'battle_rule_v1:c8e5c579f97351f53716b06514fe211e', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"],"exclude_colors":["B"]},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_destroy_target_and_draw_card_spell_v1","count":1,"destination":"graveyard","draw_count":1,"effect":"composite_resolution","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_colors":["B"]},"xmage_effect_classes":["DestroyTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Annihilate translated into ManaLoom runtime scope xmage_destroy_target_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('eastern paladin', 'Eastern Paladin', '2c989a30d9f4f99a9648dc54163ca4ef', 'battle_rule_v1:afea40681a2aa92731b0434232adf3a3', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"destroy_target","activated_remove_effect":"remove_creature","activated_remove_target":"green_creature","activation_cost_colors":["B","B"],"activation_cost_generic":0,"activation_cost_mana":"{B}{B}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"],"target_colors":["G"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","activated_effect":"destroy_target","activated_remove_effect":"remove_creature","activated_remove_target":"green_creature","activation_cost_colors":["B","B"],"activation_cost_generic":0,"activation_cost_mana":"{B}{B}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"creature","target":"creature","target_constraints":{"card_types":["creature"],"target_colors":["G"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EasternPaladin translated into ManaLoom runtime scope xmage_permanent_simple_activated_destroy_target_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated destroy-target ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('execute', 'Execute', '47b93b5f7240d9a4fc489bd64b5d0db3', 'battle_rule_v1:1f93b52c9ed6de8e93a4fa5dc105e255', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"],"target_colors":["W"]},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_destroy_target_and_draw_card_spell_v1","count":1,"destination":"graveyard","draw_count":1,"effect":"composite_resolution","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"target_colors":["W"]},"xmage_effect_classes":["DestroyTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Execute translated into ManaLoom runtime scope xmage_destroy_target_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('slay', 'Slay', '309a7db610e0746acd2928c7633def47', 'battle_rule_v1:1d35c73183c4187e06a9e033352a52ab', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"],"target_colors":["G"]},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_destroy_target_and_draw_card_spell_v1","count":1,"destination":"graveyard","draw_count":1,"effect":"composite_resolution","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"target_colors":["G"]},"xmage_effect_classes":["DestroyTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Slay translated into ManaLoom runtime scope xmage_destroy_target_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
