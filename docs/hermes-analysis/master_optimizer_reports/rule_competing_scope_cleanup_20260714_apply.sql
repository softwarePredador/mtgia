\pset pager off
\set ON_ERROR_STOP on

BEGIN;

DO $$
DECLARE
  v_stale_rows integer;
  v_replacement_rows integer;
BEGIN
  IF to_regclass('manaloom_deploy_audit.rule_competing_scope_cleanup_20260714') IS NOT NULL THEN
    RAISE EXCEPTION 'cleanup backup already exists; refuse to overwrite rollback evidence';
  END IF;

  SELECT COUNT(*) INTO v_stale_rows
  FROM card_battle_rules
  WHERE (normalized_name, logical_rule_key) IN (
    ('chrome mox', 'battle_rule_v1:baf0ceea81b709c31104e0fcb4fc4e95'),
    ('mox diamond', 'battle_rule_v1:80a4b5beca8834e0c642dc8c0663106c'),
    ('wear // tear', 'battle_rule_v1:a89224366575c83b24415529fe686a0e'),
    ('brainstone', 'battle_rule_v1:31339242dbba07888e9dfe111bc1a531'),
    ('nature''s claim', 'battle_rule_v1:0ac8416f2210ff0a8466bfb61e3b4b4e'),
    ('pirate''s pillage', 'battle_rule_v1:f13cb9da00fe7eb3bf0fccef34e64d9e'),
    ('izzet signet', 'battle_rule_v1:a4b2c1fe2265135b1bf033d5a429d662'),
    ('mind stone', 'battle_rule_v1:53afed56bbee9885bfb6201f8587db07'),
    ('stonespeaker crystal', 'battle_rule_v1:38361118faf164900a80cacbfce1411b')
  )
    AND review_status IN ('verified', 'active')
    AND execution_status IN ('auto', 'executable');

  SELECT COUNT(*) INTO v_replacement_rows
  FROM card_battle_rules
  WHERE (normalized_name, logical_rule_key) IN (
    ('chrome mox', 'battle_rule_v1:4b4ae6ec37e017046c6671e1a5985f17'),
    ('mox diamond', 'battle_rule_v1:0a78dec9b9b2b0b5218b7d0a64a9afb3'),
    ('wear // tear', 'battle_rule_v1:04938744ea1c609cc9d77c851ee8bd08'),
    ('brainstone', 'battle_rule_v1:6aab083c9a25b2af50c2069683da5131'),
    ('nature''s claim', 'battle_rule_v1:b68a368de3add71ee716cda718b9bcb9'),
    ('pirate''s pillage', 'battle_rule_v1:5a9f1968c9e479adf7f1a9695bfb4965'),
    ('izzet signet', 'battle_rule_v1:0775d7b0089db2ee45cebb6804127f30'),
    ('mind stone', 'battle_rule_v1:3818b990dbad7de33216aee39fbb14c8'),
    ('stonespeaker crystal', 'battle_rule_v1:3b749c5de073394f1c912fa43d8e7c02')
  )
    AND review_status IN ('verified', 'active')
    AND execution_status IN ('auto', 'executable');

  IF v_stale_rows <> 9 OR v_replacement_rows <> 9 THEN
    RAISE EXCEPTION 'precheck failed: stale_rows=%, replacement_rows=%',
      v_stale_rows, v_replacement_rows;
  END IF;
END $$;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.rule_competing_scope_cleanup_20260714 AS
SELECT *
FROM card_battle_rules
WHERE (normalized_name, logical_rule_key) IN (
  ('chrome mox', 'battle_rule_v1:baf0ceea81b709c31104e0fcb4fc4e95'),
  ('mox diamond', 'battle_rule_v1:80a4b5beca8834e0c642dc8c0663106c'),
  ('wear // tear', 'battle_rule_v1:a89224366575c83b24415529fe686a0e'),
  ('brainstone', 'battle_rule_v1:31339242dbba07888e9dfe111bc1a531'),
  ('nature''s claim', 'battle_rule_v1:0ac8416f2210ff0a8466bfb61e3b4b4e'),
  ('pirate''s pillage', 'battle_rule_v1:f13cb9da00fe7eb3bf0fccef34e64d9e'),
  ('izzet signet', 'battle_rule_v1:a4b2c1fe2265135b1bf033d5a429d662'),
  ('mind stone', 'battle_rule_v1:53afed56bbee9885bfb6201f8587db07'),
  ('stonespeaker crystal', 'battle_rule_v1:38361118faf164900a80cacbfce1411b')
);

DO $$
DECLARE
  v_backup_rows integer;
BEGIN
  SELECT COUNT(*) INTO v_backup_rows
  FROM manaloom_deploy_audit.rule_competing_scope_cleanup_20260714;
  IF v_backup_rows <> 9 THEN
    RAISE EXCEPTION 'backup expected 9 rows, got %', v_backup_rows;
  END IF;
END $$;

