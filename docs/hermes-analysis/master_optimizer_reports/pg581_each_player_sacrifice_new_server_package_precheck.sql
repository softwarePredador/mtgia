WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('barter in blood', 'Barter in Blood', 'be856a7f6d029bfa5be0bfe07f7915d7', 'battle_rule_v1:4dc466c70a22a941f04f26618e8a6ee1', '{"battle_model_scope":"xmage_each_player_sacrifice_fixed_permanents_spell_v1","effect":"each_player_sacrifice","instant":false,"sacrifice_card_types":["creature"],"sacrifice_choice":"controller_choice_lowest_value","sacrifice_count":2,"sacrifice_scope":"each_player","sorcery":true,"xmage_effect_class":"SacrificeAllEffect"}'::jsonb, '{"category":"unknown","effect":"each_player_sacrifice"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BarterInBlood translated into ManaLoom runtime scope xmage_each_player_sacrifice_fixed_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('crack the earth', 'Crack the Earth', '08446934f7df33a207467fb5b627fa50', 'battle_rule_v1:d2aa51841d87625e029e0c1d78119c0b', '{"battle_model_scope":"xmage_each_player_sacrifice_fixed_permanents_spell_v1","effect":"each_player_sacrifice","instant":false,"sacrifice_card_types":["permanent"],"sacrifice_choice":"controller_choice_lowest_value","sacrifice_count":1,"sacrifice_scope":"each_player","sorcery":true,"xmage_effect_class":"SacrificeAllEffect"}'::jsonb, '{"category":"unknown","effect":"each_player_sacrifice"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CrackTheEarth translated into ManaLoom runtime scope xmage_each_player_sacrifice_fixed_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('innocent blood', 'Innocent Blood', '936b01368e4684556867764af9ce37c5', 'battle_rule_v1:e36e942e876596fa39c2abef5eac238f', '{"battle_model_scope":"xmage_each_player_sacrifice_fixed_permanents_spell_v1","effect":"each_player_sacrifice","instant":false,"sacrifice_card_types":["creature"],"sacrifice_choice":"controller_choice_lowest_value","sacrifice_count":1,"sacrifice_scope":"each_player","sorcery":true,"xmage_effect_class":"SacrificeAllEffect"}'::jsonb, '{"category":"unknown","effect":"each_player_sacrifice"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class InnocentBlood translated into ManaLoom runtime scope xmage_each_player_sacrifice_fixed_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('renounce the guilds', 'Renounce the Guilds', '3127e90fe826e0d6097996f889d848b9', 'battle_rule_v1:172ceadc506f12be79de7edc8edc647b', '{"battle_model_scope":"xmage_each_player_sacrifice_fixed_permanents_spell_v1","effect":"each_player_sacrifice","instant":true,"sacrifice_card_types":["permanent"],"sacrifice_choice":"controller_choice_lowest_value","sacrifice_count":1,"sacrifice_requires_multicolored":true,"sacrifice_scope":"each_player","sorcery":false,"xmage_effect_class":"SacrificeAllEffect"}'::jsonb, '{"category":"unknown","effect":"each_player_sacrifice","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RenounceTheGuilds translated into ManaLoom runtime scope xmage_each_player_sacrifice_fixed_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('simplify', 'Simplify', '3e5ca27a1aaa76ffa9aa0c13d1689aa5', 'battle_rule_v1:8d62f54198483e3e3deeec43de124cd5', '{"battle_model_scope":"xmage_each_player_sacrifice_fixed_permanents_spell_v1","effect":"each_player_sacrifice","instant":false,"sacrifice_card_types":["enchantment"],"sacrifice_choice":"controller_choice_lowest_value","sacrifice_count":1,"sacrifice_scope":"each_player","sorcery":true,"xmage_effect_class":"SacrificeAllEffect"}'::jsonb, '{"category":"unknown","effect":"each_player_sacrifice"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Simplify translated into ManaLoom runtime scope xmage_each_player_sacrifice_fixed_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tergrid''s shadow', 'Tergrid''s Shadow', '5a7e33d8e6b36112f4c1ac58776c8e12', 'battle_rule_v1:d2088319b0a6c4d1bd660dfc024c73e6', '{"battle_model_scope":"xmage_each_player_sacrifice_fixed_permanents_spell_v1","effect":"each_player_sacrifice","instant":true,"sacrifice_card_types":["creature"],"sacrifice_choice":"controller_choice_lowest_value","sacrifice_count":2,"sacrifice_scope":"each_player","sorcery":false,"xmage_effect_class":"SacrificeAllEffect"}'::jsonb, '{"category":"unknown","effect":"each_player_sacrifice","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TergridsShadow translated into ManaLoom runtime scope xmage_each_player_sacrifice_fixed_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tremble', 'Tremble', 'e3d97dc178a6579b3b6f279e42e225db', 'battle_rule_v1:4aec324ab24ccc2a1adfe7a07131cf98', '{"battle_model_scope":"xmage_each_player_sacrifice_fixed_permanents_spell_v1","effect":"each_player_sacrifice","instant":false,"sacrifice_card_types":["land"],"sacrifice_choice":"controller_choice_lowest_value","sacrifice_count":1,"sacrifice_scope":"each_player","sorcery":true,"xmage_effect_class":"SacrificeAllEffect"}'::jsonb, '{"category":"unknown","effect":"each_player_sacrifice"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Tremble translated into ManaLoom runtime scope xmage_each_player_sacrifice_fixed_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
