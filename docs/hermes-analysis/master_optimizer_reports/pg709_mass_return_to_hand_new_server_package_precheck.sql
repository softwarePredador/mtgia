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
  LEFT JOIN public.cards c
    ON (
         lower(c.name) = p.normalized_name
         OR split_part(lower(c.name), ' // ', 1) = p.normalized_name
       )
   AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
),
target_cards AS (
  SELECT
    normalized_name,
    card_name,
    oracle_hash,
    count(card_id) AS target_card_rows,
    min(card_id::text)::uuid AS canonical_card_id,
    min(db_card_name) AS canonical_card_name
  FROM matched_cards
  GROUP BY normalized_name, card_name, oracle_hash
),
rule_rows AS (
  SELECT p.normalized_name, count(r.*) AS existing_rule_rows
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
  GROUP BY p.normalized_name
),
expected_rows AS (
  SELECT p.normalized_name, count(r.*) AS expected_rule_rows_before
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key = p.logical_rule_key
  GROUP BY p.normalized_name
),
shadow_rows AS (
  SELECT p.normalized_name, count(r.*) AS would_deprecate_shadow_rows
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key <> p.logical_rule_key
   AND r.review_status NOT IN ('deprecated', 'rejected')
   AND r.execution_status <> 'disabled'
  GROUP BY p.normalized_name
)
SELECT
  p.card_name,
  p.normalized_name,
  p.oracle_hash,
  p.logical_rule_key,
  p.shadow_handling,
  tc.target_card_rows,
  tc.canonical_card_id,
  rr.existing_rule_rows,
  er.expected_rule_rows_before,
  sr.would_deprecate_shadow_rows
FROM proposed p
JOIN target_cards tc USING (normalized_name, card_name, oracle_hash)
JOIN rule_rows rr USING (normalized_name)
JOIN expected_rows er USING (normalized_name)
JOIN shadow_rows sr USING (normalized_name)
ORDER BY p.card_name;
