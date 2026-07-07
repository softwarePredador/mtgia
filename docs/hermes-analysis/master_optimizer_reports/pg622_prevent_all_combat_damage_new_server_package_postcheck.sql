WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('angelsong', 'Angelsong', '41207c49996c4ac386e7dcd0821a24ec', 'battle_rule_v1:0ec0e4134d1272b446e1deaab61e2b8f', '{"_cycling_is_auxiliary":true,"battle_model_scope":"xmage_prevent_all_combat_damage_spell_v1","duration":"until_end_of_turn","effect":"damage_prevention_shield","has_cycling":true,"instant":true,"prevent_all_combat_damage_this_turn":true,"prevent_damage_amount":999,"prevent_damage_duration":"until_end_of_turn","prevent_damage_scope":"all_combat_damage","sorcery":false,"xmage_ability_classes":["CyclingAbility"],"xmage_effect_class":"PreventAllDamageByAllPermanentsEffect"}'::jsonb, '{"category":"protection","effect":"damage_prevention_shield","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Angelsong translated into ManaLoom runtime scope xmage_prevent_all_combat_damage_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution prevention of all combat damage until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('darkness', 'Darkness', 'ed128f5a827bf1670b8f9e8657506aca', 'battle_rule_v1:46c32a90131f7b4e260f45cd83226e08', '{"battle_model_scope":"xmage_prevent_all_combat_damage_spell_v1","duration":"until_end_of_turn","effect":"damage_prevention_shield","instant":true,"prevent_all_combat_damage_this_turn":true,"prevent_damage_amount":999,"prevent_damage_duration":"until_end_of_turn","prevent_damage_scope":"all_combat_damage","sorcery":false,"xmage_ability_classes":[],"xmage_effect_class":"PreventAllDamageByAllPermanentsEffect"}'::jsonb, '{"category":"protection","effect":"damage_prevention_shield","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Darkness translated into ManaLoom runtime scope xmage_prevent_all_combat_damage_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution prevention of all combat damage until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('haze of pollen', 'Haze of Pollen', '48694a840ec24a39385551b915aee836', 'battle_rule_v1:0ec0e4134d1272b446e1deaab61e2b8f', '{"_cycling_is_auxiliary":true,"battle_model_scope":"xmage_prevent_all_combat_damage_spell_v1","duration":"until_end_of_turn","effect":"damage_prevention_shield","has_cycling":true,"instant":true,"prevent_all_combat_damage_this_turn":true,"prevent_damage_amount":999,"prevent_damage_duration":"until_end_of_turn","prevent_damage_scope":"all_combat_damage","sorcery":false,"xmage_ability_classes":["CyclingAbility"],"xmage_effect_class":"PreventAllDamageByAllPermanentsEffect"}'::jsonb, '{"category":"protection","effect":"damage_prevention_shield","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HazeOfPollen translated into ManaLoom runtime scope xmage_prevent_all_combat_damage_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution prevention of all combat damage until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('holy day', 'Holy Day', 'ed128f5a827bf1670b8f9e8657506aca', 'battle_rule_v1:46c32a90131f7b4e260f45cd83226e08', '{"battle_model_scope":"xmage_prevent_all_combat_damage_spell_v1","duration":"until_end_of_turn","effect":"damage_prevention_shield","instant":true,"prevent_all_combat_damage_this_turn":true,"prevent_damage_amount":999,"prevent_damage_duration":"until_end_of_turn","prevent_damage_scope":"all_combat_damage","sorcery":false,"xmage_ability_classes":[],"xmage_effect_class":"PreventAllDamageByAllPermanentsEffect"}'::jsonb, '{"category":"protection","effect":"damage_prevention_shield","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HolyDay translated into ManaLoom runtime scope xmage_prevent_all_combat_damage_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution prevention of all combat damage until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lull', 'Lull', '41207c49996c4ac386e7dcd0821a24ec', 'battle_rule_v1:0ec0e4134d1272b446e1deaab61e2b8f', '{"_cycling_is_auxiliary":true,"battle_model_scope":"xmage_prevent_all_combat_damage_spell_v1","duration":"until_end_of_turn","effect":"damage_prevention_shield","has_cycling":true,"instant":true,"prevent_all_combat_damage_this_turn":true,"prevent_damage_amount":999,"prevent_damage_duration":"until_end_of_turn","prevent_damage_scope":"all_combat_damage","sorcery":false,"xmage_ability_classes":["CyclingAbility"],"xmage_effect_class":"PreventAllDamageByAllPermanentsEffect"}'::jsonb, '{"category":"protection","effect":"damage_prevention_shield","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Lull translated into ManaLoom runtime scope xmage_prevent_all_combat_damage_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution prevention of all combat damage until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('root snare', 'Root Snare', 'ed128f5a827bf1670b8f9e8657506aca', 'battle_rule_v1:46c32a90131f7b4e260f45cd83226e08', '{"battle_model_scope":"xmage_prevent_all_combat_damage_spell_v1","duration":"until_end_of_turn","effect":"damage_prevention_shield","instant":true,"prevent_all_combat_damage_this_turn":true,"prevent_damage_amount":999,"prevent_damage_duration":"until_end_of_turn","prevent_damage_scope":"all_combat_damage","sorcery":false,"xmage_ability_classes":[],"xmage_effect_class":"PreventAllDamageByAllPermanentsEffect"}'::jsonb, '{"category":"protection","effect":"damage_prevention_shield","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RootSnare translated into ManaLoom runtime scope xmage_prevent_all_combat_damage_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution prevention of all combat damage until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg622_prevent_all_combat_damage_new_serv_20260707_152050) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
