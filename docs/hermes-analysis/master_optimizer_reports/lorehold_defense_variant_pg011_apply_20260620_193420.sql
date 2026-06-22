\pset pager off
\set ON_ERROR_STOP on

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DROP TABLE IF EXISTS manaloom_deploy_audit.pg011_lorehold_defense_variant_20260620_193420;
CREATE TABLE manaloom_deploy_audit.pg011_lorehold_defense_variant_20260620_193420 (
  section text NOT NULL,
  key text NOT NULL,
  payload jsonb NOT NULL,
  captured_at timestamptz NOT NULL DEFAULT now()
);

WITH target AS (
  SELECT
    '528c877f-f829-4207-95e6-73981776c323'::uuid AS deck_id,
    'f46c0421-71b4-4de3-bb79-05a916b4988b'::uuid AS learned_deck_id
),
watch_cards(name) AS (
  VALUES
    ('Storm Herd'),
    ('Worldfire'),
    ('Rite of the Dragoncaller'),
    ('Fiery Emancipation'),
    ('Mana Geyser'),
    ('Rise of the Eldrazi'),
    ('Ghostly Prison'),
    ('Crawlspace'),
    ('Chaos Warp'),
    ('Austere Command'),
    ('Get Lost'),
    ('Professional Face-Breaker')
)
INSERT INTO manaloom_deploy_audit.pg011_lorehold_defense_variant_20260620_193420
  (section, key, payload)
SELECT
  'deck_cards',
  dc.id::text,
  to_jsonb(dc.*)
FROM deck_cards dc
JOIN cards c ON c.id = dc.card_id
JOIN watch_cards wc ON lower(wc.name) = lower(c.name)
WHERE dc.deck_id = (SELECT deck_id FROM target);

INSERT INTO manaloom_deploy_audit.pg011_lorehold_defense_variant_20260620_193420
  (section, key, payload)
SELECT
  'commander_learned_decks',
  cld.id::text,
  to_jsonb(cld.*)
FROM commander_learned_decks cld
WHERE cld.id = 'f46c0421-71b4-4de3-bb79-05a916b4988b'::uuid;

INSERT INTO manaloom_deploy_audit.pg011_lorehold_defense_variant_20260620_193420
  (section, key, payload)
SELECT
  'card_battle_rules',
  normalized_name || '|' || logical_rule_key,
  to_jsonb(cbr.*)
FROM card_battle_rules cbr
WHERE lower(card_name) IN ('ghostly prison', 'crawlspace', 'get lost');

INSERT INTO manaloom_deploy_audit.pg011_lorehold_defense_variant_20260620_193420
  (section, key, payload)
SELECT
  'card_function_tags',
  cft.card_id::text || '|' || cft.tag || '|' || cft.source,
  to_jsonb(cft.*)
FROM card_function_tags cft
JOIN cards c ON c.id = cft.card_id
WHERE lower(c.name) IN ('ghostly prison', 'crawlspace');

DO $$
DECLARE
  v_out_catalog int;
  v_in_catalog int;
  v_out_qty int;
  v_in_qty int;
  v_deck_qty int;
  v_learned_rows int;
