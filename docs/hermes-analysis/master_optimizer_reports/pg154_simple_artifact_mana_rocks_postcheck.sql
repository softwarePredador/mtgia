WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('sol ring', 'Sol Ring', '7d286f5619ac8934fb07abf152ffcb60', 'battle_rule_v1:42621fcae461313f674d46db0da059af', '{"ability_kind":"activated","battle_model_scope":"two_colorless_mana_rock_v1","effect":"ramp_permanent","mana_produced":2,"produces":"C"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class SolRing mapped to family ramp_permanent; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('izzet signet', 'Izzet Signet', '7243690f1b89dbe49c9cdf029e9067ce', 'battle_rule_v1:0775d7b0089db2ee45cebb6804127f30', '{"ability_kind":"activated","activation_cost_generic":1,"battle_model_scope":"signet_filter_mana_rock_v1","effect":"ramp_permanent","mana_produced":1,"produces":"UR"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class IzzetSignet mapped to family ramp_permanent; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('simic signet', 'Simic Signet', '7d50b0e12552ce0724250722b0684413', 'battle_rule_v1:30db5769cdff5aa7b67f163881e563e4', '{"ability_kind":"activated","activation_cost_generic":1,"battle_model_scope":"signet_filter_mana_rock_v1","effect":"ramp_permanent","mana_produced":1,"produces":"GU"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class SimicSignet mapped to family ramp_permanent; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg154_simple_artifact_mana_rocks_20260624_081824) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
