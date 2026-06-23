\pset pager off

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg081_deck607_608_shared_high_20260623_082229') IS NOT NULL THEN
    RAISE EXCEPTION 'PG081 deck607/608 shared high backup table already exists';
  END IF;
END $$;

CREATE TEMP TABLE pg081_shared_high_targets(
  normalized_name text,
  old_logical_rule_key text,
  new_logical_rule_key text,
  expected_oracle_hash text,
  expected_scope text,
  expected_effect text,
  effect_json jsonb,
  deck_role_json jsonb,
  review_note text
);

INSERT INTO pg081_shared_high_targets(
  normalized_name,
  old_logical_rule_key,
  new_logical_rule_key,
  expected_oracle_hash,
  expected_scope,
  expected_effect,
  effect_json,
  deck_role_json,
  review_note
)
VALUES
  (
    'artist''s talent',
    'battle_rule_v1:1a21b06bc25fe4cc34352b3dcb8d3903',
    'battle_rule_v1:e57aa58c2e76015a0851a6bfef5dca90',
    'd49d9b1a361e7d2b0f9a373cb239b875',
    'class_level1_own_noncreature_spell_optional_discard_draw_level2_level3_annotations_v1',
    'draw_engine',
    '{"effect":"draw_engine","trigger":"noncreature_spell_cast","trigger_effect":"rummage","draw_on_enter":false,"optional_trigger":true,"level2_cost_reduction_status":"annotation_only","level3_noncombat_damage_bonus_status":"annotation_only","battle_model_scope":"class_level1_own_noncreature_spell_optional_discard_draw_level2_level3_annotations_v1","oracle_runtime_scope":"own_noncreature_spell_optional_rummage_compact_v1","cmc":2.0}'::jsonb,
    '{"effect":"draw_engine","category":"draw","functions":["card_selection","rummage","noncreature_spell_payoff"],"runtime_modes":["own_noncreature_spell_optional_discard_draw"],"annotation_modes":["class_level_2_cost_reduction","class_level_3_noncombat_damage_bonus"]}'::jsonb,
    'PG081 shared deck607/608 high: Artist''s Talent Class level 1 modeled as own noncreature spell optional rummage; level 2/3 class text remains annotation-only.'
  ),
  (
    'pinnacle monk // mystic peak',
    'battle_rule_v1:720ffd7f16297a705ae4352b033b186e',
    'battle_rule_v1:bcde63b5e56f2b9f20af6384bc70ad5d',
    'aa1967461796c715e0c5e0b4d741f249',
    'front_creature_prowess_etb_return_instant_or_sorcery_graveyard_to_hand_back_land_annotation_v1',
    'creature',
    '{"effect":"creature","power":2,"toughness":2,"keywords":["prowess"],"etb_recursion_count":1,"etb_recursion_target":"instant_or_sorcery","etb_recursion_destination":"hand","back_face_land_status":"annotation_only","battle_model_scope":"front_creature_prowess_etb_return_instant_or_sorcery_graveyard_to_hand_back_land_annotation_v1","oracle_runtime_scope":"creature_etb_return_instant_or_sorcery_graveyard_to_hand_v1","cmc":5.0}'::jsonb,
    '{"effect":"creature","category":"engine","functions":["prowess","spell_rebuy","mdfc_land_annotation"],"runtime_modes":["creature_etb_return_instant_or_sorcery_from_graveyard_to_hand"],"annotation_modes":["back_face_land"]}'::jsonb,
    'PG081 shared deck607/608 high: replaces wrong full-name remove_permanent model with front-face creature/prowess ETB spell-recursion; Mystic Peak remains MDFC land annotation under current PG face-front convention.'
  ),
  (
    'redirect lightning',
    'battle_rule_v1:fb9b2b633a4842d42599c293e0de4d68',
    'battle_rule_v1:d47b67e18fbd03ed1745f6917901d6c9',
    'f031e271e574af339ecf11d43dbe6a5d',
    'single_target_spell_or_ability_redirect_additional_cost_annotation_v1',
    'redirect_removal',
    '{"effect":"redirect_removal","instant":true,"target":"single_target_spell_or_ability","additional_cost_status":"pay_five_life_or_two_generic_annotation","battle_model_scope":"single_target_spell_or_ability_redirect_additional_cost_annotation_v1","oracle_runtime_scope":"redirect_single_target_stack_object_compact_v1","cmc":1.0}'::jsonb,
    '{"effect":"redirect_removal","timing":"instant","category":"protection","functions":["redirect","protection","interaction"],"runtime_modes":["change_target_of_single_target_spell_or_ability"],"annotation_modes":["additional_cost_life_or_mana"]}'::jsonb,
    'PG081 shared deck607/608 high: replaces wrong draw_cards model with single-target spell/ability redirect; additional life/mana cost is tracked as annotation.'
  );

