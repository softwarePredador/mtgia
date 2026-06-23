\pset pager off
\set ON_ERROR_STOP on

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DROP TABLE IF EXISTS manaloom_deploy_audit.pg028_austere_command_battle_rule_20260622_190701;
CREATE TABLE manaloom_deploy_audit.pg028_austere_command_battle_rule_20260622_190701 (
  section text NOT NULL,
  key text NOT NULL,
  payload jsonb NOT NULL,
  captured_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO manaloom_deploy_audit.pg028_austere_command_battle_rule_20260622_190701
  (section, key, payload)
SELECT
  'card_battle_rules',
  normalized_name || '|' || logical_rule_key,
  to_jsonb(cbr.*)
FROM card_battle_rules cbr
WHERE normalized_name = 'austere command'
   OR lower(card_name) = 'austere command';

DO $$
DECLARE
  v_card_rows int;
  v_hash_rows int;
  v_legacy_rows int;
BEGIN
  SELECT count(*) INTO v_card_rows
  FROM cards
  WHERE lower(name) = 'austere command';

  SELECT count(*) INTO v_hash_rows
  FROM cards
  WHERE lower(name) = 'austere command'
    AND md5(regexp_replace(lower(coalesce(oracle_text, '')), '\s+', ' ', 'g')) =
      'bce631c9a75d6856dd8c0d7de442b47f';

  SELECT count(*) INTO v_legacy_rows
  FROM card_battle_rules
  WHERE normalized_name = 'austere command'
    AND logical_rule_key <> 'battle_rule_v1:5f19a608b87445bcc5c7ebb7ad96eb64'
    AND effect_json->>'effect' = 'board_wipe'
    AND review_status NOT IN ('rejected', 'deprecated')
    AND execution_status IN ('auto', 'executable', 'review_only');

  IF v_card_rows <> 1 THEN
    RAISE EXCEPTION 'PG028 precondition failed: Austere Command card rows=% expected 1', v_card_rows;
  END IF;
  IF v_hash_rows <> 1 THEN
    RAISE EXCEPTION 'PG028 precondition failed: Austere Command oracle hash rows=% expected 1', v_hash_rows;
  END IF;
  IF v_legacy_rows = 0 THEN
    RAISE EXCEPTION 'PG028 precondition failed: no legacy Austere Command board_wipe row to repair';
  END IF;
END $$;

WITH target_rule AS (
  SELECT
    'austere command'::text AS normalized_name,
    'Austere Command'::text AS card_name,
    'battle_rule_v1:5f19a608b87445bcc5c7ebb7ad96eb64'::text AS logical_rule_key,
    'bce631c9a75d6856dd8c0d7de442b47f'::text AS oracle_hash,
    jsonb_build_object(
      'cmc', 6.0,
      'effect', 'board_wipe',
      'sorcery', true,
      'modal_destroy_modes', jsonb_build_array(
        'artifacts',
        'enchantments',
        'creatures_mana_value_3_or_less',
        'creatures_mana_value_4_or_greater'
      ),
      'choose_modes', 2,
      'battle_model_scope', 'austere_command_choose_two_destroy_modes_v1'
    ) AS effect_json,
    jsonb_build_object(
      'category', 'wipe',
      'effect', 'board_wipe',
      'subtype', 'modal_destroy_two_modes'
    ) AS deck_role_json,
    'PG-028: promoted Austere Command as a choose-two modal destroy spell. Oracle text destroys all artifacts, all enchantments, creatures with mana value 3 or less, and creatures with mana value 4 or greater; runtime chooses two modeled modes by live-board impact and records selected modes in replay events.'::text AS notes
),
resolved_card AS (
  SELECT tr.*, c.id
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
  id,
  card_name,
  effect_json,
  deck_role_json,
  'curated',
  0.930,
  'active',
  'auto',
  1,
  oracle_hash,
  notes,
  'codex_central_auditor_pg028',
  now(),
  now(),
  now(),
  now()
FROM resolved_card
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

UPDATE card_battle_rules
SET
  review_status = 'deprecated',
  execution_status = 'disabled',
  notes = concat_ws(
    ' ',
    nullif(notes, ''),
    'PG-028 disabled this broad/shadow Austere Command row after promoting oracle-specific modal destroy rule battle_rule_v1:5f19a608b87445bcc5c7ebb7ad96eb64.'
  ),
  updated_at = now(),
  last_seen_at = now()
WHERE normalized_name = 'austere command'
  AND logical_rule_key <> 'battle_rule_v1:5f19a608b87445bcc5c7ebb7ad96eb64'
  AND effect_json->>'effect' = 'board_wipe'
  AND review_status NOT IN ('rejected', 'deprecated')
  AND execution_status IN ('auto', 'executable', 'review_only');

SELECT
  'pg028_austere_command_apply_result' AS check_name,
  card_name,
  logical_rule_key,
  effect_json,
  source,
  confidence,
  review_status,
  execution_status,
  oracle_hash
FROM card_battle_rules
WHERE normalized_name = 'austere command'
ORDER BY source, review_status, execution_status, logical_rule_key;

COMMIT;
