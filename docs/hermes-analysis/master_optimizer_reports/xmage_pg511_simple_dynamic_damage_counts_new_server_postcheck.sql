WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('runeflare trap', 'Runeflare Trap', '9ed6a2b25bb33ab63a5e733b7354d270', 'battle_rule_v1:f86cf719c13e031f50a9270dc8564003', '{"amount":0,"battle_model_scope":"xmage_dynamic_count_damage_spell_v1","damage":0,"damage_amount_source":"target_hand_count","damage_base_amount":0,"damage_per_count":1,"effect":"direct_damage","instant":true,"sorcery":false,"target":"player","target_constraints":{"scope":"player"},"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"player","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RuneflareTrap translated into ManaLoom runtime scope xmage_dynamic_count_damage_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('storm seeker', 'Storm Seeker', '432038c0d3717ce675fac8ddfb615e9e', 'battle_rule_v1:f86cf719c13e031f50a9270dc8564003', '{"amount":0,"battle_model_scope":"xmage_dynamic_count_damage_spell_v1","damage":0,"damage_amount_source":"target_hand_count","damage_base_amount":0,"damage_per_count":1,"effect":"direct_damage","instant":true,"sorcery":false,"target":"player","target_constraints":{"scope":"player"},"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"player","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StormSeeker translated into ManaLoom runtime scope xmage_dynamic_count_damage_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sudden impact', 'Sudden Impact', '8bc700f1247132390e805ef5c1d72e98', 'battle_rule_v1:f86cf719c13e031f50a9270dc8564003', '{"amount":0,"battle_model_scope":"xmage_dynamic_count_damage_spell_v1","damage":0,"damage_amount_source":"target_hand_count","damage_base_amount":0,"damage_per_count":1,"effect":"direct_damage","instant":true,"sorcery":false,"target":"player","target_constraints":{"scope":"player"},"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"player","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SuddenImpact translated into ManaLoom runtime scope xmage_dynamic_count_damage_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thunder salvo', 'Thunder Salvo', '0f8d6f811660e869eac237246dd8cdd5', 'battle_rule_v1:102529d74981d821d4e9827b80d25c5a', '{"amount":0,"battle_model_scope":"xmage_dynamic_count_damage_spell_v1","damage":0,"damage_amount_source":"other_spells_cast_this_turn","damage_base_amount":2,"damage_per_count":1,"effect":"direct_damage","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThunderSalvo translated into ManaLoom runtime scope xmage_dynamic_count_damage_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg511_xmage_pg511_simple_dynamic_damage_20260705_143220) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
