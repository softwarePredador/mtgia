BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg328_xmage_recursion_choose_one_wave_20260701_201656 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('ghoulcaller''s chant', 'march of the drowned', 'raise the draugr', 'return from extinction', 'unbury')
   OR normalized_name LIKE 'ghoulcaller''s chant // %'
   OR normalized_name LIKE 'march of the drowned // %'
   OR normalized_name LIKE 'raise the draugr // %'
   OR normalized_name LIKE 'return from extinction // %'
   OR normalized_name LIKE 'unbury // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('ghoulcaller''s chant', 'Ghoulcaller''s Chant', '4535ec92f19844162f8fe290541ca60e', 'battle_rule_v1:ed71ecbf3fdf66b1cdb2d10aad9d3e65', '{"battle_model_scope":"xmage_return_choose_one_graveyard_cards_to_hand_spell_v1","destination":"hand","effect":"recursion","instant":false,"mode_selection":"choose_one","recursion_components":[{"count":1,"destination":"hand","target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self"},{"count":2,"destination":"hand","target":"zombie_card","target_constraints":{"controller":"self","subtypes":["zombie"],"zone":"graveyard"},"target_controller":"self"}],"sorcery":true,"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GhoulcallersChant translated into ManaLoom runtime scope xmage_return_choose_one_graveyard_cards_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('march of the drowned', 'March of the Drowned', 'b4c57cf5a15caa2681270c5be311e823', 'battle_rule_v1:f0469a979771629fdf4c130ecd40d7ec', '{"battle_model_scope":"xmage_return_choose_one_graveyard_cards_to_hand_spell_v1","destination":"hand","effect":"recursion","instant":false,"mode_selection":"choose_one","recursion_components":[{"count":1,"destination":"hand","target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self"},{"count":2,"destination":"hand","target":"pirate_card","target_constraints":{"controller":"self","subtypes":["pirate"],"zone":"graveyard"},"target_controller":"self"}],"sorcery":true,"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MarchOfTheDrowned translated into ManaLoom runtime scope xmage_return_choose_one_graveyard_cards_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('raise the draugr', 'Raise the Draugr', '73ce0d42ea21a297e8bd61883f32e49d', 'battle_rule_v1:198e31e470f83b580481d825befa6ba0', '{"battle_model_scope":"xmage_return_choose_one_graveyard_cards_to_hand_spell_v1","destination":"hand","effect":"recursion","instant":true,"mode_selection":"choose_one","recursion_components":[{"count":1,"destination":"hand","target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self"},{"count":2,"destination":"hand","shared_subtype_group":"creature_type","target":"shared_creature_type","target_constraints":{"card_types":["creature"],"controller":"self","shared_subtype_group":"creature_type","zone":"graveyard"},"target_controller":"self"}],"sorcery":false,"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RaiseTheDraugr translated into ManaLoom runtime scope xmage_return_choose_one_graveyard_cards_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('return from extinction', 'Return from Extinction', '73ce0d42ea21a297e8bd61883f32e49d', 'battle_rule_v1:863ee7c378baeeb09ce204afdfa84d11', '{"battle_model_scope":"xmage_return_choose_one_graveyard_cards_to_hand_spell_v1","destination":"hand","effect":"recursion","instant":false,"mode_selection":"choose_one","recursion_components":[{"count":1,"destination":"hand","target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self"},{"count":2,"destination":"hand","shared_subtype_group":"creature_type","target":"shared_creature_type","target_constraints":{"card_types":["creature"],"controller":"self","shared_subtype_group":"creature_type","zone":"graveyard"},"target_controller":"self"}],"sorcery":true,"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ReturnFromExtinction translated into ManaLoom runtime scope xmage_return_choose_one_graveyard_cards_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('unbury', 'Unbury', '73ce0d42ea21a297e8bd61883f32e49d', 'battle_rule_v1:198e31e470f83b580481d825befa6ba0', '{"battle_model_scope":"xmage_return_choose_one_graveyard_cards_to_hand_spell_v1","destination":"hand","effect":"recursion","instant":true,"mode_selection":"choose_one","recursion_components":[{"count":1,"destination":"hand","target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self"},{"count":2,"destination":"hand","shared_subtype_group":"creature_type","target":"shared_creature_type","target_constraints":{"card_types":["creature"],"controller":"self","shared_subtype_group":"creature_type","zone":"graveyard"},"target_controller":"self"}],"sorcery":false,"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Unbury translated into ManaLoom runtime scope xmage_return_choose_one_graveyard_cards_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('ghoulcaller''s chant', 'Ghoulcaller''s Chant', '4535ec92f19844162f8fe290541ca60e', 'battle_rule_v1:ed71ecbf3fdf66b1cdb2d10aad9d3e65', '{"battle_model_scope":"xmage_return_choose_one_graveyard_cards_to_hand_spell_v1","destination":"hand","effect":"recursion","instant":false,"mode_selection":"choose_one","recursion_components":[{"count":1,"destination":"hand","target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self"},{"count":2,"destination":"hand","target":"zombie_card","target_constraints":{"controller":"self","subtypes":["zombie"],"zone":"graveyard"},"target_controller":"self"}],"sorcery":true,"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GhoulcallersChant translated into ManaLoom runtime scope xmage_return_choose_one_graveyard_cards_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('march of the drowned', 'March of the Drowned', 'b4c57cf5a15caa2681270c5be311e823', 'battle_rule_v1:f0469a979771629fdf4c130ecd40d7ec', '{"battle_model_scope":"xmage_return_choose_one_graveyard_cards_to_hand_spell_v1","destination":"hand","effect":"recursion","instant":false,"mode_selection":"choose_one","recursion_components":[{"count":1,"destination":"hand","target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self"},{"count":2,"destination":"hand","target":"pirate_card","target_constraints":{"controller":"self","subtypes":["pirate"],"zone":"graveyard"},"target_controller":"self"}],"sorcery":true,"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MarchOfTheDrowned translated into ManaLoom runtime scope xmage_return_choose_one_graveyard_cards_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('raise the draugr', 'Raise the Draugr', '73ce0d42ea21a297e8bd61883f32e49d', 'battle_rule_v1:198e31e470f83b580481d825befa6ba0', '{"battle_model_scope":"xmage_return_choose_one_graveyard_cards_to_hand_spell_v1","destination":"hand","effect":"recursion","instant":true,"mode_selection":"choose_one","recursion_components":[{"count":1,"destination":"hand","target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self"},{"count":2,"destination":"hand","shared_subtype_group":"creature_type","target":"shared_creature_type","target_constraints":{"card_types":["creature"],"controller":"self","shared_subtype_group":"creature_type","zone":"graveyard"},"target_controller":"self"}],"sorcery":false,"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RaiseTheDraugr translated into ManaLoom runtime scope xmage_return_choose_one_graveyard_cards_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('return from extinction', 'Return from Extinction', '73ce0d42ea21a297e8bd61883f32e49d', 'battle_rule_v1:863ee7c378baeeb09ce204afdfa84d11', '{"battle_model_scope":"xmage_return_choose_one_graveyard_cards_to_hand_spell_v1","destination":"hand","effect":"recursion","instant":false,"mode_selection":"choose_one","recursion_components":[{"count":1,"destination":"hand","target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self"},{"count":2,"destination":"hand","shared_subtype_group":"creature_type","target":"shared_creature_type","target_constraints":{"card_types":["creature"],"controller":"self","shared_subtype_group":"creature_type","zone":"graveyard"},"target_controller":"self"}],"sorcery":true,"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ReturnFromExtinction translated into ManaLoom runtime scope xmage_return_choose_one_graveyard_cards_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('unbury', 'Unbury', '73ce0d42ea21a297e8bd61883f32e49d', 'battle_rule_v1:198e31e470f83b580481d825befa6ba0', '{"battle_model_scope":"xmage_return_choose_one_graveyard_cards_to_hand_spell_v1","destination":"hand","effect":"recursion","instant":true,"mode_selection":"choose_one","recursion_components":[{"count":1,"destination":"hand","target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self"},{"count":2,"destination":"hand","shared_subtype_group":"creature_type","target":"shared_creature_type","target_constraints":{"card_types":["creature"],"controller":"self","shared_subtype_group":"creature_type","zone":"graveyard"},"target_controller":"self"}],"sorcery":false,"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Unbury translated into ManaLoom runtime scope xmage_return_choose_one_graveyard_cards_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('ghoulcaller''s chant', 'Ghoulcaller''s Chant', '4535ec92f19844162f8fe290541ca60e', 'battle_rule_v1:ed71ecbf3fdf66b1cdb2d10aad9d3e65', '{"battle_model_scope":"xmage_return_choose_one_graveyard_cards_to_hand_spell_v1","destination":"hand","effect":"recursion","instant":false,"mode_selection":"choose_one","recursion_components":[{"count":1,"destination":"hand","target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self"},{"count":2,"destination":"hand","target":"zombie_card","target_constraints":{"controller":"self","subtypes":["zombie"],"zone":"graveyard"},"target_controller":"self"}],"sorcery":true,"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GhoulcallersChant translated into ManaLoom runtime scope xmage_return_choose_one_graveyard_cards_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('march of the drowned', 'March of the Drowned', 'b4c57cf5a15caa2681270c5be311e823', 'battle_rule_v1:f0469a979771629fdf4c130ecd40d7ec', '{"battle_model_scope":"xmage_return_choose_one_graveyard_cards_to_hand_spell_v1","destination":"hand","effect":"recursion","instant":false,"mode_selection":"choose_one","recursion_components":[{"count":1,"destination":"hand","target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self"},{"count":2,"destination":"hand","target":"pirate_card","target_constraints":{"controller":"self","subtypes":["pirate"],"zone":"graveyard"},"target_controller":"self"}],"sorcery":true,"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MarchOfTheDrowned translated into ManaLoom runtime scope xmage_return_choose_one_graveyard_cards_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('raise the draugr', 'Raise the Draugr', '73ce0d42ea21a297e8bd61883f32e49d', 'battle_rule_v1:198e31e470f83b580481d825befa6ba0', '{"battle_model_scope":"xmage_return_choose_one_graveyard_cards_to_hand_spell_v1","destination":"hand","effect":"recursion","instant":true,"mode_selection":"choose_one","recursion_components":[{"count":1,"destination":"hand","target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self"},{"count":2,"destination":"hand","shared_subtype_group":"creature_type","target":"shared_creature_type","target_constraints":{"card_types":["creature"],"controller":"self","shared_subtype_group":"creature_type","zone":"graveyard"},"target_controller":"self"}],"sorcery":false,"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RaiseTheDraugr translated into ManaLoom runtime scope xmage_return_choose_one_graveyard_cards_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('return from extinction', 'Return from Extinction', '73ce0d42ea21a297e8bd61883f32e49d', 'battle_rule_v1:863ee7c378baeeb09ce204afdfa84d11', '{"battle_model_scope":"xmage_return_choose_one_graveyard_cards_to_hand_spell_v1","destination":"hand","effect":"recursion","instant":false,"mode_selection":"choose_one","recursion_components":[{"count":1,"destination":"hand","target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self"},{"count":2,"destination":"hand","shared_subtype_group":"creature_type","target":"shared_creature_type","target_constraints":{"card_types":["creature"],"controller":"self","shared_subtype_group":"creature_type","zone":"graveyard"},"target_controller":"self"}],"sorcery":true,"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ReturnFromExtinction translated into ManaLoom runtime scope xmage_return_choose_one_graveyard_cards_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('unbury', 'Unbury', '73ce0d42ea21a297e8bd61883f32e49d', 'battle_rule_v1:198e31e470f83b580481d825befa6ba0', '{"battle_model_scope":"xmage_return_choose_one_graveyard_cards_to_hand_spell_v1","destination":"hand","effect":"recursion","instant":true,"mode_selection":"choose_one","recursion_components":[{"count":1,"destination":"hand","target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self"},{"count":2,"destination":"hand","shared_subtype_group":"creature_type","target":"shared_creature_type","target_constraints":{"card_types":["creature"],"controller":"self","shared_subtype_group":"creature_type","zone":"graveyard"},"target_controller":"self"}],"sorcery":false,"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Unbury translated into ManaLoom runtime scope xmage_return_choose_one_graveyard_cards_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
