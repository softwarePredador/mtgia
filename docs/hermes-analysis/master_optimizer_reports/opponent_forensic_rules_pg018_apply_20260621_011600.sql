\pset pager off
\set ON_ERROR_STOP on

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DROP TABLE IF EXISTS manaloom_deploy_audit.pg018_opponent_forensic_rules_20260621_011600;
CREATE TABLE manaloom_deploy_audit.pg018_opponent_forensic_rules_20260621_011600 (
  section text NOT NULL,
  key text NOT NULL,
  payload jsonb NOT NULL,
  captured_at timestamptz NOT NULL DEFAULT now()
);

WITH wanted(card_name) AS (
  VALUES
    ('Jin-Gitaxias, Core Augur'),
    ('Chandra, Flameshaper')
)
INSERT INTO manaloom_deploy_audit.pg018_opponent_forensic_rules_20260621_011600
  (section, key, payload)
SELECT
  'card_battle_rules',
  cbr.normalized_name || '|' || cbr.logical_rule_key,
  to_jsonb(cbr.*)
FROM card_battle_rules cbr
JOIN wanted w ON lower(cbr.card_name) = lower(w.card_name);

WITH wanted(card_name) AS (
  VALUES
    ('Jin-Gitaxias, Core Augur'),
    ('Chandra, Flameshaper')
)
INSERT INTO manaloom_deploy_audit.pg018_opponent_forensic_rules_20260621_011600
  (section, key, payload)
SELECT
  'card_function_tags',
  cft.card_id::text || '|' || cft.tag || '|' || cft.source,
  to_jsonb(cft.*)
FROM card_function_tags cft
JOIN wanted w ON lower(cft.card_name) = lower(w.card_name);

DO $$
DECLARE
  v_card_rows int;
  v_legal_rows int;
  v_hash_mismatch int;
BEGIN
  WITH wanted(card_name, expected_oracle_hash) AS (
    VALUES
      ('Jin-Gitaxias, Core Augur', '6cbe9a3e4c114022f6a3e1b855bdc392'),
      ('Chandra, Flameshaper', 'd41ef10198ca5cefdfa1c4d2687f0e3b')
  )
  SELECT
    count(c.id),
    count(*) FILTER (WHERE cl.status = 'legal'),
    count(*) FILTER (
      WHERE md5(regexp_replace(lower(coalesce(c.oracle_text, '')), '\s+', ' ', 'g')) <> wanted.expected_oracle_hash
    )
  INTO v_card_rows, v_legal_rows, v_hash_mismatch
  FROM wanted
  LEFT JOIN cards c ON lower(c.name) = lower(wanted.card_name)
  LEFT JOIN card_legalities cl ON cl.card_id = c.id AND cl.format = 'commander';

  IF v_card_rows <> 2 THEN
    RAISE EXCEPTION 'PG018 precondition failed: card_rows=% expected 2', v_card_rows;
  END IF;
  IF v_legal_rows <> 2 THEN
    RAISE EXCEPTION 'PG018 precondition failed: legal commander rows=% expected 2', v_legal_rows;
  END IF;
  IF v_hash_mismatch <> 0 THEN
    RAISE EXCEPTION 'PG018 precondition failed: oracle hash mismatches=% expected 0', v_hash_mismatch;
  END IF;
END $$;

