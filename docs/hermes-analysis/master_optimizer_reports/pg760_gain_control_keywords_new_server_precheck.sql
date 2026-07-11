WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('limits of solidarity', 'Limits of Solidarity', '97d530936b58bcb36b4c9c800aefa735', 'battle_rule_v1:6ce7a3f438ef24898acb9752b339da34', '{"battle_model_scope":"xmage_gain_control_untap_haste_until_eot_spell_v1","control_duration":"until_end_of_turn","duration":"until_end_of_turn","effect":"gain_control_untap_haste_until_eot","granted_keywords_until_eot":["haste"],"instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"opponents","untap_target":true,"xmage_ability_classes":["HasteAbility"],"xmage_auxiliary_ability_classes":["CyclingAbility"],"xmage_effect_classes":["GainAbilityTargetEffect","GainControlTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"gain_control_untap_haste_until_eot","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LimitsOfSolidarity translated into ManaLoom runtime scope xmage_gain_control_untap_haste_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lose calm', 'Lose Calm', '4ea4da54e2b8bde35d5191a16c619a27', 'battle_rule_v1:573432282ac3a549c0b92e63411822bf', '{"battle_model_scope":"xmage_gain_control_untap_haste_until_eot_spell_v1","control_duration":"until_end_of_turn","duration":"until_end_of_turn","effect":"gain_control_untap_haste_until_eot","granted_keywords_until_eot":["menace","haste"],"instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"opponents","untap_target":true,"xmage_ability_classes":["HasteAbility","MenaceAbility"],"xmage_auxiliary_ability_classes":[],"xmage_effect_classes":["GainAbilityTargetEffect","GainControlTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"gain_control_untap_haste_until_eot","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LoseCalm translated into ManaLoom runtime scope xmage_gain_control_untap_haste_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('traitorous blood', 'Traitorous Blood', '2dc0dabd8fdfa87df086e28fa2d4cebb', 'battle_rule_v1:d74301b0270ea6b58123c825a9e9cfeb', '{"battle_model_scope":"xmage_gain_control_untap_haste_until_eot_spell_v1","control_duration":"until_end_of_turn","duration":"until_end_of_turn","effect":"gain_control_untap_haste_until_eot","granted_keywords_until_eot":["trample","haste"],"instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"opponents","untap_target":true,"xmage_ability_classes":["HasteAbility","TrampleAbility"],"xmage_auxiliary_ability_classes":[],"xmage_effect_classes":["GainAbilityTargetEffect","GainControlTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"gain_control_untap_haste_until_eot","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TraitorousBlood translated into ManaLoom runtime scope xmage_gain_control_untap_haste_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('turn against', 'Turn Against', 'a23a5399a4617178bbb4cc3efeaedd61', 'battle_rule_v1:58efd5d9ff4dfe4da0a6020717665c2b', '{"battle_model_scope":"xmage_gain_control_untap_haste_until_eot_spell_v1","control_duration":"until_end_of_turn","duration":"until_end_of_turn","effect":"gain_control_untap_haste_until_eot","granted_keywords_until_eot":["haste"],"instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"opponents","untap_target":true,"xmage_ability_classes":["HasteAbility"],"xmage_auxiliary_ability_classes":["DevoidAbility"],"xmage_effect_classes":["GainAbilityTargetEffect","GainControlTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"gain_control_untap_haste_until_eot","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TurnAgainst translated into ManaLoom runtime scope xmage_gain_control_untap_haste_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('word of seizing', 'Word of Seizing', '3dd2cd63ab90a61f0838b7dfe2a00b24', 'battle_rule_v1:39e8db668df0c8f0cdbce692d226ba4c', '{"battle_model_scope":"xmage_gain_control_untap_haste_until_eot_spell_v1","control_duration":"until_end_of_turn","duration":"until_end_of_turn","effect":"gain_control_untap_haste_until_eot","granted_keywords_until_eot":["haste"],"instant":true,"sorcery":false,"target":"permanent","target_constraints":{"card_types":["permanent"]},"target_controller":"opponents","untap_target":true,"xmage_ability_classes":["HasteAbility"],"xmage_auxiliary_ability_classes":["SplitSecondAbility"],"xmage_effect_classes":["GainAbilityTargetEffect","GainControlTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"gain_control_untap_haste_until_eot","target":"permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WordOfSeizing translated into ManaLoom runtime scope xmage_gain_control_untap_haste_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
