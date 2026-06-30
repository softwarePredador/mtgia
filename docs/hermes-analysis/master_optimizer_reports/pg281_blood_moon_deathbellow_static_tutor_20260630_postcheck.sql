WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('blood moon', 'Blood Moon', 'f9b52f264dbb36074c8c151ad47331cb', 'battle_rule_v1:9466d5adbf4ce91ed93a8ae9c18ecd1a', '{"ability_kind":"static","affected_lands":"nonbasic","battle_model_scope":"nonbasic_lands_are_mountains_static_v1","effect":"passive","nonbasic_lands_are_mountains":true,"nonbasic_lands_produce":"R","resulting_basic_land_type":"mountain","static_rule_restriction":true,"suppresses_land_nonmana_abilities":true}'::jsonb, '{"category":"support","effect":"passive","timing":"static"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class BloodMoon mapped to family passive; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('deathbellow war cry', 'Deathbellow War Cry', 'eecf73eadb40281bfa698aeaa1ca6294', 'battle_rule_v1:1351ad9528edafe8a4fcb98d22697e64', '{"ability_kind":"one_shot","battle_model_scope":"search_up_to_four_minotaur_creatures_different_names_to_battlefield_v1","creature_type_filter":"Minotaur","different_names":true,"effect":"tutor","instant":false,"max_count":4,"sorcery":true,"subtype_filter":"Minotaur","target":"minotaur_creature_to_battlefield","tutor_destination":"battlefield"}'::jsonb, '{"category":"tutor","effect":"tutor","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class DeathbellowWarCry mapped to family tutor; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg281_blood_moon_deathbellow_static_tutor_20260630_13402) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
