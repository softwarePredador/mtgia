\pset pager off

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg086_deck608_angels_grace_20260623_084922') IS NOT NULL THEN
    RAISE EXCEPTION 'PG086 Angel''s Grace backup table already exists';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pg086_deck608_angels_grace_20260623_084922 AS
SELECT *
FROM card_battle_rules
WHERE normalized_name = 'angel''s grace';

DO $$
DECLARE
  v_target integer;
  v_oracle integer;
  v_trusted integer;
  v_missing_hash integer;
  v_shadow integer;
BEGIN
  SELECT
    count(*),
    count(*) FILTER (WHERE md5(coalesce(c.oracle_text, '')) = '627c4ce7adf5be44b93e2b850159e5d9'),
    count(*) FILTER (WHERE cbr.review_status = 'verified' AND cbr.execution_status = 'auto'),
    count(*) FILTER (WHERE cbr.oracle_hash IS NULL OR cbr.oracle_hash = '')
  INTO v_target, v_oracle, v_trusted, v_missing_hash
  FROM cards c
  JOIN card_battle_rules cbr
    ON cbr.card_id = c.id
  WHERE c.name = 'Angel''s Grace'
    AND cbr.normalized_name = 'angel''s grace'
    AND cbr.logical_rule_key = 'battle_rule_v1:2833836fd4d943d3e02d1cfa2d284227';

  SELECT count(*)
  INTO v_shadow
  FROM card_battle_rules
  WHERE normalized_name = 'angel''s grace'
    AND source = 'generated'
    AND execution_status <> 'disabled';

  IF v_target <> 1 THEN
    RAISE EXCEPTION 'PG086 precondition failed: expected 1 Angel''s Grace target, got %', v_target;
  END IF;
  IF v_oracle <> 1 THEN
    RAISE EXCEPTION 'PG086 precondition failed: Angel''s Grace current oracle hash mismatch, got %', v_oracle;
  END IF;
  IF v_trusted <> 1 THEN
    RAISE EXCEPTION 'PG086 precondition failed: expected 1 trusted auto target, got %', v_trusted;
  END IF;
  IF v_missing_hash <> 1 THEN
    RAISE EXCEPTION 'PG086 precondition failed: expected 1 missing hash target, got %', v_missing_hash;
  END IF;
  IF v_shadow <> 2 THEN
    RAISE EXCEPTION 'PG086 precondition failed: expected 2 generated shadows, got %', v_shadow;
  END IF;
END $$;

UPDATE card_battle_rules
SET
  oracle_hash = '627c4ce7adf5be44b93e2b850159e5d9',
  effect_json = '{
    "effect": "cannot_lose_turn",
    "instant": true,
    "cmc": 1.0,
    "life_floor_on_damage": 1,
    "split_second": true,
    "opponents_cant_win_this_turn": true,
    "battle_model_scope": "split_second_cannot_lose_opponents_cannot_win_damage_life_floor_v1",
    "oracle_runtime_scope": "cannot_lose_opponents_cannot_win_damage_life_floor_split_second_annotation"
  }'::jsonb,
  deck_role_json = '{
    "category": "protection",
    "effect": "cannot_lose_turn",
    "timing": "instant",
    "functions": ["cannot_lose", "opponents_cannot_win", "damage_life_floor", "split_second_annotation"],
    "runtime_modes": ["cannot_lose_this_turn", "damage_life_floor_one"],
    "annotation_modes": ["split_second_stack_restriction"]
  }'::jsonb,
  confidence = 0.970,
  review_status = 'verified',
  execution_status = 'auto',
  rule_version = greatest(rule_version, 2),
  reviewed_by = 'codex-auditor',
  reviewed_at = now(),
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(E'\n', nullif(notes, ''), 'PG086: completed Angel''s Grace trusted rule provenance for deck608 high queue; modeled cannot-lose/opponents-cannot-win/damage floor runtime and kept split second as explicit annotation.')
WHERE normalized_name = 'angel''s grace'
  AND logical_rule_key = 'battle_rule_v1:2833836fd4d943d3e02d1cfa2d284227'
  AND review_status = 'verified'
  AND execution_status = 'auto';

UPDATE card_battle_rules
SET
  review_status = 'deprecated',
  execution_status = 'disabled',
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(E'\n', nullif(notes, ''), 'PG086 disabled generated Angel''s Grace shadows after trusted oracle-specific rule promotion.')
WHERE normalized_name = 'angel''s grace'
  AND source = 'generated'
  AND execution_status <> 'disabled';

COMMIT;
