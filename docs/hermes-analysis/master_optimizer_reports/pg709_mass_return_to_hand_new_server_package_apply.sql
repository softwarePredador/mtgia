BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg709_mass_return_to_hand_new_server_20260710_161253 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('aetherize', 'evacuation', 'filter out', 'hibernation', 'inundate', 'part the veil', 'reduce to dreams', 'retract', 'sunder', 'whelming wave')
   OR normalized_name LIKE 'aetherize // %'
   OR normalized_name LIKE 'evacuation // %'
   OR normalized_name LIKE 'filter out // %'
   OR normalized_name LIKE 'hibernation // %'
   OR normalized_name LIKE 'inundate // %'
   OR normalized_name LIKE 'part the veil // %'
   OR normalized_name LIKE 'reduce to dreams // %'
   OR normalized_name LIKE 'retract // %'
   OR normalized_name LIKE 'sunder // %'
   OR normalized_name LIKE 'whelming wave // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('aetherize', 'Aetherize', '66308023f5796252cffbc3eed76e154a', 'battle_rule_v1:b561860d3dbd695616e92469dcfc8c8e', '{"battle_model_scope":"xmage_return_all_matching_permanents_to_hand_spell_v1","destination":"hand","effect":"mass_return_to_hand","instant":true,"return_card_types":["creature"],"return_combat_state":"attacking","return_controller":"any","sorcery":false,"xmage_effect_class":"ReturnToHandFromBattlefieldAllEffect"}'::jsonb, '{"category":"unknown","effect":"mass_return_to_hand","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Aetherize translated into ManaLoom runtime scope xmage_return_all_matching_permanents_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow fixed return-all matching permanents to their owners'' hands spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('evacuation', 'Evacuation', 'f42bfcb28f19d854f28b8988bd0eeccc', 'battle_rule_v1:f92e1cab91813899d1d88449abe49c38', '{"battle_model_scope":"xmage_return_all_matching_permanents_to_hand_spell_v1","destination":"hand","effect":"mass_return_to_hand","instant":true,"return_card_types":["creature"],"return_controller":"any","sorcery":false,"xmage_effect_class":"ReturnToHandFromBattlefieldAllEffect"}'::jsonb, '{"category":"unknown","effect":"mass_return_to_hand","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Evacuation translated into ManaLoom runtime scope xmage_return_all_matching_permanents_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow fixed return-all matching permanents to their owners'' hands spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('filter out', 'Filter Out', '5175813680dce4b1e850d841ff1338f2', 'battle_rule_v1:c4ad100cf949fe2208e100e75920849b', '{"battle_model_scope":"xmage_return_all_matching_permanents_to_hand_spell_v1","destination":"hand","effect":"mass_return_to_hand","instant":true,"return_card_types":["permanent"],"return_controller":"any","return_exclude_card_types":["creature","land"],"sorcery":false,"xmage_effect_class":"ReturnToHandFromBattlefieldAllEffect"}'::jsonb, '{"category":"unknown","effect":"mass_return_to_hand","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FilterOut translated into ManaLoom runtime scope xmage_return_all_matching_permanents_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow fixed return-all matching permanents to their owners'' hands spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hibernation', 'Hibernation', 'ff89e3bebbca949067fe60a031a7a8ac', 'battle_rule_v1:0680695d4301181c4ef5bb464ca0396b', '{"battle_model_scope":"xmage_return_all_matching_permanents_to_hand_spell_v1","destination":"hand","effect":"mass_return_to_hand","instant":true,"return_card_types":["permanent"],"return_controller":"any","return_required_colors":["G"],"sorcery":false,"xmage_effect_class":"ReturnToHandFromBattlefieldAllEffect"}'::jsonb, '{"category":"unknown","effect":"mass_return_to_hand","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Hibernation translated into ManaLoom runtime scope xmage_return_all_matching_permanents_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow fixed return-all matching permanents to their owners'' hands spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('inundate', 'Inundate', '6e3e48e3305ab68720eff6608303e14e', 'battle_rule_v1:b980ae03abf6fad2870a813b434874e6', '{"battle_model_scope":"xmage_return_all_matching_permanents_to_hand_spell_v1","destination":"hand","effect":"mass_return_to_hand","instant":false,"return_card_types":["creature"],"return_controller":"any","return_excluded_colors":["U"],"sorcery":true,"xmage_effect_class":"ReturnToHandFromBattlefieldAllEffect"}'::jsonb, '{"category":"unknown","effect":"mass_return_to_hand"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Inundate translated into ManaLoom runtime scope xmage_return_all_matching_permanents_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow fixed return-all matching permanents to their owners'' hands spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('part the veil', 'Part the Veil', 'f91d1c5f19e19fd72690718effb1c634', 'battle_rule_v1:2e76ff3cd0ccd42d7fa5989d7b44ec2c', '{"battle_model_scope":"xmage_return_all_matching_permanents_to_hand_spell_v1","destination":"hand","effect":"mass_return_to_hand","instant":true,"return_card_types":["creature"],"return_controller":"self","sorcery":false,"xmage_effect_class":"ReturnToHandFromBattlefieldAllEffect"}'::jsonb, '{"category":"unknown","effect":"mass_return_to_hand","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PartTheVeil translated into ManaLoom runtime scope xmage_return_all_matching_permanents_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow fixed return-all matching permanents to their owners'' hands spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('reduce to dreams', 'Reduce to Dreams', 'e3d0c021a381f58efa5481db5b222b60', 'battle_rule_v1:20a7774f995f7f1b16accd138c1e7cad', '{"battle_model_scope":"xmage_return_all_matching_permanents_to_hand_spell_v1","destination":"hand","effect":"mass_return_to_hand","instant":false,"return_card_types":["artifact","enchantment"],"return_controller":"any","sorcery":true,"xmage_effect_class":"ReturnToHandFromBattlefieldAllEffect"}'::jsonb, '{"category":"unknown","effect":"mass_return_to_hand"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ReduceToDreams translated into ManaLoom runtime scope xmage_return_all_matching_permanents_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow fixed return-all matching permanents to their owners'' hands spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('retract', 'Retract', '389b02faaa25b2e2b2a9fe1b7d2b1e3b', 'battle_rule_v1:7747bd16209921b67115bf10d0290d90', '{"battle_model_scope":"xmage_return_all_matching_permanents_to_hand_spell_v1","destination":"hand","effect":"mass_return_to_hand","instant":true,"return_card_types":["artifact"],"return_controller":"self","sorcery":false,"xmage_effect_class":"ReturnToHandFromBattlefieldAllEffect"}'::jsonb, '{"category":"unknown","effect":"mass_return_to_hand","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Retract translated into ManaLoom runtime scope xmage_return_all_matching_permanents_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow fixed return-all matching permanents to their owners'' hands spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sunder', 'Sunder', 'e62e865773ead8e9474ab0cf48cb0335', 'battle_rule_v1:64f744843d6c935fdffb2b280975c2db', '{"battle_model_scope":"xmage_return_all_matching_permanents_to_hand_spell_v1","destination":"hand","effect":"mass_return_to_hand","instant":true,"return_card_types":["land"],"return_controller":"any","sorcery":false,"xmage_effect_class":"ReturnToHandFromBattlefieldAllEffect"}'::jsonb, '{"category":"unknown","effect":"mass_return_to_hand","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Sunder translated into ManaLoom runtime scope xmage_return_all_matching_permanents_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow fixed return-all matching permanents to their owners'' hands spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('whelming wave', 'Whelming Wave', '67e8b487fdfb1e83412a20b127302591', 'battle_rule_v1:fc6b25e8067a25efec024d91d5c7ca32', '{"battle_model_scope":"xmage_return_all_matching_permanents_to_hand_spell_v1","destination":"hand","effect":"mass_return_to_hand","instant":false,"return_card_types":["creature"],"return_controller":"any","return_excluded_subtypes":["kraken","leviathan","octopus","serpent"],"sorcery":true,"xmage_effect_class":"ReturnToHandFromBattlefieldAllEffect"}'::jsonb, '{"category":"unknown","effect":"mass_return_to_hand"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WhelmingWave translated into ManaLoom runtime scope xmage_return_all_matching_permanents_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow fixed return-all matching permanents to their owners'' hands spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('aetherize', 'Aetherize', '66308023f5796252cffbc3eed76e154a', 'battle_rule_v1:b561860d3dbd695616e92469dcfc8c8e', '{"battle_model_scope":"xmage_return_all_matching_permanents_to_hand_spell_v1","destination":"hand","effect":"mass_return_to_hand","instant":true,"return_card_types":["creature"],"return_combat_state":"attacking","return_controller":"any","sorcery":false,"xmage_effect_class":"ReturnToHandFromBattlefieldAllEffect"}'::jsonb, '{"category":"unknown","effect":"mass_return_to_hand","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Aetherize translated into ManaLoom runtime scope xmage_return_all_matching_permanents_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow fixed return-all matching permanents to their owners'' hands spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('evacuation', 'Evacuation', 'f42bfcb28f19d854f28b8988bd0eeccc', 'battle_rule_v1:f92e1cab91813899d1d88449abe49c38', '{"battle_model_scope":"xmage_return_all_matching_permanents_to_hand_spell_v1","destination":"hand","effect":"mass_return_to_hand","instant":true,"return_card_types":["creature"],"return_controller":"any","sorcery":false,"xmage_effect_class":"ReturnToHandFromBattlefieldAllEffect"}'::jsonb, '{"category":"unknown","effect":"mass_return_to_hand","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Evacuation translated into ManaLoom runtime scope xmage_return_all_matching_permanents_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow fixed return-all matching permanents to their owners'' hands spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('filter out', 'Filter Out', '5175813680dce4b1e850d841ff1338f2', 'battle_rule_v1:c4ad100cf949fe2208e100e75920849b', '{"battle_model_scope":"xmage_return_all_matching_permanents_to_hand_spell_v1","destination":"hand","effect":"mass_return_to_hand","instant":true,"return_card_types":["permanent"],"return_controller":"any","return_exclude_card_types":["creature","land"],"sorcery":false,"xmage_effect_class":"ReturnToHandFromBattlefieldAllEffect"}'::jsonb, '{"category":"unknown","effect":"mass_return_to_hand","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FilterOut translated into ManaLoom runtime scope xmage_return_all_matching_permanents_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow fixed return-all matching permanents to their owners'' hands spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hibernation', 'Hibernation', 'ff89e3bebbca949067fe60a031a7a8ac', 'battle_rule_v1:0680695d4301181c4ef5bb464ca0396b', '{"battle_model_scope":"xmage_return_all_matching_permanents_to_hand_spell_v1","destination":"hand","effect":"mass_return_to_hand","instant":true,"return_card_types":["permanent"],"return_controller":"any","return_required_colors":["G"],"sorcery":false,"xmage_effect_class":"ReturnToHandFromBattlefieldAllEffect"}'::jsonb, '{"category":"unknown","effect":"mass_return_to_hand","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Hibernation translated into ManaLoom runtime scope xmage_return_all_matching_permanents_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow fixed return-all matching permanents to their owners'' hands spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('inundate', 'Inundate', '6e3e48e3305ab68720eff6608303e14e', 'battle_rule_v1:b980ae03abf6fad2870a813b434874e6', '{"battle_model_scope":"xmage_return_all_matching_permanents_to_hand_spell_v1","destination":"hand","effect":"mass_return_to_hand","instant":false,"return_card_types":["creature"],"return_controller":"any","return_excluded_colors":["U"],"sorcery":true,"xmage_effect_class":"ReturnToHandFromBattlefieldAllEffect"}'::jsonb, '{"category":"unknown","effect":"mass_return_to_hand"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Inundate translated into ManaLoom runtime scope xmage_return_all_matching_permanents_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow fixed return-all matching permanents to their owners'' hands spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('part the veil', 'Part the Veil', 'f91d1c5f19e19fd72690718effb1c634', 'battle_rule_v1:2e76ff3cd0ccd42d7fa5989d7b44ec2c', '{"battle_model_scope":"xmage_return_all_matching_permanents_to_hand_spell_v1","destination":"hand","effect":"mass_return_to_hand","instant":true,"return_card_types":["creature"],"return_controller":"self","sorcery":false,"xmage_effect_class":"ReturnToHandFromBattlefieldAllEffect"}'::jsonb, '{"category":"unknown","effect":"mass_return_to_hand","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PartTheVeil translated into ManaLoom runtime scope xmage_return_all_matching_permanents_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow fixed return-all matching permanents to their owners'' hands spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('reduce to dreams', 'Reduce to Dreams', 'e3d0c021a381f58efa5481db5b222b60', 'battle_rule_v1:20a7774f995f7f1b16accd138c1e7cad', '{"battle_model_scope":"xmage_return_all_matching_permanents_to_hand_spell_v1","destination":"hand","effect":"mass_return_to_hand","instant":false,"return_card_types":["artifact","enchantment"],"return_controller":"any","sorcery":true,"xmage_effect_class":"ReturnToHandFromBattlefieldAllEffect"}'::jsonb, '{"category":"unknown","effect":"mass_return_to_hand"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ReduceToDreams translated into ManaLoom runtime scope xmage_return_all_matching_permanents_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow fixed return-all matching permanents to their owners'' hands spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('retract', 'Retract', '389b02faaa25b2e2b2a9fe1b7d2b1e3b', 'battle_rule_v1:7747bd16209921b67115bf10d0290d90', '{"battle_model_scope":"xmage_return_all_matching_permanents_to_hand_spell_v1","destination":"hand","effect":"mass_return_to_hand","instant":true,"return_card_types":["artifact"],"return_controller":"self","sorcery":false,"xmage_effect_class":"ReturnToHandFromBattlefieldAllEffect"}'::jsonb, '{"category":"unknown","effect":"mass_return_to_hand","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Retract translated into ManaLoom runtime scope xmage_return_all_matching_permanents_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow fixed return-all matching permanents to their owners'' hands spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sunder', 'Sunder', 'e62e865773ead8e9474ab0cf48cb0335', 'battle_rule_v1:64f744843d6c935fdffb2b280975c2db', '{"battle_model_scope":"xmage_return_all_matching_permanents_to_hand_spell_v1","destination":"hand","effect":"mass_return_to_hand","instant":true,"return_card_types":["land"],"return_controller":"any","sorcery":false,"xmage_effect_class":"ReturnToHandFromBattlefieldAllEffect"}'::jsonb, '{"category":"unknown","effect":"mass_return_to_hand","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Sunder translated into ManaLoom runtime scope xmage_return_all_matching_permanents_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow fixed return-all matching permanents to their owners'' hands spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('whelming wave', 'Whelming Wave', '67e8b487fdfb1e83412a20b127302591', 'battle_rule_v1:fc6b25e8067a25efec024d91d5c7ca32', '{"battle_model_scope":"xmage_return_all_matching_permanents_to_hand_spell_v1","destination":"hand","effect":"mass_return_to_hand","instant":false,"return_card_types":["creature"],"return_controller":"any","return_excluded_subtypes":["kraken","leviathan","octopus","serpent"],"sorcery":true,"xmage_effect_class":"ReturnToHandFromBattlefieldAllEffect"}'::jsonb, '{"category":"unknown","effect":"mass_return_to_hand"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WhelmingWave translated into ManaLoom runtime scope xmage_return_all_matching_permanents_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow fixed return-all matching permanents to their owners'' hands spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('aetherize', 'Aetherize', '66308023f5796252cffbc3eed76e154a', 'battle_rule_v1:b561860d3dbd695616e92469dcfc8c8e', '{"battle_model_scope":"xmage_return_all_matching_permanents_to_hand_spell_v1","destination":"hand","effect":"mass_return_to_hand","instant":true,"return_card_types":["creature"],"return_combat_state":"attacking","return_controller":"any","sorcery":false,"xmage_effect_class":"ReturnToHandFromBattlefieldAllEffect"}'::jsonb, '{"category":"unknown","effect":"mass_return_to_hand","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Aetherize translated into ManaLoom runtime scope xmage_return_all_matching_permanents_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow fixed return-all matching permanents to their owners'' hands spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('evacuation', 'Evacuation', 'f42bfcb28f19d854f28b8988bd0eeccc', 'battle_rule_v1:f92e1cab91813899d1d88449abe49c38', '{"battle_model_scope":"xmage_return_all_matching_permanents_to_hand_spell_v1","destination":"hand","effect":"mass_return_to_hand","instant":true,"return_card_types":["creature"],"return_controller":"any","sorcery":false,"xmage_effect_class":"ReturnToHandFromBattlefieldAllEffect"}'::jsonb, '{"category":"unknown","effect":"mass_return_to_hand","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Evacuation translated into ManaLoom runtime scope xmage_return_all_matching_permanents_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow fixed return-all matching permanents to their owners'' hands spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('filter out', 'Filter Out', '5175813680dce4b1e850d841ff1338f2', 'battle_rule_v1:c4ad100cf949fe2208e100e75920849b', '{"battle_model_scope":"xmage_return_all_matching_permanents_to_hand_spell_v1","destination":"hand","effect":"mass_return_to_hand","instant":true,"return_card_types":["permanent"],"return_controller":"any","return_exclude_card_types":["creature","land"],"sorcery":false,"xmage_effect_class":"ReturnToHandFromBattlefieldAllEffect"}'::jsonb, '{"category":"unknown","effect":"mass_return_to_hand","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FilterOut translated into ManaLoom runtime scope xmage_return_all_matching_permanents_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow fixed return-all matching permanents to their owners'' hands spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hibernation', 'Hibernation', 'ff89e3bebbca949067fe60a031a7a8ac', 'battle_rule_v1:0680695d4301181c4ef5bb464ca0396b', '{"battle_model_scope":"xmage_return_all_matching_permanents_to_hand_spell_v1","destination":"hand","effect":"mass_return_to_hand","instant":true,"return_card_types":["permanent"],"return_controller":"any","return_required_colors":["G"],"sorcery":false,"xmage_effect_class":"ReturnToHandFromBattlefieldAllEffect"}'::jsonb, '{"category":"unknown","effect":"mass_return_to_hand","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Hibernation translated into ManaLoom runtime scope xmage_return_all_matching_permanents_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow fixed return-all matching permanents to their owners'' hands spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('inundate', 'Inundate', '6e3e48e3305ab68720eff6608303e14e', 'battle_rule_v1:b980ae03abf6fad2870a813b434874e6', '{"battle_model_scope":"xmage_return_all_matching_permanents_to_hand_spell_v1","destination":"hand","effect":"mass_return_to_hand","instant":false,"return_card_types":["creature"],"return_controller":"any","return_excluded_colors":["U"],"sorcery":true,"xmage_effect_class":"ReturnToHandFromBattlefieldAllEffect"}'::jsonb, '{"category":"unknown","effect":"mass_return_to_hand"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Inundate translated into ManaLoom runtime scope xmage_return_all_matching_permanents_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow fixed return-all matching permanents to their owners'' hands spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('part the veil', 'Part the Veil', 'f91d1c5f19e19fd72690718effb1c634', 'battle_rule_v1:2e76ff3cd0ccd42d7fa5989d7b44ec2c', '{"battle_model_scope":"xmage_return_all_matching_permanents_to_hand_spell_v1","destination":"hand","effect":"mass_return_to_hand","instant":true,"return_card_types":["creature"],"return_controller":"self","sorcery":false,"xmage_effect_class":"ReturnToHandFromBattlefieldAllEffect"}'::jsonb, '{"category":"unknown","effect":"mass_return_to_hand","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PartTheVeil translated into ManaLoom runtime scope xmage_return_all_matching_permanents_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow fixed return-all matching permanents to their owners'' hands spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('reduce to dreams', 'Reduce to Dreams', 'e3d0c021a381f58efa5481db5b222b60', 'battle_rule_v1:20a7774f995f7f1b16accd138c1e7cad', '{"battle_model_scope":"xmage_return_all_matching_permanents_to_hand_spell_v1","destination":"hand","effect":"mass_return_to_hand","instant":false,"return_card_types":["artifact","enchantment"],"return_controller":"any","sorcery":true,"xmage_effect_class":"ReturnToHandFromBattlefieldAllEffect"}'::jsonb, '{"category":"unknown","effect":"mass_return_to_hand"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ReduceToDreams translated into ManaLoom runtime scope xmage_return_all_matching_permanents_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow fixed return-all matching permanents to their owners'' hands spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('retract', 'Retract', '389b02faaa25b2e2b2a9fe1b7d2b1e3b', 'battle_rule_v1:7747bd16209921b67115bf10d0290d90', '{"battle_model_scope":"xmage_return_all_matching_permanents_to_hand_spell_v1","destination":"hand","effect":"mass_return_to_hand","instant":true,"return_card_types":["artifact"],"return_controller":"self","sorcery":false,"xmage_effect_class":"ReturnToHandFromBattlefieldAllEffect"}'::jsonb, '{"category":"unknown","effect":"mass_return_to_hand","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Retract translated into ManaLoom runtime scope xmage_return_all_matching_permanents_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow fixed return-all matching permanents to their owners'' hands spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sunder', 'Sunder', 'e62e865773ead8e9474ab0cf48cb0335', 'battle_rule_v1:64f744843d6c935fdffb2b280975c2db', '{"battle_model_scope":"xmage_return_all_matching_permanents_to_hand_spell_v1","destination":"hand","effect":"mass_return_to_hand","instant":true,"return_card_types":["land"],"return_controller":"any","sorcery":false,"xmage_effect_class":"ReturnToHandFromBattlefieldAllEffect"}'::jsonb, '{"category":"unknown","effect":"mass_return_to_hand","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Sunder translated into ManaLoom runtime scope xmage_return_all_matching_permanents_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow fixed return-all matching permanents to their owners'' hands spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('whelming wave', 'Whelming Wave', '67e8b487fdfb1e83412a20b127302591', 'battle_rule_v1:fc6b25e8067a25efec024d91d5c7ca32', '{"battle_model_scope":"xmage_return_all_matching_permanents_to_hand_spell_v1","destination":"hand","effect":"mass_return_to_hand","instant":false,"return_card_types":["creature"],"return_controller":"any","return_excluded_subtypes":["kraken","leviathan","octopus","serpent"],"sorcery":true,"xmage_effect_class":"ReturnToHandFromBattlefieldAllEffect"}'::jsonb, '{"category":"unknown","effect":"mass_return_to_hand"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WhelmingWave translated into ManaLoom runtime scope xmage_return_all_matching_permanents_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow fixed return-all matching permanents to their owners'' hands spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
