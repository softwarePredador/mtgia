WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('pristine talisman', 'Pristine Talisman', 'bddb4a4e2c68a1625b1093dd2575a1c9', 'battle_rule_v1:00c2951a1600c393196c1027b5528586', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_with_gain_life_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_life_gain":1,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"artifact","produced_mana_symbols":["C"],"produces":"C","xmage_ability_classes":["ColorlessManaAbility"],"xmage_effect_classes":["GainLifeEffect"],"xmage_mana_ability_classes":["ColorlessManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PristineTalisman translated into ManaLoom runtime scope xmage_simple_tap_mana_source_with_gain_life_v1. This row is package-ready only because the source signature is a narrow mana-source permanent with fixed life gain on mana activation with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg716_mana_activation_life_gain_new_serv_20260710_192227) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
