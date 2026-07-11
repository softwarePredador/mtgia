WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('dakmor plague', 'Dakmor Plague', '013e9a91772b5cb2d8a1993d559d5126', 'battle_rule_v1:58ac689d2294972d0e1b6d29535ad07e', '{"amount":3,"battle_model_scope":"xmage_fixed_damage_each_creature_each_player_spell_v1","damage":3,"damage_players":true,"damage_scope":"each_creature","effect":"damage_wipe","instant":false,"sorcery":true,"target_controller":"all","xmage_effect_class":"DamageEverythingEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DakmorPlague translated into ManaLoom runtime scope xmage_fixed_damage_each_creature_each_player_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dry spell', 'Dry Spell', '37af1c7171b4d44b601b0887aea099be', 'battle_rule_v1:dadbf2239e41f350d14d994f0991b0c0', '{"amount":1,"battle_model_scope":"xmage_fixed_damage_each_creature_each_player_spell_v1","damage":1,"damage_players":true,"damage_scope":"each_creature","effect":"damage_wipe","instant":false,"sorcery":true,"target_controller":"all","xmage_effect_class":"DamageEverythingEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DrySpell translated into ManaLoom runtime scope xmage_fixed_damage_each_creature_each_player_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('famine', 'Famine', '6049389ea99f86359fac910367a8baa4', 'battle_rule_v1:58ac689d2294972d0e1b6d29535ad07e', '{"amount":3,"battle_model_scope":"xmage_fixed_damage_each_creature_each_player_spell_v1","damage":3,"damage_players":true,"damage_scope":"each_creature","effect":"damage_wipe","instant":false,"sorcery":true,"target_controller":"all","xmage_effect_class":"DamageEverythingEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Famine translated into ManaLoom runtime scope xmage_fixed_damage_each_creature_each_player_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fire tempest', 'Fire Tempest', '51b25fe4487c2ba60bfe5449d9cf4638', 'battle_rule_v1:fb4700fa4da352cbafe2cac6efe2bffe', '{"amount":6,"battle_model_scope":"xmage_fixed_damage_each_creature_each_player_spell_v1","damage":6,"damage_players":true,"damage_scope":"each_creature","effect":"damage_wipe","instant":false,"sorcery":true,"target_controller":"all","xmage_effect_class":"DamageEverythingEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FireTempest translated into ManaLoom runtime scope xmage_fixed_damage_each_creature_each_player_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('inferno', 'Inferno', '93769e4f5f3cb715b3507a643e3c0f10', 'battle_rule_v1:1013318f41fd3644ecd11bb07115c68f', '{"amount":6,"battle_model_scope":"xmage_fixed_damage_each_creature_each_player_spell_v1","damage":6,"damage_players":true,"damage_scope":"each_creature","effect":"damage_wipe","instant":true,"sorcery":false,"target_controller":"all","xmage_effect_class":"DamageEverythingEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Inferno translated into ManaLoom runtime scope xmage_fixed_damage_each_creature_each_player_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rain of embers', 'Rain of Embers', '53c764d28470e0a8945bc3cc448033e6', 'battle_rule_v1:dadbf2239e41f350d14d994f0991b0c0', '{"amount":1,"battle_model_scope":"xmage_fixed_damage_each_creature_each_player_spell_v1","damage":1,"damage_players":true,"damage_scope":"each_creature","effect":"damage_wipe","instant":false,"sorcery":true,"target_controller":"all","xmage_effect_class":"DamageEverythingEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RainOfEmbers translated into ManaLoom runtime scope xmage_fixed_damage_each_creature_each_player_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('steam blast', 'Steam Blast', '48aacdc842feb2625aa9f6ca7999b89c', 'battle_rule_v1:d272553afbab073b0b90a707c20d03e1', '{"amount":2,"battle_model_scope":"xmage_fixed_damage_each_creature_each_player_spell_v1","damage":2,"damage_players":true,"damage_scope":"each_creature","effect":"damage_wipe","instant":false,"sorcery":true,"target_controller":"all","xmage_effect_class":"DamageEverythingEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SteamBlast translated into ManaLoom runtime scope xmage_fixed_damage_each_creature_each_player_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
