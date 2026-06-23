-- PG059 sync metadata restore apply.
-- Restores oracle_hash and oracle-runtime metadata for trusted rows already
-- closed in PG052/PG054/PG057/PG058 after a reviewed JSON sync drift.

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg059_sync_metadata_restore_20260623_022328
(LIKE card_battle_rules INCLUDING ALL);

WITH target_rules(card_name, logical_rule_key) AS (
  VALUES
    ('Fellwar Stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba'),
    ('Mana Vault', 'battle_rule_v1:5a2533694ffd19223d3cde1e25d258ff'),
    ('Mox Amber', 'battle_rule_v1:972703914ee50acd7a4e6f529fea1adf'),
    ('Seething Song', 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7'),
    ('Silence', 'battle_rule_v1:74b210b77b004a677906e0216d44e445'),
    ('Talisman of Conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470'),
    ('Valakut Awakening // Valakut Stoneforge', 'battle_rule_v1:6e1f3b876822abafe1de47610f46858d')
)
INSERT INTO manaloom_deploy_audit.pg059_sync_metadata_restore_20260623_022328
SELECT cbr.*
FROM card_battle_rules cbr
JOIN target_rules tr
  ON cbr.normalized_name = lower(tr.card_name)
 AND cbr.logical_rule_key = tr.logical_rule_key
ON CONFLICT (normalized_name, logical_rule_key) DO NOTHING;

WITH target_rules(card_name, logical_rule_key, expected_effect_patch) AS (
  VALUES
    (
      'Fellwar Stone',
      'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba',
      '{"opponent_color_status":"abstracted_to_available_table_colors","oracle_runtime_scope":"mana_source_runtime_opponent_land_colors_abstracted","pg055_l3a_artifact_mana_family":"deck6_artifact_mana_rocks"}'::jsonb
    ),
    (
      'Mana Vault',
      'battle_rule_v1:5a2533694ffd19223d3cde1e25d258ff',
      '{"draw_step_damage_status":"annotation_only","normal_untap_status":"annotation_only","oracle_runtime_scope":"fast_mana_source_runtime_annotation_only_untap_damage_clauses","pg055_l3a_artifact_mana_family":"deck6_artifact_mana_rocks","upkeep_untap_status":"annotation_only"}'::jsonb
    ),
    (
      'Mox Amber',
      'battle_rule_v1:972703914ee50acd7a4e6f529fea1adf',
      '{"legend_gate_status":"runtime_requires_legendary_creature_or_planeswalker","oracle_runtime_scope":"legendary_presence_gate_runtime_color_choice_abstracted","pg055_l3a_artifact_mana_family":"deck6_artifact_mana_rocks"}'::jsonb
    ),
    (
      'Seething Song',
      'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7',
      '{"mana_color_status":"abstracted_to_generic_pool_runtime","oracle_runtime_scope":"single_shot_red_ritual_runtime_generic_pool_color_annotation","pg058_l3b_simple_red_ritual_family":"deck6_simple_red_rituals"}'::jsonb
    ),
    (
      'Silence',
      'battle_rule_v1:74b210b77b004a677906e0216d44e445',
      '{"oracle_runtime_scope":"opponent_spell_cast_lock_until_eot_runtime","pg054_l6_silence_family":"deck6_silence_lock"}'::jsonb
    ),
    (
      'Talisman of Conviction',
      'battle_rule_v1:02133e513da5ea98ac74d32d39b16470',
      '{"life_loss_status":"annotation_only","oracle_runtime_scope":"mana_source_runtime_life_loss_annotation_only","pg055_l3a_artifact_mana_family":"deck6_artifact_mana_rocks"}'::jsonb
    ),
    (
      'Valakut Awakening // Valakut Stoneforge',
      'battle_rule_v1:6e1f3b876822abafe1de47610f46858d',
      '{}'::jsonb
    )
),
target_data AS (
  SELECT
    tr.card_name,
    tr.logical_rule_key,
    tr.expected_effect_patch,
    c.id AS target_card_id,
    md5(coalesce(c.oracle_text, '')) AS target_oracle_hash
  FROM target_rules tr
  JOIN cards c
    ON lower(c.name) = lower(tr.card_name)
)
UPDATE card_battle_rules cbr
SET
  card_id = coalesce(cbr.card_id, td.target_card_id),
  oracle_hash = td.target_oracle_hash,
  effect_json = cbr.effect_json || td.expected_effect_patch,
  notes = CASE
    WHEN coalesce(cbr.notes, '') LIKE '%PG059 2026-06-23:%'
      THEN cbr.notes
    ELSE concat_ws(E'\n', nullif(cbr.notes, ''), 'PG059 2026-06-23: Restored trusted oracle_hash/oracle-runtime metadata after reviewed JSON sync drift; sync_battle_card_rules_pg.py now preserves existing hashes and curated metadata on conflict.')
  END,
  updated_at = CURRENT_TIMESTAMP,
  last_seen_at = CURRENT_TIMESTAMP
FROM target_data td
WHERE cbr.normalized_name = lower(td.card_name)
  AND cbr.logical_rule_key = td.logical_rule_key
  AND cbr.source = 'curated'
  AND cbr.review_status IN ('verified', 'active')
  AND cbr.execution_status IN ('auto', 'executable');

COMMIT;
