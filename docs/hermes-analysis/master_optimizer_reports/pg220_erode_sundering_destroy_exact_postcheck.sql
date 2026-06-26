WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('erode', 'Erode', 'fade62a3cbc3e6987d7988b711a5a834', 'battle_rule_v1:dd175af9c77feea940de97138a916fe3', '{"ability_kind":"one_shot","basic_land_compensation_status":"annotation_only","battle_model_scope":"destroy_creature_or_planeswalker_target_controller_basic_land_tapped_annotation_v1","effect":"remove_permanent","instant":true,"target":"creature_or_planeswalker","target_controller_basic_land_tapped":true}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Erode mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('sundering eruption // volcanic fissure', 'Sundering Eruption // Volcanic Fissure', '09148a5a6f4d14c04a30bf19819e20b8', 'battle_rule_v1:98d0006543fc622cfc1d82991bd5a66a', '{"ability_kind":"one_shot","basic_land_compensation_status":"annotation_only","battle_model_scope":"destroy_target_land_target_controller_basic_land_tapped_nonfliers_cant_block_or_tapped_red_land_v1","cant_block_mode_status":"annotation_only","cant_block_target_restriction":"creatures_without_flying","effect":"remove_permanent","land_side_add_mana":"R","land_side_pay_three_life_else_tapped":true,"sorcery":true,"target":"land","target_controller_basic_land_tapped":true}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class SunderingEruption mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg220_erode_sundering_destroy_exact_20260626_030046) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
