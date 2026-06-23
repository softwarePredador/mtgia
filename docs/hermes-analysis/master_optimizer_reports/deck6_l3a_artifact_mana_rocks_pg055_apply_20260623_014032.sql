-- PG055 Deck 6 L3A artifact mana-rock family apply.
-- Expected precheck:
--   deck_target_cards=7
--   target_rule_rows=18
--   target_runtime_rows=7
--   generated_review_only_rows=7
--   curated_shadow_rows_to_disable=4
--   trusted_missing_hash_rows=11
--   trusted_without_scope_rows=7
--   target_runtime_rows_without_produces=3
--   active_card_id_mismatch_same_oracle_rows=2
--   active_card_id_mismatch_unknown_or_mismatch_oracle_rows=0
--   target_names_missing_rules=0

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg055_deck6_l3a_artifact_mana_rocks_20260623_014032 AS
WITH target_names(name) AS (
  VALUES
    ('Arcane Signet'),
    ('Boros Signet'),
    ('Fellwar Stone'),
    ('Mana Vault'),
    ('Mox Amber'),
    ('Sol Ring'),
    ('Talisman of Conviction')
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
  target_logical_rule_key,
  produces,
  mana_produced,
  battle_model_scope,
  oracle_runtime_scope,
  activation_cost_generic,
  activation_cost_status,
  commander_identity_status,
  opponent_color_status,
  life_loss_status,
  normal_untap_status,
  draw_step_damage_status,
  upkeep_untap_status,
  legend_gate_status
) AS (
  VALUES
    ('Arcane Signet', 'battle_rule_v1:6671147cad5e2014454ed291f4b0c5ea', 'RW', 1, 'commander_identity_mana_rock_deck_scoped_v1', 'mana_source_runtime_commander_identity_annotation', NULL::integer, NULL::text, 'deck6_lorehold_rw_runtime_scope', NULL::text, NULL::text, NULL::text, NULL::text, NULL::text, NULL::text),
    ('Boros Signet', 'battle_rule_v1:6671147cad5e2014454ed291f4b0c5ea', 'RW', 1, 'activation_cost_net_mana_pair_rock_v1', 'net_mana_source_runtime_activation_cost_abstracted', 1, 'abstracted_as_net_one_mana', NULL::text, NULL::text, NULL::text, NULL::text, NULL::text, NULL::text, NULL::text),
    ('Fellwar Stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba', 'WUBRGC', 1, 'conditional_opponent_color_mana_rock_v1', 'mana_source_runtime_opponent_land_colors_abstracted', NULL::integer, NULL::text, NULL::text, 'abstracted_to_available_table_colors', NULL::text, NULL::text, NULL::text, NULL::text, NULL::text),
    ('Mana Vault', 'battle_rule_v1:5a2533694ffd19223d3cde1e25d258ff', 'C', 3, 'fast_mana_artifact_partial_v1', 'fast_mana_source_runtime_annotation_only_untap_damage_clauses', NULL::integer, NULL::text, NULL::text, NULL::text, NULL::text, 'annotation_only', 'annotation_only', 'annotation_only', NULL::text),
    ('Mox Amber', 'battle_rule_v1:972703914ee50acd7a4e6f529fea1adf', 'WUBRGC', 1, 'legend_gated_fast_mana_v1', 'legendary_presence_gate_runtime_color_choice_abstracted', NULL::integer, NULL::text, NULL::text, NULL::text, NULL::text, NULL::text, NULL::text, NULL::text, 'runtime_requires_legendary_creature_or_planeswalker'),
    ('Sol Ring', 'battle_rule_v1:54660395e3972806e107ca61c374b218', 'C', 2, 'colorless_two_mana_rock_v1', 'colorless_mana_source_runtime', NULL::integer, NULL::text, NULL::text, NULL::text, NULL::text, NULL::text, NULL::text, NULL::text, NULL::text),
    ('Talisman of Conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470', 'CRW', 1, 'pain_talisman_color_pair_partial_v1', 'mana_source_runtime_life_loss_annotation_only', NULL::integer, NULL::text, NULL::text, NULL::text, 'annotation_only', NULL::text, NULL::text, NULL::text, NULL::text)
),
deck_target AS (
  SELECT
    lower(c.name) AS normalized_name,
    c.name,
    c.id AS deck_card_id,
    md5(coalesce(c.oracle_text, '')) AS target_oracle_hash,
    tm.target_logical_rule_key,
    tm.produces,
    tm.mana_produced,
    tm.battle_model_scope,
    tm.oracle_runtime_scope,
    tm.activation_cost_generic,
    tm.activation_cost_status,
    tm.commander_identity_status,
    tm.opponent_color_status,
    tm.life_loss_status,
    tm.normal_untap_status,
    tm.draw_step_damage_status,
    tm.upkeep_untap_status,
    tm.legend_gate_status
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
      'effect', 'ramp_permanent',
      'mana_produced', dt.mana_produced,
      'produces', dt.produces,
      'battle_model_scope', dt.battle_model_scope,
      'oracle_runtime_scope', dt.oracle_runtime_scope,
      'activation_cost_generic', dt.activation_cost_generic,
      'activation_cost_status', dt.activation_cost_status,
      'commander_identity_status', dt.commander_identity_status,
      'opponent_color_status', dt.opponent_color_status,
      'life_loss_status', dt.life_loss_status,
      'normal_untap_status', dt.normal_untap_status,
      'draw_step_damage_status', dt.draw_step_damage_status,
      'upkeep_untap_status', dt.upkeep_untap_status,
      'legend_gate_status', dt.legend_gate_status,
      'requires_legendary_creature_or_planeswalker_for_mana', CASE WHEN dt.name = 'Mox Amber' THEN true ELSE NULL END,
      'conditionally_produces_opponent_land_colors', CASE WHEN dt.name = 'Fellwar Stone' THEN true ELSE NULL END,
      'does_not_untap_normally', CASE WHEN dt.name = 'Mana Vault' THEN true ELSE NULL END,
      'tapped_upkeep_damage', CASE WHEN dt.name = 'Mana Vault' THEN 1 ELSE NULL END,
      'upkeep_optional_untap_cost_generic', CASE WHEN dt.name = 'Mana Vault' THEN 4 ELSE NULL END,
      'pg055_l3a_artifact_mana_family', 'deck6_artifact_mana_rocks'
    )
  ),
  notes = concat_ws(
    E'\n',
    nullif(cbr.notes, ''),
    'PG055 2026-06-23: Deck 6 L3A artifact mana-rock family. Added oracle_hash, produces/mana_produced, battle_model_scope, and explicit annotation/abstraction status for non-executed activation/life/untap/color clauses. No deck swap.'
  ),
  updated_at = now()
