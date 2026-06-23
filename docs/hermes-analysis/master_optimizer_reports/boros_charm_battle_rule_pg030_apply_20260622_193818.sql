\pset pager off
\set ON_ERROR_STOP on

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DROP TABLE IF EXISTS manaloom_deploy_audit.pg030_boros_charm_battle_rule_20260622_193818;
CREATE TABLE manaloom_deploy_audit.pg030_boros_charm_battle_rule_20260622_193818 (
  section text NOT NULL,
  key text NOT NULL,
  payload jsonb NOT NULL,
  captured_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO manaloom_deploy_audit.pg030_boros_charm_battle_rule_20260622_193818
  (section, key, payload)
SELECT
  'card_battle_rules',
  normalized_name || '|' || logical_rule_key,
  to_jsonb(cbr.*)
FROM card_battle_rules cbr
WHERE normalized_name = 'boros charm'
   OR lower(card_name) = 'boros charm';

DO $$
DECLARE
  v_card_rows int;
  v_hash_rows int;
  v_legacy_rows int;
BEGIN
  SELECT count(*) INTO v_card_rows
  FROM cards
  WHERE lower(name) = 'boros charm';

  SELECT count(*) INTO v_hash_rows
  FROM cards
  WHERE lower(name) = 'boros charm'
    AND md5(regexp_replace(lower(coalesce(oracle_text, '')), '\s+', ' ', 'g')) =
      '98a7be829075118b499a7c283a23501f';

  SELECT count(*) INTO v_legacy_rows
  FROM card_battle_rules
  WHERE normalized_name = 'boros charm'
    AND logical_rule_key <> 'battle_rule_v1:32605a838d7a519f44eaa0899d2c40bf'
    AND effect_json->>'effect' IN ('modal_boros_charm', 'indestructible')
    AND review_status NOT IN ('rejected', 'deprecated')
    AND execution_status IN ('auto', 'executable', 'review_only');

  IF v_card_rows <> 1 THEN
    RAISE EXCEPTION 'PG030 precondition failed: Boros Charm card rows=% expected 1', v_card_rows;
  END IF;
  IF v_hash_rows <> 1 THEN
    RAISE EXCEPTION 'PG030 precondition failed: Boros Charm oracle hash rows=% expected 1', v_hash_rows;
  END IF;
  IF v_legacy_rows = 0 THEN
    RAISE EXCEPTION 'PG030 precondition failed: no enabled Boros Charm modal/shadow row to repair';
  END IF;
END $$;

WITH target_rule AS (
  SELECT
    'boros charm'::text AS normalized_name,
    'Boros Charm'::text AS card_name,
    'battle_rule_v1:32605a838d7a519f44eaa0899d2c40bf'::text AS logical_rule_key,
    '98a7be829075118b499a7c283a23501f'::text AS oracle_hash,
    jsonb_build_object(
      'effect', 'modal_boros_charm',
      'instant', true,
      'battle_model_scope', 'boros_charm_choose_one_damage_indestructible_double_strike_v1',
      'modes', jsonb_build_array(
        jsonb_build_object(
          'mode', 'damage_player_or_planeswalker',
          'amount', 4,
          'target', 'player_or_planeswalker',
          'mode_status', 'annotation_only'
        ),
        jsonb_build_object(
          'mode', 'permanents_you_control_gain_indestructible_until_eot',
          'grants', jsonb_build_array('indestructible'),
          'target_scope', 'permanents_you_control',
          'duration', 'until_end_of_turn'
        ),
        jsonb_build_object(
          'mode', 'target_creature_gains_double_strike_until_eot',
          'grants', jsonb_build_array('double_strike'),
          'target_scope', 'target_creature',
          'duration', 'until_end_of_turn'
        )
      )
    ) AS effect_json,
    jsonb_build_object(
      'category', 'protection',
      'effect', 'modal_boros_charm',
      'timing', 'instant',
      'battle_model_scope', 'boros_charm_choose_one_damage_indestructible_double_strike_v1'
    ) AS deck_role_json,
    'PG-030: promoted Boros Charm as oracle-specific modal rule. Runtime models the indestructible mode as all permanents you control until EOT and the double-strike mode as one target creature until EOT. The 4 damage player/planeswalker mode is retained as annotation_only metadata because this runtime slice does not yet select direct-damage modal targets.'::text AS notes
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
  'codex_central_auditor_pg030',
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
    'PG-030 disabled this broad/shadow Boros Charm row after promoting oracle-specific modal rule battle_rule_v1:32605a838d7a519f44eaa0899d2c40bf.'
  ),
  updated_at = now(),
  last_seen_at = now()
WHERE normalized_name = 'boros charm'
  AND logical_rule_key <> 'battle_rule_v1:32605a838d7a519f44eaa0899d2c40bf'
  AND effect_json->>'effect' IN ('modal_boros_charm', 'indestructible')
  AND review_status NOT IN ('rejected', 'deprecated')
  AND execution_status IN ('auto', 'executable', 'review_only');

SELECT
  'pg030_boros_charm_apply_result' AS check_name,
  card_name,
  logical_rule_key,
  effect_json,
  source,
  confidence,
  review_status,
  execution_status,
  oracle_hash
FROM card_battle_rules
WHERE normalized_name = 'boros charm'
ORDER BY source, review_status, execution_status, logical_rule_key;

COMMIT;
