BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg070_deck6_red_discard_runtime_20260623_042617') IS NOT NULL THEN
    RAISE EXCEPTION 'PG070 backup table already exists';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pg070_deck6_red_discard_runtime_20260623_042617 AS
SELECT now() AS backed_up_at, to_jsonb(cbr) AS payload
FROM card_battle_rules cbr
WHERE cbr.normalized_name IN ('faithless looting', 'gamble');

DO $$
DECLARE
  v_cards integer;
  v_rules integer;
  v_specific integer;
BEGIN
  SELECT count(*)
  INTO v_cards
  FROM cards c
  WHERE (
      c.name = 'Faithless Looting'
      AND md5(coalesce(c.oracle_text, '')) = '2e734d8bae3f331866abf1b030c92781'
    )
    OR (
      c.name = 'Gamble'
      AND md5(coalesce(c.oracle_text, '')) = '9b3fc8ab7f664f6c084e0bda0ccf9a7c'
    );

  SELECT count(*)
  INTO v_rules
  FROM card_battle_rules
  WHERE normalized_name IN ('faithless looting', 'gamble');

  SELECT count(*)
  INTO v_specific
  FROM card_battle_rules
  WHERE (normalized_name = 'faithless looting'
      AND logical_rule_key = 'battle_rule_v1:554fe811b81e8a284b8a5ca9c6543caa')
    OR (normalized_name = 'gamble'
      AND logical_rule_key = 'battle_rule_v1:2861739f22e978549e28d2339288df2a');

  IF v_cards <> 2 THEN
    RAISE EXCEPTION 'PG070 precondition failed: expected 2 target cards with current oracle hashes, got %', v_cards;
  END IF;
  IF v_rules <> 4 THEN
    RAISE EXCEPTION 'PG070 precondition failed: expected 4 target rules, got %', v_rules;
  END IF;
  IF v_specific <> 2 THEN
    RAISE EXCEPTION 'PG070 precondition failed: expected 2 existing curated runtime rows, got %', v_specific;
  END IF;
END $$;

UPDATE card_battle_rules
SET
  oracle_hash = '2e734d8bae3f331866abf1b030c92781',
  effect_json = effect_json || jsonb_build_object(
    'effect', 'loot',
    'count', 2,
    'draw_count', 2,
    'discard_count', 2,
    'sorcery', true,
    'battle_model_scope', 'draw_two_discard_two_flashback_annotation_v1',
    'flashback_status', 'annotation_only_cost_2r_exile_on_resolution_not_autocast'
  ),
  deck_role_json = deck_role_json || jsonb_build_object(
    'effect', 'loot',
    'category', 'draw_filter',
    'graveyard_setup', true
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
    'PG070: replaced broad draw_cards model with draw-two/discard-two loot runtime; flashback remains explicit annotation-only metadata.'
  )
WHERE normalized_name = 'faithless looting'
  AND logical_rule_key = 'battle_rule_v1:554fe811b81e8a284b8a5ca9c6543caa';

UPDATE card_battle_rules
SET
  oracle_hash = '9b3fc8ab7f664f6c084e0bda0ccf9a7c',
  effect_json = effect_json || jsonb_build_object(
    'effect', 'tutor',
    'target', 'any',
    'sorcery', true,
    'discard_after_tutor_random', true,
    'battle_model_scope', 'any_card_to_hand_then_random_discard_v1',
    'random_discard_status', 'runtime_random_from_hand_after_tutor',
    'library_shuffle_status', 'annotation_only_hidden_zone_shuffle_no_order_model'
  ),
  deck_role_json = deck_role_json || jsonb_build_object(
    'effect', 'tutor',
    'target', 'any',
    'category', 'tutor',
    'discard_risk', true
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
    'PG070: added scoped any-card tutor runtime with random post-tutor discard; library shuffle remains annotation-only because hidden-zone ordering is not modeled.'
  )
WHERE normalized_name = 'gamble'
  AND logical_rule_key = 'battle_rule_v1:2861739f22e978549e28d2339288df2a';

UPDATE card_battle_rules
SET
  review_status = 'deprecated',
  execution_status = 'disabled',
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(
    E'\n',
    nullif(notes, ''),
    'PG070: disabled superseded generated review-only row after scoped curated runtime promotion.'
  )
WHERE normalized_name IN ('faithless looting', 'gamble')
  AND logical_rule_key IN (
    'battle_rule_v1:d081b2dbb37755e4efe056313d78e58c',
    'battle_rule_v1:06e7d53f056c85dafd82a9676aac1b3b'
  );

COMMIT;
