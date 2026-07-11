WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('limits of solidarity', 'Limits of Solidarity', '97d530936b58bcb36b4c9c800aefa735', 'battle_rule_v1:6ce7a3f438ef24898acb9752b339da34', '{"battle_model_scope":"xmage_gain_control_untap_haste_until_eot_spell_v1","control_duration":"until_end_of_turn","duration":"until_end_of_turn","effect":"gain_control_untap_haste_until_eot","granted_keywords_until_eot":["haste"],"instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"opponents","untap_target":true,"xmage_ability_classes":["HasteAbility"],"xmage_auxiliary_ability_classes":["CyclingAbility"],"xmage_effect_classes":["GainAbilityTargetEffect","GainControlTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"gain_control_untap_haste_until_eot","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LimitsOfSolidarity translated into ManaLoom runtime scope xmage_gain_control_untap_haste_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lose calm', 'Lose Calm', '4ea4da54e2b8bde35d5191a16c619a27', 'battle_rule_v1:573432282ac3a549c0b92e63411822bf', '{"battle_model_scope":"xmage_gain_control_untap_haste_until_eot_spell_v1","control_duration":"until_end_of_turn","duration":"until_end_of_turn","effect":"gain_control_untap_haste_until_eot","granted_keywords_until_eot":["menace","haste"],"instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"opponents","untap_target":true,"xmage_ability_classes":["HasteAbility","MenaceAbility"],"xmage_auxiliary_ability_classes":[],"xmage_effect_classes":["GainAbilityTargetEffect","GainControlTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"gain_control_untap_haste_until_eot","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LoseCalm translated into ManaLoom runtime scope xmage_gain_control_untap_haste_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('traitorous blood', 'Traitorous Blood', '2dc0dabd8fdfa87df086e28fa2d4cebb', 'battle_rule_v1:d74301b0270ea6b58123c825a9e9cfeb', '{"battle_model_scope":"xmage_gain_control_untap_haste_until_eot_spell_v1","control_duration":"until_end_of_turn","duration":"until_end_of_turn","effect":"gain_control_untap_haste_until_eot","granted_keywords_until_eot":["trample","haste"],"instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"opponents","untap_target":true,"xmage_ability_classes":["HasteAbility","TrampleAbility"],"xmage_auxiliary_ability_classes":[],"xmage_effect_classes":["GainAbilityTargetEffect","GainControlTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"gain_control_untap_haste_until_eot","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TraitorousBlood translated into ManaLoom runtime scope xmage_gain_control_untap_haste_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('turn against', 'Turn Against', 'a23a5399a4617178bbb4cc3efeaedd61', 'battle_rule_v1:58efd5d9ff4dfe4da0a6020717665c2b', '{"battle_model_scope":"xmage_gain_control_untap_haste_until_eot_spell_v1","control_duration":"until_end_of_turn","duration":"until_end_of_turn","effect":"gain_control_untap_haste_until_eot","granted_keywords_until_eot":["haste"],"instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"opponents","untap_target":true,"xmage_ability_classes":["HasteAbility"],"xmage_auxiliary_ability_classes":["DevoidAbility"],"xmage_effect_classes":["GainAbilityTargetEffect","GainControlTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"gain_control_untap_haste_until_eot","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TurnAgainst translated into ManaLoom runtime scope xmage_gain_control_untap_haste_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('word of seizing', 'Word of Seizing', '3dd2cd63ab90a61f0838b7dfe2a00b24', 'battle_rule_v1:39e8db668df0c8f0cdbce692d226ba4c', '{"battle_model_scope":"xmage_gain_control_untap_haste_until_eot_spell_v1","control_duration":"until_end_of_turn","duration":"until_end_of_turn","effect":"gain_control_untap_haste_until_eot","granted_keywords_until_eot":["haste"],"instant":true,"sorcery":false,"target":"permanent","target_constraints":{"card_types":["permanent"]},"target_controller":"opponents","untap_target":true,"xmage_ability_classes":["HasteAbility"],"xmage_auxiliary_ability_classes":["SplitSecondAbility"],"xmage_effect_classes":["GainAbilityTargetEffect","GainControlTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"gain_control_untap_haste_until_eot","target":"permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WordOfSeizing translated into ManaLoom runtime scope xmage_gain_control_untap_haste_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg760_gain_control_keywords_new_server_g_20260711_121318) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