WITH rules(card_name, normalized_name, logical_rule_key, oracle_hash, effect_json, deck_role_json, tag, confidence, notes) AS (
  VALUES
    (
      'Jin-Gitaxias, Core Augur',
      'jin-gitaxias, core augur',
      'battle_rule_v1:d14acbe78307b4328ec7c6b58500d39e',
      '6cbe9a3e4c114022f6a3e1b855bdc392',
      jsonb_build_object(
        'effect', 'draw_cards',
        'count', 7,
        'draw_count', 7,
        'cmc', 10.0,
        'battle_model_scope', 'jin_gitaxias_core_augur_draw_seven_proxy_max_hand_size_unmodeled_v1'
      ),
      jsonb_build_object(
        'category', 'draw',
        'effect', 'draw_cards',
        'subtype', 'end_step_draw_proxy'
      ),
      'draw',
      0.86,
      'PG-018: replaces forensic-blocking functional_tags_json heuristic for opponent replays. Runtime proxy draws seven on resolution path; beginning-of-end-step timing and opponent maximum-hand-size reduction are documented but not modeled in this pass.'
    ),
    (
      'Chandra, Flameshaper',
      'chandra, flameshaper',
      'battle_rule_v1:ee7ee13e3d57abd378763be663390375',
      'd41ef10198ca5cefdfa1c4d2687f0e3b',
      jsonb_build_object(
        'effect', 'ramp_permanent',
        'mana_produced', 3,
        'is_mana_source', true,
        'cmc', 7.0,
        'battle_model_scope', 'chandra_flameshaper_plus_two_mana_proxy_loyalty_unmodeled_v1'
      ),
      jsonb_build_object(
        'category', 'ramp',
        'effect', 'ramp_permanent',
        'subtype', 'planeswalker_mana_proxy'
      ),
      'ramp',
      0.84,
      'PG-018: replaces forensic-blocking functional_tags_json heuristic for opponent replays. Runtime proxy models the +2 as a repeatable three-mana source; loyalty timing, impulse choice, token copy, and divided damage modes are documented but not modeled in this pass.'
    )
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
  rules.normalized_name,
  rules.logical_rule_key,
  cards.id,
  cards.name,
  rules.effect_json,
  rules.deck_role_json,
  'curated',
  rules.confidence,
  'verified',
  'auto',
  1,
  rules.oracle_hash,
  rules.notes,
  'codex_central_auditor_pg018',
  now(),
  now(),
  now(),
  now()
FROM rules
JOIN cards ON lower(cards.name) = lower(rules.card_name)
ON CONFLICT (normalized_name, logical_rule_key)
DO UPDATE SET
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

WITH rules(card_name, tag, confidence, evidence) AS (
  VALUES
    (
      'Jin-Gitaxias, Core Augur',
      'draw',
      0.86,
      'PG-018 curated draw_cards proxy battle rule battle_rule_v1:d14acbe78307b4328ec7c6b58500d39e'
    ),
    (
      'Chandra, Flameshaper',
      'ramp',
      0.84,
      'PG-018 curated ramp_permanent proxy battle rule battle_rule_v1:ee7ee13e3d57abd378763be663390375'
    )
)
INSERT INTO card_function_tags (
  card_id,
  card_name,
  tag,
  confidence,
  source,
  evidence,
  updated_at
)
SELECT
  cards.id,
  cards.name,
  rules.tag,
  rules.confidence,
  'card_battle_rules_v1',
  rules.evidence,
  now()
FROM rules
JOIN cards ON lower(cards.name) = lower(rules.card_name)
ON CONFLICT (card_id, tag, source)
DO UPDATE SET
  card_name = EXCLUDED.card_name,
  confidence = EXCLUDED.confidence,
  evidence = EXCLUDED.evidence,
  updated_at = now();

DO $$
DECLARE
  v_curated int;
  v_tags int;
BEGIN
  SELECT count(*) INTO v_curated
  FROM card_battle_rules
  WHERE normalized_name IN ('jin-gitaxias, core augur', 'chandra, flameshaper')
    AND source = 'curated'
    AND review_status = 'verified'
    AND execution_status = 'auto'
    AND logical_rule_key IN (
      'battle_rule_v1:d14acbe78307b4328ec7c6b58500d39e',
      'battle_rule_v1:ee7ee13e3d57abd378763be663390375'
    );

  SELECT count(*) INTO v_tags
  FROM card_function_tags
  WHERE lower(card_name) IN ('jin-gitaxias, core augur', 'chandra, flameshaper')
    AND source = 'card_battle_rules_v1'
    AND tag IN ('draw', 'ramp');

  IF v_curated <> 2 THEN
    RAISE EXCEPTION 'PG018 apply failed: curated executable rows=% expected 2', v_curated;
  END IF;
  IF v_tags <> 2 THEN
    RAISE EXCEPTION 'PG018 apply failed: function tags=% expected 2', v_tags;
  END IF;
END $$;

COMMIT;
