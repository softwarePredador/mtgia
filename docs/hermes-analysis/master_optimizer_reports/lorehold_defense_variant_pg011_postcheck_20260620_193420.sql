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
)
SELECT
  'pg011_postcheck_counts' AS check_name,
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
      AND card_list ILIKE '%Professional Face-Breaker%'
  ) AS active_learned_deck_ok;

SELECT
  'pg011_deck_membership' AS check_name,
  c.name,
  COALESCE(SUM(dc.quantity), 0)::int AS qty_in_target_deck
FROM cards c
LEFT JOIN deck_cards dc
  ON dc.card_id = c.id
 AND dc.deck_id = '528c877f-f829-4207-95e6-73981776c323'::uuid
WHERE lower(c.name) IN (
  'storm herd',
  'worldfire',
  'rite of the dragoncaller',
  'fiery emancipation',
  'mana geyser',
  'rise of the eldrazi',
  'ghostly prison',
  'crawlspace',
  'chaos warp',
  'austere command',
  'get lost',
  'professional face-breaker'
)
GROUP BY c.name
ORDER BY c.name;

SELECT
  'pg011_rule_postcheck' AS check_name,
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
  'pg011_function_tag_postcheck' AS check_name,
  c.name,
  cft.tag,
  cft.source,
  cft.confidence,
  cft.evidence
FROM cards c
JOIN card_function_tags cft ON cft.card_id = c.id
WHERE lower(c.name) IN ('ghostly prison', 'crawlspace')
ORDER BY c.name, cft.tag, cft.source;

SELECT
  'pg011_snapshot_postcheck' AS check_name,
  name,
  function_tags,
  battle_rules
FROM card_intelligence_snapshot
WHERE lower(name) IN ('ghostly prison', 'crawlspace', 'get lost')
ORDER BY name;
