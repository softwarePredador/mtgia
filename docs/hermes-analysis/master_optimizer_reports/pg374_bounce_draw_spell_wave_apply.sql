BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg374_bounce_draw_spell_wave_pg374_bounce_draw_spell_wav AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('drag under', 'galestrike', 'leave in the dust', 'repulse', 'symbol of unsummoning')
   OR normalized_name LIKE 'drag under // %'
   OR normalized_name LIKE 'galestrike // %'
   OR normalized_name LIKE 'leave in the dust // %'
   OR normalized_name LIKE 'repulse // %'
   OR normalized_name LIKE 'symbol of unsummoning // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('drag under', 'Drag Under', '6dd402431d3b7fb848824229d033614a', 'battle_rule_v1:f862445930f198fc3c6dc8a3d59362bb', '{"_composite_rule_components":[{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","compose_on_resolution":true,"destination":"hand","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"ReturnToHandTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_return_target_to_hand_and_draw_card_spell_v1","count":1,"destination":"hand","draw_count":1,"effect":"composite_resolution","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["ReturnToHandTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DragUnder translated into ManaLoom runtime scope xmage_return_target_to_hand_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed return-target-to-hand plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('galestrike', 'Galestrike', 'e17ba3ddaf7febad91161213aad18a2a', 'battle_rule_v1:d6525baec4c35d68b522fb1fa2a96b9f', '{"_composite_rule_components":[{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","compose_on_resolution":true,"destination":"hand","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"],"tapped_state":"tapped"},"xmage_effect_class":"ReturnToHandTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_return_target_to_hand_and_draw_card_spell_v1","count":1,"destination":"hand","draw_count":1,"effect":"composite_resolution","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"tapped_state":"tapped"},"xmage_effect_classes":["ReturnToHandTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Galestrike translated into ManaLoom runtime scope xmage_return_target_to_hand_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed return-target-to-hand plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('leave in the dust', 'Leave in the Dust', 'e0aea105a62d82d27328b92b26231700', 'battle_rule_v1:1db4bbcee08be05bdcfcdbc8c3503ab1', '{"_composite_rule_components":[{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","compose_on_resolution":true,"destination":"hand","effect":"remove_permanent","target":"nonland_permanent","target_constraints":{"card_types":["nonland_permanent"]},"xmage_effect_class":"ReturnToHandTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_return_target_to_hand_and_draw_card_spell_v1","count":1,"destination":"hand","draw_count":1,"effect":"composite_resolution","instant":true,"sorcery":false,"target":"nonland_permanent","target_constraints":{"card_types":["nonland_permanent"]},"xmage_effect_classes":["ReturnToHandTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"nonland_permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LeaveInTheDust translated into ManaLoom runtime scope xmage_return_target_to_hand_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed return-target-to-hand plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('repulse', 'Repulse', '6dd402431d3b7fb848824229d033614a', 'battle_rule_v1:c26825e6148a1ceed1bb1f5236af63de', '{"_composite_rule_components":[{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","compose_on_resolution":true,"destination":"hand","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"ReturnToHandTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_return_target_to_hand_and_draw_card_spell_v1","count":1,"destination":"hand","draw_count":1,"effect":"composite_resolution","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["ReturnToHandTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Repulse translated into ManaLoom runtime scope xmage_return_target_to_hand_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed return-target-to-hand plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('symbol of unsummoning', 'Symbol of Unsummoning', '6dd402431d3b7fb848824229d033614a', 'battle_rule_v1:f862445930f198fc3c6dc8a3d59362bb', '{"_composite_rule_components":[{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","compose_on_resolution":true,"destination":"hand","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"ReturnToHandTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_return_target_to_hand_and_draw_card_spell_v1","count":1,"destination":"hand","draw_count":1,"effect":"composite_resolution","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["ReturnToHandTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SymbolOfUnsummoning translated into ManaLoom runtime scope xmage_return_target_to_hand_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed return-target-to-hand plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('drag under', 'Drag Under', '6dd402431d3b7fb848824229d033614a', 'battle_rule_v1:f862445930f198fc3c6dc8a3d59362bb', '{"_composite_rule_components":[{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","compose_on_resolution":true,"destination":"hand","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"ReturnToHandTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_return_target_to_hand_and_draw_card_spell_v1","count":1,"destination":"hand","draw_count":1,"effect":"composite_resolution","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["ReturnToHandTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DragUnder translated into ManaLoom runtime scope xmage_return_target_to_hand_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed return-target-to-hand plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('galestrike', 'Galestrike', 'e17ba3ddaf7febad91161213aad18a2a', 'battle_rule_v1:d6525baec4c35d68b522fb1fa2a96b9f', '{"_composite_rule_components":[{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","compose_on_resolution":true,"destination":"hand","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"],"tapped_state":"tapped"},"xmage_effect_class":"ReturnToHandTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_return_target_to_hand_and_draw_card_spell_v1","count":1,"destination":"hand","draw_count":1,"effect":"composite_resolution","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"tapped_state":"tapped"},"xmage_effect_classes":["ReturnToHandTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Galestrike translated into ManaLoom runtime scope xmage_return_target_to_hand_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed return-target-to-hand plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('leave in the dust', 'Leave in the Dust', 'e0aea105a62d82d27328b92b26231700', 'battle_rule_v1:1db4bbcee08be05bdcfcdbc8c3503ab1', '{"_composite_rule_components":[{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","compose_on_resolution":true,"destination":"hand","effect":"remove_permanent","target":"nonland_permanent","target_constraints":{"card_types":["nonland_permanent"]},"xmage_effect_class":"ReturnToHandTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_return_target_to_hand_and_draw_card_spell_v1","count":1,"destination":"hand","draw_count":1,"effect":"composite_resolution","instant":true,"sorcery":false,"target":"nonland_permanent","target_constraints":{"card_types":["nonland_permanent"]},"xmage_effect_classes":["ReturnToHandTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"nonland_permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LeaveInTheDust translated into ManaLoom runtime scope xmage_return_target_to_hand_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed return-target-to-hand plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('repulse', 'Repulse', '6dd402431d3b7fb848824229d033614a', 'battle_rule_v1:c26825e6148a1ceed1bb1f5236af63de', '{"_composite_rule_components":[{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","compose_on_resolution":true,"destination":"hand","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"ReturnToHandTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_return_target_to_hand_and_draw_card_spell_v1","count":1,"destination":"hand","draw_count":1,"effect":"composite_resolution","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["ReturnToHandTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Repulse translated into ManaLoom runtime scope xmage_return_target_to_hand_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed return-target-to-hand plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('symbol of unsummoning', 'Symbol of Unsummoning', '6dd402431d3b7fb848824229d033614a', 'battle_rule_v1:f862445930f198fc3c6dc8a3d59362bb', '{"_composite_rule_components":[{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","compose_on_resolution":true,"destination":"hand","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"ReturnToHandTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_return_target_to_hand_and_draw_card_spell_v1","count":1,"destination":"hand","draw_count":1,"effect":"composite_resolution","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["ReturnToHandTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SymbolOfUnsummoning translated into ManaLoom runtime scope xmage_return_target_to_hand_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed return-target-to-hand plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('drag under', 'Drag Under', '6dd402431d3b7fb848824229d033614a', 'battle_rule_v1:f862445930f198fc3c6dc8a3d59362bb', '{"_composite_rule_components":[{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","compose_on_resolution":true,"destination":"hand","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"ReturnToHandTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_return_target_to_hand_and_draw_card_spell_v1","count":1,"destination":"hand","draw_count":1,"effect":"composite_resolution","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["ReturnToHandTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DragUnder translated into ManaLoom runtime scope xmage_return_target_to_hand_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed return-target-to-hand plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('galestrike', 'Galestrike', 'e17ba3ddaf7febad91161213aad18a2a', 'battle_rule_v1:d6525baec4c35d68b522fb1fa2a96b9f', '{"_composite_rule_components":[{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","compose_on_resolution":true,"destination":"hand","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"],"tapped_state":"tapped"},"xmage_effect_class":"ReturnToHandTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_return_target_to_hand_and_draw_card_spell_v1","count":1,"destination":"hand","draw_count":1,"effect":"composite_resolution","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"tapped_state":"tapped"},"xmage_effect_classes":["ReturnToHandTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Galestrike translated into ManaLoom runtime scope xmage_return_target_to_hand_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed return-target-to-hand plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('leave in the dust', 'Leave in the Dust', 'e0aea105a62d82d27328b92b26231700', 'battle_rule_v1:1db4bbcee08be05bdcfcdbc8c3503ab1', '{"_composite_rule_components":[{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","compose_on_resolution":true,"destination":"hand","effect":"remove_permanent","target":"nonland_permanent","target_constraints":{"card_types":["nonland_permanent"]},"xmage_effect_class":"ReturnToHandTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_return_target_to_hand_and_draw_card_spell_v1","count":1,"destination":"hand","draw_count":1,"effect":"composite_resolution","instant":true,"sorcery":false,"target":"nonland_permanent","target_constraints":{"card_types":["nonland_permanent"]},"xmage_effect_classes":["ReturnToHandTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"nonland_permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LeaveInTheDust translated into ManaLoom runtime scope xmage_return_target_to_hand_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed return-target-to-hand plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('repulse', 'Repulse', '6dd402431d3b7fb848824229d033614a', 'battle_rule_v1:c26825e6148a1ceed1bb1f5236af63de', '{"_composite_rule_components":[{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","compose_on_resolution":true,"destination":"hand","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"ReturnToHandTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_return_target_to_hand_and_draw_card_spell_v1","count":1,"destination":"hand","draw_count":1,"effect":"composite_resolution","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["ReturnToHandTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Repulse translated into ManaLoom runtime scope xmage_return_target_to_hand_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed return-target-to-hand plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('symbol of unsummoning', 'Symbol of Unsummoning', '6dd402431d3b7fb848824229d033614a', 'battle_rule_v1:f862445930f198fc3c6dc8a3d59362bb', '{"_composite_rule_components":[{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","compose_on_resolution":true,"destination":"hand","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"ReturnToHandTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_return_target_to_hand_and_draw_card_spell_v1","count":1,"destination":"hand","draw_count":1,"effect":"composite_resolution","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["ReturnToHandTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SymbolOfUnsummoning translated into ManaLoom runtime scope xmage_return_target_to_hand_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed return-target-to-hand plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
