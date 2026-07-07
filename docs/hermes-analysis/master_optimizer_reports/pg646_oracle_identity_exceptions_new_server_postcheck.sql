WITH target_cards AS (
  SELECT
    c.id,
    c.name,
    c.oracle_id,
    c.oracle_text,
    c.type_line,
    c.mana_cost,
    c.layout,
    c.card_faces_json,
    max(cl.status) FILTER (WHERE lower(cl.format) = 'commander') AS commander_status
  FROM public.cards c
  LEFT JOIN public.card_legalities cl ON cl.card_id = c.id
  WHERE c.id IN (
    '31807991-2e13-4418-9262-a1a15a4e708e'::uuid,
    '0c98f655-1590-41cf-8222-27991fa4fe48'::uuid,
    '84bba8e8-da9b-4ed7-9e3e-cb7520d75f50'::uuid,
    '68908e1f-4a77-4c33-96f8-954ee9523207'::uuid
  )
  GROUP BY c.id
),
checks AS (
  SELECT
    count(*) FILTER (
      WHERE name IN ('A-Alrund''s Epiphany', 'A-Omnath, Locus of Creation', 'A-Unholy Heat')
        AND oracle_id IS NULL
        AND btrim(coalesce(oracle_text, '')) <> ''
        AND btrim(coalesce(type_line, '')) <> ''
        AND commander_status = 'not_legal'
    ) AS digital_exception_decided_count,
    count(*) FILTER (
      WHERE name = 'Birds of Paradise // Birds of Paradise'
        AND oracle_id = 'd3a0b660-358c-41bd-9cd2-41fbf3491b1a'::uuid
        AND oracle_text = E'Flying\n{T}: Add one mana of any color.'
        AND type_line = 'Creature — Bird'
        AND mana_cost = '{G}'
        AND layout = 'reversible_card'
        AND card_faces_json IS NOT NULL
        AND commander_status = 'legal'
    ) AS reversible_birds_backfilled_count,
    count(*) AS total_target_count
  FROM target_cards
)
SELECT
  checks.*,
  (digital_exception_decided_count = 3) AS digital_exception_decided_ok,
  (reversible_birds_backfilled_count = 1) AS reversible_birds_backfilled_ok,
  (total_target_count = 4) AS target_count_ok
FROM checks;
