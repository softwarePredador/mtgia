\pset pager off
\set ON_ERROR_STOP on

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DROP TABLE IF EXISTS manaloom_deploy_audit.pg036_past_in_flames_battle_rule_20260622_210425;
CREATE TABLE manaloom_deploy_audit.pg036_past_in_flames_battle_rule_20260622_210425 (
  section text NOT NULL,
  key text NOT NULL,
  payload jsonb NOT NULL,
  captured_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO manaloom_deploy_audit.pg036_past_in_flames_battle_rule_20260622_210425
  (section, key, payload)
SELECT
  'card_battle_rules',
  normalized_name || '|' || logical_rule_key,
  to_jsonb(cbr.*)
FROM card_battle_rules cbr
WHERE normalized_name = 'past in flames'
   OR lower(card_name) = 'past in flames';

DO $$
DECLARE
  v_card_rows int;
  v_distinct_oracle_ids int;
  v_hash_rows int;
  v_exact_rows int;
  v_legacy_rows int;
BEGIN
  SELECT count(*), count(DISTINCT oracle_id)
    INTO v_card_rows, v_distinct_oracle_ids
  FROM cards
  WHERE lower(name) = 'past in flames';

  SELECT count(*) INTO v_hash_rows
  FROM cards
  WHERE lower(name) = 'past in flames'
    AND md5(regexp_replace(lower(coalesce(oracle_text, '')), '\s+', ' ', 'g')) =
      '12f293d8d746fbc4e5ba80828919dec5';

  SELECT count(*) INTO v_exact_rows
  FROM card_battle_rules
  WHERE normalized_name = 'past in flames'
    AND logical_rule_key = 'battle_rule_v1:ccdb2d362690ed2c1ef32711b42e51be'
    AND review_status = 'active'
    AND execution_status = 'auto'
    AND oracle_hash = '12f293d8d746fbc4e5ba80828919dec5';

  SELECT count(*) INTO v_legacy_rows
  FROM card_battle_rules
  WHERE normalized_name = 'past in flames'
    AND logical_rule_key <> 'battle_rule_v1:ccdb2d362690ed2c1ef32711b42e51be'
    AND effect_json->>'effect' IN ('recursion')
    AND review_status NOT IN ('rejected', 'deprecated')
    AND execution_status IN ('auto', 'executable', 'review_only');

  IF v_card_rows <> 1 THEN
    RAISE EXCEPTION 'PG036 precondition failed: Past in Flames card rows=% expected 1', v_card_rows;
  END IF;
  IF v_distinct_oracle_ids <> 1 THEN
    RAISE EXCEPTION 'PG036 precondition failed: distinct oracle ids=% expected 1', v_distinct_oracle_ids;
  END IF;
  IF v_hash_rows <> v_card_rows THEN
    RAISE EXCEPTION 'PG036 precondition failed: oracle hash rows=% expected all % rows', v_hash_rows, v_card_rows;
  END IF;
  IF v_exact_rows <> 0 THEN
    RAISE EXCEPTION 'PG036 precondition failed: target Past in Flames rule already active';
  END IF;
  IF v_legacy_rows = 0 THEN
    RAISE EXCEPTION 'PG036 precondition failed: no enabled Past in Flames recursion rows to repair';
  END IF;
END $$;

WITH target_rule AS (
  SELECT
    'past in flames'::text AS normalized_name,
    'Past in Flames'::text AS card_name,
    'battle_rule_v1:ccdb2d362690ed2c1ef32711b42e51be'::text AS logical_rule_key,
    '12f293d8d746fbc4e5ba80828919dec5'::text AS oracle_hash,
    jsonb_build_object(
      'effect', 'graveyard_flashback_grant',
      'battle_model_scope',
        'past_in_flames_graveyard_instants_sorceries_flashback_until_eot_v1',
      'cmc', 4.0,
      'target_zone', 'graveyard',
      'grants_flashback_to', 'instant_or_sorcery',
      'flashback_cost', 'mana_cost',
      'duration', 'until_end_of_turn',
      'self_flashback_cost', '{4}{R}',
      'exile_on_flashback_resolution', true
    ) AS effect_json,
    jsonb_build_object(
      'category', 'engine',
      'effect', 'graveyard_flashback_grant',
      'target', 'instant_or_sorcery',
      'battle_model_scope',
        'past_in_flames_graveyard_instants_sorceries_flashback_until_eot_v1'
    ) AS deck_role_json,
    'PG-036: promoted Past in Flames as oracle-specific temporary flashback grant for instant and sorcery cards in controller graveyard until end of turn. Runtime grants flashback_cost equal to each card mana_cost and uses the existing flashback cast path, which exiles the spell on resolution; broader priority/timing policy remains the current battle approximation.'::text AS notes
),
resolved_card AS (
  SELECT tr.*, c.id
  FROM target_rule tr
  JOIN cards c
    ON lower(c.name) = tr.normalized_name
  ORDER BY c.id
  LIMIT 1
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
  0.940,
  'active',
  'auto',
  1,
  oracle_hash,
  notes,
  'codex_central_auditor_pg036',
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
    'PG-036 disabled this generic Past in Flames recursion row after promoting oracle-specific flashback grant rule battle_rule_v1:ccdb2d362690ed2c1ef32711b42e51be.'
  ),
  updated_at = now(),
  last_seen_at = now()
WHERE normalized_name = 'past in flames'
  AND logical_rule_key <> 'battle_rule_v1:ccdb2d362690ed2c1ef32711b42e51be'
  AND effect_json->>'effect' IN ('recursion')
  AND review_status NOT IN ('rejected', 'deprecated')
  AND execution_status IN ('auto', 'executable', 'review_only');

SELECT
  'pg036_past_in_flames_apply_result' AS check_name,
  card_name,
  logical_rule_key,
  effect_json,
  deck_role_json,
  source,
  confidence,
  review_status,
  execution_status,
  oracle_hash
FROM card_battle_rules
WHERE normalized_name = 'past in flames'
ORDER BY source, review_status, execution_status, logical_rule_key;

COMMIT;
