BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg076_deck6_chaos_warp_runtime_20260623_055230') IS NOT NULL THEN
    RAISE EXCEPTION 'PG076 backup table already exists';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pg076_deck6_chaos_warp_runtime_20260623_055230 AS
SELECT now() AS backed_up_at, to_jsonb(cbr) AS payload
FROM card_battle_rules cbr
WHERE cbr.normalized_name = 'chaos warp';

DO $$
DECLARE
  v_cards integer;
  v_rules integer;
  v_specific integer;
BEGIN
  SELECT count(*)
  INTO v_cards
  FROM cards c
  WHERE c.name = 'Chaos Warp'
    AND md5(coalesce(c.oracle_text, '')) = '7db2bc44526b855fd22302e9569746b5';

  SELECT count(*)
  INTO v_rules
  FROM card_battle_rules
  WHERE normalized_name = 'chaos warp';

  SELECT count(*)
  INTO v_specific
  FROM card_battle_rules
  WHERE normalized_name = 'chaos warp'
    AND logical_rule_key = 'battle_rule_v1:0b547d7209a38ac2d23a1cca07917680';

  IF v_cards <> 1 THEN
    RAISE EXCEPTION 'PG076 precondition failed: expected 1 Chaos Warp card with current oracle hash, got %', v_cards;
  END IF;
  IF v_rules <> 2 THEN
    RAISE EXCEPTION 'PG076 precondition failed: expected 2 Chaos Warp rule rows, got %', v_rules;
  END IF;
  IF v_specific <> 1 THEN
    RAISE EXCEPTION 'PG076 precondition failed: expected 1 curated Chaos Warp runtime row, got %', v_specific;
  END IF;
END $$;

UPDATE card_battle_rules
SET
  oracle_hash = '7db2bc44526b855fd22302e9569746b5',
  effect_json = effect_json || jsonb_build_object(
    'effect', 'remove_permanent',
    'instant', true,
    'target', 'permanent',
    'destination', 'library',
    'top_reveal_after_shuffle', true,
    'permanent_reveal_to_battlefield', true,
    'nonpermanent_reveal_status', 'revealed_card_remains_on_top_of_library',
    'token_target_status', 'token_vanishes_after_shuffle_replacement',
    'battle_model_scope', 'target_permanent_shuffle_into_owner_library_reveal_top_permanent_to_battlefield_v1',
    'oracle_runtime_scope', 'owner_shuffle_target_permanent_into_library_then_reveal_top_permanent_to_battlefield_v1'
  ),
  deck_role_json = deck_role_json || jsonb_build_object(
    'effect', 'remove_permanent',
    'category', 'interaction',
    'target_types', jsonb_build_array('permanent'),
    'destination', 'library',
    'top_reveal_compensation', 'permanent_to_battlefield_if_revealed'
  ),
  confidence = 0.970,
  rule_version = greatest(rule_version, 2),
  reviewed_by = 'codex-auditor',
  reviewed_at = now(),
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(
    E'\n',
    nullif(notes, ''),
    'PG076: scoped Chaos Warp to target permanent -> owner library shuffle -> reveal top; revealed permanent enters battlefield, nonpermanent remains on top. Token target vanishes after zone-change replacement.'
  )
WHERE normalized_name = 'chaos warp'
  AND logical_rule_key = 'battle_rule_v1:0b547d7209a38ac2d23a1cca07917680';

UPDATE card_battle_rules
SET
  review_status = 'deprecated',
  execution_status = 'disabled',
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(
    E'\n',
    nullif(notes, ''),
    'PG076: disabled superseded generated review-only draw_cards row; Chaos Warp is targeted permanent shuffle/reveal interaction, not draw.'
  )
WHERE normalized_name = 'chaos warp'
  AND logical_rule_key = 'battle_rule_v1:1bd5dce7cffed8d0af007d20b15e8549';

COMMIT;
