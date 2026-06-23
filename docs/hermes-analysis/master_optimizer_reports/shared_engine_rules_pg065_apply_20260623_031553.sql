BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg065_shared_engine_rules_20260623_031553 AS
SELECT
  now() AS backed_up_at,
  to_jsonb(cbr) AS payload
FROM card_battle_rules cbr
WHERE cbr.normalized_name IN ('scroll rack', 'smothering tithe');

DO $$
DECLARE
  v_bad_hash_count integer;
  v_missing_count integer;
BEGIN
  WITH expected(card_name, expected_oracle_hash) AS (
    VALUES
      ('Scroll Rack', '8133928f03d5a5a77f2beecfcbd09e30'),
      ('Smothering Tithe', 'bb7d29c1a84a53604c017da1b5f0620c')
  )
  SELECT
    count(*) FILTER (WHERE c.id IS NULL),
    count(*) FILTER (
      WHERE c.id IS NOT NULL
        AND md5(coalesce(c.oracle_text, '')) <> expected.expected_oracle_hash
    )
  INTO v_missing_count, v_bad_hash_count
  FROM expected
  LEFT JOIN cards c ON lower(c.name) = lower(expected.card_name);

  IF v_missing_count <> 0 THEN
    RAISE EXCEPTION 'PG065 precondition failed: missing target card rows=%', v_missing_count;
  END IF;

  IF v_bad_hash_count <> 0 THEN
    RAISE EXCEPTION 'PG065 precondition failed: oracle hash mismatches=%', v_bad_hash_count;
  END IF;
END $$;

WITH rules AS (
  SELECT
    'Scroll Rack'::text AS card_name,
    'scroll rack'::text AS normalized_name,
    'battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2'::text AS logical_rule_key,
    '8133928f03d5a5a77f2beecfcbd09e30'::text AS oracle_hash,
    jsonb_build_object(
      'cmc', 2.0,
      'effect', 'topdeck_manipulation',
      'activation_cost_generic', 1,
      'hand_to_top_exchange', true,
      'battle_model_scope', 'scroll_rack_upkeep_single_exchange_v1',
      'runtime_slice', 'lorehold_opponent_upkeep_single_exchange_for_first_draw',
      'full_exchange_status', 'annotation_only'
    ) AS effect_json,
    jsonb_build_object(
      'category', 'draw',
      'effect', 'topdeck_manipulation',
      'subtype', 'topdeck_setup'
    ) AS deck_role_json,
    'curated'::text AS source,
    0.90::numeric AS confidence,
    'active'::text AS review_status,
    'auto'::text AS execution_status,
    2::integer AS rule_version,
    'PG065: oracle-hashed Scroll Rack runtime slice. Exact oracle supports arbitrary hand/top exchange; simulator executes the Lorehold-safe opponent-upkeep single-card exchange that sets the next first draw, while full arbitrary sequencing remains annotation-only.'::text AS notes
  UNION ALL
  SELECT
    'Smothering Tithe'::text AS card_name,
    'smothering tithe'::text AS normalized_name,
    'battle_rule_v1:242df1cde958c67ece11aae4af5f4bc6'::text AS logical_rule_key,
    'bb7d29c1a84a53604c017da1b5f0620c'::text AS oracle_hash,
    jsonb_build_object(
      'cmc', 4.0,
      'effect', 'ramp_engine',
      'trigger', 'opponent_draw',
      'tax_amount', 2,
      'tax_payment_model', 'compact_assume_unpaid_v1',
      'treasure_count', 1,
      'battle_model_scope', 'opponent_draw_tax_treasure_v1',
      'wheel_payoff_model', 'opponent_cards_drawn_to_treasures_cap20_v1'
    ) AS effect_json,
    jsonb_build_object(
      'category', 'ramp',
      'effect', 'ramp_engine',
      'subtype', 'treasure_tax'
    ) AS deck_role_json,
    'curated'::text AS source,
    0.95::numeric AS confidence,
    'verified'::text AS review_status,
    'auto'::text AS execution_status,
    2::integer AS rule_version,
    'PG065: oracle-hashed Smothering Tithe runtime model. Draw-step opponent draws create one Treasure in the compact model; wheel payoff converts opponent cards drawn into Treasures with the existing cap for replay stability.'::text AS notes
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
  updated_at,
  last_seen_at
)
SELECT
  rules.normalized_name,
  rules.logical_rule_key,
  c.id,
  rules.card_name,
  rules.effect_json,
  rules.deck_role_json,
  rules.source,
  rules.confidence,
  rules.review_status,
  rules.execution_status,
  rules.rule_version,
  rules.oracle_hash,
  rules.notes,
  'codex-auditor',
  now(),
  now(),
  now()
FROM rules
JOIN cards c ON lower(c.name) = lower(rules.card_name)
ON CONFLICT (normalized_name, logical_rule_key) DO UPDATE SET
  card_id = excluded.card_id,
  card_name = excluded.card_name,
  effect_json = excluded.effect_json,
  deck_role_json = excluded.deck_role_json,
  source = excluded.source,
  confidence = excluded.confidence,
  review_status = excluded.review_status,
  execution_status = excluded.execution_status,
  rule_version = excluded.rule_version,
  oracle_hash = excluded.oracle_hash,
  notes = excluded.notes,
  reviewed_by = excluded.reviewed_by,
  reviewed_at = excluded.reviewed_at,
  updated_at = excluded.updated_at,
  last_seen_at = excluded.last_seen_at;

UPDATE card_battle_rules
SET
  review_status = 'deprecated',
  execution_status = 'disabled',
  updated_at = now(),
  notes = concat_ws(
    E'\n',
    nullif(notes, ''),
    'PG065 disabled: superseded by oracle-hashed Scroll Rack topdeck_manipulation runtime slice battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2.'
  )
WHERE normalized_name = 'scroll rack'
  AND logical_rule_key IN (
    'battle_rule_v1:601753de1461f2f66d16bb51bd3fb408',
    'battle_rule_v1:efb8905b224067dc9b1c61e0bf194bfe'
  );

UPDATE card_battle_rules
SET
  review_status = 'deprecated',
  execution_status = 'disabled',
  updated_at = now(),
  notes = concat_ws(
    E'\n',
    nullif(notes, ''),
    'PG065 disabled: superseded by oracle-hashed Smothering Tithe opponent_draw treasure-tax runtime row battle_rule_v1:242df1cde958c67ece11aae4af5f4bc6.'
  )
WHERE normalized_name = 'smothering tithe'
  AND logical_rule_key = 'battle_rule_v1:6a05a46cea1a531f333aafb19180eb88';

COMMIT;