BEGIN
  WITH out_cards(name) AS (
    VALUES
      ('Storm Herd'),
      ('Worldfire'),
      ('Rite of the Dragoncaller'),
      ('Fiery Emancipation'),
      ('Mana Geyser'),
      ('Rise of the Eldrazi')
  )
  SELECT count(*) INTO v_out_catalog
  FROM cards c
  JOIN out_cards oc ON lower(c.name) = lower(oc.name);

  WITH in_cards(name) AS (
    VALUES
      ('Ghostly Prison'),
      ('Crawlspace'),
      ('Chaos Warp'),
      ('Austere Command'),
      ('Get Lost'),
      ('Professional Face-Breaker')
  )
  SELECT count(*) INTO v_in_catalog
  FROM cards c
  JOIN in_cards ic ON lower(c.name) = lower(ic.name);

  WITH out_cards(name) AS (
    VALUES
      ('Storm Herd'),
      ('Worldfire'),
      ('Rite of the Dragoncaller'),
      ('Fiery Emancipation'),
      ('Mana Geyser'),
      ('Rise of the Eldrazi')
  )
  SELECT COALESCE(SUM(dc.quantity), 0)::int INTO v_out_qty
  FROM deck_cards dc
  JOIN cards c ON c.id = dc.card_id
  JOIN out_cards oc ON lower(c.name) = lower(oc.name)
  WHERE dc.deck_id = '528c877f-f829-4207-95e6-73981776c323'::uuid;

  WITH in_cards(name) AS (
    VALUES
      ('Ghostly Prison'),
      ('Crawlspace'),
      ('Chaos Warp'),
      ('Austere Command'),
      ('Get Lost'),
      ('Professional Face-Breaker')
  )
  SELECT COALESCE(SUM(dc.quantity), 0)::int INTO v_in_qty
  FROM deck_cards dc
  JOIN cards c ON c.id = dc.card_id
  JOIN in_cards ic ON lower(c.name) = lower(ic.name)
  WHERE dc.deck_id = '528c877f-f829-4207-95e6-73981776c323'::uuid;

  SELECT COALESCE(SUM(quantity), 0)::int INTO v_deck_qty
  FROM deck_cards
  WHERE deck_id = '528c877f-f829-4207-95e6-73981776c323'::uuid;

  SELECT count(*) INTO v_learned_rows
  FROM commander_learned_decks
  WHERE id = 'f46c0421-71b4-4de3-bb79-05a916b4988b'::uuid
    AND is_active = true
    AND card_count = 100
    AND card_list ILIKE '%Storm Herd%'
    AND card_list ILIKE '%Worldfire%'
    AND card_list ILIKE '%Rite of the Dragoncaller%'
    AND card_list ILIKE '%Fiery Emancipation%'
    AND card_list ILIKE '%Mana Geyser%'
    AND card_list ILIKE '%Rise of the Eldrazi%'
    AND card_list NOT ILIKE '%Ghostly Prison%'
    AND card_list NOT ILIKE '%Crawlspace%';

  IF v_out_catalog <> 6 THEN
    RAISE EXCEPTION 'PG011 precondition failed: out_catalog=% expected 6', v_out_catalog;
  END IF;
  IF v_in_catalog <> 6 THEN
    RAISE EXCEPTION 'PG011 precondition failed: in_catalog=% expected 6', v_in_catalog;
  END IF;
  IF v_out_qty <> 6 THEN
    RAISE EXCEPTION 'PG011 precondition failed: out_qty=% expected 6', v_out_qty;
  END IF;
  IF v_in_qty <> 0 THEN
    RAISE EXCEPTION 'PG011 precondition failed: in_qty=% expected 0', v_in_qty;
  END IF;
  IF v_deck_qty <> 100 THEN
    RAISE EXCEPTION 'PG011 precondition failed: deck_qty=% expected 100', v_deck_qty;
  END IF;
  IF v_learned_rows <> 1 THEN
    RAISE EXCEPTION 'PG011 precondition failed: active learned deck rows=% expected 1', v_learned_rows;
  END IF;
END $$;

WITH out_cards(name) AS (
  VALUES
    ('Storm Herd'),
    ('Worldfire'),
    ('Rite of the Dragoncaller'),
    ('Fiery Emancipation'),
    ('Mana Geyser'),
    ('Rise of the Eldrazi')
)
DELETE FROM deck_cards dc
USING cards c, out_cards oc
WHERE dc.card_id = c.id
  AND lower(c.name) = lower(oc.name)
  AND dc.deck_id = '528c877f-f829-4207-95e6-73981776c323'::uuid;

