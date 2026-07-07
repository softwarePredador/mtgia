WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('ethereal haze', 'Ethereal Haze', 'e40ccef210036508a675913beb82b76a', 'battle_rule_v1:9fca8ead02e6ecfd5dca402fd1b5005f', '{"battle_model_scope":"xmage_prevent_damage_from_creatures_spell_v1","duration":"until_end_of_turn","effect":"damage_prevention_shield","instant":true,"prevent_damage_amount":999,"prevent_damage_duration":"until_end_of_turn","prevent_damage_from_creature_sources_this_turn":true,"prevent_damage_kind":"all_damage","prevent_damage_scope":"damage_from_creatures","prevent_source_constraints":{"card_types":["creature"]},"sorcery":false,"xmage_ability_classes":[],"xmage_effect_class":"PreventAllDamageByAllPermanentsEffect"}'::jsonb, '{"category":"protection","effect":"damage_prevention_shield","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EtherealHaze translated into ManaLoom runtime scope xmage_prevent_damage_from_creatures_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution prevention of damage from filtered creature sources until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('harmless assault', 'Harmless Assault', 'ce5c49e8d6fa039f6ef0779f2948babd', 'battle_rule_v1:5f3de78578b5094b87f338c98ae4b9a7', '{"battle_model_scope":"xmage_prevent_damage_from_creatures_spell_v1","duration":"until_end_of_turn","effect":"damage_prevention_shield","instant":true,"prevent_damage_amount":999,"prevent_damage_duration":"until_end_of_turn","prevent_damage_from_creature_sources_this_turn":true,"prevent_damage_kind":"combat_damage","prevent_damage_scope":"combat_damage_from_creatures","prevent_source_constraints":{"card_types":["creature"],"combat_role":"attacking"},"sorcery":false,"xmage_ability_classes":[],"xmage_effect_class":"PreventAllDamageByAllPermanentsEffect"}'::jsonb, '{"category":"protection","effect":"damage_prevention_shield","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HarmlessAssault translated into ManaLoom runtime scope xmage_prevent_damage_from_creatures_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution prevention of damage from filtered creature sources until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hunter''s ambush', 'Hunter''s Ambush', 'c25758a6bbd50a7d902c5c98b40764ac', 'battle_rule_v1:85209bbf30b3c8a3fd7ed15f58a779e2', '{"battle_model_scope":"xmage_prevent_damage_from_creatures_spell_v1","duration":"until_end_of_turn","effect":"damage_prevention_shield","instant":true,"prevent_damage_amount":999,"prevent_damage_duration":"until_end_of_turn","prevent_damage_from_creature_sources_this_turn":true,"prevent_damage_kind":"combat_damage","prevent_damage_scope":"combat_damage_from_creatures","prevent_source_constraints":{"card_types":["creature"],"exclude_colors":["G"]},"sorcery":false,"xmage_ability_classes":[],"xmage_effect_class":"PreventAllDamageByAllPermanentsEffect"}'::jsonb, '{"category":"protection","effect":"damage_prevention_shield","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HuntersAmbush translated into ManaLoom runtime scope xmage_prevent_damage_from_creatures_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution prevention of damage from filtered creature sources until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thwart the enemy', 'Thwart the Enemy', 'ad413164aca5d65f29503d075eaee7f8', 'battle_rule_v1:276afd80522f6d887335c2f46352b750', '{"battle_model_scope":"xmage_prevent_damage_from_creatures_spell_v1","duration":"until_end_of_turn","effect":"damage_prevention_shield","instant":true,"prevent_damage_amount":999,"prevent_damage_duration":"until_end_of_turn","prevent_damage_from_creature_sources_this_turn":true,"prevent_damage_kind":"all_damage","prevent_damage_scope":"damage_from_creatures","prevent_source_constraints":{"card_types":["creature"],"controller_scope":"opponents_control"},"sorcery":false,"xmage_ability_classes":[],"xmage_effect_class":"PreventAllDamageByAllPermanentsEffect"}'::jsonb, '{"category":"protection","effect":"damage_prevention_shield","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThwartTheEnemy translated into ManaLoom runtime scope xmage_prevent_damage_from_creatures_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution prevention of damage from filtered creature sources until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vine snare', 'Vine Snare', '8bbd84b4d5d6a574896f766d9974bf80', 'battle_rule_v1:d0ac46bdd9ce7de24c3f2a13a6b4d0af', '{"battle_model_scope":"xmage_prevent_damage_from_creatures_spell_v1","duration":"until_end_of_turn","effect":"damage_prevention_shield","instant":true,"prevent_damage_amount":999,"prevent_damage_duration":"until_end_of_turn","prevent_damage_from_creature_sources_this_turn":true,"prevent_damage_kind":"combat_damage","prevent_damage_scope":"combat_damage_from_creatures","prevent_source_constraints":{"card_types":["creature"],"power_lte":4},"sorcery":false,"xmage_ability_classes":[],"xmage_effect_class":"PreventAllDamageByAllPermanentsEffect"}'::jsonb, '{"category":"protection","effect":"damage_prevention_shield","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VineSnare translated into ManaLoom runtime scope xmage_prevent_damage_from_creatures_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution prevention of damage from filtered creature sources until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg643_creature_source_prevention_new_ser_20260707_220414) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
