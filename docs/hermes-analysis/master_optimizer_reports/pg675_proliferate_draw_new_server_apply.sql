BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg675_proliferate_draw_new_server_prolif_20260708_223712 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('contentious plan', 'steady progress', 'tezzeret''s gambit', 'vivisurgeon''s insight')
   OR normalized_name LIKE 'contentious plan // %'
   OR normalized_name LIKE 'steady progress // %'
   OR normalized_name LIKE 'tezzeret''s gambit // %'
   OR normalized_name LIKE 'vivisurgeon''s insight // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('contentious plan', 'Contentious Plan', '4582abf74328130a7ac8ca45cbcd1d2d', 'battle_rule_v1:821bc3c6274082b25465b68c03d58653', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_proliferate_spell_v1","compose_on_resolution":true,"effect":"proliferate","proliferate_count":1,"xmage_effect_class":"ProliferateEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_proliferate_and_draw_cards_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":false,"proliferate_count":1,"resolution_order":"proliferate_then_draw","sorcery":true,"xmage_effect_classes":["DrawCardSourceControllerEffect","ProliferateEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ContentiousPlan translated into ManaLoom runtime scope xmage_fixed_proliferate_and_draw_cards_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('steady progress', 'Steady Progress', '4582abf74328130a7ac8ca45cbcd1d2d', 'battle_rule_v1:6f809a58fe795aff31937be7484e5915', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_proliferate_spell_v1","compose_on_resolution":true,"effect":"proliferate","proliferate_count":1,"xmage_effect_class":"ProliferateEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_proliferate_and_draw_cards_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":true,"proliferate_count":1,"resolution_order":"proliferate_then_draw","sorcery":false,"xmage_effect_classes":["DrawCardSourceControllerEffect","ProliferateEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SteadyProgress translated into ManaLoom runtime scope xmage_fixed_proliferate_and_draw_cards_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tezzeret''s gambit', 'Tezzeret''s Gambit', 'cd253b1acdf30fc75b8a62d7630b45cd', 'battle_rule_v1:a550b8881a1b501010aad2549aa54472', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":2,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"},{"battle_model_scope":"xmage_fixed_proliferate_spell_v1","compose_on_resolution":true,"effect":"proliferate","proliferate_count":1,"xmage_effect_class":"ProliferateEffect"}],"battle_model_scope":"xmage_fixed_proliferate_and_draw_cards_spell_v1","count":2,"draw_count":2,"effect":"composite_resolution","instant":false,"proliferate_count":1,"resolution_order":"draw_then_proliferate","sorcery":true,"xmage_effect_classes":["DrawCardSourceControllerEffect","ProliferateEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TezzeretsGambit translated into ManaLoom runtime scope xmage_fixed_proliferate_and_draw_cards_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vivisurgeon''s insight', 'Vivisurgeon''s Insight', '225971006721adf2999911730a636afc', 'battle_rule_v1:5f0f5e17992389750140c3f40957d89c', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":3,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"},{"battle_model_scope":"xmage_fixed_proliferate_spell_v1","compose_on_resolution":true,"effect":"proliferate","proliferate_count":1,"xmage_effect_class":"ProliferateEffect"}],"battle_model_scope":"xmage_fixed_proliferate_and_draw_cards_spell_v1","count":3,"draw_count":3,"effect":"composite_resolution","instant":false,"proliferate_count":1,"resolution_order":"draw_then_proliferate","sorcery":true,"xmage_effect_classes":["DrawCardSourceControllerEffect","ProliferateEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VivisurgeonsInsight translated into ManaLoom runtime scope xmage_fixed_proliferate_and_draw_cards_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('contentious plan', 'Contentious Plan', '4582abf74328130a7ac8ca45cbcd1d2d', 'battle_rule_v1:821bc3c6274082b25465b68c03d58653', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_proliferate_spell_v1","compose_on_resolution":true,"effect":"proliferate","proliferate_count":1,"xmage_effect_class":"ProliferateEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_proliferate_and_draw_cards_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":false,"proliferate_count":1,"resolution_order":"proliferate_then_draw","sorcery":true,"xmage_effect_classes":["DrawCardSourceControllerEffect","ProliferateEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ContentiousPlan translated into ManaLoom runtime scope xmage_fixed_proliferate_and_draw_cards_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('steady progress', 'Steady Progress', '4582abf74328130a7ac8ca45cbcd1d2d', 'battle_rule_v1:6f809a58fe795aff31937be7484e5915', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_proliferate_spell_v1","compose_on_resolution":true,"effect":"proliferate","proliferate_count":1,"xmage_effect_class":"ProliferateEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_proliferate_and_draw_cards_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":true,"proliferate_count":1,"resolution_order":"proliferate_then_draw","sorcery":false,"xmage_effect_classes":["DrawCardSourceControllerEffect","ProliferateEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SteadyProgress translated into ManaLoom runtime scope xmage_fixed_proliferate_and_draw_cards_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tezzeret''s gambit', 'Tezzeret''s Gambit', 'cd253b1acdf30fc75b8a62d7630b45cd', 'battle_rule_v1:a550b8881a1b501010aad2549aa54472', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":2,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"},{"battle_model_scope":"xmage_fixed_proliferate_spell_v1","compose_on_resolution":true,"effect":"proliferate","proliferate_count":1,"xmage_effect_class":"ProliferateEffect"}],"battle_model_scope":"xmage_fixed_proliferate_and_draw_cards_spell_v1","count":2,"draw_count":2,"effect":"composite_resolution","instant":false,"proliferate_count":1,"resolution_order":"draw_then_proliferate","sorcery":true,"xmage_effect_classes":["DrawCardSourceControllerEffect","ProliferateEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TezzeretsGambit translated into ManaLoom runtime scope xmage_fixed_proliferate_and_draw_cards_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vivisurgeon''s insight', 'Vivisurgeon''s Insight', '225971006721adf2999911730a636afc', 'battle_rule_v1:5f0f5e17992389750140c3f40957d89c', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":3,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"},{"battle_model_scope":"xmage_fixed_proliferate_spell_v1","compose_on_resolution":true,"effect":"proliferate","proliferate_count":1,"xmage_effect_class":"ProliferateEffect"}],"battle_model_scope":"xmage_fixed_proliferate_and_draw_cards_spell_v1","count":3,"draw_count":3,"effect":"composite_resolution","instant":false,"proliferate_count":1,"resolution_order":"draw_then_proliferate","sorcery":true,"xmage_effect_classes":["DrawCardSourceControllerEffect","ProliferateEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VivisurgeonsInsight translated into ManaLoom runtime scope xmage_fixed_proliferate_and_draw_cards_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('contentious plan', 'Contentious Plan', '4582abf74328130a7ac8ca45cbcd1d2d', 'battle_rule_v1:821bc3c6274082b25465b68c03d58653', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_proliferate_spell_v1","compose_on_resolution":true,"effect":"proliferate","proliferate_count":1,"xmage_effect_class":"ProliferateEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_proliferate_and_draw_cards_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":false,"proliferate_count":1,"resolution_order":"proliferate_then_draw","sorcery":true,"xmage_effect_classes":["DrawCardSourceControllerEffect","ProliferateEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ContentiousPlan translated into ManaLoom runtime scope xmage_fixed_proliferate_and_draw_cards_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('steady progress', 'Steady Progress', '4582abf74328130a7ac8ca45cbcd1d2d', 'battle_rule_v1:6f809a58fe795aff31937be7484e5915', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_proliferate_spell_v1","compose_on_resolution":true,"effect":"proliferate","proliferate_count":1,"xmage_effect_class":"ProliferateEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_proliferate_and_draw_cards_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":true,"proliferate_count":1,"resolution_order":"proliferate_then_draw","sorcery":false,"xmage_effect_classes":["DrawCardSourceControllerEffect","ProliferateEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SteadyProgress translated into ManaLoom runtime scope xmage_fixed_proliferate_and_draw_cards_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tezzeret''s gambit', 'Tezzeret''s Gambit', 'cd253b1acdf30fc75b8a62d7630b45cd', 'battle_rule_v1:a550b8881a1b501010aad2549aa54472', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":2,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"},{"battle_model_scope":"xmage_fixed_proliferate_spell_v1","compose_on_resolution":true,"effect":"proliferate","proliferate_count":1,"xmage_effect_class":"ProliferateEffect"}],"battle_model_scope":"xmage_fixed_proliferate_and_draw_cards_spell_v1","count":2,"draw_count":2,"effect":"composite_resolution","instant":false,"proliferate_count":1,"resolution_order":"draw_then_proliferate","sorcery":true,"xmage_effect_classes":["DrawCardSourceControllerEffect","ProliferateEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TezzeretsGambit translated into ManaLoom runtime scope xmage_fixed_proliferate_and_draw_cards_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vivisurgeon''s insight', 'Vivisurgeon''s Insight', '225971006721adf2999911730a636afc', 'battle_rule_v1:5f0f5e17992389750140c3f40957d89c', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":3,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"},{"battle_model_scope":"xmage_fixed_proliferate_spell_v1","compose_on_resolution":true,"effect":"proliferate","proliferate_count":1,"xmage_effect_class":"ProliferateEffect"}],"battle_model_scope":"xmage_fixed_proliferate_and_draw_cards_spell_v1","count":3,"draw_count":3,"effect":"composite_resolution","instant":false,"proliferate_count":1,"resolution_order":"draw_then_proliferate","sorcery":true,"xmage_effect_classes":["DrawCardSourceControllerEffect","ProliferateEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VivisurgeonsInsight translated into ManaLoom runtime scope xmage_fixed_proliferate_and_draw_cards_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