CREATE TABLE manaloom_deploy_audit.pg081_deck607_608_shared_high_20260623_082229 AS
SELECT *
FROM card_battle_rules
WHERE normalized_name IN (SELECT normalized_name FROM pg081_shared_high_targets);

DO $$
DECLARE
  v_target integer;
  v_oracle integer;
  v_trusted integer;
  v_conflicts integer;
  v_shadow integer;
BEGIN
  SELECT
    count(*),
    count(*) FILTER (WHERE md5(coalesce(c.oracle_text, '')) = t.expected_oracle_hash),
    count(*) FILTER (WHERE cbr.source = 'curated' AND cbr.review_status = 'verified' AND cbr.execution_status = 'auto')
  INTO v_target, v_oracle, v_trusted
  FROM pg081_shared_high_targets t
  JOIN card_battle_rules cbr
    ON cbr.normalized_name = t.normalized_name
   AND cbr.logical_rule_key = t.old_logical_rule_key
  JOIN cards c
    ON c.id = cbr.card_id;

  SELECT count(*)
  INTO v_conflicts
  FROM pg081_shared_high_targets t
  JOIN card_battle_rules cbr
    ON cbr.normalized_name = t.normalized_name
   AND cbr.logical_rule_key = t.new_logical_rule_key;

  SELECT count(*)
  INTO v_shadow
  FROM pg081_shared_high_targets t
  JOIN card_battle_rules cbr
    ON cbr.normalized_name = t.normalized_name
   AND cbr.source = 'generated'
   AND cbr.execution_status <> 'disabled';

  IF v_target <> 3 THEN
    RAISE EXCEPTION 'PG081 precondition failed: expected 3 target rows, got %', v_target;
  END IF;
  IF v_oracle <> 3 THEN
    RAISE EXCEPTION 'PG081 precondition failed: expected 3 current oracle hashes, got %', v_oracle;
  END IF;
  IF v_trusted <> 3 THEN
    RAISE EXCEPTION 'PG081 precondition failed: expected 3 trusted curated auto rows, got %', v_trusted;
  END IF;
  IF v_conflicts <> 0 THEN
    RAISE EXCEPTION 'PG081 precondition failed: expected 0 new logical key conflicts, got %', v_conflicts;
  END IF;
  IF v_shadow <> 3 THEN
    RAISE EXCEPTION 'PG081 precondition failed: expected 3 generated shadows, got %', v_shadow;
  END IF;
END $$;

UPDATE card_battle_rules cbr
SET
  logical_rule_key = t.new_logical_rule_key,
  effect_json = t.effect_json,
  deck_role_json = t.deck_role_json,
  oracle_hash = t.expected_oracle_hash,
  confidence = 0.970,
  review_status = 'verified',
  execution_status = 'auto',
  rule_version = greatest(cbr.rule_version, 2),
  reviewed_by = 'codex-auditor',
  reviewed_at = now(),
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(E'\n', nullif(cbr.notes, ''), t.review_note)
FROM pg081_shared_high_targets t
WHERE cbr.normalized_name = t.normalized_name
  AND cbr.logical_rule_key = t.old_logical_rule_key
  AND cbr.source = 'curated';

UPDATE card_battle_rules cbr
SET
  review_status = 'deprecated',
  execution_status = 'disabled',
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(E'\n', nullif(cbr.notes, ''), 'PG081 disabled generated shadow after trusted shared deck607/608 high rule promotion.')
FROM pg081_shared_high_targets t
WHERE cbr.normalized_name = t.normalized_name
  AND cbr.source = 'generated'
  AND cbr.execution_status <> 'disabled';

COMMIT;
