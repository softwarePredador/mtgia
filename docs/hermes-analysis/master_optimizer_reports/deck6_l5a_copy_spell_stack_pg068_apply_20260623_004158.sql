BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg068_deck6_l5a_copy_spell_stack_20260623_004158 AS
SELECT now() AS backed_up_at, to_jsonb(cbr) AS payload
FROM card_battle_rules cbr
WHERE cbr.normalized_name IN ('dualcaster mage', 'reiterate');

DO $$
DECLARE
  v_cards integer;
  v_rules integer;
  v_new integer;
BEGIN
  SELECT count(*)
  INTO v_cards
  FROM cards c
  WHERE (
      c.name = 'Dualcaster Mage'
      AND md5(coalesce(c.oracle_text, '')) = 'e26f613394b72e9724d299512983218a'
    )
    OR (
      c.name = 'Reiterate'
      AND md5(coalesce(c.oracle_text, '')) = '996fb5f02f16605ff7f1c899f2c50f60'
    );

  SELECT count(*)
  INTO v_rules
  FROM card_battle_rules
  WHERE normalized_name IN ('dualcaster mage', 'reiterate');

  SELECT count(*)
  INTO v_new
  FROM card_battle_rules
  WHERE logical_rule_key IN (
    'battle_rule_v1:e176019b87d68d22e2388e08a4efbf55',
    'battle_rule_v1:18eeabc2a2fa631d99caf65a43a8c405'
  );

  IF v_cards <> 2 THEN
    RAISE EXCEPTION 'PG068 precondition failed: expected 2 target cards with exact oracle hashes, got %', v_cards;
  END IF;
  IF v_rules <> 4 THEN
    RAISE EXCEPTION 'PG068 precondition failed: expected 4 existing target rules, got %', v_rules;
  END IF;
  IF v_new <> 0 THEN
    RAISE EXCEPTION 'PG068 precondition failed: new logical_rule_key rows already exist: %', v_new;
  END IF;
END $$;

UPDATE card_battle_rules
SET
  review_status = 'deprecated',
  execution_status = 'disabled',
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(
    E'\n',
    nullif(notes, ''),
    'PG068: superseded by scoped copy-spell stack rules for Reiterate/Dualcaster Mage.'
  )
WHERE normalized_name IN ('dualcaster mage', 'reiterate')
  AND logical_rule_key NOT IN (
    'battle_rule_v1:e176019b87d68d22e2388e08a4efbf55',
    'battle_rule_v1:18eeabc2a2fa631d99caf65a43a8c405'
  );

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
  updated_at,
  last_seen_at
)
SELECT
  'reiterate',
  'battle_rule_v1:18eeabc2a2fa631d99caf65a43a8c405',
  c.id,
  c.name,
  jsonb_build_object(
    'effect', 'copy_spell',
    'cmc', 3.0,
    'instant', true,
    'target', 'instant_or_sorcery_on_stack',
    'copy_is_not_cast', true,
    'may_choose_new_targets', true,
    'choose_new_targets_status', 'annotation_only',
    'buyback_status', 'annotation_only',
    'additional_cost_buyback_generic', 3,
    'battle_model_scope', 'copy_stack_instant_or_sorcery_buyback_annotation_v1',
    'oracle_runtime_scope', 'copy_target_instant_or_sorcery_spell_new_targets_annotation_buyback_annotation',
    'pg068_copy_spell_family', 'deck6_l5a_copy_spell_stack'
  ),
  jsonb_build_object(
    'category', 'engine',
    'effect', 'copy_spell',
    'timing', 'instant',
    'subtype', 'stack_spell_copy',
    'buyback_status', 'annotation_only'
  ),
  'curated',
  1.000,
  'verified',
  'auto',
  1,
  '996fb5f02f16605ff7f1c899f2c50f60',
  'PG068: Reiterate oracle is copy target instant/sorcery spell; new target choice and buyback are annotation-only, copy is not cast.',
  'codex-auditor',
  now(),
  now(),
  now()
FROM cards c
WHERE c.name = 'Reiterate'
  AND md5(coalesce(c.oracle_text, '')) = '996fb5f02f16605ff7f1c899f2c50f60'
UNION ALL
SELECT
  'dualcaster mage',
  'battle_rule_v1:e176019b87d68d22e2388e08a4efbf55',
  c.id,
  c.name,
  jsonb_build_object(
    'effect', 'copy_spell',
    'cmc', 3.0,
    'is_creature_permanent', true,
    'power', 2,
    'toughness', 2,
    'keywords', jsonb_build_array('flash'),
    'flash', true,
    'etb_copy_spell', true,
    'target', 'instant_or_sorcery_on_stack',
    'copy_is_not_cast', true,
    'may_choose_new_targets', true,
    'choose_new_targets_status', 'annotation_only',
    'battle_model_scope', 'creature_etb_copy_stack_instant_or_sorcery_v1',
    'oracle_runtime_scope', 'flash_creature_etb_copy_target_instant_or_sorcery_spell_new_targets_annotation',
    'pg068_copy_spell_family', 'deck6_l5a_copy_spell_stack'
  ),
  jsonb_build_object(
    'category', 'engine',
    'effect', 'creature',
    'timing', 'flash_creature',
    'subtype', 'etb_stack_spell_copy'
  ),
  'curated',
  1.000,
  'verified',
  'auto',
  1,
  'e26f613394b72e9724d299512983218a',
  'PG068: Dualcaster Mage is a flash creature whose ETB copies target instant/sorcery spell; new target choice is annotation-only.',
  'codex-auditor',
  now(),
  now(),
  now()
FROM cards c
WHERE c.name = 'Dualcaster Mage'
  AND md5(coalesce(c.oracle_text, '')) = 'e26f613394b72e9724d299512983218a'
ON CONFLICT (normalized_name, logical_rule_key) DO UPDATE
SET
  card_id = excluded.card_id,
  card_name = excluded.card_name,
  effect_json = excluded.effect_json,
  deck_role_json = excluded.deck_role_json,
  source = excluded.source,
  confidence = excluded.confidence,
  review_status = excluded.review_status,
  execution_status = excluded.execution_status,
  rule_version = greatest(card_battle_rules.rule_version, excluded.rule_version),
  oracle_hash = excluded.oracle_hash,
  notes = excluded.notes,
  reviewed_by = excluded.reviewed_by,
  reviewed_at = excluded.reviewed_at,
  updated_at = excluded.updated_at,
  last_seen_at = excluded.last_seen_at;

COMMIT;