WITH in_cards(name) AS (
  VALUES
    ('Ghostly Prison'),
    ('Crawlspace'),
    ('Chaos Warp'),
    ('Austere Command'),
    ('Get Lost'),
    ('Professional Face-Breaker')
)
INSERT INTO deck_cards (deck_id, card_id, quantity, is_commander, condition)
SELECT
  '528c877f-f829-4207-95e6-73981776c323'::uuid,
  c.id,
  1,
  false,
  'NM'
FROM cards c
JOIN in_cards ic ON lower(c.name) = lower(ic.name)
ON CONFLICT (deck_id, card_id)
DO UPDATE SET
  quantity = EXCLUDED.quantity,
  is_commander = false,
  condition = COALESCE(deck_cards.condition, EXCLUDED.condition);

UPDATE commander_learned_decks
SET
  card_list = replace(
    replace(
      replace(
        replace(
          replace(
            replace(
              card_list,
              '1 Storm Herd',
              '1 Crawlspace'
            ),
            '1 Worldfire',
            '1 Ghostly Prison'
          ),
          '1 Rite of the Dragoncaller',
          '1 Get Lost'
        ),
        '1 Fiery Emancipation',
        '1 Chaos Warp'
      ),
      '1 Mana Geyser',
      '1 Austere Command'
    ),
    '1 Rise of the Eldrazi',
    '1 Professional Face-Breaker'
  ),
  metadata = COALESCE(metadata, '{}'::jsonb)
    || jsonb_build_object(
      'lorehold_defense_variant_b_20260620',
      jsonb_build_object(
        'applied_at', now(),
        'source', 'battle_variant_b_16_seed_screen',
        'baseline', 'post-combat-fix official 16 seeds: 1 win, 1 stall, 14 losses',
        'variant_result', 'direct temp-db 16 seeds: 3 wins, 0 stalls, 13 losses',
        'out', jsonb_build_array(
          'Storm Herd',
          'Worldfire',
          'Rite of the Dragoncaller',
          'Fiery Emancipation',
          'Mana Geyser',
          'Rise of the Eldrazi'
        ),
        'in', jsonb_build_array(
          'Ghostly Prison',
          'Crawlspace',
          'Chaos Warp',
          'Austere Command',
          'Get Lost',
          'Professional Face-Breaker'
        )
      )
    ),
  updated_at = now()
WHERE id = 'f46c0421-71b4-4de3-bb79-05a916b4988b'::uuid;

UPDATE card_battle_rules
SET
  card_id = c.id,
  effect_json = '{"effect":"attack_limit","max_attackers_against_you":2}'::jsonb,
  deck_role_json = '{"category":"stax","effect":"attack_limit"}'::jsonb,
  source = 'curated',
  confidence = 1.000,
  review_status = 'verified',
  execution_status = 'auto',
  notes = 'PG011 Lorehold defense variant: oracle-reviewed Crawlspace attack limit model.',
  reviewed_by = 'auditor_central',
  reviewed_at = now(),
  updated_at = now(),
  last_seen_at = now()
FROM cards c
WHERE card_battle_rules.normalized_name = 'crawlspace'
  AND card_battle_rules.logical_rule_key = 'battle_rule_v1:cefbed3716a64a7d8c9b2497a4986591'
  AND lower(c.name) = 'crawlspace';

UPDATE card_battle_rules
SET
  card_id = c.id,
  effect_json = '{"effect":"attack_tax","attack_tax_per_creature":2}'::jsonb,
  deck_role_json = '{"category":"stax","effect":"attack_tax"}'::jsonb,
  source = 'curated',
  confidence = 1.000,
  review_status = 'verified',
  execution_status = 'auto',
  notes = 'PG011 Lorehold defense variant: oracle-reviewed Ghostly Prison attack tax model.',
  reviewed_by = 'auditor_central',
  reviewed_at = now(),
  updated_at = now(),
  last_seen_at = now()
FROM cards c
WHERE card_battle_rules.normalized_name = 'ghostly prison'
  AND card_battle_rules.logical_rule_key = 'battle_rule_v1:99151859bece89ba3ead032e05b1f65a'
  AND lower(c.name) = 'ghostly prison';

