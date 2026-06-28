WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('boros reckoner', 'Boros Reckoner', '8cb6c980428b2501343f3f38dc686efb', 'battle_rule_v1:fe53d1b9c2f4ef62fddec4c92c2e02f1', '{"ability_kind":"triggered","activated_gain_first_strike_until_eot":true,"battle_model_scope":"source_dealt_damage_reflect_to_any_target_v1","cmc":3.0,"damage_amount_source":"damage_dealt_to_source","effect":"creature","first_strike_activation_cost":"{R/W}","power":3,"source_damage_reflect_to_any_target":true,"target":"any_target","target_constraints":{"scope":"any_target"},"toughness":3,"trigger":"source_dealt_damage","trigger_effect":"damage_any_target"}'::jsonb, '{"category":"burn_engine","effect":"damage_reflection","subtype":"source_damaged_reflect_any_target","timing":"triggered"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class BorosReckoner mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg_boros_reckoner_runtime_20260628_boros_reckoner_runtim) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