FROM deck_target dt
WHERE cbr.normalized_name = dt.normalized_name
  AND cbr.logical_rule_key = dt.target_logical_rule_key
  AND cbr.source = 'curated'
  AND cbr.review_status IN ('verified', 'active')
  AND cbr.execution_status = 'auto';

WITH target_metadata(
  name,
  target_logical_rule_key
) AS (
  VALUES
    ('Arcane Signet', 'battle_rule_v1:6671147cad5e2014454ed291f4b0c5ea'),
    ('Boros Signet', 'battle_rule_v1:6671147cad5e2014454ed291f4b0c5ea'),
    ('Fellwar Stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba'),
    ('Mana Vault', 'battle_rule_v1:5a2533694ffd19223d3cde1e25d258ff'),
    ('Mox Amber', 'battle_rule_v1:972703914ee50acd7a4e6f529fea1adf'),
    ('Sol Ring', 'battle_rule_v1:54660395e3972806e107ca61c374b218'),
    ('Talisman of Conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470')
),
deck_target AS (
  SELECT
    lower(c.name) AS normalized_name,
    c.name,
    tm.target_logical_rule_key
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
    'PG055 2026-06-23: Disabled generated/legacy artifact mana-rock shadow after retaining an oracle-hashed trusted runtime rule for Deck 6 L3A artifact mana family.'
  ),
  updated_at = now()
FROM deck_target dt
WHERE cbr.normalized_name = dt.normalized_name
  AND (
    (cbr.source = 'generated'
      AND cbr.review_status = 'needs_review'
      AND cbr.execution_status = 'review_only')
    OR (
      cbr.source = 'curated'
      AND cbr.review_status IN ('verified', 'active')
      AND cbr.execution_status = 'auto'
      AND cbr.logical_rule_key IS DISTINCT FROM dt.target_logical_rule_key
    )
  );

COMMIT;
