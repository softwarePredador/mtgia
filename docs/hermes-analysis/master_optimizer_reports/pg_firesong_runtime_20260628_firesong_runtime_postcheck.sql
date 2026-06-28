WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('firesong and sunspeaker', 'Firesong and Sunspeaker', '834cfb8f0f869e7e9b4bc5342ad63046', 'battle_rule_v1:56ed490d005e3803aa6461859b1a3fd7', '{"ability_kind":"triggered","battle_model_scope":"red_instant_sorcery_lifelink_white_lifegain_damage_v1","cmc":6.0,"effect":"creature","instant_sorcery_lifelink_colors":["R"],"instant_sorcery_spells_you_control_have_lifelink":true,"power":4,"target":"any_target","target_constraints":{"scope":"any_target"},"toughness":6,"trigger":"white_instant_sorcery_lifegain","trigger_effect":"damage_any_target","white_instant_sorcery_lifegain_trigger_damage":3}'::jsonb, '{"category":"burn_lifegain_engine","effect":"instant_sorcery_lifelink_lifegain_damage","subtype":"red_spell_lifelink_white_spell_lifegain_damage","timing":"static_and_triggered"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class FiresongAndSunspeaker mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg_firesong_runtime_20260628_firesong_runtime_20260628_1) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
