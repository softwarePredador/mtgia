BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg578_look_library_graveyard_new_server_20260706_225325 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('forbidden alchemy', 'nagging thoughts', 'resentful revelation', 'tapping at the window')
   OR normalized_name LIKE 'forbidden alchemy // %'
   OR normalized_name LIKE 'nagging thoughts // %'
   OR normalized_name LIKE 'resentful revelation // %'
   OR normalized_name LIKE 'tapping at the window // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('forbidden alchemy', 'Forbidden Alchemy', '4800d22353040527a3f8a9ddaaa3529f', 'battle_rule_v1:e285a4ed5ba76a8a0a9def976a43b0a0', '{"battle_model_scope":"xmage_look_library_pick_to_hand_rest_graveyard_spell_v1","count":1,"destination":"hand","effect":"dig_to_hand","instant":true,"look_count":4,"max_count":1,"pick_all_matching":false,"pick_count":1,"pick_target":"any_card","pick_up_to_count":false,"rest_destination":"graveyard","reveal":false,"sorcery":false,"target":"any_card","target_constraints":{"controller":"self","scope":"any_card","zone":"library"},"xmage_effect_class":"LookLibraryAndPickControllerEffect"}'::jsonb, '{"category":"draw","effect":"dig_to_hand","target":"any_card","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ForbiddenAlchemy translated into ManaLoom runtime scope xmage_look_library_pick_to_hand_rest_graveyard_spell_v1. This row is package-ready only because the source signature is a narrow fixed look-at-library pick-to-hand spell with rest in graveyard with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('nagging thoughts', 'Nagging Thoughts', 'd750ade2afb400a96ed4d09a6de448ed', 'battle_rule_v1:0c0c6b5f5d6ac1b30757c2c3d4794c24', '{"battle_model_scope":"xmage_look_library_pick_to_hand_rest_graveyard_spell_v1","count":1,"destination":"hand","effect":"dig_to_hand","instant":false,"look_count":2,"max_count":1,"pick_all_matching":false,"pick_count":1,"pick_target":"any_card","pick_up_to_count":false,"rest_destination":"graveyard","reveal":false,"sorcery":true,"target":"any_card","target_constraints":{"controller":"self","scope":"any_card","zone":"library"},"xmage_effect_class":"LookLibraryAndPickControllerEffect"}'::jsonb, '{"category":"draw","effect":"dig_to_hand","target":"any_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NaggingThoughts translated into ManaLoom runtime scope xmage_look_library_pick_to_hand_rest_graveyard_spell_v1. This row is package-ready only because the source signature is a narrow fixed look-at-library pick-to-hand spell with rest in graveyard with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('resentful revelation', 'Resentful Revelation', 'c0c873de2a6cb009f2bb3f0e304d6805', 'battle_rule_v1:818eec9a981f612634bc818b78997e22', '{"battle_model_scope":"xmage_look_library_pick_to_hand_rest_graveyard_spell_v1","count":1,"destination":"hand","effect":"dig_to_hand","instant":false,"look_count":3,"max_count":1,"pick_all_matching":false,"pick_count":1,"pick_target":"any_card","pick_up_to_count":false,"rest_destination":"graveyard","reveal":false,"sorcery":true,"target":"any_card","target_constraints":{"controller":"self","scope":"any_card","zone":"library"},"xmage_effect_class":"LookLibraryAndPickControllerEffect"}'::jsonb, '{"category":"draw","effect":"dig_to_hand","target":"any_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ResentfulRevelation translated into ManaLoom runtime scope xmage_look_library_pick_to_hand_rest_graveyard_spell_v1. This row is package-ready only because the source signature is a narrow fixed look-at-library pick-to-hand spell with rest in graveyard with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tapping at the window', 'Tapping at the Window', 'c85b98ff679c3eac0187834661613f50', 'battle_rule_v1:f81c5a7e4a1474b2f585b16efca99840', '{"battle_model_scope":"xmage_look_library_pick_to_hand_rest_graveyard_spell_v1","count":1,"destination":"hand","effect":"dig_to_hand","instant":false,"look_count":3,"max_count":1,"pick_all_matching":false,"pick_count":1,"pick_target":"creature","pick_up_to_count":true,"rest_destination":"graveyard","reveal":true,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"library"},"xmage_effect_class":"LookLibraryAndPickControllerEffect"}'::jsonb, '{"category":"draw","effect":"dig_to_hand","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TappingAtTheWindow translated into ManaLoom runtime scope xmage_look_library_pick_to_hand_rest_graveyard_spell_v1. This row is package-ready only because the source signature is a narrow fixed look-at-library pick-to-hand spell with rest in graveyard with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('forbidden alchemy', 'Forbidden Alchemy', '4800d22353040527a3f8a9ddaaa3529f', 'battle_rule_v1:e285a4ed5ba76a8a0a9def976a43b0a0', '{"battle_model_scope":"xmage_look_library_pick_to_hand_rest_graveyard_spell_v1","count":1,"destination":"hand","effect":"dig_to_hand","instant":true,"look_count":4,"max_count":1,"pick_all_matching":false,"pick_count":1,"pick_target":"any_card","pick_up_to_count":false,"rest_destination":"graveyard","reveal":false,"sorcery":false,"target":"any_card","target_constraints":{"controller":"self","scope":"any_card","zone":"library"},"xmage_effect_class":"LookLibraryAndPickControllerEffect"}'::jsonb, '{"category":"draw","effect":"dig_to_hand","target":"any_card","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ForbiddenAlchemy translated into ManaLoom runtime scope xmage_look_library_pick_to_hand_rest_graveyard_spell_v1. This row is package-ready only because the source signature is a narrow fixed look-at-library pick-to-hand spell with rest in graveyard with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('nagging thoughts', 'Nagging Thoughts', 'd750ade2afb400a96ed4d09a6de448ed', 'battle_rule_v1:0c0c6b5f5d6ac1b30757c2c3d4794c24', '{"battle_model_scope":"xmage_look_library_pick_to_hand_rest_graveyard_spell_v1","count":1,"destination":"hand","effect":"dig_to_hand","instant":false,"look_count":2,"max_count":1,"pick_all_matching":false,"pick_count":1,"pick_target":"any_card","pick_up_to_count":false,"rest_destination":"graveyard","reveal":false,"sorcery":true,"target":"any_card","target_constraints":{"controller":"self","scope":"any_card","zone":"library"},"xmage_effect_class":"LookLibraryAndPickControllerEffect"}'::jsonb, '{"category":"draw","effect":"dig_to_hand","target":"any_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NaggingThoughts translated into ManaLoom runtime scope xmage_look_library_pick_to_hand_rest_graveyard_spell_v1. This row is package-ready only because the source signature is a narrow fixed look-at-library pick-to-hand spell with rest in graveyard with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('resentful revelation', 'Resentful Revelation', 'c0c873de2a6cb009f2bb3f0e304d6805', 'battle_rule_v1:818eec9a981f612634bc818b78997e22', '{"battle_model_scope":"xmage_look_library_pick_to_hand_rest_graveyard_spell_v1","count":1,"destination":"hand","effect":"dig_to_hand","instant":false,"look_count":3,"max_count":1,"pick_all_matching":false,"pick_count":1,"pick_target":"any_card","pick_up_to_count":false,"rest_destination":"graveyard","reveal":false,"sorcery":true,"target":"any_card","target_constraints":{"controller":"self","scope":"any_card","zone":"library"},"xmage_effect_class":"LookLibraryAndPickControllerEffect"}'::jsonb, '{"category":"draw","effect":"dig_to_hand","target":"any_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ResentfulRevelation translated into ManaLoom runtime scope xmage_look_library_pick_to_hand_rest_graveyard_spell_v1. This row is package-ready only because the source signature is a narrow fixed look-at-library pick-to-hand spell with rest in graveyard with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tapping at the window', 'Tapping at the Window', 'c85b98ff679c3eac0187834661613f50', 'battle_rule_v1:f81c5a7e4a1474b2f585b16efca99840', '{"battle_model_scope":"xmage_look_library_pick_to_hand_rest_graveyard_spell_v1","count":1,"destination":"hand","effect":"dig_to_hand","instant":false,"look_count":3,"max_count":1,"pick_all_matching":false,"pick_count":1,"pick_target":"creature","pick_up_to_count":true,"rest_destination":"graveyard","reveal":true,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"library"},"xmage_effect_class":"LookLibraryAndPickControllerEffect"}'::jsonb, '{"category":"draw","effect":"dig_to_hand","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TappingAtTheWindow translated into ManaLoom runtime scope xmage_look_library_pick_to_hand_rest_graveyard_spell_v1. This row is package-ready only because the source signature is a narrow fixed look-at-library pick-to-hand spell with rest in graveyard with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('forbidden alchemy', 'Forbidden Alchemy', '4800d22353040527a3f8a9ddaaa3529f', 'battle_rule_v1:e285a4ed5ba76a8a0a9def976a43b0a0', '{"battle_model_scope":"xmage_look_library_pick_to_hand_rest_graveyard_spell_v1","count":1,"destination":"hand","effect":"dig_to_hand","instant":true,"look_count":4,"max_count":1,"pick_all_matching":false,"pick_count":1,"pick_target":"any_card","pick_up_to_count":false,"rest_destination":"graveyard","reveal":false,"sorcery":false,"target":"any_card","target_constraints":{"controller":"self","scope":"any_card","zone":"library"},"xmage_effect_class":"LookLibraryAndPickControllerEffect"}'::jsonb, '{"category":"draw","effect":"dig_to_hand","target":"any_card","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ForbiddenAlchemy translated into ManaLoom runtime scope xmage_look_library_pick_to_hand_rest_graveyard_spell_v1. This row is package-ready only because the source signature is a narrow fixed look-at-library pick-to-hand spell with rest in graveyard with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('nagging thoughts', 'Nagging Thoughts', 'd750ade2afb400a96ed4d09a6de448ed', 'battle_rule_v1:0c0c6b5f5d6ac1b30757c2c3d4794c24', '{"battle_model_scope":"xmage_look_library_pick_to_hand_rest_graveyard_spell_v1","count":1,"destination":"hand","effect":"dig_to_hand","instant":false,"look_count":2,"max_count":1,"pick_all_matching":false,"pick_count":1,"pick_target":"any_card","pick_up_to_count":false,"rest_destination":"graveyard","reveal":false,"sorcery":true,"target":"any_card","target_constraints":{"controller":"self","scope":"any_card","zone":"library"},"xmage_effect_class":"LookLibraryAndPickControllerEffect"}'::jsonb, '{"category":"draw","effect":"dig_to_hand","target":"any_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NaggingThoughts translated into ManaLoom runtime scope xmage_look_library_pick_to_hand_rest_graveyard_spell_v1. This row is package-ready only because the source signature is a narrow fixed look-at-library pick-to-hand spell with rest in graveyard with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('resentful revelation', 'Resentful Revelation', 'c0c873de2a6cb009f2bb3f0e304d6805', 'battle_rule_v1:818eec9a981f612634bc818b78997e22', '{"battle_model_scope":"xmage_look_library_pick_to_hand_rest_graveyard_spell_v1","count":1,"destination":"hand","effect":"dig_to_hand","instant":false,"look_count":3,"max_count":1,"pick_all_matching":false,"pick_count":1,"pick_target":"any_card","pick_up_to_count":false,"rest_destination":"graveyard","reveal":false,"sorcery":true,"target":"any_card","target_constraints":{"controller":"self","scope":"any_card","zone":"library"},"xmage_effect_class":"LookLibraryAndPickControllerEffect"}'::jsonb, '{"category":"draw","effect":"dig_to_hand","target":"any_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ResentfulRevelation translated into ManaLoom runtime scope xmage_look_library_pick_to_hand_rest_graveyard_spell_v1. This row is package-ready only because the source signature is a narrow fixed look-at-library pick-to-hand spell with rest in graveyard with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tapping at the window', 'Tapping at the Window', 'c85b98ff679c3eac0187834661613f50', 'battle_rule_v1:f81c5a7e4a1474b2f585b16efca99840', '{"battle_model_scope":"xmage_look_library_pick_to_hand_rest_graveyard_spell_v1","count":1,"destination":"hand","effect":"dig_to_hand","instant":false,"look_count":3,"max_count":1,"pick_all_matching":false,"pick_count":1,"pick_target":"creature","pick_up_to_count":true,"rest_destination":"graveyard","reveal":true,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"library"},"xmage_effect_class":"LookLibraryAndPickControllerEffect"}'::jsonb, '{"category":"draw","effect":"dig_to_hand","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TappingAtTheWindow translated into ManaLoom runtime scope xmage_look_library_pick_to_hand_rest_graveyard_spell_v1. This row is package-ready only because the source signature is a narrow fixed look-at-library pick-to-hand spell with rest in graveyard with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
