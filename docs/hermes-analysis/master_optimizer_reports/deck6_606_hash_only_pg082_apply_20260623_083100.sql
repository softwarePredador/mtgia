\pset pager off

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg082_deck6_606_hash_only_20260623_083100') IS NOT NULL THEN
    RAISE EXCEPTION 'PG082 deck6/606 hash-only backup table already exists';
  END IF;
END $$;

CREATE TEMP TABLE pg082_hash_only_targets(
  normalized_name text,
  logical_rule_key text,
  expected_oracle_hash text,
  expected_effect text,
  expected_scope text
);

INSERT INTO pg082_hash_only_targets(
  normalized_name,
  logical_rule_key,
  expected_oracle_hash,
  expected_effect,
  expected_scope
)
VALUES
  ('library of leng', 'battle_rule_v1:b6491cf6f7d7df9a3fb0d91abd3d31c3', '575aef3cc2523831e440ea7dcd55fa6e', 'passive', 'discard_replacement_to_top_v1'),
  ('scroll rack', 'battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2', '8133928f03d5a5a77f2beecfcbd09e30', 'topdeck_manipulation', 'scroll_rack_upkeep_single_exchange_v1'),
  ('unexpected windfall', 'battle_rule_v1:f9f98ea1925518eea7a7c94c21ef2dc4', '9c4fbe06104051a2e8b1d295d307b26a', 'treasure_maker', 'discard_draw_create_treasures_v1'),
  ('valakut awakening // valakut stoneforge', 'battle_rule_v1:6e1f3b876822abafe1de47610f46858d', '22b42fcc181b7aed71f78b2e1e51e887', 'hand_filter', 'bottom_then_draw_plus_one_mdfc_land_v1'),
  ('wayfarer''s bauble', 'battle_rule_v1:97eb0d5868d1c777b74aa7d35fc85eab', 'f11935fa793ae03d95ae75d62cdfa516', 'ramp_permanent', 'self_sacrifice_basic_land_tutor_artifact_v1');

CREATE TABLE manaloom_deploy_audit.pg082_deck6_606_hash_only_20260623_083100 AS
SELECT cbr.*
FROM card_battle_rules cbr
JOIN pg082_hash_only_targets t USING (normalized_name);

DO $$
DECLARE
  target_count integer;
  missing_count integer;
  effect_count integer;
  scope_count integer;
  oracle_match_count integer;
  active_shadow_count integer;
BEGIN
  SELECT count(*) INTO target_count
  FROM card_battle_rules cbr
  JOIN pg082_hash_only_targets t
    ON cbr.normalized_name = t.normalized_name
   AND cbr.logical_rule_key = t.logical_rule_key
  WHERE cbr.source IN ('manual', 'curated')
    AND cbr.execution_status IN ('auto', 'executable');

  SELECT count(*) INTO missing_count
  FROM card_battle_rules cbr
  JOIN pg082_hash_only_targets t
    ON cbr.normalized_name = t.normalized_name
   AND cbr.logical_rule_key = t.logical_rule_key
  WHERE cbr.oracle_hash IS NULL OR cbr.oracle_hash = '';

  SELECT count(*) INTO effect_count
  FROM card_battle_rules cbr
  JOIN pg082_hash_only_targets t
    ON cbr.normalized_name = t.normalized_name
   AND cbr.logical_rule_key = t.logical_rule_key
  WHERE cbr.effect_json->>'effect' = t.expected_effect;

  SELECT count(*) INTO scope_count
  FROM card_battle_rules cbr
  JOIN pg082_hash_only_targets t
    ON cbr.normalized_name = t.normalized_name
   AND cbr.logical_rule_key = t.logical_rule_key
  WHERE cbr.effect_json->>'battle_model_scope' = t.expected_scope;

  SELECT count(*) INTO oracle_match_count
  FROM pg082_hash_only_targets t
  JOIN cards c ON lower(c.name) = t.normalized_name
  WHERE md5(coalesce(c.oracle_text, '')) = t.expected_oracle_hash;

  SELECT count(*) INTO active_shadow_count
  FROM card_battle_rules cbr
  JOIN pg082_hash_only_targets t USING (normalized_name)
  WHERE cbr.source = 'generated'
    AND cbr.execution_status <> 'disabled';

  IF target_count <> 5 THEN
    RAISE EXCEPTION 'Expected 5 trusted target rows, found %', target_count;
  END IF;
  IF missing_count <> 5 THEN
    RAISE EXCEPTION 'Expected 5 target rows missing oracle_hash before apply, found %', missing_count;
  END IF;
  IF effect_count <> 5 THEN
    RAISE EXCEPTION 'Expected 5 target rows with expected effects, found %', effect_count;
  END IF;
  IF scope_count <> 5 THEN
    RAISE EXCEPTION 'Expected 5 target rows with expected scopes, found %', scope_count;
  END IF;
  IF oracle_match_count <> 5 THEN
    RAISE EXCEPTION 'Expected 5 card oracle hashes to match expected hashes, found %', oracle_match_count;
  END IF;
  IF active_shadow_count <> 0 THEN
    RAISE EXCEPTION 'Expected zero non-disabled generated shadow rows for hash-only targets, found %', active_shadow_count;
  END IF;
END $$;

UPDATE card_battle_rules cbr
SET
  oracle_hash = t.expected_oracle_hash,
  rule_version = GREATEST(cbr.rule_version, 2),
  notes = CASE
    WHEN cbr.notes ILIKE '%PG082 deck6/606 hash-only%'
      THEN cbr.notes
    ELSE concat_ws(' ', NULLIF(cbr.notes, ''), 'PG082 deck6/606 hash-only: restored oracle_hash provenance for already scoped trusted executable rule; no semantic runtime, effect_json, deck_role_json, or deck composition change.')
  END,
  reviewed_by = COALESCE(cbr.reviewed_by, 'codex-pg082'),
  reviewed_at = COALESCE(cbr.reviewed_at, CURRENT_TIMESTAMP),
  updated_at = CURRENT_TIMESTAMP,
  last_seen_at = CURRENT_TIMESTAMP
FROM pg082_hash_only_targets t
WHERE cbr.normalized_name = t.normalized_name
  AND cbr.logical_rule_key = t.logical_rule_key;

UPDATE card_battle_rules cbr
SET
  execution_status = 'disabled',
  review_status = 'deprecated',
  notes = CASE
    WHEN cbr.notes ILIKE '%PG082 deck6/606 hash-only%'
      THEN cbr.notes
    ELSE concat_ws(' ', NULLIF(cbr.notes, ''), 'PG082 deck6/606 hash-only: generated shadow remains disabled after scoped trusted executable row retained oracle_hash provenance.')
  END,
  updated_at = CURRENT_TIMESTAMP,
  last_seen_at = CURRENT_TIMESTAMP
FROM pg082_hash_only_targets t
WHERE cbr.normalized_name = t.normalized_name
  AND cbr.source = 'generated'
  AND cbr.execution_status <> 'disabled';

COMMIT;