UPDATE card_battle_rules
SET
  card_id = c.id,
  effect_json = '{"cmc":2.0,"effect":"remove_creature","instant":true}'::jsonb,
  deck_role_json = '{"category":"removal","effect":"remove_creature","timing":"instant"}'::jsonb,
  source = 'curated',
  confidence = 0.900,
  review_status = 'verified',
  execution_status = 'auto',
  notes = 'PG011 Lorehold defense variant: conservative Get Lost creature-removal mode.',
  reviewed_by = 'auditor_central',
  reviewed_at = now(),
  updated_at = now(),
  last_seen_at = now()
FROM cards c
WHERE card_battle_rules.normalized_name = 'get lost'
  AND card_battle_rules.logical_rule_key = 'battle_rule_v1:8e7da3df51386d58c857a596433f73ea'
  AND lower(c.name) = 'get lost';

UPDATE card_battle_rules
SET
  review_status = 'deprecated',
  execution_status = 'disabled',
  notes = COALESCE(notes || ' ', '') || 'PG011 disabled stale generated duplicate after curated runtime rule promotion.',
  updated_at = now()
WHERE normalized_name IN ('crawlspace', 'ghostly prison', 'get lost')
  AND source = 'generated'
  AND logical_rule_key NOT IN (
    'battle_rule_v1:cefbed3716a64a7d8c9b2497a4986591',
    'battle_rule_v1:99151859bece89ba3ead032e05b1f65a',
    'battle_rule_v1:8e7da3df51386d58c857a596433f73ea'
  );

