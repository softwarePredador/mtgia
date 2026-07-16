-- MUTATING. Do not run without explicit PostgreSQL approval for this execution.
BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

LOCK TABLE public.card_function_tags IN SHARE ROW EXCLUSIVE MODE;

DO $$
BEGIN
  IF to_regclass(
    'manaloom_deploy_audit.pg869_product_deck_function_tags_20260715'
  ) IS NOT NULL THEN
    RAISE EXCEPTION 'PG869 abort: audit snapshot already exists';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pg869_product_deck_function_tags_20260715 AS
SELECT *
FROM public.card_function_tags
WHERE source = 'curated_product_deck_families_20260715';

DO $$
DECLARE
  v_missing jsonb;
  v_name_count bigint;
  v_card_row_count bigint;
  v_expected_tag_rows bigint;
  v_existing_source_rows bigint;
BEGIN
  WITH proposed(card_name, normalized_name, oracle_hash, tags) AS (
    VALUES
      ('Aggravated Assault', 'aggravated assault', 'ae9d059bba80bb701fff89f8cbe6ee32', ARRAY['engine','wincon']::text[]),
      ('Ancestral Statue', 'ancestral statue', '9d46a0f16b980cb44b8923780c88048a', ARRAY['engine','etb']::text[]),
      ('Back to Basics', 'back to basics', '92f7414e388a8085279535fb2fa77c71', ARRAY['protection','stax']::text[]),
      ('Branching Evolution', 'branching evolution', '2d55e24e23228dc265b024e0f1b6ee02', ARRAY['engine']::text[]),
      ('Chaos Warp', 'chaos warp', '7db2bc44526b855fd22302e9569746b5', ARRAY['removal']::text[]),
      ('Displacement Wave', 'displacement wave', 'd461892cf0561124fb4c68cb3ae561d5', ARRAY['board_wipe']::text[]),
      ('Duskshell Crawler', 'duskshell crawler', '936a21bc68360a300aaac80871d37859', ARRAY['engine','etb']::text[]),
      ('Engulf the Shore', 'engulf the shore', '599f9ef17314533e386da3296d352f50', ARRAY['board_wipe']::text[]),
      ('Hardened Scales', 'hardened scales', 'ecd2b97440c6f463a294af09543114a7', ARRAY['engine']::text[]),
      ('High Tide', 'high tide', '025575b6cd950e2beb8b07dd7fb253da', ARRAY['ramp']::text[]),
      ('Isshin, Two Heavens as One', 'isshin, two heavens as one', 'c0d5a1c8621b7a4ba928ba935e305fd0', ARRAY['engine']::text[]),
      ('Kaalia of the Vast', 'kaalia of the vast', '64e21ef8f558e7102b9f832b0c772092', ARRAY['engine']::text[]),
      ('Karlach, Fury of Avernus', 'karlach, fury of avernus', 'c51368dcc4b3f5c9a14127588441c0f8', ARRAY['engine','wincon']::text[]),
      ('Manifold Key', 'manifold key', 'a1858a5bb6c951bd75d7d584611bb09c', ARRAY['engine']::text[]),
      ('Master of Cruelties', 'master of cruelties', '4b2c1fdf88036c53803a6735a8f25189', ARRAY['wincon']::text[]),
      ('Peregrine Drake', 'peregrine drake', '767753e683e0fa72ca6ef7b8166df8c6', ARRAY['etb','ramp']::text[]),
      ('Phyrexian Metamorph', 'phyrexian metamorph', 'f33412ad2deef26bceca34c6b467f890', ARRAY['engine']::text[]),
      ('Quicksilver Amulet', 'quicksilver amulet', '5a6fa5d251e34f51abc60120806df86b', ARRAY['engine']::text[]),
      ('Relentless Assault', 'relentless assault', '329f65c951650f3fde602740592363d1', ARRAY['engine','wincon']::text[]),
      ('Rings of Brighthearth', 'rings of brighthearth', '09429f5efbb874bb12167818a72c1168', ARRAY['engine']::text[]),
      ('Sapphire Medallion', 'sapphire medallion', 'ce0b6343ccf5f7701f575fb94834a23c', ARRAY['enabler','ramp']::text[]),
      ('Shrieking Drake', 'shrieking drake', '1beaf68511c151a2c6a54af1881dfaa7', ARRAY['engine','etb']::text[]),
      ('Strionic Resonator', 'strionic resonator', '42d36b9e45d9ee15dbbc4982bfe28f6d', ARRAY['engine']::text[]),
      ('Surrak Dragonclaw', 'surrak dragonclaw', 'b67c6778fc42fdbc3fc7ff3a5556cfa4', ARRAY['protection']::text[]),
      ('The Earth Crystal', 'the earth crystal', 'cf2c8141d05901a469cb63fd8d261f6f', ARRAY['enabler','engine','ramp']::text[]),
      ('The Ozolith', 'the ozolith', 'c48573fbe7752f56539f1b63e5fe4700', ARRAY['engine']::text[])
  ), matched AS (
    SELECT p.*, c.id AS card_id
    FROM proposed p
    LEFT JOIN public.cards c
      ON lower(c.name) = p.normalized_name
     AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
  ), counts AS (
    SELECT
      card_name,
      count(card_id) AS matched_rows,
      count(card_id) * cardinality(tags) AS expected_tag_rows
    FROM matched
    GROUP BY card_name, tags
  )
  SELECT
    jsonb_agg(counts ORDER BY card_name)
      FILTER (WHERE matched_rows < 1),
    count(*),
    sum(matched_rows),
    sum(expected_tag_rows),
    (
      SELECT count(*)
      FROM matched m
      JOIN public.card_function_tags cft ON cft.card_id = m.card_id
      WHERE cft.source = 'curated_product_deck_families_20260715'
    )
  INTO
    v_missing,
    v_name_count,
    v_card_row_count,
    v_expected_tag_rows,
    v_existing_source_rows
  FROM counts;

  IF v_missing IS NOT NULL THEN
    RAISE EXCEPTION 'PG869 abort: card/hash mismatch: %', v_missing;
  END IF;

  IF v_name_count <> 26
     OR v_card_row_count <> 35
     OR v_expected_tag_rows <> 46
     OR v_existing_source_rows <> 0 THEN
    RAISE EXCEPTION
      'PG869 abort: cardinality drift names=% cards=% tags=% existing=%',
      v_name_count,
      v_card_row_count,
      v_expected_tag_rows,
      v_existing_source_rows;
  END IF;
