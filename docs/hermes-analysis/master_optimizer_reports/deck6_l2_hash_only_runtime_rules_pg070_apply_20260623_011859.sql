BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg070_deck6_l2_hash_only_runtime_rules_20260623_011859') IS NOT NULL THEN
    RAISE EXCEPTION 'PG070 backup table already exists';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pg070_deck6_l2_hash_only_runtime_rules_20260623_011859 AS
WITH target_rules(normalized_name) AS (
  VALUES
    ('fellwar stone'),
    ('mana vault'),
    ('mox amber'),
    ('scroll rack'),
    ('seething song'),
    ('silence'),
    ('talisman of conviction'),
    ('unexpected windfall'),
    ('valakut awakening // valakut stoneforge')
)
SELECT now() AS backed_up_at, to_jsonb(cbr) AS payload
FROM card_battle_rules cbr
JOIN target_rules tr ON tr.normalized_name = cbr.normalized_name;

DO $$
DECLARE
  v_cards integer;
  v_runtime_rows integer;
  v_missing_hash integer;
  v_active_needs_review integer;
BEGIN
  WITH target_rules(normalized_name, logical_rule_key, expected_scope) AS (
    VALUES
      ('fellwar stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba', 'conditional_opponent_color_mana_rock_v1'),
      ('mana vault', 'battle_rule_v1:5a2533694ffd19223d3cde1e25d258ff', 'fast_mana_artifact_partial_v1'),
      ('mox amber', 'battle_rule_v1:972703914ee50acd7a4e6f529fea1adf', 'legend_gated_fast_mana_v1'),
      ('scroll rack', 'battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2', 'scroll_rack_upkeep_single_exchange_v1'),
      ('seething song', 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7', 'single_shot_red_ritual_v1'),
      ('silence', 'battle_rule_v1:74b210b77b004a677906e0216d44e445', 'silence_until_eot_v1'),
      ('talisman of conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470', 'pain_talisman_color_pair_partial_v1'),
      ('unexpected windfall', 'battle_rule_v1:f9f98ea1925518eea7a7c94c21ef2dc4', 'discard_draw_create_treasures_v1'),
      ('valakut awakening // valakut stoneforge', 'battle_rule_v1:6e1f3b876822abafe1de47610f46858d', 'bottom_then_draw_plus_one_mdfc_land_v1')
  ),
  card_hashes AS (
    SELECT
      tr.normalized_name,
      count(c.id) AS card_rows,
      count(DISTINCT md5(coalesce(c.oracle_text, ''))) AS distinct_oracle_hashes
    FROM target_rules tr
    LEFT JOIN cards c ON lower(c.name) = tr.normalized_name
    GROUP BY tr.normalized_name
  )
  SELECT count(*) INTO v_cards
  FROM card_hashes
  WHERE card_rows >= 1
    AND distinct_oracle_hashes = 1;

  WITH target_rules(normalized_name, logical_rule_key, expected_scope) AS (
    VALUES
      ('fellwar stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba', 'conditional_opponent_color_mana_rock_v1'),
      ('mana vault', 'battle_rule_v1:5a2533694ffd19223d3cde1e25d258ff', 'fast_mana_artifact_partial_v1'),
      ('mox amber', 'battle_rule_v1:972703914ee50acd7a4e6f529fea1adf', 'legend_gated_fast_mana_v1'),
      ('scroll rack', 'battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2', 'scroll_rack_upkeep_single_exchange_v1'),
      ('seething song', 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7', 'single_shot_red_ritual_v1'),
      ('silence', 'battle_rule_v1:74b210b77b004a677906e0216d44e445', 'silence_until_eot_v1'),
      ('talisman of conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470', 'pain_talisman_color_pair_partial_v1'),
      ('unexpected windfall', 'battle_rule_v1:f9f98ea1925518eea7a7c94c21ef2dc4', 'discard_draw_create_treasures_v1'),
      ('valakut awakening // valakut stoneforge', 'battle_rule_v1:6e1f3b876822abafe1de47610f46858d', 'bottom_then_draw_plus_one_mdfc_land_v1')
  )
  SELECT
    count(*) FILTER (
      WHERE cbr.source = 'curated'
        AND cbr.review_status IN ('verified', 'active')
        AND cbr.execution_status IN ('auto', 'executable')
        AND cbr.effect_json->>'battle_model_scope' = tr.expected_scope
    ),
    count(*) FILTER (WHERE coalesce(cbr.oracle_hash, '') = ''),
    (
      SELECT count(*)
      FROM card_battle_rules shadow
      JOIN target_rules tr2 ON tr2.normalized_name = shadow.normalized_name
      WHERE shadow.review_status = 'needs_review'
        AND shadow.execution_status <> 'disabled'
    )
  INTO v_runtime_rows, v_missing_hash, v_active_needs_review
  FROM target_rules tr
  LEFT JOIN card_battle_rules cbr
    ON cbr.normalized_name = tr.normalized_name
   AND cbr.logical_rule_key = tr.logical_rule_key;

  IF v_cards <> 9 THEN
    RAISE EXCEPTION 'PG070 precondition failed: expected 9 target cards with single current oracle hash, got %', v_cards;
  END IF;
  IF v_runtime_rows <> 9 THEN
    RAISE EXCEPTION 'PG070 precondition failed: expected 9 matching scoped runtime rows, got %', v_runtime_rows;
  END IF;
  IF v_missing_hash <> 9 THEN
    RAISE EXCEPTION 'PG070 precondition failed: expected 9 missing runtime hashes before apply, got %', v_missing_hash;
  END IF;
  IF v_active_needs_review <> 0 THEN
    RAISE EXCEPTION 'PG070 precondition failed: active needs_review shadow rows still enabled: %', v_active_needs_review;
  END IF;
END $$;

WITH target_rules(normalized_name, logical_rule_key) AS (
  VALUES
    ('fellwar stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba'),
    ('mana vault', 'battle_rule_v1:5a2533694ffd19223d3cde1e25d258ff'),
    ('mox amber', 'battle_rule_v1:972703914ee50acd7a4e6f529fea1adf'),
    ('scroll rack', 'battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2'),
    ('seething song', 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7'),
    ('silence', 'battle_rule_v1:74b210b77b004a677906e0216d44e445'),
    ('talisman of conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470'),
    ('unexpected windfall', 'battle_rule_v1:f9f98ea1925518eea7a7c94c21ef2dc4'),
    ('valakut awakening // valakut stoneforge', 'battle_rule_v1:6e1f3b876822abafe1de47610f46858d')
),
card_hashes AS (
  SELECT
    tr.normalized_name,
    max(md5(coalesce(c.oracle_text, ''))) AS oracle_hash
  FROM target_rules tr
  JOIN cards c ON lower(c.name) = tr.normalized_name
  GROUP BY tr.normalized_name
)
UPDATE card_battle_rules cbr
SET
  oracle_hash = ch.oracle_hash,
  rule_version = greatest(cbr.rule_version, 2),
  reviewed_by = coalesce(cbr.reviewed_by, 'codex-auditor'),
  reviewed_at = coalesce(cbr.reviewed_at, now()),
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(
    E'\n',
    nullif(cbr.notes, ''),
    'PG070: hash-only L2 cleanup; filled oracle_hash from current PostgreSQL cards.oracle_text without changing runtime effect_json.'
  )
FROM target_rules tr
JOIN card_hashes ch ON ch.normalized_name = tr.normalized_name
WHERE cbr.normalized_name = tr.normalized_name
  AND cbr.logical_rule_key = tr.logical_rule_key;

COMMIT;
