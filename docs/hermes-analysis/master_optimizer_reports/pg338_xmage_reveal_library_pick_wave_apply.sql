BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg338_xmage_reveal_library_pick_wave_pg338_xmage_reveal_ AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('commune with the gods', 'glacial revelation', 'grisly salvage', 'kruphix''s insight', 'pieces of the puzzle', 'scout the borders')
   OR normalized_name LIKE 'commune with the gods // %'
   OR normalized_name LIKE 'glacial revelation // %'
   OR normalized_name LIKE 'grisly salvage // %'
   OR normalized_name LIKE 'kruphix''s insight // %'
   OR normalized_name LIKE 'pieces of the puzzle // %'
   OR normalized_name LIKE 'scout the borders // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('commune with the gods', 'Commune with the Gods', '6d7ce4016bfce500247badd42e1fbf9a', 'battle_rule_v1:dee33e0d21b42f1d5133090250212c7f', '{"battle_model_scope":"xmage_reveal_top_library_pick_to_hand_rest_graveyard_spell_v1","count":1,"destination":"hand","effect":"dig_to_hand","instant":false,"look_count":5,"max_count":1,"pick_all_matching":false,"pick_count":1,"pick_target":"creature_or_enchantment","pick_up_to_count":true,"rest_destination":"graveyard","reveal":true,"sorcery":true,"target":"creature_or_enchantment","target_constraints":{"card_types":["creature","enchantment"],"controller":"self","zone":"library"},"xmage_effect_class":"RevealLibraryPickControllerEffect"}'::jsonb, '{"category":"draw","effect":"dig_to_hand","target":"creature_or_enchantment"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CommuneWithTheGods translated into ManaLoom runtime scope xmage_reveal_top_library_pick_to_hand_rest_graveyard_spell_v1. This row is package-ready only because the source signature is a narrow fixed reveal-top-library pick-to-hand spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('glacial revelation', 'Glacial Revelation', 'a52b48afaaa84dbc14c2e0ab196edb78', 'battle_rule_v1:96532e985cb2d1a3673024caef9269b3', '{"battle_model_scope":"xmage_reveal_top_library_pick_to_hand_rest_graveyard_spell_v1","count":6,"destination":"hand","effect":"dig_to_hand","instant":false,"look_count":6,"max_count":6,"pick_all_matching":true,"pick_count":6,"pick_target":"snow_permanent","pick_up_to_count":true,"rest_destination":"graveyard","reveal":true,"sorcery":true,"target":"snow_permanent","target_constraints":{"card_types":["artifact","creature","enchantment","planeswalker","battle","land"],"controller":"self","supertypes":["snow"],"zone":"library"},"xmage_effect_class":"RevealLibraryPickControllerEffect"}'::jsonb, '{"category":"draw","effect":"dig_to_hand","target":"snow_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GlacialRevelation translated into ManaLoom runtime scope xmage_reveal_top_library_pick_to_hand_rest_graveyard_spell_v1. This row is package-ready only because the source signature is a narrow fixed reveal-top-library pick-to-hand spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('grisly salvage', 'Grisly Salvage', '522a2aca336e4812e880cb700b936c4c', 'battle_rule_v1:2ca4973baa031b2e1d7c68c1a7a8b7cc', '{"battle_model_scope":"xmage_reveal_top_library_pick_to_hand_rest_graveyard_spell_v1","count":1,"destination":"hand","effect":"dig_to_hand","instant":true,"look_count":5,"max_count":1,"pick_all_matching":false,"pick_count":1,"pick_target":"creature_or_land","pick_up_to_count":true,"rest_destination":"graveyard","reveal":true,"sorcery":false,"target":"creature_or_land","target_constraints":{"card_types":["creature","land"],"controller":"self","zone":"library"},"xmage_effect_class":"RevealLibraryPickControllerEffect"}'::jsonb, '{"category":"draw","effect":"dig_to_hand","target":"creature_or_land","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GrislySalvage translated into ManaLoom runtime scope xmage_reveal_top_library_pick_to_hand_rest_graveyard_spell_v1. This row is package-ready only because the source signature is a narrow fixed reveal-top-library pick-to-hand spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kruphix''s insight', 'Kruphix''s Insight', '84bc958dbae0f32d686301e44ad75930', 'battle_rule_v1:732b2144450d7b4be404ba0f023e3465', '{"battle_model_scope":"xmage_reveal_top_library_pick_to_hand_rest_graveyard_spell_v1","count":3,"destination":"hand","effect":"dig_to_hand","instant":false,"look_count":6,"max_count":3,"pick_all_matching":false,"pick_count":3,"pick_target":"enchantment","pick_up_to_count":true,"rest_destination":"graveyard","reveal":true,"sorcery":true,"target":"enchantment","target_constraints":{"card_types":["enchantment"],"controller":"self","zone":"library"},"xmage_effect_class":"RevealLibraryPickControllerEffect"}'::jsonb, '{"category":"draw","effect":"dig_to_hand","target":"enchantment"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KruphixsInsight translated into ManaLoom runtime scope xmage_reveal_top_library_pick_to_hand_rest_graveyard_spell_v1. This row is package-ready only because the source signature is a narrow fixed reveal-top-library pick-to-hand spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pieces of the puzzle', 'Pieces of the Puzzle', '268daefa60fcde1c979fd668541d8970', 'battle_rule_v1:17c94b3a53e5d4898d2bae7e0270fb00', '{"battle_model_scope":"xmage_reveal_top_library_pick_to_hand_rest_graveyard_spell_v1","count":2,"destination":"hand","effect":"dig_to_hand","instant":false,"look_count":5,"max_count":2,"pick_all_matching":false,"pick_count":2,"pick_target":"instant_or_sorcery","pick_up_to_count":true,"rest_destination":"graveyard","reveal":true,"sorcery":true,"target":"instant_or_sorcery","target_constraints":{"card_types":["instant","sorcery"],"controller":"self","zone":"library"},"xmage_effect_class":"RevealLibraryPickControllerEffect"}'::jsonb, '{"category":"draw","effect":"dig_to_hand","target":"instant_or_sorcery"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PiecesOfThePuzzle translated into ManaLoom runtime scope xmage_reveal_top_library_pick_to_hand_rest_graveyard_spell_v1. This row is package-ready only because the source signature is a narrow fixed reveal-top-library pick-to-hand spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('scout the borders', 'Scout the Borders', '522a2aca336e4812e880cb700b936c4c', 'battle_rule_v1:edbce89b4e5ec35359ceb44c67366492', '{"battle_model_scope":"xmage_reveal_top_library_pick_to_hand_rest_graveyard_spell_v1","count":1,"destination":"hand","effect":"dig_to_hand","instant":false,"look_count":5,"max_count":1,"pick_all_matching":false,"pick_count":1,"pick_target":"creature_or_land","pick_up_to_count":true,"rest_destination":"graveyard","reveal":true,"sorcery":true,"target":"creature_or_land","target_constraints":{"card_types":["creature","land"],"controller":"self","zone":"library"},"xmage_effect_class":"RevealLibraryPickControllerEffect"}'::jsonb, '{"category":"draw","effect":"dig_to_hand","target":"creature_or_land"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ScoutTheBorders translated into ManaLoom runtime scope xmage_reveal_top_library_pick_to_hand_rest_graveyard_spell_v1. This row is package-ready only because the source signature is a narrow fixed reveal-top-library pick-to-hand spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('commune with the gods', 'Commune with the Gods', '6d7ce4016bfce500247badd42e1fbf9a', 'battle_rule_v1:dee33e0d21b42f1d5133090250212c7f', '{"battle_model_scope":"xmage_reveal_top_library_pick_to_hand_rest_graveyard_spell_v1","count":1,"destination":"hand","effect":"dig_to_hand","instant":false,"look_count":5,"max_count":1,"pick_all_matching":false,"pick_count":1,"pick_target":"creature_or_enchantment","pick_up_to_count":true,"rest_destination":"graveyard","reveal":true,"sorcery":true,"target":"creature_or_enchantment","target_constraints":{"card_types":["creature","enchantment"],"controller":"self","zone":"library"},"xmage_effect_class":"RevealLibraryPickControllerEffect"}'::jsonb, '{"category":"draw","effect":"dig_to_hand","target":"creature_or_enchantment"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CommuneWithTheGods translated into ManaLoom runtime scope xmage_reveal_top_library_pick_to_hand_rest_graveyard_spell_v1. This row is package-ready only because the source signature is a narrow fixed reveal-top-library pick-to-hand spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('glacial revelation', 'Glacial Revelation', 'a52b48afaaa84dbc14c2e0ab196edb78', 'battle_rule_v1:96532e985cb2d1a3673024caef9269b3', '{"battle_model_scope":"xmage_reveal_top_library_pick_to_hand_rest_graveyard_spell_v1","count":6,"destination":"hand","effect":"dig_to_hand","instant":false,"look_count":6,"max_count":6,"pick_all_matching":true,"pick_count":6,"pick_target":"snow_permanent","pick_up_to_count":true,"rest_destination":"graveyard","reveal":true,"sorcery":true,"target":"snow_permanent","target_constraints":{"card_types":["artifact","creature","enchantment","planeswalker","battle","land"],"controller":"self","supertypes":["snow"],"zone":"library"},"xmage_effect_class":"RevealLibraryPickControllerEffect"}'::jsonb, '{"category":"draw","effect":"dig_to_hand","target":"snow_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GlacialRevelation translated into ManaLoom runtime scope xmage_reveal_top_library_pick_to_hand_rest_graveyard_spell_v1. This row is package-ready only because the source signature is a narrow fixed reveal-top-library pick-to-hand spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('grisly salvage', 'Grisly Salvage', '522a2aca336e4812e880cb700b936c4c', 'battle_rule_v1:2ca4973baa031b2e1d7c68c1a7a8b7cc', '{"battle_model_scope":"xmage_reveal_top_library_pick_to_hand_rest_graveyard_spell_v1","count":1,"destination":"hand","effect":"dig_to_hand","instant":true,"look_count":5,"max_count":1,"pick_all_matching":false,"pick_count":1,"pick_target":"creature_or_land","pick_up_to_count":true,"rest_destination":"graveyard","reveal":true,"sorcery":false,"target":"creature_or_land","target_constraints":{"card_types":["creature","land"],"controller":"self","zone":"library"},"xmage_effect_class":"RevealLibraryPickControllerEffect"}'::jsonb, '{"category":"draw","effect":"dig_to_hand","target":"creature_or_land","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GrislySalvage translated into ManaLoom runtime scope xmage_reveal_top_library_pick_to_hand_rest_graveyard_spell_v1. This row is package-ready only because the source signature is a narrow fixed reveal-top-library pick-to-hand spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kruphix''s insight', 'Kruphix''s Insight', '84bc958dbae0f32d686301e44ad75930', 'battle_rule_v1:732b2144450d7b4be404ba0f023e3465', '{"battle_model_scope":"xmage_reveal_top_library_pick_to_hand_rest_graveyard_spell_v1","count":3,"destination":"hand","effect":"dig_to_hand","instant":false,"look_count":6,"max_count":3,"pick_all_matching":false,"pick_count":3,"pick_target":"enchantment","pick_up_to_count":true,"rest_destination":"graveyard","reveal":true,"sorcery":true,"target":"enchantment","target_constraints":{"card_types":["enchantment"],"controller":"self","zone":"library"},"xmage_effect_class":"RevealLibraryPickControllerEffect"}'::jsonb, '{"category":"draw","effect":"dig_to_hand","target":"enchantment"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KruphixsInsight translated into ManaLoom runtime scope xmage_reveal_top_library_pick_to_hand_rest_graveyard_spell_v1. This row is package-ready only because the source signature is a narrow fixed reveal-top-library pick-to-hand spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pieces of the puzzle', 'Pieces of the Puzzle', '268daefa60fcde1c979fd668541d8970', 'battle_rule_v1:17c94b3a53e5d4898d2bae7e0270fb00', '{"battle_model_scope":"xmage_reveal_top_library_pick_to_hand_rest_graveyard_spell_v1","count":2,"destination":"hand","effect":"dig_to_hand","instant":false,"look_count":5,"max_count":2,"pick_all_matching":false,"pick_count":2,"pick_target":"instant_or_sorcery","pick_up_to_count":true,"rest_destination":"graveyard","reveal":true,"sorcery":true,"target":"instant_or_sorcery","target_constraints":{"card_types":["instant","sorcery"],"controller":"self","zone":"library"},"xmage_effect_class":"RevealLibraryPickControllerEffect"}'::jsonb, '{"category":"draw","effect":"dig_to_hand","target":"instant_or_sorcery"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PiecesOfThePuzzle translated into ManaLoom runtime scope xmage_reveal_top_library_pick_to_hand_rest_graveyard_spell_v1. This row is package-ready only because the source signature is a narrow fixed reveal-top-library pick-to-hand spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('scout the borders', 'Scout the Borders', '522a2aca336e4812e880cb700b936c4c', 'battle_rule_v1:edbce89b4e5ec35359ceb44c67366492', '{"battle_model_scope":"xmage_reveal_top_library_pick_to_hand_rest_graveyard_spell_v1","count":1,"destination":"hand","effect":"dig_to_hand","instant":false,"look_count":5,"max_count":1,"pick_all_matching":false,"pick_count":1,"pick_target":"creature_or_land","pick_up_to_count":true,"rest_destination":"graveyard","reveal":true,"sorcery":true,"target":"creature_or_land","target_constraints":{"card_types":["creature","land"],"controller":"self","zone":"library"},"xmage_effect_class":"RevealLibraryPickControllerEffect"}'::jsonb, '{"category":"draw","effect":"dig_to_hand","target":"creature_or_land"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ScoutTheBorders translated into ManaLoom runtime scope xmage_reveal_top_library_pick_to_hand_rest_graveyard_spell_v1. This row is package-ready only because the source signature is a narrow fixed reveal-top-library pick-to-hand spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('commune with the gods', 'Commune with the Gods', '6d7ce4016bfce500247badd42e1fbf9a', 'battle_rule_v1:dee33e0d21b42f1d5133090250212c7f', '{"battle_model_scope":"xmage_reveal_top_library_pick_to_hand_rest_graveyard_spell_v1","count":1,"destination":"hand","effect":"dig_to_hand","instant":false,"look_count":5,"max_count":1,"pick_all_matching":false,"pick_count":1,"pick_target":"creature_or_enchantment","pick_up_to_count":true,"rest_destination":"graveyard","reveal":true,"sorcery":true,"target":"creature_or_enchantment","target_constraints":{"card_types":["creature","enchantment"],"controller":"self","zone":"library"},"xmage_effect_class":"RevealLibraryPickControllerEffect"}'::jsonb, '{"category":"draw","effect":"dig_to_hand","target":"creature_or_enchantment"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CommuneWithTheGods translated into ManaLoom runtime scope xmage_reveal_top_library_pick_to_hand_rest_graveyard_spell_v1. This row is package-ready only because the source signature is a narrow fixed reveal-top-library pick-to-hand spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('glacial revelation', 'Glacial Revelation', 'a52b48afaaa84dbc14c2e0ab196edb78', 'battle_rule_v1:96532e985cb2d1a3673024caef9269b3', '{"battle_model_scope":"xmage_reveal_top_library_pick_to_hand_rest_graveyard_spell_v1","count":6,"destination":"hand","effect":"dig_to_hand","instant":false,"look_count":6,"max_count":6,"pick_all_matching":true,"pick_count":6,"pick_target":"snow_permanent","pick_up_to_count":true,"rest_destination":"graveyard","reveal":true,"sorcery":true,"target":"snow_permanent","target_constraints":{"card_types":["artifact","creature","enchantment","planeswalker","battle","land"],"controller":"self","supertypes":["snow"],"zone":"library"},"xmage_effect_class":"RevealLibraryPickControllerEffect"}'::jsonb, '{"category":"draw","effect":"dig_to_hand","target":"snow_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GlacialRevelation translated into ManaLoom runtime scope xmage_reveal_top_library_pick_to_hand_rest_graveyard_spell_v1. This row is package-ready only because the source signature is a narrow fixed reveal-top-library pick-to-hand spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('grisly salvage', 'Grisly Salvage', '522a2aca336e4812e880cb700b936c4c', 'battle_rule_v1:2ca4973baa031b2e1d7c68c1a7a8b7cc', '{"battle_model_scope":"xmage_reveal_top_library_pick_to_hand_rest_graveyard_spell_v1","count":1,"destination":"hand","effect":"dig_to_hand","instant":true,"look_count":5,"max_count":1,"pick_all_matching":false,"pick_count":1,"pick_target":"creature_or_land","pick_up_to_count":true,"rest_destination":"graveyard","reveal":true,"sorcery":false,"target":"creature_or_land","target_constraints":{"card_types":["creature","land"],"controller":"self","zone":"library"},"xmage_effect_class":"RevealLibraryPickControllerEffect"}'::jsonb, '{"category":"draw","effect":"dig_to_hand","target":"creature_or_land","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GrislySalvage translated into ManaLoom runtime scope xmage_reveal_top_library_pick_to_hand_rest_graveyard_spell_v1. This row is package-ready only because the source signature is a narrow fixed reveal-top-library pick-to-hand spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kruphix''s insight', 'Kruphix''s Insight', '84bc958dbae0f32d686301e44ad75930', 'battle_rule_v1:732b2144450d7b4be404ba0f023e3465', '{"battle_model_scope":"xmage_reveal_top_library_pick_to_hand_rest_graveyard_spell_v1","count":3,"destination":"hand","effect":"dig_to_hand","instant":false,"look_count":6,"max_count":3,"pick_all_matching":false,"pick_count":3,"pick_target":"enchantment","pick_up_to_count":true,"rest_destination":"graveyard","reveal":true,"sorcery":true,"target":"enchantment","target_constraints":{"card_types":["enchantment"],"controller":"self","zone":"library"},"xmage_effect_class":"RevealLibraryPickControllerEffect"}'::jsonb, '{"category":"draw","effect":"dig_to_hand","target":"enchantment"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KruphixsInsight translated into ManaLoom runtime scope xmage_reveal_top_library_pick_to_hand_rest_graveyard_spell_v1. This row is package-ready only because the source signature is a narrow fixed reveal-top-library pick-to-hand spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pieces of the puzzle', 'Pieces of the Puzzle', '268daefa60fcde1c979fd668541d8970', 'battle_rule_v1:17c94b3a53e5d4898d2bae7e0270fb00', '{"battle_model_scope":"xmage_reveal_top_library_pick_to_hand_rest_graveyard_spell_v1","count":2,"destination":"hand","effect":"dig_to_hand","instant":false,"look_count":5,"max_count":2,"pick_all_matching":false,"pick_count":2,"pick_target":"instant_or_sorcery","pick_up_to_count":true,"rest_destination":"graveyard","reveal":true,"sorcery":true,"target":"instant_or_sorcery","target_constraints":{"card_types":["instant","sorcery"],"controller":"self","zone":"library"},"xmage_effect_class":"RevealLibraryPickControllerEffect"}'::jsonb, '{"category":"draw","effect":"dig_to_hand","target":"instant_or_sorcery"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PiecesOfThePuzzle translated into ManaLoom runtime scope xmage_reveal_top_library_pick_to_hand_rest_graveyard_spell_v1. This row is package-ready only because the source signature is a narrow fixed reveal-top-library pick-to-hand spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('scout the borders', 'Scout the Borders', '522a2aca336e4812e880cb700b936c4c', 'battle_rule_v1:edbce89b4e5ec35359ceb44c67366492', '{"battle_model_scope":"xmage_reveal_top_library_pick_to_hand_rest_graveyard_spell_v1","count":1,"destination":"hand","effect":"dig_to_hand","instant":false,"look_count":5,"max_count":1,"pick_all_matching":false,"pick_count":1,"pick_target":"creature_or_land","pick_up_to_count":true,"rest_destination":"graveyard","reveal":true,"sorcery":true,"target":"creature_or_land","target_constraints":{"card_types":["creature","land"],"controller":"self","zone":"library"},"xmage_effect_class":"RevealLibraryPickControllerEffect"}'::jsonb, '{"category":"draw","effect":"dig_to_hand","target":"creature_or_land"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ScoutTheBorders translated into ManaLoom runtime scope xmage_reveal_top_library_pick_to_hand_rest_graveyard_spell_v1. This row is package-ready only because the source signature is a narrow fixed reveal-top-library pick-to-hand spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
