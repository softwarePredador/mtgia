-- PG051 Deck 6 L1B non-fetch land mana-source apply.
-- Scope: Battle-relevant land mana production for Deck 6 non-fetch lands only.
-- Expected precheck:
--   deck_target_cards=11
--   fetchland_names_in_target=0
--   target_rule_rows=22
--   generated_review_only_rows=11
--   trusted_missing_hash_rows=11
--   trusted_without_scope_rows=11
--   trusted_without_produces_rows=11
--   active_card_id_mismatch_same_oracle_rows=0
--   active_card_id_mismatch_unknown_or_mismatch_oracle_rows=0
--   target_names_missing_rules=0

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg051_deck6_l1b_nonfetch_land_mana_20260623_011438 AS
WITH target_names(name) AS (
  VALUES
    ('Battlefield Forge'),
    ('City of Brass'),
    ('Clifftop Retreat'),
    ('Elegant Parlor'),
    ('Inspiring Vantage'),
    ('Mana Confluence'),
    ('Rugged Prairie'),
    ('Sacred Foundry'),
    ('Spectator Seating'),
    ('Sunbillow Verge'),
    ('Sundown Pass')
),
deck_target AS (
  SELECT lower(c.name) AS normalized_name
  FROM deck_cards dc
  JOIN cards c ON c.id = dc.card_id
  JOIN target_names tn ON tn.name = c.name
  WHERE dc.deck_id = '528c877f-f829-4207-95e6-73981776c323'::uuid
)
SELECT cbr.*
FROM card_battle_rules cbr
JOIN deck_target dt ON dt.normalized_name = cbr.normalized_name;

WITH target_metadata(
  name,
  produces,
  battle_model_scope,
  annotation_field,
  annotation_value,
  land_enters_tapped
) AS (
  VALUES
    ('Battlefield Forge', 'CWR', 'pain_land_flexible_mana_life_loss_annotation_v1', 'life_loss_on_colored_mana_status', 'annotation_only', NULL::boolean),
    ('City of Brass', 'WUBRG', 'five_color_tap_damage_land_annotation_v1', 'tap_damage_status', 'annotation_only', NULL::boolean),
    ('Clifftop Retreat', 'RW', 'check_land_dual_source_etb_annotation_v1', 'conditional_enters_tapped_status', 'annotation_only', NULL::boolean),
    ('Elegant Parlor', 'RW', 'surveil_dual_typed_land_etb_annotation_v1', 'surveil_status', 'annotation_only', true),
    ('Inspiring Vantage', 'RW', 'fastland_dual_source_etb_annotation_v1', 'conditional_enters_tapped_status', 'annotation_only', NULL::boolean),
    ('Mana Confluence', 'WUBRG', 'five_color_life_paid_land_annotation_v1', 'life_payment_status', 'annotation_only', NULL::boolean),
    ('Rugged Prairie', 'CWR', 'filter_land_flexible_mana_annotation_v1', 'filter_activation_status', 'abstracted_as_flexible_source', NULL::boolean),
    ('Sacred Foundry', 'RW', 'shock_dual_typed_land_etb_annotation_v1', 'optional_pay_2_life_status', 'annotation_only', NULL::boolean),
    ('Spectator Seating', 'RW', 'bond_land_dual_source_etb_annotation_v1', 'multiplayer_enters_untapped_status', 'assumed_for_commander_table', NULL::boolean),
    ('Sunbillow Verge', 'WR', 'verge_dual_source_condition_annotation_v1', 'red_condition_status', 'annotation_only', NULL::boolean),
    ('Sundown Pass', 'RW', 'slowland_dual_source_etb_annotation_v1', 'conditional_enters_tapped_status', 'annotation_only', NULL::boolean)
),
deck_target AS (
  SELECT
    lower(c.name) AS normalized_name,
    c.name,
    c.id AS deck_card_id,
    md5(coalesce(c.oracle_text, '')) AS target_oracle_hash,
    tm.produces,
    tm.battle_model_scope,
    tm.annotation_field,
    tm.annotation_value,
    tm.land_enters_tapped
  FROM deck_cards dc
  JOIN cards c ON c.id = dc.card_id
  JOIN target_metadata tm ON tm.name = c.name
  WHERE dc.deck_id = '528c877f-f829-4207-95e6-73981776c323'::uuid
)
UPDATE card_battle_rules cbr
SET
  card_id = dt.deck_card_id,
  oracle_hash = dt.target_oracle_hash,
  effect_json = jsonb_strip_nulls(
    coalesce(cbr.effect_json, '{}'::jsonb)
    || jsonb_build_object(
      'effect', 'land',
      'mana_produced', 1,
      'produces', dt.produces,
      'battle_model_scope', dt.battle_model_scope,
      'oracle_runtime_scope', 'mana_source_runtime_with_annotation_only_clauses',
      'pg051_l1b_land_family', 'deck6_nonfetch_mana_land',
      dt.annotation_field, dt.annotation_value,
      'land_enters_tapped', CASE WHEN dt.land_enters_tapped IS TRUE THEN true ELSE NULL END
    )
  ),
  notes = concat_ws(
    E'\n',
    nullif(cbr.notes, ''),
    'PG051 2026-06-23: Deck 6 L1B non-fetch land mana-source model. Added oracle_hash, battle_model_scope, mana production, and annotation-only status for non-executed life/ETB/filter/surveil clauses. No deck swap.'
  ),
  updated_at = now()
FROM deck_target dt
WHERE cbr.normalized_name = dt.normalized_name
  AND cbr.source = 'curated'
  AND cbr.review_status IN ('verified', 'active')
  AND cbr.execution_status = 'auto';

WITH target_metadata(name) AS (
  VALUES
    ('Battlefield Forge'),
    ('City of Brass'),
    ('Clifftop Retreat'),
    ('Elegant Parlor'),
    ('Inspiring Vantage'),
    ('Mana Confluence'),
    ('Rugged Prairie'),
    ('Sacred Foundry'),
    ('Spectator Seating'),
    ('Sunbillow Verge'),
    ('Sundown Pass')
),
deck_target AS (
  SELECT lower(c.name) AS normalized_name
  FROM deck_cards dc
  JOIN cards c ON c.id = dc.card_id
  JOIN target_metadata tm ON tm.name = c.name
  WHERE dc.deck_id = '528c877f-f829-4207-95e6-73981776c323'::uuid
)
UPDATE card_battle_rules cbr
SET
  review_status = 'deprecated',
  execution_status = 'disabled',
  notes = concat_ws(
    E'\n',
    nullif(cbr.notes, ''),
    'PG051 2026-06-23: Disabled generated review_only land shadow after retaining curated oracle-backed non-fetch land mana model for Deck 6 L1B.'
  ),
  updated_at = now()
FROM deck_target dt
WHERE cbr.normalized_name = dt.normalized_name
  AND cbr.source = 'generated'
  AND cbr.review_status = 'needs_review'
  AND cbr.execution_status = 'review_only';

COMMIT;
