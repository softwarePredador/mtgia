WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('nature''s rhythm', 'Nature''s Rhythm', '109e64b1ea27da04b6266d4e86b52aad', 'battle_rule_v1:6763f8258c7027a341e182900af5e8fc', '{"ability_kind":"one_shot","battle_model_scope":"creature_tutor_to_battlefield_mana_value_x_or_less_harmonize_v1","effect":"tutor","harmonize":true,"instant":false,"target":"creature_to_battlefield","target_mana_value_max_from_x":true}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class NaturesRhythm mapped to family tutor; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('chord of calling', 'Chord of Calling', '8399842a5c007c7f4b890bfdf3f84521', 'battle_rule_v1:1250cdd03a9389a2fe31e53ac5766394', '{"ability_kind":"one_shot","battle_model_scope":"convoke_creature_tutor_to_battlefield_mana_value_x_or_less_v1","convoke":true,"effect":"tutor","instant":true,"target":"creature_to_battlefield","target_mana_value_max_from_x":true}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ChordOfCalling mapped to family tutor; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('green sun''s zenith', 'Green Sun''s Zenith', 'cfaabe0e9d9d20d134845c8f4b946e1e', 'battle_rule_v1:c1c56ae7a9b9e0cae540e39cecb4f157', '{"ability_kind":"one_shot","battle_model_scope":"green_creature_tutor_to_battlefield_mana_value_x_or_less_then_shuffle_self_v1","effect":"tutor","instant":false,"shuffle_self_into_library_on_resolution":true,"target":"green_creature_to_battlefield","target_mana_value_max_from_x":true}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class GreenSunsZenith mapped to family tutor; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('whir of invention', 'Whir of Invention', '47a15ce5ca279f509f387d3909695959', 'battle_rule_v1:719bc165cd6259a33d138d4fe2b1d2a2', '{"ability_kind":"one_shot","battle_model_scope":"improvise_artifact_tutor_to_battlefield_mana_value_x_or_less_v1","effect":"tutor","improvise":true,"instant":true,"target":"artifact_to_battlefield","target_mana_value_max_from_x":true}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class WhirOfInvention mapped to family tutor; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg173_x_tutor_battlefield_spells_20260624_123404) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
