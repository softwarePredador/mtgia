-- PG063 deck608 tutor/search package apply.
-- Promotes four oracle-specific tutor/search rules after runtime regression
-- coverage proved library-top, hand, graveyard, and ETB creature tutor paths.

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg063_deck608_tutor_search_20260623_024856') IS NOT NULL THEN
    RAISE EXCEPTION 'Backup table manaloom_deploy_audit.pg063_deck608_tutor_search_20260623_024856 already exists';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pg063_deck608_tutor_search_20260623_024856 AS
SELECT *
FROM card_battle_rules
WHERE normalized_name IN (
  'enlightened tutor',
  'idyllic tutor',
  'goblin engineer',
  'imperial recruiter'
);

DO $$
DECLARE
  v_backup_rows integer;
  v_target_cards integer;
BEGIN
  SELECT count(*) INTO v_backup_rows
  FROM manaloom_deploy_audit.pg063_deck608_tutor_search_20260623_024856;

  SELECT count(*) INTO v_target_cards
  FROM cards
  WHERE lower(name) IN (
    'enlightened tutor',
    'idyllic tutor',
    'goblin engineer',
    'imperial recruiter'
  );

  IF v_backup_rows <> 8 THEN
    RAISE EXCEPTION 'PG063 precondition failed: backup_rows=% expected 8', v_backup_rows;
  END IF;
  IF v_target_cards <> 4 THEN
    RAISE EXCEPTION 'PG063 precondition failed: target_cards=% expected 4', v_target_cards;
  END IF;
END $$;

