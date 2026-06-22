\pset pager off
\set ON_ERROR_STOP on

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DROP TABLE IF EXISTS manaloom_deploy_audit.pg016_anti_combat_rules_20260621_011500;
CREATE TABLE manaloom_deploy_audit.pg016_anti_combat_rules_20260621_011500 (
  section text NOT NULL,
  key text NOT NULL,
  payload jsonb NOT NULL,
  captured_at timestamptz NOT NULL DEFAULT now()
);

WITH wanted(card_name) AS (
  VALUES
    ('Norn''s Annex'),
    ('Windborn Muse'),
    ('Silent Arbiter'),
    ('Ensnaring Bridge'),
    ('Magus of the Moat')
)
INSERT INTO manaloom_deploy_audit.pg016_anti_combat_rules_20260621_011500
  (section, key, payload)
SELECT
  'card_battle_rules',
  cbr.normalized_name || '|' || cbr.logical_rule_key,
  to_jsonb(cbr.*)
FROM card_battle_rules cbr
JOIN wanted w ON lower(cbr.card_name) = lower(w.card_name);

WITH wanted(card_name) AS (
  VALUES
    ('Norn''s Annex'),
    ('Windborn Muse'),
    ('Silent Arbiter'),
    ('Ensnaring Bridge'),
    ('Magus of the Moat')
)
INSERT INTO manaloom_deploy_audit.pg016_anti_combat_rules_20260621_011500
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
      ('Norn''s Annex', 'c24fdd009dc36172162fa5f1c581b2da'),
      ('Windborn Muse', '370b18223df70f111f8673fd6b4acb7f'),
      ('Silent Arbiter', '77d31b859247e6129c25b4fa47be336e'),
      ('Ensnaring Bridge', 'f5f24e3b4b9f6a52fb0afa1cef9ae3d3'),
      ('Magus of the Moat', 'da1c62032e405fc6fc6151ccdf6df879')
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

  IF v_card_rows <> 5 THEN
    RAISE EXCEPTION 'PG016 precondition failed: card_rows=% expected 5', v_card_rows;
  END IF;
  IF v_legal_rows <> 5 THEN
    RAISE EXCEPTION 'PG016 precondition failed: legal commander rows=% expected 5', v_legal_rows;
  END IF;
  IF v_hash_mismatch <> 0 THEN
    RAISE EXCEPTION 'PG016 precondition failed: oracle hash mismatches=% expected 0', v_hash_mismatch;
  END IF;
END $$;

