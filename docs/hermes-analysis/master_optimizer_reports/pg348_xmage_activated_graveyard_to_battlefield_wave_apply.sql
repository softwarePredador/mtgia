BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg348_xmage_activated_graveyard_to_battlefield_wave_2026 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('doomed necromancer', 'protomatter powder')
   OR normalized_name LIKE 'doomed necromancer // %'
   OR normalized_name LIKE 'protomatter powder // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('doomed necromancer', 'Doomed Necromancer', '16f413bd06f6099af1b5f2edc8376ef8', 'battle_rule_v1:69aa5c0d8ef05abc7839277c916ca703', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","activated_effect":"recursion","activated_self_sacrifice_recursion":true,"activation_cost_colors":["B"],"activation_cost_generic":0,"activation_cost_mana":"{B}","activation_requires_sacrifice":true,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","battlefield_controller":"self","count":1,"destination":"battlefield","effect":"recursion","graveyard_to_hand_destination":"battlefield","graveyard_to_hand_target":"creature","graveyard_to_hand_target_count":1,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","activated_effect":"recursion","activated_self_sacrifice_recursion":true,"activation_cost_colors":["B"],"activation_cost_generic":0,"activation_cost_mana":"{B}","activation_requires_sacrifice":true,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","battlefield_controller":"self","count":1,"destination":"battlefield","effect":"creature","graveyard_to_hand_activation_cost_colors":["B"],"graveyard_to_hand_activation_cost_generic":0,"graveyard_to_hand_activation_cost_mana":"{B}","graveyard_to_hand_activation_requires_sacrifice":true,"graveyard_to_hand_activation_requires_tap":true,"graveyard_to_hand_destination":"battlefield","graveyard_to_hand_target":"creature","graveyard_to_hand_target_count":1,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DoomedNecromancer translated into ManaLoom runtime scope xmage_permanent_simple_activated_graveyard_to_battlefield_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated graveyard-to-battlefield ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('protomatter powder', 'Protomatter Powder', '10ed15a25e1fe4d28f46da77df2dd0d9', 'battle_rule_v1:fff8c850b20d1a8c8f747263abc55491', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","activated_effect":"recursion","activated_self_sacrifice_recursion":true,"activation_cost_colors":["W"],"activation_cost_generic":4,"activation_cost_mana":"{4}{W}","activation_requires_sacrifice":true,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","battlefield_controller":"self","count":1,"destination":"battlefield","effect":"recursion","graveyard_to_hand_destination":"battlefield","graveyard_to_hand_target":"artifact","graveyard_to_hand_target_count":1,"target":"artifact","target_constraints":{"card_types":["artifact"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","activated_effect":"recursion","activated_self_sacrifice_recursion":true,"activation_cost_colors":["W"],"activation_cost_generic":4,"activation_cost_mana":"{4}{W}","activation_requires_sacrifice":true,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","battlefield_controller":"self","count":1,"destination":"battlefield","effect":"artifact","graveyard_to_hand_activation_cost_colors":["W"],"graveyard_to_hand_activation_cost_generic":4,"graveyard_to_hand_activation_cost_mana":"{4}{W}","graveyard_to_hand_activation_requires_sacrifice":true,"graveyard_to_hand_activation_requires_tap":true,"graveyard_to_hand_destination":"battlefield","graveyard_to_hand_target":"artifact","graveyard_to_hand_target_count":1,"target":"artifact","target_constraints":{"card_types":["artifact"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"unknown","effect":"artifact","target":"artifact"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ProtomatterPowder translated into ManaLoom runtime scope xmage_permanent_simple_activated_graveyard_to_battlefield_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated graveyard-to-battlefield ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('doomed necromancer', 'Doomed Necromancer', '16f413bd06f6099af1b5f2edc8376ef8', 'battle_rule_v1:69aa5c0d8ef05abc7839277c916ca703', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","activated_effect":"recursion","activated_self_sacrifice_recursion":true,"activation_cost_colors":["B"],"activation_cost_generic":0,"activation_cost_mana":"{B}","activation_requires_sacrifice":true,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","battlefield_controller":"self","count":1,"destination":"battlefield","effect":"recursion","graveyard_to_hand_destination":"battlefield","graveyard_to_hand_target":"creature","graveyard_to_hand_target_count":1,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","activated_effect":"recursion","activated_self_sacrifice_recursion":true,"activation_cost_colors":["B"],"activation_cost_generic":0,"activation_cost_mana":"{B}","activation_requires_sacrifice":true,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","battlefield_controller":"self","count":1,"destination":"battlefield","effect":"creature","graveyard_to_hand_activation_cost_colors":["B"],"graveyard_to_hand_activation_cost_generic":0,"graveyard_to_hand_activation_cost_mana":"{B}","graveyard_to_hand_activation_requires_sacrifice":true,"graveyard_to_hand_activation_requires_tap":true,"graveyard_to_hand_destination":"battlefield","graveyard_to_hand_target":"creature","graveyard_to_hand_target_count":1,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DoomedNecromancer translated into ManaLoom runtime scope xmage_permanent_simple_activated_graveyard_to_battlefield_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated graveyard-to-battlefield ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('protomatter powder', 'Protomatter Powder', '10ed15a25e1fe4d28f46da77df2dd0d9', 'battle_rule_v1:fff8c850b20d1a8c8f747263abc55491', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","activated_effect":"recursion","activated_self_sacrifice_recursion":true,"activation_cost_colors":["W"],"activation_cost_generic":4,"activation_cost_mana":"{4}{W}","activation_requires_sacrifice":true,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","battlefield_controller":"self","count":1,"destination":"battlefield","effect":"recursion","graveyard_to_hand_destination":"battlefield","graveyard_to_hand_target":"artifact","graveyard_to_hand_target_count":1,"target":"artifact","target_constraints":{"card_types":["artifact"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","activated_effect":"recursion","activated_self_sacrifice_recursion":true,"activation_cost_colors":["W"],"activation_cost_generic":4,"activation_cost_mana":"{4}{W}","activation_requires_sacrifice":true,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","battlefield_controller":"self","count":1,"destination":"battlefield","effect":"artifact","graveyard_to_hand_activation_cost_colors":["W"],"graveyard_to_hand_activation_cost_generic":4,"graveyard_to_hand_activation_cost_mana":"{4}{W}","graveyard_to_hand_activation_requires_sacrifice":true,"graveyard_to_hand_activation_requires_tap":true,"graveyard_to_hand_destination":"battlefield","graveyard_to_hand_target":"artifact","graveyard_to_hand_target_count":1,"target":"artifact","target_constraints":{"card_types":["artifact"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"unknown","effect":"artifact","target":"artifact"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ProtomatterPowder translated into ManaLoom runtime scope xmage_permanent_simple_activated_graveyard_to_battlefield_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated graveyard-to-battlefield ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('doomed necromancer', 'Doomed Necromancer', '16f413bd06f6099af1b5f2edc8376ef8', 'battle_rule_v1:69aa5c0d8ef05abc7839277c916ca703', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","activated_effect":"recursion","activated_self_sacrifice_recursion":true,"activation_cost_colors":["B"],"activation_cost_generic":0,"activation_cost_mana":"{B}","activation_requires_sacrifice":true,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","battlefield_controller":"self","count":1,"destination":"battlefield","effect":"recursion","graveyard_to_hand_destination":"battlefield","graveyard_to_hand_target":"creature","graveyard_to_hand_target_count":1,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","activated_effect":"recursion","activated_self_sacrifice_recursion":true,"activation_cost_colors":["B"],"activation_cost_generic":0,"activation_cost_mana":"{B}","activation_requires_sacrifice":true,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","battlefield_controller":"self","count":1,"destination":"battlefield","effect":"creature","graveyard_to_hand_activation_cost_colors":["B"],"graveyard_to_hand_activation_cost_generic":0,"graveyard_to_hand_activation_cost_mana":"{B}","graveyard_to_hand_activation_requires_sacrifice":true,"graveyard_to_hand_activation_requires_tap":true,"graveyard_to_hand_destination":"battlefield","graveyard_to_hand_target":"creature","graveyard_to_hand_target_count":1,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DoomedNecromancer translated into ManaLoom runtime scope xmage_permanent_simple_activated_graveyard_to_battlefield_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated graveyard-to-battlefield ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('protomatter powder', 'Protomatter Powder', '10ed15a25e1fe4d28f46da77df2dd0d9', 'battle_rule_v1:fff8c850b20d1a8c8f747263abc55491', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","activated_effect":"recursion","activated_self_sacrifice_recursion":true,"activation_cost_colors":["W"],"activation_cost_generic":4,"activation_cost_mana":"{4}{W}","activation_requires_sacrifice":true,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","battlefield_controller":"self","count":1,"destination":"battlefield","effect":"recursion","graveyard_to_hand_destination":"battlefield","graveyard_to_hand_target":"artifact","graveyard_to_hand_target_count":1,"target":"artifact","target_constraints":{"card_types":["artifact"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","activated_effect":"recursion","activated_self_sacrifice_recursion":true,"activation_cost_colors":["W"],"activation_cost_generic":4,"activation_cost_mana":"{4}{W}","activation_requires_sacrifice":true,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_battlefield_v1","battlefield_controller":"self","count":1,"destination":"battlefield","effect":"artifact","graveyard_to_hand_activation_cost_colors":["W"],"graveyard_to_hand_activation_cost_generic":4,"graveyard_to_hand_activation_cost_mana":"{4}{W}","graveyard_to_hand_activation_requires_sacrifice":true,"graveyard_to_hand_activation_requires_tap":true,"graveyard_to_hand_destination":"battlefield","graveyard_to_hand_target":"artifact","graveyard_to_hand_target_count":1,"target":"artifact","target_constraints":{"card_types":["artifact"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"unknown","effect":"artifact","target":"artifact"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ProtomatterPowder translated into ManaLoom runtime scope xmage_permanent_simple_activated_graveyard_to_battlefield_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated graveyard-to-battlefield ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
