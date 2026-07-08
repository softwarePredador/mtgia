WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('act of treason', 'Act of Treason', '314d7d72d85e8d60855b79224faa18a0', 'battle_rule_v1:199fac345843225e12ff24fe814702d7', '{"battle_model_scope":"xmage_gain_control_untap_haste_until_eot_spell_v1","control_duration":"until_end_of_turn","duration":"until_end_of_turn","effect":"gain_control_untap_haste_until_eot","granted_keywords_until_eot":["haste"],"instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"opponents","untap_target":true,"xmage_ability_classes":["HasteAbility"],"xmage_effect_classes":["GainAbilityTargetEffect","GainControlTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"gain_control_untap_haste_until_eot","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ActOfTreason translated into ManaLoom runtime scope xmage_gain_control_untap_haste_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('blind with anger', 'Blind with Anger', '162af0a71afdbc978f0e9530a2930b60', 'battle_rule_v1:1d33ee89a15a6b3fc2b5c63b1ba31d8c', '{"battle_model_scope":"xmage_gain_control_untap_haste_until_eot_spell_v1","control_duration":"until_end_of_turn","duration":"until_end_of_turn","effect":"gain_control_untap_haste_until_eot","granted_keywords_until_eot":["haste"],"instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_supertypes":["legendary"]},"target_controller":"opponents","untap_target":true,"xmage_ability_classes":["HasteAbility"],"xmage_effect_classes":["GainAbilityTargetEffect","GainControlTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"gain_control_untap_haste_until_eot","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BlindWithAnger translated into ManaLoom runtime scope xmage_gain_control_untap_haste_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('claim the firstborn', 'Claim the Firstborn', '4844d46e00c8278d9b188b290aa88777', 'battle_rule_v1:67e89d7ed196e92637743285bc65dace', '{"battle_model_scope":"xmage_gain_control_untap_haste_until_eot_spell_v1","control_duration":"until_end_of_turn","duration":"until_end_of_turn","effect":"gain_control_untap_haste_until_eot","granted_keywords_until_eot":["haste"],"instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"],"mana_value_max":3},"target_controller":"opponents","untap_target":true,"xmage_ability_classes":["HasteAbility"],"xmage_effect_classes":["GainAbilityTargetEffect","GainControlTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"gain_control_untap_haste_until_eot","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ClaimTheFirstborn translated into ManaLoom runtime scope xmage_gain_control_untap_haste_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hijack', 'Hijack', '3711f7d4278a254798ac98fbda59b936', 'battle_rule_v1:8d3585724a53c93157963888594819c6', '{"battle_model_scope":"xmage_gain_control_untap_haste_until_eot_spell_v1","control_duration":"until_end_of_turn","duration":"until_end_of_turn","effect":"gain_control_untap_haste_until_eot","granted_keywords_until_eot":["haste"],"instant":false,"sorcery":true,"target":"artifact_or_creature","target_constraints":{"card_types":["artifact","creature"]},"target_controller":"opponents","untap_target":true,"xmage_ability_classes":["HasteAbility"],"xmage_effect_classes":["GainAbilityTargetEffect","GainControlTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"gain_control_untap_haste_until_eot","target":"artifact_or_creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Hijack translated into ManaLoom runtime scope xmage_gain_control_untap_haste_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('metallic mastery', 'Metallic Mastery', 'c26c2a0a7881cd27fe7d29931ad559b3', 'battle_rule_v1:94992b67574bf9d7d4a187521ee18c6a', '{"battle_model_scope":"xmage_gain_control_untap_haste_until_eot_spell_v1","control_duration":"until_end_of_turn","duration":"until_end_of_turn","effect":"gain_control_untap_haste_until_eot","granted_keywords_until_eot":["haste"],"instant":false,"sorcery":true,"target":"artifact","target_constraints":{"card_types":["artifact"]},"target_controller":"opponents","untap_target":true,"xmage_ability_classes":["HasteAbility"],"xmage_effect_classes":["GainAbilityTargetEffect","GainControlTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"gain_control_untap_haste_until_eot","target":"artifact"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MetallicMastery translated into ManaLoom runtime scope xmage_gain_control_untap_haste_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('threaten', 'Threaten', '851f2791896c2e7d48ec022575763ce0', 'battle_rule_v1:199fac345843225e12ff24fe814702d7', '{"battle_model_scope":"xmage_gain_control_untap_haste_until_eot_spell_v1","control_duration":"until_end_of_turn","duration":"until_end_of_turn","effect":"gain_control_untap_haste_until_eot","granted_keywords_until_eot":["haste"],"instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"opponents","untap_target":true,"xmage_ability_classes":["HasteAbility"],"xmage_effect_classes":["GainAbilityTargetEffect","GainControlTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"gain_control_untap_haste_until_eot","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Threaten translated into ManaLoom runtime scope xmage_gain_control_untap_haste_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wrangle', 'Wrangle', '8be9095f8bcf4906391501cc2f94294f', 'battle_rule_v1:5cfcbf2ede0226e481d4fbc7e825d78c', '{"battle_model_scope":"xmage_gain_control_untap_haste_until_eot_spell_v1","control_duration":"until_end_of_turn","duration":"until_end_of_turn","effect":"gain_control_untap_haste_until_eot","granted_keywords_until_eot":["haste"],"instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"],"power_max":4},"target_controller":"opponents","untap_target":true,"xmage_ability_classes":["HasteAbility"],"xmage_effect_classes":["GainAbilityTargetEffect","GainControlTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"gain_control_untap_haste_until_eot","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Wrangle translated into ManaLoom runtime scope xmage_gain_control_untap_haste_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