END $$;

DELETE FROM public.card_function_tags
WHERE source = 'curated_product_deck_families_20260715';

WITH proposed(card_name, normalized_name, oracle_hash, tags) AS (
  VALUES
    ('Aggravated Assault', 'aggravated assault', 'ae9d059bba80bb701fff89f8cbe6ee32', ARRAY['engine','wincon']::text[]),
    ('Ancestral Statue', 'ancestral statue', '9d46a0f16b980cb44b8923780c88048a', ARRAY['engine','etb']::text[]),
    ('Back to Basics', 'back to basics', '92f7414e388a8085279535fb2fa77c71', ARRAY['protection','stax']::text[]),
    ('Branching Evolution', 'branching evolution', '2d55e24e23228dc265b024e0f1b6ee02', ARRAY['engine']::text[]),
    ('Chaos Warp', 'chaos warp', '7db2bc44526b855fd22302e9569746b5', ARRAY['removal']::text[]),
    ('Displacement Wave', 'displacement wave', 'd461892cf0561124fb4c68cb3ae561d5', ARRAY['board_wipe']::text[]),
    ('Duskshell Crawler', 'duskshell crawler', '936a21bc68360a300aaac80871d37859', ARRAY['engine','etb']::text[]),
    ('Engulf the Shore', 'engulf the shore', '599f9ef17314533e386da3296d352f50', ARRAY['board_wipe']::text[]),
    ('Hardened Scales', 'hardened scales', 'ecd2b97440c6f463a294af09543114a7', ARRAY['engine']::text[]),
    ('High Tide', 'high tide', '025575b6cd950e2beb8b07dd7fb253da', ARRAY['ramp']::text[]),
    ('Isshin, Two Heavens as One', 'isshin, two heavens as one', 'c0d5a1c8621b7a4ba928ba935e305fd0', ARRAY['engine']::text[]),
    ('Kaalia of the Vast', 'kaalia of the vast', '64e21ef8f558e7102b9f832b0c772092', ARRAY['engine']::text[]),
    ('Karlach, Fury of Avernus', 'karlach, fury of avernus', 'c51368dcc4b3f5c9a14127588441c0f8', ARRAY['engine','wincon']::text[]),
    ('Manifold Key', 'manifold key', 'a1858a5bb6c951bd75d7d584611bb09c', ARRAY['engine']::text[]),
    ('Master of Cruelties', 'master of cruelties', '4b2c1fdf88036c53803a6735a8f25189', ARRAY['wincon']::text[]),
    ('Peregrine Drake', 'peregrine drake', '767753e683e0fa72ca6ef7b8166df8c6', ARRAY['etb','ramp']::text[]),
    ('Phyrexian Metamorph', 'phyrexian metamorph', 'f33412ad2deef26bceca34c6b467f890', ARRAY['engine']::text[]),
    ('Quicksilver Amulet', 'quicksilver amulet', '5a6fa5d251e34f51abc60120806df86b', ARRAY['engine']::text[]),
    ('Relentless Assault', 'relentless assault', '329f65c951650f3fde602740592363d1', ARRAY['engine','wincon']::text[]),
    ('Rings of Brighthearth', 'rings of brighthearth', '09429f5efbb874bb12167818a72c1168', ARRAY['engine']::text[]),
    ('Sapphire Medallion', 'sapphire medallion', 'ce0b6343ccf5f7701f575fb94834a23c', ARRAY['enabler','ramp']::text[]),
    ('Shrieking Drake', 'shrieking drake', '1beaf68511c151a2c6a54af1881dfaa7', ARRAY['engine','etb']::text[]),
    ('Strionic Resonator', 'strionic resonator', '42d36b9e45d9ee15dbbc4982bfe28f6d', ARRAY['engine']::text[]),
    ('Surrak Dragonclaw', 'surrak dragonclaw', 'b67c6778fc42fdbc3fc7ff3a5556cfa4', ARRAY['protection']::text[]),
    ('The Earth Crystal', 'the earth crystal', 'cf2c8141d05901a469cb63fd8d261f6f', ARRAY['enabler','engine','ramp']::text[]),
    ('The Ozolith', 'the ozolith', 'c48573fbe7752f56539f1b63e5fe4700', ARRAY['engine']::text[])
), expanded AS (
  SELECT
    c.id AS card_id,
    c.name AS card_name,
    tag
  FROM proposed p
  JOIN public.cards c
    ON lower(c.name) = p.normalized_name
   AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
  CROSS JOIN LATERAL unnest(p.tags) AS tag
)
INSERT INTO public.card_function_tags (
  card_id, card_name, tag, confidence, source, evidence, updated_at
)
SELECT
  card_id,
  card_name,
  tag,
  0.95,
  'curated_product_deck_families_20260715',
  'Oracle family reviewed against current product-deck role coverage; runtime classifier and focused regression matrix validated 2026-07-15.',
  now()
FROM expanded
ON CONFLICT (card_id, tag, source) DO UPDATE SET
  card_name = EXCLUDED.card_name,
  confidence = EXCLUDED.confidence,
  evidence = EXCLUDED.evidence,
  updated_at = EXCLUDED.updated_at;

COMMIT;
