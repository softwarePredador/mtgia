\pset pager off
BEGIN;
-- Apply single-card catalog backfill from Scryfall for Kaalia Variant 01.
INSERT INTO cards (
  id, scryfall_id, name, mana_cost, type_line, oracle_text,
  colors, image_url, set_code, rarity, color_identity, cmc,
  collector_number, foil, power, toughness, keywords, oracle_id, layout
) VALUES (
  '2beb2cbd-d9d7-5b59-9c70-b72cc76c2b47'::uuid,
  '3db94749-340c-4454-a15d-ba6353e0c4a4'::uuid,
  'Alicia Masters, Skilled Sculptor',
  '{1}{R}',
  'Legendary Creature — Human Artificer',
  'At the beginning of combat on your turn, if you''ve cast a noncreature spell this turn, create a Treasure token.
Sense the Good — At the beginning of your end step, each player gains control of all creatures they own.',
  ARRAY['R']::text[],
  'https://cards.scryfall.io/normal/front/3/d/3db94749-340c-4454-a15d-ba6353e0c4a4.jpg?1781013802',
  'msc',
  'rare',
  ARRAY['R']::text[],
  2.0,
  '48',
  true,
  '0',
  '4',
  ARRAY['Treasure']::text[],
  '223504ba-174a-46f2-a4a2-5d663a82dfd3'::uuid,
  'normal'
)
ON CONFLICT (scryfall_id) DO UPDATE SET
  name = EXCLUDED.name,
  mana_cost = EXCLUDED.mana_cost,
  type_line = EXCLUDED.type_line,
  oracle_text = EXCLUDED.oracle_text,
  colors = EXCLUDED.colors,
  image_url = EXCLUDED.image_url,
  set_code = EXCLUDED.set_code,
  rarity = EXCLUDED.rarity,
  color_identity = EXCLUDED.color_identity,
  cmc = EXCLUDED.cmc,
  collector_number = EXCLUDED.collector_number,
  foil = EXCLUDED.foil,
  power = EXCLUDED.power,
  toughness = EXCLUDED.toughness,
  keywords = EXCLUDED.keywords,
  oracle_id = EXCLUDED.oracle_id,
  layout = EXCLUDED.layout;

WITH target_card AS (
  SELECT id FROM cards WHERE scryfall_id = '3db94749-340c-4454-a15d-ba6353e0c4a4'::uuid
), legalities(format, status) AS (
  VALUES
  ('alchemy'::text, 'not_legal'::text),
  ('brawl'::text, 'not_legal'::text),
  ('commander'::text, 'legal'::text),
  ('competitivebrawl'::text, 'not_legal'::text),
  ('duel'::text, 'legal'::text),
  ('future'::text, 'not_legal'::text),
  ('gladiator'::text, 'not_legal'::text),
  ('historic'::text, 'not_legal'::text),
  ('legacy'::text, 'legal'::text),
  ('modern'::text, 'not_legal'::text),
  ('oathbreaker'::text, 'legal'::text),
  ('oldschool'::text, 'not_legal'::text),
  ('pauper'::text, 'not_legal'::text),
  ('paupercommander'::text, 'not_legal'::text),
  ('penny'::text, 'not_legal'::text),
  ('pioneer'::text, 'not_legal'::text),
  ('predh'::text, 'not_legal'::text),
  ('premodern'::text, 'not_legal'::text),
  ('standard'::text, 'not_legal'::text),
  ('standardbrawl'::text, 'not_legal'::text),
  ('timeless'::text, 'not_legal'::text),
  ('tlr'::text, 'not_legal'::text),
  ('vintage'::text, 'legal'::text)
)
INSERT INTO card_legalities (card_id, format, status)
SELECT target_card.id, legalities.format, legalities.status
FROM target_card CROSS JOIN legalities
ON CONFLICT (card_id, format) DO UPDATE SET status = EXCLUDED.status;
COMMIT;