UPDATE card_battle_rules
SET
  review_status = 'deprecated',
  execution_status = 'disabled',
  notes = concat_ws(
    ' ',
    NULLIF(trim(COALESCE(notes, '')), ''),
    'Superseded by the exact executable rule selected during the 2026-07-14 competing-scope validation.'
  ),
  updated_at = CURRENT_TIMESTAMP
WHERE (normalized_name, logical_rule_key) IN (
  ('chrome mox', 'battle_rule_v1:baf0ceea81b709c31104e0fcb4fc4e95'),
  ('mox diamond', 'battle_rule_v1:80a4b5beca8834e0c642dc8c0663106c'),
  ('wear // tear', 'battle_rule_v1:a89224366575c83b24415529fe686a0e'),
  ('brainstone', 'battle_rule_v1:31339242dbba07888e9dfe111bc1a531'),
  ('nature''s claim', 'battle_rule_v1:0ac8416f2210ff0a8466bfb61e3b4b4e'),
  ('pirate''s pillage', 'battle_rule_v1:f13cb9da00fe7eb3bf0fccef34e64d9e'),
  ('izzet signet', 'battle_rule_v1:a4b2c1fe2265135b1bf033d5a429d662'),
  ('mind stone', 'battle_rule_v1:53afed56bbee9885bfb6201f8587db07'),
  ('stonespeaker crystal', 'battle_rule_v1:38361118faf164900a80cacbfce1411b')
)
  AND review_status IN ('verified', 'active')
  AND execution_status IN ('auto', 'executable');

DO $$
DECLARE
  v_changed_rows integer;
  v_competing_groups integer;
BEGIN
  SELECT COUNT(*) INTO v_changed_rows
  FROM card_battle_rules
  WHERE (normalized_name, logical_rule_key) IN (
    ('chrome mox', 'battle_rule_v1:baf0ceea81b709c31104e0fcb4fc4e95'),
    ('mox diamond', 'battle_rule_v1:80a4b5beca8834e0c642dc8c0663106c'),
    ('wear // tear', 'battle_rule_v1:a89224366575c83b24415529fe686a0e'),
    ('brainstone', 'battle_rule_v1:31339242dbba07888e9dfe111bc1a531'),
    ('nature''s claim', 'battle_rule_v1:0ac8416f2210ff0a8466bfb61e3b4b4e'),
    ('pirate''s pillage', 'battle_rule_v1:f13cb9da00fe7eb3bf0fccef34e64d9e'),
    ('izzet signet', 'battle_rule_v1:a4b2c1fe2265135b1bf033d5a429d662'),
    ('mind stone', 'battle_rule_v1:53afed56bbee9885bfb6201f8587db07'),
    ('stonespeaker crystal', 'battle_rule_v1:38361118faf164900a80cacbfce1411b')
  )
    AND review_status = 'deprecated'
    AND execution_status = 'disabled';

  SELECT COUNT(*) INTO v_competing_groups
  FROM (
    SELECT
      card_id,
      effect_json->>'effect' AS effect,
      effect_json->>'battle_model_scope' AS battle_model_scope
    FROM card_battle_rules
    WHERE card_id IS NOT NULL
      AND review_status IN ('verified', 'active')
      AND execution_status IN ('auto', 'executable')
      AND COALESCE(effect_json->>'effect', '') <> ''
      AND COALESCE(effect_json->>'battle_model_scope', '') <> ''
    GROUP BY card_id, effect, battle_model_scope
    HAVING COUNT(DISTINCT logical_rule_key) > 1
  ) competing;

  IF v_changed_rows <> 9 OR v_competing_groups <> 0 THEN
    RAISE EXCEPTION 'postcheck failed: changed_rows=%, competing_groups=%',
      v_changed_rows, v_competing_groups;
  END IF;
END $$;

COMMIT;

SELECT normalized_name, logical_rule_key, review_status, execution_status
FROM card_battle_rules
WHERE (normalized_name, logical_rule_key) IN (
  ('chrome mox', 'battle_rule_v1:baf0ceea81b709c31104e0fcb4fc4e95'),
  ('mox diamond', 'battle_rule_v1:80a4b5beca8834e0c642dc8c0663106c'),
  ('wear // tear', 'battle_rule_v1:a89224366575c83b24415529fe686a0e'),
  ('brainstone', 'battle_rule_v1:31339242dbba07888e9dfe111bc1a531'),
  ('nature''s claim', 'battle_rule_v1:0ac8416f2210ff0a8466bfb61e3b4b4e'),
  ('pirate''s pillage', 'battle_rule_v1:f13cb9da00fe7eb3bf0fccef34e64d9e'),
  ('izzet signet', 'battle_rule_v1:a4b2c1fe2265135b1bf033d5a429d662'),
  ('mind stone', 'battle_rule_v1:53afed56bbee9885bfb6201f8587db07'),
  ('stonespeaker crystal', 'battle_rule_v1:38361118faf164900a80cacbfce1411b')
)
ORDER BY normalized_name;
