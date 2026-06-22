\pset pager off

WITH target AS (
  SELECT
    '528c877f-f829-4207-95e6-73981776c323'::uuid AS deck_id,
    'f46c0421-71b4-4de3-bb79-05a916b4988b'::uuid AS learned_deck_id
),
out_cards(name) AS (
  VALUES
    ('Storm Herd'),
    ('Worldfire'),
    ('Rite of the Dragoncaller'),
    ('Fiery Emancipation'),
    ('Mana Geyser'),
    ('Rise of the Eldrazi')
),
in_cards(name) AS (
  VALUES
    ('Ghostly Prison'),
    ('Crawlspace'),
    ('Chaos Warp'),
    ('Austere Command'),
    ('Get Lost'),
    ('Professional Face-Breaker')
),
watch_cards(name) AS (
  SELECT name FROM out_cards
  UNION ALL
  SELECT name FROM in_cards
)
SELECT
  'pg011_card_catalog_and_deck_state' AS check_name,
  wc.name,
  c.id::text AS card_id,
  COALESCE(SUM(dc.quantity), 0)::int AS qty_in_target_deck,
  COALESCE(BOOL_OR(dc.is_commander), false) AS is_commander
FROM watch_cards wc
LEFT JOIN cards c ON lower(c.name) = lower(wc.name)
LEFT JOIN deck_cards dc
  ON dc.card_id = c.id
 AND dc.deck_id = (SELECT deck_id FROM target)
GROUP BY wc.name, c.id
ORDER BY wc.name;

WITH target AS (
  SELECT
    '528c877f-f829-4207-95e6-73981776c323'::uuid AS deck_id,
    'f46c0421-71b4-4de3-bb79-05a916b4988b'::uuid AS learned_deck_id
),
out_cards(name) AS (
  VALUES
    ('Storm Herd'),
    ('Worldfire'),
    ('Rite of the Dragoncaller'),
    ('Fiery Emancipation'),
    ('Mana Geyser'),
    ('Rise of the Eldrazi')
),
in_cards(name) AS (
  VALUES
    ('Ghostly Prison'),
    ('Crawlspace'),
    ('Chaos Warp'),
    ('Austere Command'),
    ('Get Lost'),
    ('Professional Face-Breaker')
)
SELECT
  'pg011_precheck_counts' AS check_name,
  (SELECT count(*) FROM cards c JOIN out_cards oc ON lower(c.name) = lower(oc.name)) AS out_catalog_rows,
  (SELECT count(*) FROM cards c JOIN in_cards ic ON lower(c.name) = lower(ic.name)) AS in_catalog_rows,
  (
    SELECT COALESCE(SUM(dc.quantity), 0)::int
    FROM deck_cards dc
    JOIN cards c ON c.id = dc.card_id
    JOIN out_cards oc ON lower(c.name) = lower(oc.name)
    WHERE dc.deck_id = (SELECT deck_id FROM target)
  ) AS out_qty_in_target_deck,
  (
    SELECT COALESCE(SUM(dc.quantity), 0)::int
    FROM deck_cards dc
    JOIN cards c ON c.id = dc.card_id
    JOIN in_cards ic ON lower(c.name) = lower(ic.name)
    WHERE dc.deck_id = (SELECT deck_id FROM target)
  ) AS in_qty_in_target_deck,
  (
    SELECT COALESCE(SUM(quantity), 0)::int
    FROM deck_cards
    WHERE deck_id = (SELECT deck_id FROM target)
  ) AS target_deck_qty,
  (
    SELECT count(*)
    FROM deck_cards
    WHERE deck_id = (SELECT deck_id FROM target)
  ) AS target_deck_rows,
  (
    SELECT count(*)
    FROM commander_learned_decks
    WHERE id = (SELECT learned_deck_id FROM target)
      AND is_active = true
      AND card_count = 100
  ) AS active_learned_deck_rows;

WITH target AS (
  SELECT 'f46c0421-71b4-4de3-bb79-05a916b4988b'::uuid AS learned_deck_id
)
SELECT
  'pg011_learned_deck_text_state' AS check_name,
  id::text,
  source_ref,
  card_count,
  is_active,
  card_list ILIKE '%Storm Herd%' AS has_storm_herd,
  card_list ILIKE '%Worldfire%' AS has_worldfire,
  card_list ILIKE '%Rite of the Dragoncaller%' AS has_rite,
  card_list ILIKE '%Fiery Emancipation%' AS has_fiery_emancipation,
  card_list ILIKE '%Mana Geyser%' AS has_mana_geyser,
  card_list ILIKE '%Rise of the Eldrazi%' AS has_rise,
  card_list ILIKE '%Ghostly Prison%' AS has_ghostly_prison,
  card_list ILIKE '%Crawlspace%' AS has_crawlspace
FROM commander_learned_decks
WHERE id = (SELECT learned_deck_id FROM target);

SELECT
  'pg011_current_rule_state' AS check_name,
  card_name,
  logical_rule_key,
  effect_json,
  deck_role_json,
  source,
  confidence,
  review_status,
  execution_status
FROM card_battle_rules
WHERE lower(card_name) IN ('ghostly prison', 'crawlspace', 'get lost')
ORDER BY card_name, review_status, execution_status, logical_rule_key;

SELECT
  'pg011_current_function_tags' AS check_name,
  c.name,
  cft.tag,
  cft.source,
  cft.confidence,
  cft.evidence
FROM cards c
LEFT JOIN card_function_tags cft ON cft.card_id = c.id
WHERE lower(c.name) IN ('ghostly prison', 'crawlspace')
ORDER BY c.name, cft.tag, cft.source;
