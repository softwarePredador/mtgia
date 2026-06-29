-- PGC054 Spectator Seating opponent-count ETB runtime apply.
-- Expected precheck:
--   target_cards=1
--   target_rule_rows=2
--   curated_auto_rows=1
--   generated_disabled_rows=1
--   target_oracle_hash_rows=1
--   current_assumed_commander_rows=1
--   current_annotation_scope_rows=1
--   pgc054_namespace_rows=0
--   backup_table_exists=0

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
DECLARE
  v_target_cards integer;
  v_target_rules integer;
  v_curated_auto integer;
  v_generated_disabled integer;
  v_hash_rows integer;
  v_assumed_rows integer;
  v_annotation_rows integer;
  v_namespace_rows integer;
  v_backup_exists integer;
BEGIN
  SELECT count(*) INTO v_target_cards
  FROM cards
  WHERE lower(name) = 'spectator seating';

  SELECT count(*) INTO v_target_rules
  FROM card_battle_rules
  WHERE normalized_name = 'spectator seating';

  SELECT count(*) INTO v_curated_auto
  FROM card_battle_rules
  WHERE normalized_name = 'spectator seating'
    AND source = 'curated'
    AND review_status IN ('verified', 'active')
    AND execution_status = 'auto';

  SELECT count(*) INTO v_generated_disabled
  FROM card_battle_rules
  WHERE normalized_name = 'spectator seating'
    AND source = 'generated'
    AND execution_status = 'disabled';

  SELECT count(*) INTO v_hash_rows
  FROM card_battle_rules cbr
  JOIN cards c ON lower(c.name) = cbr.normalized_name
  WHERE cbr.normalized_name = 'spectator seating'
    AND cbr.source = 'curated'
    AND cbr.oracle_hash = md5(coalesce(c.oracle_text, ''));

  SELECT count(*) INTO v_assumed_rows
  FROM card_battle_rules
  WHERE normalized_name = 'spectator seating'
    AND source = 'curated'
    AND effect_json->>'multiplayer_enters_untapped_status' = 'assumed_for_commander_table';

  SELECT count(*) INTO v_annotation_rows
  FROM card_battle_rules
  WHERE normalized_name = 'spectator seating'
    AND source = 'curated'
    AND effect_json->>'oracle_runtime_scope' = 'mana_source_runtime_with_annotation_only_clauses';

  SELECT count(*) INTO v_namespace_rows
  FROM card_battle_rules
  WHERE coalesce(reviewed_by, '') = 'codex-pgc054'
     OR coalesce(notes, '') ILIKE '%PGC054%';

  SELECT count(*) INTO v_backup_exists
  FROM information_schema.tables
  WHERE table_schema = 'manaloom_deploy_audit'
    AND table_name = 'pgc054_spectator_seating_opponent_count_20260629';

  IF v_target_cards <> 1
    OR v_target_rules <> 2
    OR v_curated_auto <> 1
    OR v_generated_disabled <> 1
    OR v_hash_rows <> 1
    OR v_assumed_rows <> 1
    OR v_annotation_rows <> 1
    OR v_namespace_rows <> 0
    OR v_backup_exists <> 0 THEN
    RAISE EXCEPTION
      'PGC054 guard failed: target_cards %, target_rules %, curated_auto %, generated_disabled %, hash_rows %, assumed_rows %, annotation_rows %, namespace_rows %, backup_exists %',
      v_target_cards, v_target_rules, v_curated_auto, v_generated_disabled,
      v_hash_rows, v_assumed_rows, v_annotation_rows, v_namespace_rows,
      v_backup_exists;
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pgc054_spectator_seating_opponent_count_20260629 AS
SELECT *
FROM card_battle_rules
WHERE normalized_name = 'spectator seating';

DO $$
DECLARE
  v_updated integer;
BEGIN
  WITH target_card AS (
    SELECT
      id AS target_card_id,
      md5(coalesce(oracle_text, '')) AS target_oracle_hash
    FROM cards
    WHERE lower(name) = 'spectator seating'
  )
  UPDATE card_battle_rules cbr
  SET
    card_id = tc.target_card_id,
    oracle_hash = tc.target_oracle_hash,
    effect_json = jsonb_strip_nulls(
      coalesce(cbr.effect_json, '{}'::jsonb)
      || jsonb_build_object(
        'effect', 'land',
        'mana_produced', 1,
        'produces', 'RW',
        'battle_model_scope', 'bond_land_dual_source_etb_opponent_count_runtime_v1',
        'oracle_runtime_scope', 'red_white_mana_enters_tapped_unless_two_or_more_opponents_runtime_v1',
        'pg051_l1b_land_family', 'deck6_nonfetch_mana_land',
        'enters_tapped_unless_opponent_count', 2,
        'opponent_count_status', 'runtime_executor_v1',
        'multiplayer_enters_untapped_status', 'runtime_executor_v1'
      )
    ),
    rule_version = greatest(coalesce(cbr.rule_version, 1) + 1, 2),
    reviewed_by = 'codex-pgc054',
    reviewed_at = now(),
    notes = concat_ws(
      E'\n',
      nullif(cbr.notes, ''),
      'PGC054 2026-06-29: Spectator Seating ETB now executes opponent-count condition. Enters tapped unless live opponent count is at least 2; mana remains exact R/W choice. Sources: Scryfall Oracle and XMage TwoOrMoreOpponentsCondition.'
    ),
    updated_at = now()
  FROM target_card tc
  WHERE cbr.normalized_name = 'spectator seating'
    AND cbr.source = 'curated'
    AND cbr.review_status IN ('verified', 'active')
    AND cbr.execution_status = 'auto';

  GET DIAGNOSTICS v_updated = ROW_COUNT;
  IF v_updated <> 1 THEN
    RAISE EXCEPTION 'PGC054 expected to update 1 curated row, updated %', v_updated;
  END IF;
END $$;

COMMIT;
