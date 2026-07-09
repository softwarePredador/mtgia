WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('consume the meek', 'Consume the Meek', '91884342fe2f9766caa1cd9119438a52', 'battle_rule_v1:46da0eb5a14f570ff5008f97da566411', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["creature"],"destroy_mana_value_lte":3,"effect":"board_wipe","instant":true,"sorcery":false,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ConsumeTheMeek translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('culling sun', 'Culling Sun', 'f043b25ffba2e178df62a4236bfe7c4c', 'battle_rule_v1:5b1499437b3584a0c1ec4364787d223b', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["creature"],"destroy_mana_value_lte":3,"effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CullingSun translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('doomskar', 'Doomskar', '58904231035d856db08d5aec75fb5476', 'battle_rule_v1:acf7a4c6829b305ea62cbdb81430e0af', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["creature"],"effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Doomskar translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('extinguish all hope', 'Extinguish All Hope', 'cd57e9dd6d335c46fab4aee1fa4b1515', 'battle_rule_v1:808b26d673252c323a1236694536fee1', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["creature"],"destroy_exclude_card_types":["enchantment"],"effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ExtinguishAllHope translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('granulate', 'Granulate', 'ea49c59a7706e1faf80fe2b22f427568', 'battle_rule_v1:d77c161c970bb914806ab0f70c632cd7', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["artifact"],"destroy_exclude_card_types":["land"],"destroy_mana_value_lte":4,"effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Granulate translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('in garruk''s wake', 'In Garruk''s Wake', '9c97ba287f7749999bf71bfaae773091', 'battle_rule_v1:b5cab617536e29c27971e6580e04cb31', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["creature","planeswalker"],"destroy_controller":"opponents_control","effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class InGarruksWake translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jokulhaups', 'Jokulhaups', 'b02f24ad678531e03173c832045d4ed7', 'battle_rule_v1:a7d11833732a5e3d4bc4d356c1aa33ff', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["artifact","creature","land"],"effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Jokulhaups translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('obliterate', 'Obliterate', '4d634aaf1338bd7282fa9d4acea914ca', 'battle_rule_v1:a7d11833732a5e3d4bc4d356c1aa33ff', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["artifact","creature","land"],"effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Obliterate translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sublime exhalation', 'Sublime Exhalation', 'c94c3440f7cb3cd1be685e2c2635984e', 'battle_rule_v1:acf7a4c6829b305ea62cbdb81430e0af', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["creature"],"effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SublimeExhalation translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('supreme verdict', 'Supreme Verdict', '3c8b78df51c98a53489dfe0e396ad3b7', 'battle_rule_v1:acf7a4c6829b305ea62cbdb81430e0af', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["creature"],"effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SupremeVerdict translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
