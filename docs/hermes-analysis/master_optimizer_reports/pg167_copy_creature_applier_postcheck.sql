WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('imposter mech', 'Imposter Mech', '35f38b34bb79ee6327a68ece8587f7a1', 'battle_rule_v1:4f317236846bce55c91965bb4605762f', '{"ability_kind":"replacement","battle_model_scope":"etb_copy_target_creature_with_copy_applier_modifiers_v1","copy_overwrite_subtypes":["Vehicle"],"copy_overwrite_types":["artifact"],"copy_target_types":["creature"],"copy_vehicle_crew_value":3,"effect":"copy_permanent_etb","target_controller":"opponent"}'::jsonb, '{"category":"board_development","effect":"copy_permanent_etb","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ImposterMech mapped to family copy_permanent_etb; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('mockingbird', 'Mockingbird', 'f3b499fed5cd401f51e14b49fc2c9edd', 'battle_rule_v1:43e3543e0e752d74fab3cf0a170d081e', '{"ability_kind":"replacement","battle_model_scope":"etb_copy_target_creature_with_copy_applier_modifiers_v1","copy_additional_subtypes":["Bird"],"copy_granted_keywords":["flying"],"copy_target_mana_value_lte_source_mana_value":true,"copy_target_types":["creature"],"effect":"copy_permanent_etb","target_controller":"any"}'::jsonb, '{"category":"board_development","effect":"copy_permanent_etb","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Mockingbird mapped to family copy_permanent_etb; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('flesh duplicate', 'Flesh Duplicate', '93e6894ab82a238b50dcbbbd1a8d9e68', 'battle_rule_v1:03e13973df9fbbf9ad781f5ace004f05', '{"ability_kind":"replacement","battle_model_scope":"etb_copy_target_creature_with_copy_applier_modifiers_v1","copy_grant_vanishing_if_missing":3,"copy_target_types":["creature"],"effect":"copy_permanent_etb","target_controller":"any"}'::jsonb, '{"category":"board_development","effect":"copy_permanent_etb","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class FleshDuplicate mapped to family copy_permanent_etb; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('phantasmal image', 'Phantasmal Image', 'd354295810b0219eb38e5137a0ba0e9f', 'battle_rule_v1:e2b5d8a5284d2c8a2b986ecc343702cd', '{"ability_kind":"replacement","battle_model_scope":"etb_copy_target_creature_with_copy_applier_modifiers_v1","copy_additional_subtypes":["Illusion"],"copy_sacrifice_when_targeted":true,"copy_target_types":["creature"],"effect":"copy_permanent_etb","target_controller":"any"}'::jsonb, '{"category":"board_development","effect":"copy_permanent_etb","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class PhantasmalImage mapped to family copy_permanent_etb; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg167_copy_creature_applier_20260624_111913) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
