WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('cursed mirror', 'Cursed Mirror', '93b50442db2c2249c10e34671728801b', 'battle_rule_v1:e4964406f7479873bbab9b6266928a48', '{"ability_kind":"one_shot","activation_requires_tap":true,"battle_model_scope":"red_mana_rock_etb_copy_creature_haste_annotation_v1","effect":"ramp_permanent","etb_copy_grants_haste":true,"etb_copy_status":"annotation_only","etb_may_copy_any_creature_until_eot":true,"is_mana_source":true,"mana_produced":1,"nonmana_abilities_require_separate_scope":true,"nonmana_abilities_status":"etb_copy_creature_haste_annotation_only","permanent_type":"artifact","produces":"R"}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class CursedMirror mapped to family ramp_permanent; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg260_cursed_mirror_exact_runtime_20260629_20260629_1725) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