WITH target_rules(
  normalized_name,
  card_name,
  logical_rule_key,
  expected_oracle_hash,
  effect_json,
  deck_role_json,
  notes
) AS (
  VALUES
    (
      'enlightened tutor',
      'Enlightened Tutor',
      'battle_rule_v1:ed0d4316c416061742e6eea0e4bade8a',
      '82899cda80d16c0c70ee5861f7e693d5',
      '{"effect":"tutor","cmc":1.0,"instant":true,"target":"artifact_or_enchantment_to_top","tutor_destination":"library_top","reveals_tutored_card":true,"battle_model_scope":"artifact_enchantment_tutor_to_library_top_v1","oracle_runtime_scope":"instant_artifact_or_enchantment_reveal_shuffle_to_top_runtime","pg063_tutor_family":"deck608_tutor_search_package"}'::jsonb,
      '{"category":"tutor","effect":"tutor","target":"artifact_or_enchantment","timing":"instant","destination":"library_top","deck_package":"deck608_tutor_search"}'::jsonb,
      'PG063 2026-06-23: Enlightened Tutor modeled as artifact/enchantment reveal-shuffle-to-library-top, matching oracle and runtime test test_enlightened_tutor_puts_artifact_or_enchantment_on_library_top.'
    ),
    (
      'idyllic tutor',
      'Idyllic Tutor',
      'battle_rule_v1:b516a3f8059b43f049f156445eeeaf21',
      'c47e51a791e68f5ecb96f7187d68a20f',
      '{"effect":"tutor","cmc":3.0,"sorcery":true,"target":"enchantment","tutor_destination":"hand","reveals_tutored_card":true,"battle_model_scope":"enchantment_tutor_to_hand_v1","oracle_runtime_scope":"sorcery_enchantment_reveal_shuffle_to_hand_runtime","pg063_tutor_family":"deck608_tutor_search_package"}'::jsonb,
      '{"category":"tutor","effect":"tutor","target":"enchantment","timing":"sorcery","destination":"hand","deck_package":"deck608_tutor_search"}'::jsonb,
      'PG063 2026-06-23: Idyllic Tutor promoted from generated review-only artifact_or_enchantment fallback to enchantment-only reveal-to-hand runtime rule.'
    ),
    (
      'goblin engineer',
      'Goblin Engineer',
      'battle_rule_v1:bbff8bfe05ccbe03f94fcbadd749be18',
      '64c401c2fd35257e988374fdfc22d86b',
      '{"effect":"creature","cmc":2.0,"is_creature_permanent":true,"power":1,"toughness":2,"etb_tutor_target":"artifact_to_graveyard","etb_tutor_destination":"graveyard","reveals_tutored_card":false,"activated_artifact_reanimation_status":"annotation_only","activated_artifact_reanimation_target":"artifact_mv_lte_3_from_graveyard","activated_artifact_reanimation_cost":"R_tap_sacrifice_artifact","battle_model_scope":"goblin_engineer_etb_artifact_to_graveyard_v1","oracle_runtime_scope":"creature_etb_artifact_library_to_graveyard_runtime_activated_reanimation_annotation","pg063_tutor_family":"deck608_tutor_search_package"}'::jsonb,
      '{"category":"tutor","effect":"creature","subtype":"etb_artifact_graveyard_tutor","target":"artifact","destination":"graveyard","deck_package":"deck608_tutor_search"}'::jsonb,
      'PG063 2026-06-23: Goblin Engineer modeled as creature with ETB artifact library-to-graveyard tutor; activated reanimation clause remains annotation_only until ability activation runtime exists.'
    ),
    (
      'imperial recruiter',
      'Imperial Recruiter',
      'battle_rule_v1:3323c3883679f1a92af90fbb39918840',
      '8ed92583adcde1d5b9d01b21a2415fb0',
      '{"effect":"creature","cmc":3.0,"is_creature_permanent":true,"power":1,"toughness":1,"etb_tutor_target":"creature_power_lte_2","etb_tutor_destination":"hand","reveals_tutored_card":true,"battle_model_scope":"imperial_recruiter_etb_power2_creature_to_hand_v1","oracle_runtime_scope":"creature_etb_power_lte_2_creature_reveal_shuffle_to_hand_runtime","pg063_tutor_family":"deck608_tutor_search_package"}'::jsonb,
      '{"category":"tutor","effect":"creature","subtype":"etb_small_creature_tutor","target":"creature_power_lte_2","destination":"hand","deck_package":"deck608_tutor_search"}'::jsonb,
      'PG063 2026-06-23: Imperial Recruiter modeled as creature with ETB creature-power-2-or-less reveal-to-hand tutor.'
    )
),
resolved AS (
  SELECT tr.*, c.id AS card_id, md5(coalesce(c.oracle_text, '')) AS live_oracle_hash
  FROM target_rules tr
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
  'codex_central_auditor_pg063',
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

WITH active_keys(normalized_name, logical_rule_key) AS (
  VALUES
    ('enlightened tutor', 'battle_rule_v1:ed0d4316c416061742e6eea0e4bade8a'),
    ('idyllic tutor', 'battle_rule_v1:b516a3f8059b43f049f156445eeeaf21'),
    ('goblin engineer', 'battle_rule_v1:bbff8bfe05ccbe03f94fcbadd749be18'),
    ('imperial recruiter', 'battle_rule_v1:3323c3883679f1a92af90fbb39918840')
)
UPDATE card_battle_rules cbr
SET
  review_status = 'deprecated',
  execution_status = 'disabled',
  notes = concat_ws(
    E'\n',
    nullif(cbr.notes, ''),
    'PG063 2026-06-23: Disabled superseded broad/shadow tutor row after promoting oracle-specific deck608 tutor/search runtime rule.'
  ),
  updated_at = now(),
  last_seen_at = now()
WHERE cbr.normalized_name IN (
    'enlightened tutor',
    'idyllic tutor',
    'goblin engineer',
    'imperial recruiter'
  )
  AND NOT EXISTS (
    SELECT 1
    FROM active_keys ak
    WHERE ak.normalized_name = cbr.normalized_name
      AND ak.logical_rule_key = cbr.logical_rule_key
  )
  AND cbr.review_status NOT IN ('deprecated', 'rejected')
  AND cbr.execution_status IN ('auto', 'executable', 'review_only');

COMMIT;
