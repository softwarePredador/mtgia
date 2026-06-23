-- PG066 deck6 Birgi spell-cast resource engine apply.
-- Promotes an oracle-specific front-face runtime rule for Birgi.

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg066_deck6_birgi_spellcast_resource_engine_20260623_032200') IS NOT NULL THEN
    RAISE EXCEPTION 'Backup table manaloom_deploy_audit.pg066_deck6_birgi_spellcast_resource_engine_20260623_032200 already exists';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pg066_deck6_birgi_spellcast_resource_engine_20260623_032200 AS
SELECT *
FROM card_battle_rules
WHERE normalized_name = 'birgi, god of storytelling // harnfel, horn of bounty';

DO $$
DECLARE
  v_backup_rows integer;
  v_target_cards integer;
  v_deck6_cards integer;
  v_hash_matches integer;
  v_new_rule_rows integer;
BEGIN
  SELECT count(*) INTO v_backup_rows
  FROM manaloom_deploy_audit.pg066_deck6_birgi_spellcast_resource_engine_20260623_032200;

  SELECT count(*) INTO v_target_cards
  FROM cards
  WHERE lower(name) = 'birgi, god of storytelling // harnfel, horn of bounty';

  SELECT count(*) INTO v_deck6_cards
  FROM deck_cards dc
  JOIN cards c ON c.id = dc.card_id
  WHERE dc.deck_id = '528c877f-f829-4207-95e6-73981776c323'::uuid
    AND lower(c.name) = 'birgi, god of storytelling // harnfel, horn of bounty';

  SELECT count(*) INTO v_hash_matches
  FROM cards
  WHERE lower(name) = 'birgi, god of storytelling // harnfel, horn of bounty'
    AND md5(coalesce(oracle_text, '')) = '5f1ed696a63cd668fd46a2fe9971a54e';

  SELECT count(*) INTO v_new_rule_rows
  FROM card_battle_rules
  WHERE logical_rule_key = 'battle_rule_v1:05576012d8fca56910da7ea072abe15e';

  IF v_backup_rows <> 2 THEN
    RAISE EXCEPTION 'PG066 precondition failed: backup_rows=% expected 2', v_backup_rows;
  END IF;
  IF v_target_cards <> 1 THEN
    RAISE EXCEPTION 'PG066 precondition failed: target_cards=% expected 1', v_target_cards;
  END IF;
  IF v_deck6_cards <> 1 THEN
    RAISE EXCEPTION 'PG066 precondition failed: deck6_cards=% expected 1', v_deck6_cards;
  END IF;
  IF v_hash_matches <> 1 THEN
    RAISE EXCEPTION 'PG066 precondition failed: oracle hash match rows=% expected 1', v_hash_matches;
  END IF;
  IF v_new_rule_rows <> 0 THEN
    RAISE EXCEPTION 'PG066 precondition failed: new rule rows already present=% expected 0', v_new_rule_rows;
  END IF;
END $$;

WITH target_rule(
  normalized_name,
  card_name,
  logical_rule_key,
  expected_oracle_hash,
  effect_json,
  deck_role_json,
  notes
) AS (
  VALUES (
    'birgi, god of storytelling // harnfel, horn of bounty',
    'Birgi, God of Storytelling // Harnfel, Horn of Bounty',
    'battle_rule_v1:05576012d8fca56910da7ea072abe15e',
    '5f1ed696a63cd668fd46a2fe9971a54e',
    '{"effect":"creature","cmc":3.0,"is_creature_permanent":true,"power":3,"toughness":3,"trigger":"spell_cast","spell_cast_add_mana":1,"spell_cast_mana_color":"R","produces":"R","mana_persists_steps":true,"battle_model_scope":"spell_cast_red_mana_trigger_v1","oracle_runtime_scope":"front_face_creature_spell_cast_add_red_runtime_back_face_annotation","back_face":{"name":"Harnfel, Horn of Bounty","type_line":"Legendary Artifact","effect":"impulse_draw_engine","requires_discard_card":true,"runtime_status":"annotation_only"},"back_face_runtime_status":"annotation_only","boast_runtime_status":"annotation_only","pg066_resource_engine_family":"deck6_triggered_resource_engines"}'::jsonb,
    '{"category":"engine","effect":"creature","subtype":"spell_cast_mana_engine","deck_package":"deck6_triggered_resource_engines"}'::jsonb,
    'PG066 2026-06-23: Birgi modeled as a creature permanent with front-face spell-cast red mana trigger. Back face Harnfel and boast text remain annotation-only until separate executor validation.'
  )
),
resolved AS (
  SELECT tr.*, c.id AS card_id, md5(coalesce(c.oracle_text, '')) AS live_oracle_hash
  FROM target_rule tr
  JOIN cards c ON lower(c.name) = tr.normalized_name
)
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
)
SELECT
  normalized_name,
  logical_rule_key,
  card_id,
  card_name,
  effect_json,
  deck_role_json,
  'curated',
  0.930,
  'active',
  'auto',
  1,
  expected_oracle_hash,
  notes,
  'codex_central_auditor_pg066',
  now(),
  now(),
  now(),
  now()
FROM resolved
WHERE live_oracle_hash = expected_oracle_hash
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
  updated_at = now(),
  last_seen_at = now();

UPDATE card_battle_rules cbr
SET
  review_status = 'deprecated',
  execution_status = 'disabled',
  notes = concat_ws(
    E'\n',
    nullif(cbr.notes, ''),
    'PG066 2026-06-23: Disabled superseded Birgi broad/shadow row after promoting oracle-specific front-face spell-cast red mana runtime rule.'
  ),
  updated_at = now(),
  last_seen_at = now()
WHERE cbr.normalized_name = 'birgi, god of storytelling // harnfel, horn of bounty'
  AND cbr.logical_rule_key <> 'battle_rule_v1:05576012d8fca56910da7ea072abe15e'
  AND cbr.review_status NOT IN ('deprecated', 'rejected')
  AND cbr.execution_status IN ('auto', 'executable', 'review_only', 'disabled');

COMMIT;
