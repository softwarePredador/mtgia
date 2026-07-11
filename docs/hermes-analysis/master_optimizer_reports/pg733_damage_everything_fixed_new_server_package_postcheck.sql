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
rule_rows AS (
  SELECT
    r.normalized_name,
    r.logical_rule_key,
    r.oracle_hash,
    r.review_status,
    r.execution_status
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key = p.logical_rule_key
)
SELECT
  p.card_name,
  p.normalized_name,
  p.logical_rule_key,
  count(r.*) FILTER (WHERE r.logical_rule_key = p.logical_rule_key) AS promoted_rule_rows,
  count(r.*) FILTER (WHERE r.review_status = 'verified' AND r.execution_status = 'auto') AS promoted_verified_auto_rows,
  count(r.*) FILTER (WHERE r.oracle_hash = p.oracle_hash) AS promoted_oracle_hash_rows,
  (SELECT count(*) FROM manaloom_deploy_audit.pg733_damage_everything_fixed_new_server_20260711_014908) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