WITH stax_cards(name) AS (
  VALUES
    ('Ghostly Prison'),
    ('Crawlspace')
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
  'stax',
  0.900,
  'curated_pg011_lorehold_defense',
  'PG011 Lorehold defense variant: attack tax/limit pillow-fort role validated in direct 16-seed replay screen.',
  now()
FROM cards c
JOIN stax_cards sc ON lower(c.name) = lower(sc.name)
ON CONFLICT (card_id, tag, source)
DO UPDATE SET
  confidence = EXCLUDED.confidence,
  evidence = EXCLUDED.evidence,
  updated_at = now();

DO $$
DECLARE
  v_out_qty int;
  v_in_qty int;
  v_deck_qty int;
  v_rules int;
  v_tags int;
  v_learned_ok int;
BEGIN
  WITH out_cards(name) AS (
    VALUES
      ('Storm Herd'),
      ('Worldfire'),
      ('Rite of the Dragoncaller'),
      ('Fiery Emancipation'),
      ('Mana Geyser'),
      ('Rise of the Eldrazi')
  )
  SELECT COALESCE(SUM(dc.quantity), 0)::int INTO v_out_qty
  FROM deck_cards dc
  JOIN cards c ON c.id = dc.card_id
  JOIN out_cards oc ON lower(c.name) = lower(oc.name)
  WHERE dc.deck_id = '528c877f-f829-4207-95e6-73981776c323'::uuid;

  WITH in_cards(name) AS (
    VALUES
      ('Ghostly Prison'),
      ('Crawlspace'),
      ('Chaos Warp'),
      ('Austere Command'),
      ('Get Lost'),
      ('Professional Face-Breaker')
  )
  SELECT COALESCE(SUM(dc.quantity), 0)::int INTO v_in_qty
  FROM deck_cards dc
  JOIN cards c ON c.id = dc.card_id
  JOIN in_cards ic ON lower(c.name) = lower(ic.name)
  WHERE dc.deck_id = '528c877f-f829-4207-95e6-73981776c323'::uuid;

  SELECT COALESCE(SUM(quantity), 0)::int INTO v_deck_qty
  FROM deck_cards
  WHERE deck_id = '528c877f-f829-4207-95e6-73981776c323'::uuid;

  SELECT count(*) INTO v_rules
  FROM card_battle_rules
  WHERE (normalized_name, logical_rule_key) IN (
    ('crawlspace', 'battle_rule_v1:cefbed3716a64a7d8c9b2497a4986591'),
    ('ghostly prison', 'battle_rule_v1:99151859bece89ba3ead032e05b1f65a'),
    ('get lost', 'battle_rule_v1:8e7da3df51386d58c857a596433f73ea')
  )
    AND review_status = 'verified'
    AND execution_status = 'auto'
    AND source = 'curated';

  SELECT count(*) INTO v_tags
  FROM card_function_tags cft
  JOIN cards c ON c.id = cft.card_id
  WHERE lower(c.name) IN ('ghostly prison', 'crawlspace')
    AND cft.tag = 'stax'
    AND cft.source = 'curated_pg011_lorehold_defense';

  SELECT count(*) INTO v_learned_ok
  FROM commander_learned_decks
  WHERE id = 'f46c0421-71b4-4de3-bb79-05a916b4988b'::uuid
    AND card_count = 100
    AND card_list NOT ILIKE '%Storm Herd%'
    AND card_list NOT ILIKE '%Worldfire%'
    AND card_list NOT ILIKE '%Rite of the Dragoncaller%'
    AND card_list NOT ILIKE '%Fiery Emancipation%'
    AND card_list NOT ILIKE '%Mana Geyser%'
    AND card_list NOT ILIKE '%Rise of the Eldrazi%'
    AND card_list ILIKE '%Ghostly Prison%'
    AND card_list ILIKE '%Crawlspace%'
    AND card_list ILIKE '%Chaos Warp%'
    AND card_list ILIKE '%Austere Command%'
    AND card_list ILIKE '%Get Lost%'
    AND card_list ILIKE '%Professional Face-Breaker%';

  IF v_out_qty <> 0 THEN
    RAISE EXCEPTION 'PG011 postcondition failed: out_qty=% expected 0', v_out_qty;
  END IF;
  IF v_in_qty <> 6 THEN
    RAISE EXCEPTION 'PG011 postcondition failed: in_qty=% expected 6', v_in_qty;
  END IF;
  IF v_deck_qty <> 100 THEN
    RAISE EXCEPTION 'PG011 postcondition failed: deck_qty=% expected 100', v_deck_qty;
  END IF;
  IF v_rules <> 3 THEN
    RAISE EXCEPTION 'PG011 postcondition failed: curated_rules=% expected 3', v_rules;
  END IF;
  IF v_tags <> 2 THEN
    RAISE EXCEPTION 'PG011 postcondition failed: stax_tags=% expected 2', v_tags;
  END IF;
  IF v_learned_ok <> 1 THEN
    RAISE EXCEPTION 'PG011 postcondition failed: learned_ok=% expected 1', v_learned_ok;
  END IF;
END $$;

SELECT
  'pg011_apply_result' AS result,
  (
    SELECT COALESCE(SUM(quantity), 0)::int
    FROM deck_cards
    WHERE deck_id = '528c877f-f829-4207-95e6-73981776c323'::uuid
  ) AS target_deck_qty,
  (
    SELECT count(*)
    FROM card_battle_rules
    WHERE (normalized_name, logical_rule_key) IN (
      ('crawlspace', 'battle_rule_v1:cefbed3716a64a7d8c9b2497a4986591'),
      ('ghostly prison', 'battle_rule_v1:99151859bece89ba3ead032e05b1f65a'),
      ('get lost', 'battle_rule_v1:8e7da3df51386d58c857a596433f73ea')
    )
      AND review_status = 'verified'
      AND execution_status = 'auto'
      AND source = 'curated'
  ) AS curated_runtime_rules,
  (
    SELECT count(*)
    FROM card_function_tags cft
    JOIN cards c ON c.id = cft.card_id
    WHERE lower(c.name) IN ('ghostly prison', 'crawlspace')
      AND cft.tag = 'stax'
      AND cft.source = 'curated_pg011_lorehold_defense'
  ) AS curated_stax_tags;

COMMIT;
