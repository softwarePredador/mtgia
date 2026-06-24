WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('treasure vault', 'Treasure Vault', '8b779ddf95f004e28c281873c3a2a091', 'battle_rule_v1:67aa4bb13af58f2ee2cd320a52d37de6', '{"ability_kind":"activated","activation_cost_generic_is_x_twice":true,"activation_requires_sacrifice":true,"activation_requires_tap":true,"battle_model_scope":"activated_xx_tap_sacrifice_create_x_treasures_v1","effect":"treasure_maker","mana_produced":1,"produces":"C","treasure_count_per_x":1,"treasure_count_source":"x_value"}'::jsonb, '{"category":"ramp","effect":"treasure_maker","subtype":"treasure_conversion","timing":"activated_or_resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class TreasureVault mapped to family treasure_maker; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg145_treasure_vault_x_treasure_land_20260624_055034) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
