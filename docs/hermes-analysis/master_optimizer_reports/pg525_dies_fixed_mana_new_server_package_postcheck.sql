WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('cathodion', 'Cathodion', '8eee9f6f80a8f71952699262b53de665', 'battle_rule_v1:99e2345f9e2822ce6c5f437fa28dbfe4', '{"ability_kind":"triggered","battle_model_scope":"xmage_permanent_dies_add_fixed_mana_v1","dies_mana_produced":3,"dies_produced_mana_symbols":["C","C","C"],"dies_produces":"C","effect":"creature","instant":false,"permanent_type":"artifact_creature","sorcery":false,"trigger":"dies","trigger_effect":"add_mana","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"BasicManaEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Cathodion translated into ManaLoom runtime scope xmage_permanent_dies_add_fixed_mana_v1. This row is package-ready only because the source signature is a narrow permanent with fixed dies mana trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('myr moonvessel', 'Myr Moonvessel', 'bedc3ee1326649ad0f54b11502533026', 'battle_rule_v1:d21552b190e879250ea80be10bbd88da', '{"ability_kind":"triggered","battle_model_scope":"xmage_permanent_dies_add_fixed_mana_v1","dies_mana_produced":1,"dies_produced_mana_symbols":["C"],"dies_produces":"C","effect":"creature","instant":false,"permanent_type":"artifact_creature","sorcery":false,"trigger":"dies","trigger_effect":"add_mana","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"BasicManaEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MyrMoonvessel translated into ManaLoom runtime scope xmage_permanent_dies_add_fixed_mana_v1. This row is package-ready only because the source signature is a narrow permanent with fixed dies mana trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('su-chi', 'Su-Chi', '304214b937f688ed7bf116c9d7a9bb68', 'battle_rule_v1:50e81199eb12ebc399f9655afa70bd0c', '{"ability_kind":"triggered","battle_model_scope":"xmage_permanent_dies_add_fixed_mana_v1","dies_mana_produced":4,"dies_produced_mana_symbols":["C","C","C","C"],"dies_produces":"C","effect":"creature","instant":false,"permanent_type":"artifact_creature","sorcery":false,"trigger":"dies","trigger_effect":"add_mana","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"BasicManaEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SuChi translated into ManaLoom runtime scope xmage_permanent_dies_add_fixed_mana_v1. This row is package-ready only because the source signature is a narrow permanent with fixed dies mana trigger with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.xmage_pg525_dies_fixed_mana_new_server_p_20260705_192227) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
