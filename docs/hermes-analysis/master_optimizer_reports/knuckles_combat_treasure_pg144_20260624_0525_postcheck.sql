WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('knuckles the echidna', 'Knuckles the Echidna', 'c1d16fe4ac367c244d328c560c58f1dd', 'battle_rule_v1:9a9beaa23c31ad3d60c8c593696399cf', '{"ability_kind":"triggered","battle_model_scope":"one_or_more_creatures_you_control_combat_damage_player_create_treasure_v1","double_strike":true,"effect":"ramp_engine","haste":true,"is_creature_permanent":true,"power":2,"toughness":4,"trample":true,"treasure_count":1,"trigger":"combat_damage_to_player","trigger_creatures_you_control":true,"upkeep_win_if_control_artifacts_at_least":30,"upkeep_win_status":"annotation_only"}'::jsonb, '{"category":"ramp","effect":"ramp_engine","timing":"triggered"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class KnucklesTheEchidna mapped to family ramp_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg144_knuckles_combat_treasure_20260624_052524) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
