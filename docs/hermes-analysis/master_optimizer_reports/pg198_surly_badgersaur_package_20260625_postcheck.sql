WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('surly badgersaur', 'Surly Badgersaur', '14e07cfa7107a44732b5631f2136be3e', 'battle_rule_v1:a4b42e4cef8bbab31819346e7b68a263', '{"ability_kind":"triggered","battle_model_scope":"surly_badgersaur_discard_card_type_triggers_v1","controller_discard_counter_count":1,"controller_discard_counter_type":"+1/+1","controller_discard_creature_add_plus_one_counter":true,"controller_discard_fight_optional":true,"controller_discard_fight_target":"up_to_one_creature_you_dont_control","controller_discard_land_create_treasure":true,"controller_discard_noncreature_nonland_fight":true,"controller_discard_treasure_count":1,"effect":"creature","power":3,"toughness":3,"trigger":"controller_discard"}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class SurlyBadgersaur mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg198_surly_badgersaur_20260625_015702) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
