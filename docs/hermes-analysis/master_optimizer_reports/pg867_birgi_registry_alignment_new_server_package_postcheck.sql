WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('birgi, god of storytelling', 'Birgi, God of Storytelling // Harnfel, Horn of Bounty', '5f1ed696a63cd668fd46a2fe9971a54e', 'battle_rule_v1:c21762e62b990dbb474be0b5764d71a7', '{"ability_kind":"triggered","back_face_harnfel_discard_exile_two_play_this_turn":true,"back_face_status":"annotation_only","battle_model_scope":"spell_cast_red_mana_trigger_boast_harnfel_annotation_v1","boast_twice_each_turn":true,"boast_twice_status":"annotation_only","cmc":3.0,"effect":"ramp_engine","is_creature_permanent":true,"mana_persists_steps":true,"power":3,"produces":"R","spell_cast_add_mana":1,"spell_cast_mana_color":"R","toughness":3,"trigger":"spell_cast"}'::jsonb, '{"category":"ramp","effect":"ramp_engine","subtype":"spell_cast_mana_engine"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage-authoritative Birgi front-face spell-cast red mana engine; boast-twice and Harnfel remain explicit annotations.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg867_birgi_registry_alignment_new_serve_20260715_153348) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