WITH rules(card_name, normalized_name, logical_rule_key, oracle_hash, effect_json, deck_role_json, notes) AS (
  VALUES
    (
      'Norn''s Annex',
      'norn''s annex',
      'battle_rule_v1:0b3adc33c3be375c3d4005b0082ff5c2',
      'c24fdd009dc36172162fa5f1c581b2da',
      jsonb_build_object(
        'effect', 'attack_tax',
        'attack_tax_per_creature', 1,
        'cmc', 5.0,
        'battle_model_scope', 'norns_annex_phyrexian_attack_tax_generic_proxy_v1'
      ),
      jsonb_build_object(
        'category', 'protection',
        'effect', 'attack_tax',
        'subtype', 'norns_annex_phyrexian_attack_tax_generic_proxy_v1'
      ),
      'PG-016: oracle-verified anti-combat candidate. Runtime proxy models Norn''s Annex as one generic attack tax per creature; Phyrexian life-payment choice is not modeled in this candidate pass.'
    ),
    (
      'Windborn Muse',
      'windborn muse',
      'battle_rule_v1:6932f0223ca41f0eedf724d55a9a858b',
      '370b18223df70f111f8673fd6b4acb7f',
      jsonb_build_object(
        'effect', 'attack_tax',
        'attack_tax_per_creature', 2,
        'cmc', 4.0,
        'battle_model_scope', 'windborn_muse_attack_tax_v1'
      ),
      jsonb_build_object(
        'category', 'protection',
        'effect', 'attack_tax',
        'subtype', 'windborn_muse_attack_tax_v1'
      ),
      'PG-016: oracle-verified anti-combat candidate. Runtime models Windborn Muse as Ghostly Prison style attack tax attached to the controller.'
    ),
    (
      'Silent Arbiter',
      'silent arbiter',
      'battle_rule_v1:6f6089b73fb8f7f9aee20cacb64fffc7',
      '77d31b859247e6129c25b4fa47be336e',
      jsonb_build_object(
        'effect', 'attack_limit',
        'max_attackers_against_you', 1,
        'cmc', 4.0,
        'battle_model_scope', 'silent_arbiter_single_attacker_against_lorehold_v1'
      ),
      jsonb_build_object(
        'category', 'protection',
        'effect', 'attack_limit',
        'subtype', 'silent_arbiter_single_attacker_against_lorehold_v1'
      ),
      'PG-016: oracle-verified anti-combat candidate. Runtime proxy models the relevant table-pressure behavior as one attacker against controller; one-blocker clause is not modeled in this candidate pass.'
    ),
    (
      'Ensnaring Bridge',
      'ensnaring bridge',
      'battle_rule_v1:1ea5840419f4343c05a661e79d6829d5',
      'f5f24e3b4b9f6a52fb0afa1cef9ae3d3',
      jsonb_build_object(
        'effect', 'attack_limit',
        'max_attacker_power_by_defender_hand_size', true,
        'cmc', 3.0,
        'battle_model_scope', 'ensnaring_bridge_hand_size_power_filter_v1'
      ),
      jsonb_build_object(
        'category', 'protection',
        'effect', 'attack_limit',
        'subtype', 'ensnaring_bridge_hand_size_power_filter_v1'
      ),
      'PG-016: oracle-verified anti-combat candidate. Runtime filters attackers with power greater than controller hand size.'
    ),
    (
      'Magus of the Moat',
      'magus of the moat',
      'battle_rule_v1:439de5be33887bbce5dde1cfb367774a',
      'da1c62032e405fc6fc6151ccdf6df879',
      jsonb_build_object(
        'effect', 'attack_limit',
        'attack_requires_keyword', 'flying',
        'cmc', 4.0,
        'battle_model_scope', 'magus_of_the_moat_flying_attack_filter_v1'
      ),
      jsonb_build_object(
        'category', 'protection',
        'effect', 'attack_limit',
        'subtype', 'magus_of_the_moat_flying_attack_filter_v1'
      ),
      'PG-016: oracle-verified anti-combat candidate. Runtime filters non-flying attackers against the controller.'
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
  c.id,
  c.name,
  rules.effect_json,
  rules.deck_role_json,
  'curated',
  0.92,
  'verified',
  'auto',
  1,
  rules.oracle_hash,
  rules.notes,
  'codex_central_auditor_pg016',
  now(),
  now(),
  now(),
  now()
FROM rules
JOIN cards c ON lower(c.name) = lower(rules.card_name)
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

WITH wanted(card_name, keep_key) AS (
  VALUES
    ('Norn''s Annex', 'battle_rule_v1:0b3adc33c3be375c3d4005b0082ff5c2'),
    ('Windborn Muse', 'battle_rule_v1:6932f0223ca41f0eedf724d55a9a858b'),
    ('Silent Arbiter', 'battle_rule_v1:6f6089b73fb8f7f9aee20cacb64fffc7'),
    ('Ensnaring Bridge', 'battle_rule_v1:1ea5840419f4343c05a661e79d6829d5'),
    ('Magus of the Moat', 'battle_rule_v1:439de5be33887bbce5dde1cfb367774a')
)
UPDATE card_battle_rules cbr
SET
  review_status = 'deprecated',
  execution_status = 'disabled',
  notes = concat_ws(
    E'\n',
    NULLIF(cbr.notes, ''),
    'PG-016 disabled stale generated approximation after curated anti-combat candidate rule.'
  ),
  reviewed_by = 'codex_central_auditor_pg016',
  reviewed_at = now(),
  updated_at = now()
FROM wanted
WHERE lower(cbr.card_name) = lower(wanted.card_name)
  AND cbr.logical_rule_key <> wanted.keep_key
  AND cbr.source = 'generated';

WITH wanted(card_name, logical_rule_key) AS (
  VALUES
    ('Norn''s Annex', 'battle_rule_v1:0b3adc33c3be375c3d4005b0082ff5c2'),
    ('Windborn Muse', 'battle_rule_v1:6932f0223ca41f0eedf724d55a9a858b'),
    ('Silent Arbiter', 'battle_rule_v1:6f6089b73fb8f7f9aee20cacb64fffc7'),
    ('Ensnaring Bridge', 'battle_rule_v1:1ea5840419f4343c05a661e79d6829d5'),
    ('Magus of the Moat', 'battle_rule_v1:439de5be33887bbce5dde1cfb367774a')
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
  c.id,
  c.name,
  'protection',
  0.92,
  'card_battle_rules_v1',
  'PG-016 curated anti-combat candidate rule ' || wanted.logical_rule_key,
  now()
FROM wanted
JOIN cards c ON lower(c.name) = lower(wanted.card_name)
ON CONFLICT (card_id, tag, source)
DO UPDATE SET
  card_name = EXCLUDED.card_name,
  confidence = EXCLUDED.confidence,
  evidence = EXCLUDED.evidence,
  updated_at = now();

DO $$
DECLARE
  v_curated int;
  v_stale_generated int;
  v_tags int;
BEGIN
  WITH wanted(card_name, logical_rule_key, expected_effect) AS (
    VALUES
      ('Norn''s Annex', 'battle_rule_v1:0b3adc33c3be375c3d4005b0082ff5c2', 'attack_tax'),
      ('Windborn Muse', 'battle_rule_v1:6932f0223ca41f0eedf724d55a9a858b', 'attack_tax'),
      ('Silent Arbiter', 'battle_rule_v1:6f6089b73fb8f7f9aee20cacb64fffc7', 'attack_limit'),
      ('Ensnaring Bridge', 'battle_rule_v1:1ea5840419f4343c05a661e79d6829d5', 'attack_limit'),
      ('Magus of the Moat', 'battle_rule_v1:439de5be33887bbce5dde1cfb367774a', 'attack_limit')
  )
  SELECT count(*) INTO v_curated
  FROM wanted
  JOIN card_battle_rules cbr
    ON lower(cbr.card_name) = lower(wanted.card_name)
   AND cbr.logical_rule_key = wanted.logical_rule_key
   AND cbr.effect_json->>'effect' = wanted.expected_effect
   AND cbr.review_status = 'verified'
   AND cbr.execution_status = 'auto'
   AND cbr.source = 'curated';

  WITH wanted(card_name, keep_key) AS (
    VALUES
      ('Norn''s Annex', 'battle_rule_v1:0b3adc33c3be375c3d4005b0082ff5c2'),
      ('Windborn Muse', 'battle_rule_v1:6932f0223ca41f0eedf724d55a9a858b'),
      ('Silent Arbiter', 'battle_rule_v1:6f6089b73fb8f7f9aee20cacb64fffc7'),
      ('Ensnaring Bridge', 'battle_rule_v1:1ea5840419f4343c05a661e79d6829d5'),
      ('Magus of the Moat', 'battle_rule_v1:439de5be33887bbce5dde1cfb367774a')
  )
  SELECT count(*) INTO v_stale_generated
  FROM wanted
  JOIN card_battle_rules cbr ON lower(cbr.card_name) = lower(wanted.card_name)
  WHERE cbr.logical_rule_key <> wanted.keep_key
    AND cbr.source = 'generated'
    AND cbr.execution_status IN ('auto', 'executable', 'review_only');

  SELECT count(*) INTO v_tags
  FROM card_function_tags
  WHERE lower(card_name) IN (
    'norn''s annex',
    'windborn muse',
    'silent arbiter',
    'ensnaring bridge',
    'magus of the moat'
  )
    AND tag = 'protection'
    AND source = 'card_battle_rules_v1';

  IF v_curated <> 5 THEN
    RAISE EXCEPTION 'PG016 apply failed: curated executable rows=% expected 5', v_curated;
  END IF;
  IF v_stale_generated <> 0 THEN
    RAISE EXCEPTION 'PG016 apply failed: stale generated enabled rows=% expected 0', v_stale_generated;
  END IF;
  IF v_tags <> 5 THEN
    RAISE EXCEPTION 'PG016 apply failed: protection function tags=% expected 5', v_tags;
  END IF;
END $$;

COMMIT;
