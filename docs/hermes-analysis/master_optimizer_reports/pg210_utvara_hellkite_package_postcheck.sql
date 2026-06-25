WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('utvara hellkite', 'Utvara Hellkite', 'f3228e8b8e9f9938c173c5b82b529e7f', 'battle_rule_v1:012931e8f186299c8f59ebec2e9b1eb8', '{"ability_kind":"triggered","battle_model_scope":"dragon_you_control_attacks_create_6_6_red_flying_dragon_v1","effect":"token_maker","flying":true,"power":6,"token_colors":["R"],"token_count":1,"token_flying":true,"token_keywords":["flying"],"token_name":"Dragon Token","token_power":6,"token_subtype":"Dragon","token_toughness":6,"toughness":6,"trigger":"dragon_you_control_attacks","trigger_attacking_creature_subtype":"Dragon","trigger_effect":"token_maker","trigger_token_count":1}'::jsonb, '{"category":"board_development","effect":"token_maker","timing":"resolution_or_trigger"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class UtvaraHellkite mapped to family token_maker; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg210_utvara_hellkite_20260625_081209) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
