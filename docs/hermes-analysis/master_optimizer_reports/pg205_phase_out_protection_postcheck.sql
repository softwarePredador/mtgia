WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('clever concealment', 'Clever Concealment', '0758768c03fd70154a139abfbcded146', 'battle_rule_v1:945733dd08f8366a99033e707c400975', '{"ability_kind":"one_shot","battle_model_scope":"target_nonland_permanents_you_control_phase_out_v1","choice_model":"phase_out_all_legal_nonland_permanents_you_control","convoke":true,"effect":"phase_out","instant":true,"phase_out_all_permanents_you_control":true,"phase_out_includes_lands":false,"target":"nonland_permanents_you_control","target_constraints":{"card_types":["permanent"],"controller_scope":"source_controller","exclude_card_types":["land"],"target_count":"any_number"}}'::jsonb, '{"category":"protection","effect":"phase_out","subtype":"phase_out","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class CleverConcealment mapped to family phase_out_protection; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg205_phase_out_protection_20260625_061320) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
