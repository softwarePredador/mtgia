WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('angelsong', 'Angelsong', '41207c49996c4ac386e7dcd0821a24ec', 'battle_rule_v1:0ec0e4134d1272b446e1deaab61e2b8f', '{"_cycling_is_auxiliary":true,"battle_model_scope":"xmage_prevent_all_combat_damage_spell_v1","duration":"until_end_of_turn","effect":"damage_prevention_shield","has_cycling":true,"instant":true,"prevent_all_combat_damage_this_turn":true,"prevent_damage_amount":999,"prevent_damage_duration":"until_end_of_turn","prevent_damage_scope":"all_combat_damage","sorcery":false,"xmage_ability_classes":["CyclingAbility"],"xmage_effect_class":"PreventAllDamageByAllPermanentsEffect"}'::jsonb, '{"category":"protection","effect":"damage_prevention_shield","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Angelsong translated into ManaLoom runtime scope xmage_prevent_all_combat_damage_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution prevention of all combat damage until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('darkness', 'Darkness', 'ed128f5a827bf1670b8f9e8657506aca', 'battle_rule_v1:46c32a90131f7b4e260f45cd83226e08', '{"battle_model_scope":"xmage_prevent_all_combat_damage_spell_v1","duration":"until_end_of_turn","effect":"damage_prevention_shield","instant":true,"prevent_all_combat_damage_this_turn":true,"prevent_damage_amount":999,"prevent_damage_duration":"until_end_of_turn","prevent_damage_scope":"all_combat_damage","sorcery":false,"xmage_ability_classes":[],"xmage_effect_class":"PreventAllDamageByAllPermanentsEffect"}'::jsonb, '{"category":"protection","effect":"damage_prevention_shield","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Darkness translated into ManaLoom runtime scope xmage_prevent_all_combat_damage_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution prevention of all combat damage until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('haze of pollen', 'Haze of Pollen', '48694a840ec24a39385551b915aee836', 'battle_rule_v1:0ec0e4134d1272b446e1deaab61e2b8f', '{"_cycling_is_auxiliary":true,"battle_model_scope":"xmage_prevent_all_combat_damage_spell_v1","duration":"until_end_of_turn","effect":"damage_prevention_shield","has_cycling":true,"instant":true,"prevent_all_combat_damage_this_turn":true,"prevent_damage_amount":999,"prevent_damage_duration":"until_end_of_turn","prevent_damage_scope":"all_combat_damage","sorcery":false,"xmage_ability_classes":["CyclingAbility"],"xmage_effect_class":"PreventAllDamageByAllPermanentsEffect"}'::jsonb, '{"category":"protection","effect":"damage_prevention_shield","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HazeOfPollen translated into ManaLoom runtime scope xmage_prevent_all_combat_damage_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution prevention of all combat damage until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('holy day', 'Holy Day', 'ed128f5a827bf1670b8f9e8657506aca', 'battle_rule_v1:46c32a90131f7b4e260f45cd83226e08', '{"battle_model_scope":"xmage_prevent_all_combat_damage_spell_v1","duration":"until_end_of_turn","effect":"damage_prevention_shield","instant":true,"prevent_all_combat_damage_this_turn":true,"prevent_damage_amount":999,"prevent_damage_duration":"until_end_of_turn","prevent_damage_scope":"all_combat_damage","sorcery":false,"xmage_ability_classes":[],"xmage_effect_class":"PreventAllDamageByAllPermanentsEffect"}'::jsonb, '{"category":"protection","effect":"damage_prevention_shield","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HolyDay translated into ManaLoom runtime scope xmage_prevent_all_combat_damage_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution prevention of all combat damage until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lull', 'Lull', '41207c49996c4ac386e7dcd0821a24ec', 'battle_rule_v1:0ec0e4134d1272b446e1deaab61e2b8f', '{"_cycling_is_auxiliary":true,"battle_model_scope":"xmage_prevent_all_combat_damage_spell_v1","duration":"until_end_of_turn","effect":"damage_prevention_shield","has_cycling":true,"instant":true,"prevent_all_combat_damage_this_turn":true,"prevent_damage_amount":999,"prevent_damage_duration":"until_end_of_turn","prevent_damage_scope":"all_combat_damage","sorcery":false,"xmage_ability_classes":["CyclingAbility"],"xmage_effect_class":"PreventAllDamageByAllPermanentsEffect"}'::jsonb, '{"category":"protection","effect":"damage_prevention_shield","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Lull translated into ManaLoom runtime scope xmage_prevent_all_combat_damage_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution prevention of all combat damage until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('root snare', 'Root Snare', 'ed128f5a827bf1670b8f9e8657506aca', 'battle_rule_v1:46c32a90131f7b4e260f45cd83226e08', '{"battle_model_scope":"xmage_prevent_all_combat_damage_spell_v1","duration":"until_end_of_turn","effect":"damage_prevention_shield","instant":true,"prevent_all_combat_damage_this_turn":true,"prevent_damage_amount":999,"prevent_damage_duration":"until_end_of_turn","prevent_damage_scope":"all_combat_damage","sorcery":false,"xmage_ability_classes":[],"xmage_effect_class":"PreventAllDamageByAllPermanentsEffect"}'::jsonb, '{"category":"protection","effect":"damage_prevention_shield","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RootSnare translated into ManaLoom runtime scope xmage_prevent_all_combat_damage_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution prevention of all combat damage until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
