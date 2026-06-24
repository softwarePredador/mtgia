WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('elves of deep shadow', 'Elves of Deep Shadow', '5dd30cbea74064369bcba667795049e2', 'battle_rule_v1:1272fb910383d34360702e343ec16b37', '{"ability_kind":"activated","battle_model_scope":"one_mana_one_one_black_pain_mana_dork_v1","damage_on_tap":1,"effect":"creature","is_mana_source":true,"mana_produced":1,"power":1,"produces":"B","tap_damage_status":"annotation_only","toughness":1}'::jsonb, '{"category":"ramp","effect":"ramp_permanent","subtype":"mana_creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ElvesOfDeepShadow mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('talisman of curiosity', 'Talisman of Curiosity', '212d43a126a54d9aabbf1dec21b93acb', 'battle_rule_v1:c4df4800bcf67bfd2ded6ea1fc6a8efa', '{"ability_kind":"activated","battle_model_scope":"pain_talisman_color_pair_partial_v1","effect":"ramp_permanent","life_for_colored_mana":1,"mana_produced":1,"produces":"CUG"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class TalismanOfCuriosity mapped to family ramp_permanent; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('tarnished citadel', 'Tarnished Citadel', 'd8bdb24e586e16274f0bd42e40e2dc58', 'battle_rule_v1:d5663032352408a845b7602f9cb5adf9', '{"ability_kind":"activated","battle_model_scope":"colorless_or_any_color_pain_land_v1","effect":"land","life_for_colored_mana":3,"life_loss_on_colored_mana_status":"annotation_only","mana_produced":1,"produces":"CWUBRG"}'::jsonb, '{"category":"ramp","effect":"land","subtype":"mana_base","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class TarnishedCitadel mapped to family land; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg176_damage_controller_pain_sources_20260624_131434) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
