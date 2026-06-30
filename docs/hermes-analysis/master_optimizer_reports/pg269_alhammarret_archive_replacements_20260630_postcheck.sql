WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('alhammarret''s archive', 'Alhammarret''s Archive', '88427c5aaa2391a1419a4e79a3690e4a', 'battle_rule_v1:b865a68cb5efcaf543f5ceda5d9ed599', '{"ability_kind":"static","battle_model_scope":"static_double_life_gain_and_draw_except_first_draw_step_v1","draw_on_enter":false,"draw_replacement_amount_multiplier":2,"draw_replacement_controller_only":true,"draw_replacement_double_except_first_draw_step":true,"draw_replacement_first_draw_step_exception":true,"effect":"draw_engine","legendary":true,"life_gain_multiplier":2,"life_gain_replacement_double":true,"permanent_type":"artifact"}'::jsonb, '{"category":"draw","effect":"draw_engine","subtype":"draw_and_life_gain_replacement","timing":"static_replacement"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class AlhammarretsArchive mapped to family draw_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg269_alhammarret_archive_replacements_20260630_alhammar) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
