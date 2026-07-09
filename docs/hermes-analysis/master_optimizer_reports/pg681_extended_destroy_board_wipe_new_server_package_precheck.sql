WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('damning verdict', 'Damning Verdict', '33f0171bc14c8f1984348bf7768e9dd2', 'battle_rule_v1:1f18065fc9e05b7382e97bd6e22d84c1', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["creature"],"destroy_counter_state":"none","effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DamningVerdict translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fight to the death', 'Fight to the Death', '544386e89921de0d8edccea0f7cf3db2', 'battle_rule_v1:4c3d89a5de268a64585efcfaa5ea8a45', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["creature"],"destroy_combat_state":"blocking_or_blocked","effect":"board_wipe","instant":true,"sorcery":false,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FightToTheDeath translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('forced march', 'Forced March', '0f27f0e3effac970d62931e180ee9ebe', 'battle_rule_v1:fe2535899e8907daeb65efa6d08625d0', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["creature"],"destroy_mana_value_lte":0,"destroy_mana_value_lte_source":"x_value","effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ForcedMarch translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('iridian maelstrom', 'Iridian Maelstrom', '111aee9fb9a2474072a4997ba67059c3', 'battle_rule_v1:95132cc301dd7fa7d0f202f3931d49ee', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["creature"],"destroy_color_count_lt":5,"effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class IridianMaelstrom translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('retaliate', 'Retaliate', '2dc2616abd9d2da1be57ba8cb10eceb9', 'battle_rule_v1:7a3f2be667a7bdef390e594f94ec79af', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["creature"],"destroy_dealt_damage_to_you_this_turn":true,"effect":"board_wipe","instant":true,"sorcery":false,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Retaliate translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ruinous ultimatum', 'Ruinous Ultimatum', '423f331acf69e0207d6337f18eaad355', 'battle_rule_v1:844a41ecce998ddb47894d50dfebd1c5', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["permanent"],"destroy_controller":"opponents_control","destroy_exclude_card_types":["land"],"effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RuinousUltimatum translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('serene heart', 'Serene Heart', '132c041ddc763e613cf3f60e1f263479', 'battle_rule_v1:9fdbcabe98a9e71e5b7c7a00c79b1104', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["enchantment"],"destroy_required_subtypes":["aura"],"effect":"board_wipe","instant":true,"sorcery":false,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SereneHeart translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('slash the ranks', 'Slash the Ranks', '301ab432ebc0997382ca787fe76a51af', 'battle_rule_v1:f082db7e1494a74df8a4d5a4d41ae126', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["creature","planeswalker"],"destroy_exclude_commanders":true,"effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SlashTheRanks translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tivadar''s crusade', 'Tivadar''s Crusade', '181c916db01842331fd5d9145ab75a85', 'battle_rule_v1:4923d48bfef02728a27fd70237fbc5f6', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["permanent"],"destroy_required_subtypes":["goblin"],"effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TivadarsCrusade translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tranquil domain', 'Tranquil Domain', '839dadbbbb938ef2d85872020c666dbc', 'battle_rule_v1:1d8b56017de6edbe969c20209c6ae0a9', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["enchantment"],"destroy_excluded_subtypes":["aura"],"effect":"board_wipe","instant":true,"sorcery":false,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TranquilDomain translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('winds of rath', 'Winds of Rath', 'de9e91433d311fc360b75148bbba6f17', 'battle_rule_v1:e0d89211c65d375ab79b6c021718b55b', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["creature"],"destroy_enchanted_state":"not_enchanted","effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WindsOfRath translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
