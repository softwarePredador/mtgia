\set ON_ERROR_STOP on

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg007_leyline_abundance_battle_rule_20260620_1018 AS
SELECT now() AS backed_up_at, *
FROM card_battle_rules
WHERE normalized_name = 'leyline of abundance'
  AND logical_rule_key = 'battle_rule_v1:f3c990ed2e762aaab17c617ac3a42941'
WITH NO DATA;

INSERT INTO manaloom_deploy_audit.pg007_leyline_abundance_battle_rule_20260620_1018
SELECT now() AS backed_up_at, cbr.*
FROM card_battle_rules cbr
WHERE cbr.normalized_name = 'leyline of abundance'
  AND cbr.logical_rule_key = 'battle_rule_v1:f3c990ed2e762aaab17c617ac3a42941'
ON CONFLICT DO NOTHING;

INSERT INTO card_battle_rules (
  normalized_name,
  logical_rule_key,
  card_id,
  card_name,
  effect_json,
  deck_role_json,
  source,
  confidence,
  review_status,
  execution_status,
  rule_version,
  oracle_hash,
  notes,
  reviewed_by,
  reviewed_at,
  created_at,
  updated_at,
  last_seen_at
) VALUES (
  'leyline of abundance',
  'battle_rule_v1:f3c990ed2e762aaab17c617ac3a42941',
  'd524183f-6430-411b-8a9b-48eda6cb0f7d'::uuid,
  'Leyline of Abundance',
  '{"ability_kind":"static","activated_counter_ability_not_modeled":true,"battle_model_scope":"leyline_of_abundance_static_mana_bonus_partial_v1","cmc":4.0,"effect":"ramp_permanent","mana_bonus_amount":1,"mana_bonus_color":"G","static_mana_bonus_for_creatures":true}'::jsonb,
  '{"category":"ramp","effect":"ramp_permanent","subtype":"static_mana_bonus_enchantment"}'::jsonb,
  'curated',
  0.820,
  'active',
  'auto',
  1,
  NULL,
  'PG-007: trace Leyline of Abundance spell-cast ramp_permanent fallback seen in battle latest 20260620_125745 seed_63211258. Runtime behavior remains the existing ramp_permanent battlefield approximation; static mana bonus is partial and activated counter ability is not modeled.',
  'auditor_central',
  CURRENT_TIMESTAMP,
  CURRENT_TIMESTAMP,
  CURRENT_TIMESTAMP,
  CURRENT_TIMESTAMP
)
ON CONFLICT (normalized_name, logical_rule_key) DO UPDATE SET
  card_id = EXCLUDED.card_id,
  card_name = EXCLUDED.card_name,
  effect_json = EXCLUDED.effect_json,
  deck_role_json = EXCLUDED.deck_role_json,
  source = EXCLUDED.source,
  confidence = EXCLUDED.confidence,
  review_status = EXCLUDED.review_status,
  execution_status = EXCLUDED.execution_status,
  rule_version = EXCLUDED.rule_version,
  oracle_hash = EXCLUDED.oracle_hash,
  notes = EXCLUDED.notes,
  reviewed_by = EXCLUDED.reviewed_by,
  reviewed_at = EXCLUDED.reviewed_at,
  updated_at = CURRENT_TIMESTAMP,
  last_seen_at = CURRENT_TIMESTAMP;

SELECT 'pg007_apply_result' AS check_name,
       normalized_name,
       logical_rule_key,
       card_id,
       card_name,
       source,
       review_status,
       execution_status,
       confidence,
       effect_json::text AS effect_json,
       deck_role_json::text AS deck_role_json
FROM card_battle_rules
WHERE normalized_name = 'leyline of abundance'
  AND logical_rule_key = 'battle_rule_v1:f3c990ed2e762aaab17c617ac3a42941';

COMMIT;
