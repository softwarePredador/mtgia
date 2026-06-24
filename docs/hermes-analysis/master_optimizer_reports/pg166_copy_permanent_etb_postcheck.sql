WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('copy enchantment', 'Copy Enchantment', 'e1e0ee06fa971e9233368741b7478a7d', 'battle_rule_v1:ca58149e510c6834c2ed6ae602074483', '{"ability_kind":"replacement","battle_model_scope":"etb_copy_target_permanent_with_optional_extra_type_v1","copy_target_types":["enchantment"],"effect":"copy_permanent_etb","target_controller":"any"}'::jsonb, '{"category":"board_development","effect":"copy_permanent_etb","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class CopyEnchantment mapped to family copy_permanent_etb; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('mirrormade', 'Mirrormade', '49a1b071e36257efbc6ddb75d03ac14a', 'battle_rule_v1:d267ffd54ecf9c5026b8aaf43076edc9', '{"ability_kind":"replacement","battle_model_scope":"etb_copy_target_permanent_with_optional_extra_type_v1","copy_target_types":["artifact","enchantment"],"effect":"copy_permanent_etb","target_controller":"any"}'::jsonb, '{"category":"board_development","effect":"copy_permanent_etb","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Mirrormade mapped to family copy_permanent_etb; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('phyrexian metamorph', 'Phyrexian Metamorph', 'f33412ad2deef26bceca34c6b467f890', 'battle_rule_v1:1c9b7206e4e878ac743fc9186cdf5beb', '{"ability_kind":"replacement","battle_model_scope":"etb_copy_target_permanent_with_optional_extra_type_v1","copy_additional_types":["artifact"],"copy_target_types":["artifact","creature"],"effect":"copy_permanent_etb","target_controller":"any"}'::jsonb, '{"category":"board_development","effect":"copy_permanent_etb","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class PhyrexianMetamorph mapped to family copy_permanent_etb; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('clever impersonator', 'Clever Impersonator', 'b5a888ad1107dbe2b4d9be83113e83bb', 'battle_rule_v1:743bc58026f68050c6ef7c902ce85cde', '{"ability_kind":"replacement","battle_model_scope":"etb_copy_target_permanent_with_optional_extra_type_v1","copy_target_types":["nonland_permanent"],"effect":"copy_permanent_etb","target_controller":"any"}'::jsonb, '{"category":"board_development","effect":"copy_permanent_etb","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class CleverImpersonator mapped to family copy_permanent_etb; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('copy artifact', 'Copy Artifact', '394ca9be04e11f918cac24d8cc648f1f', 'battle_rule_v1:d466142f168d3c2d58c0594eb14214c9', '{"ability_kind":"replacement","battle_model_scope":"etb_copy_target_permanent_with_optional_extra_type_v1","copy_additional_types":["enchantment"],"copy_target_types":["artifact"],"effect":"copy_permanent_etb","target_controller":"any"}'::jsonb, '{"category":"board_development","effect":"copy_permanent_etb","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class CopyArtifact mapped to family copy_permanent_etb; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg166_copy_permanent_etb_20260624_111014) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
