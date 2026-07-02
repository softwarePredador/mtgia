BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg342_xmage_recursion_exile_self_spell_wave_20260702_010 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('reconstruct history', 'retrieve', 'vivid revival')
   OR normalized_name LIKE 'reconstruct history // %'
   OR normalized_name LIKE 'retrieve // %'
   OR normalized_name LIKE 'vivid revival // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('reconstruct history', 'Reconstruct History', 'fef076b46b9660e2f9eb20dbce095b86', 'battle_rule_v1:5891f73a4c159c6a7e04ab4a73194bb2', '{"battle_model_scope":"xmage_return_multiple_graveyard_cards_to_hand_exile_self_spell_v1","destination":"hand","effect":"recursion","exiles_self":true,"instant":false,"mode_selection":"all_components","recursion_components":[{"count":1,"destination":"hand","target":"artifact","target_constraints":{"card_types":["artifact"],"controller":"self","zone":"graveyard"},"target_controller":"self","up_to_count":true},{"count":1,"destination":"hand","target":"enchantment","target_constraints":{"card_types":["enchantment"],"controller":"self","zone":"graveyard"},"target_controller":"self","up_to_count":true},{"count":1,"destination":"hand","target":"instant","target_constraints":{"card_types":["instant"],"controller":"self","zone":"graveyard"},"target_controller":"self","up_to_count":true},{"count":1,"destination":"hand","target":"sorcery","target_constraints":{"card_types":["sorcery"],"controller":"self","zone":"graveyard"},"target_controller":"self","up_to_count":true},{"count":1,"destination":"hand","target":"planeswalker","target_constraints":{"card_types":["planeswalker"],"controller":"self","zone":"graveyard"},"target_controller":"self","up_to_count":true}],"sorcery":true,"target_controller":"self","xmage_additional_effect_class":"ExileSpellEffect","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ReconstructHistory translated into ManaLoom runtime scope xmage_return_multiple_graveyard_cards_to_hand_exile_self_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('retrieve', 'Retrieve', '18bc4cc44ffd6382912e0c7fe24e7335', 'battle_rule_v1:3fb7ce15a27a11482bfeb0a35cc5e088', '{"battle_model_scope":"xmage_return_multiple_graveyard_cards_to_hand_exile_self_spell_v1","destination":"hand","effect":"recursion","exiles_self":true,"instant":false,"mode_selection":"all_components","recursion_components":[{"count":1,"destination":"hand","target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","up_to_count":true},{"count":1,"destination":"hand","target":"noncreature_permanent","target_constraints":{"card_types":["artifact","enchantment","planeswalker","battle","land"],"controller":"self","exclude_card_types":["creature"],"zone":"graveyard"},"target_controller":"self","up_to_count":true}],"sorcery":true,"target_controller":"self","xmage_additional_effect_class":"ExileSpellEffect","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Retrieve translated into ManaLoom runtime scope xmage_return_multiple_graveyard_cards_to_hand_exile_self_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vivid revival', 'Vivid Revival', '9f4629b135cb2888979404fca4a71cea', 'battle_rule_v1:0eaec04572207c2751454d4b4793493b', '{"battle_model_scope":"xmage_return_target_graveyard_card_to_hand_spell_v1","count":3,"destination":"hand","effect":"recursion","exiles_self":true,"instant":false,"sorcery":true,"target":"multicolored_card","target_constraints":{"controller":"self","min_colors":2,"zone":"graveyard"},"target_controller":"self","up_to_count":true,"xmage_additional_effect_class":"ExileSpellEffect","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"multicolored_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VividRevival translated into ManaLoom runtime scope xmage_return_target_graveyard_card_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('reconstruct history', 'Reconstruct History', 'fef076b46b9660e2f9eb20dbce095b86', 'battle_rule_v1:5891f73a4c159c6a7e04ab4a73194bb2', '{"battle_model_scope":"xmage_return_multiple_graveyard_cards_to_hand_exile_self_spell_v1","destination":"hand","effect":"recursion","exiles_self":true,"instant":false,"mode_selection":"all_components","recursion_components":[{"count":1,"destination":"hand","target":"artifact","target_constraints":{"card_types":["artifact"],"controller":"self","zone":"graveyard"},"target_controller":"self","up_to_count":true},{"count":1,"destination":"hand","target":"enchantment","target_constraints":{"card_types":["enchantment"],"controller":"self","zone":"graveyard"},"target_controller":"self","up_to_count":true},{"count":1,"destination":"hand","target":"instant","target_constraints":{"card_types":["instant"],"controller":"self","zone":"graveyard"},"target_controller":"self","up_to_count":true},{"count":1,"destination":"hand","target":"sorcery","target_constraints":{"card_types":["sorcery"],"controller":"self","zone":"graveyard"},"target_controller":"self","up_to_count":true},{"count":1,"destination":"hand","target":"planeswalker","target_constraints":{"card_types":["planeswalker"],"controller":"self","zone":"graveyard"},"target_controller":"self","up_to_count":true}],"sorcery":true,"target_controller":"self","xmage_additional_effect_class":"ExileSpellEffect","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ReconstructHistory translated into ManaLoom runtime scope xmage_return_multiple_graveyard_cards_to_hand_exile_self_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('retrieve', 'Retrieve', '18bc4cc44ffd6382912e0c7fe24e7335', 'battle_rule_v1:3fb7ce15a27a11482bfeb0a35cc5e088', '{"battle_model_scope":"xmage_return_multiple_graveyard_cards_to_hand_exile_self_spell_v1","destination":"hand","effect":"recursion","exiles_self":true,"instant":false,"mode_selection":"all_components","recursion_components":[{"count":1,"destination":"hand","target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","up_to_count":true},{"count":1,"destination":"hand","target":"noncreature_permanent","target_constraints":{"card_types":["artifact","enchantment","planeswalker","battle","land"],"controller":"self","exclude_card_types":["creature"],"zone":"graveyard"},"target_controller":"self","up_to_count":true}],"sorcery":true,"target_controller":"self","xmage_additional_effect_class":"ExileSpellEffect","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Retrieve translated into ManaLoom runtime scope xmage_return_multiple_graveyard_cards_to_hand_exile_self_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vivid revival', 'Vivid Revival', '9f4629b135cb2888979404fca4a71cea', 'battle_rule_v1:0eaec04572207c2751454d4b4793493b', '{"battle_model_scope":"xmage_return_target_graveyard_card_to_hand_spell_v1","count":3,"destination":"hand","effect":"recursion","exiles_self":true,"instant":false,"sorcery":true,"target":"multicolored_card","target_constraints":{"controller":"self","min_colors":2,"zone":"graveyard"},"target_controller":"self","up_to_count":true,"xmage_additional_effect_class":"ExileSpellEffect","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"multicolored_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VividRevival translated into ManaLoom runtime scope xmage_return_target_graveyard_card_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('reconstruct history', 'Reconstruct History', 'fef076b46b9660e2f9eb20dbce095b86', 'battle_rule_v1:5891f73a4c159c6a7e04ab4a73194bb2', '{"battle_model_scope":"xmage_return_multiple_graveyard_cards_to_hand_exile_self_spell_v1","destination":"hand","effect":"recursion","exiles_self":true,"instant":false,"mode_selection":"all_components","recursion_components":[{"count":1,"destination":"hand","target":"artifact","target_constraints":{"card_types":["artifact"],"controller":"self","zone":"graveyard"},"target_controller":"self","up_to_count":true},{"count":1,"destination":"hand","target":"enchantment","target_constraints":{"card_types":["enchantment"],"controller":"self","zone":"graveyard"},"target_controller":"self","up_to_count":true},{"count":1,"destination":"hand","target":"instant","target_constraints":{"card_types":["instant"],"controller":"self","zone":"graveyard"},"target_controller":"self","up_to_count":true},{"count":1,"destination":"hand","target":"sorcery","target_constraints":{"card_types":["sorcery"],"controller":"self","zone":"graveyard"},"target_controller":"self","up_to_count":true},{"count":1,"destination":"hand","target":"planeswalker","target_constraints":{"card_types":["planeswalker"],"controller":"self","zone":"graveyard"},"target_controller":"self","up_to_count":true}],"sorcery":true,"target_controller":"self","xmage_additional_effect_class":"ExileSpellEffect","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ReconstructHistory translated into ManaLoom runtime scope xmage_return_multiple_graveyard_cards_to_hand_exile_self_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('retrieve', 'Retrieve', '18bc4cc44ffd6382912e0c7fe24e7335', 'battle_rule_v1:3fb7ce15a27a11482bfeb0a35cc5e088', '{"battle_model_scope":"xmage_return_multiple_graveyard_cards_to_hand_exile_self_spell_v1","destination":"hand","effect":"recursion","exiles_self":true,"instant":false,"mode_selection":"all_components","recursion_components":[{"count":1,"destination":"hand","target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","up_to_count":true},{"count":1,"destination":"hand","target":"noncreature_permanent","target_constraints":{"card_types":["artifact","enchantment","planeswalker","battle","land"],"controller":"self","exclude_card_types":["creature"],"zone":"graveyard"},"target_controller":"self","up_to_count":true}],"sorcery":true,"target_controller":"self","xmage_additional_effect_class":"ExileSpellEffect","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Retrieve translated into ManaLoom runtime scope xmage_return_multiple_graveyard_cards_to_hand_exile_self_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vivid revival', 'Vivid Revival', '9f4629b135cb2888979404fca4a71cea', 'battle_rule_v1:0eaec04572207c2751454d4b4793493b', '{"battle_model_scope":"xmage_return_target_graveyard_card_to_hand_spell_v1","count":3,"destination":"hand","effect":"recursion","exiles_self":true,"instant":false,"sorcery":true,"target":"multicolored_card","target_constraints":{"controller":"self","min_colors":2,"zone":"graveyard"},"target_controller":"self","up_to_count":true,"xmage_additional_effect_class":"ExileSpellEffect","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"multicolored_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VividRevival translated into ManaLoom runtime scope xmage_return_target_graveyard_card_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
