WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('coal stoker', 'Coal Stoker', '30f3d291f75d0e6fccda1c89d8843189', 'battle_rule_v1:219016c5586f35bc0cfe9a4c7308703a', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_add_fixed_mana_v1","effect":"ramp_permanent","etb_mana_condition":"cast_from_hand","etb_mana_produced":3,"etb_produced_mana_symbols":["R","R","R"],"etb_produces":"R","instant":false,"is_mana_source":false,"mana_produced":3,"permanent_type":"creature","produced_mana_symbols":["R","R","R"],"produces":"R","sorcery":false,"trigger":"enters_battlefield","trigger_effect":"add_mana","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BasicManaEffect"}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CoalStoker translated into ManaLoom runtime scope xmage_creature_etb_add_fixed_mana_v1. This row is package-ready only because the source signature is a narrow creature with fixed enter-the-battlefield mana trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('iridescent tiger', 'Iridescent Tiger', '5320aef7894f806a2479d490088d1fa7', 'battle_rule_v1:40ddd485da3bf403787ae236f9fa35bb', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_add_fixed_mana_v1","effect":"ramp_permanent","etb_mana_condition":"cast","etb_mana_produced":5,"etb_produced_mana_symbols":["W","U","B","R","G"],"etb_produces":"WUBRG","instant":false,"is_mana_source":false,"mana_produced":5,"permanent_type":"creature","produced_mana_symbols":["W","U","B","R","G"],"produces":"WUBRG","sorcery":false,"trigger":"enters_battlefield","trigger_effect":"add_mana","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BasicManaEffect"}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class IridescentTiger translated into ManaLoom runtime scope xmage_creature_etb_add_fixed_mana_v1. This row is package-ready only because the source signature is a narrow creature with fixed enter-the-battlefield mana trigger with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg665_etb_conditional_cast_mana_new_serv_20260708_173414) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
