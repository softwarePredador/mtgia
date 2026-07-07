BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg646_oracle_identity_exception_cards_20260707 AS
SELECT *
FROM public.cards
WHERE id IN (
  '31807991-2e13-4418-9262-a1a15a4e708e'::uuid,
  '0c98f655-1590-41cf-8222-27991fa4fe48'::uuid,
  '84bba8e8-da9b-4ed7-9e3e-cb7520d75f50'::uuid,
  '68908e1f-4a77-4c33-96f8-954ee9523207'::uuid
);

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg646_oracle_identity_exception_legalities_20260707 AS
SELECT *
FROM public.card_legalities
WHERE card_id IN (
  '31807991-2e13-4418-9262-a1a15a4e708e'::uuid,
  '0c98f655-1590-41cf-8222-27991fa4fe48'::uuid,
  '84bba8e8-da9b-4ed7-9e3e-cb7520d75f50'::uuid,
  '68908e1f-4a77-4c33-96f8-954ee9523207'::uuid
);

DO $$
DECLARE
  v_bad jsonb;
BEGIN
  WITH target_cards AS (
    SELECT
      c.id,
      c.name,
      c.set_code,
      c.scryfall_id,
      c.oracle_id,
      c.oracle_text,
      c.type_line,
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
  )
  SELECT jsonb_agg(target_cards ORDER BY name)
    INTO v_bad
  FROM target_cards
  WHERE (
      name IN ('A-Alrund''s Epiphany', 'A-Omnath, Locus of Creation', 'A-Unholy Heat')
      AND (
        oracle_id IS NOT NULL
        OR btrim(coalesce(oracle_text, '')) = ''
        OR btrim(coalesce(type_line, '')) = ''
        OR commander_status IS NOT NULL
      )
    )
    OR (
      name = 'Birds of Paradise // Birds of Paradise'
      AND (
        scryfall_id <> 'dae8751c-4c72-4034-a192-a1e166f20246'::uuid
        OR set_code <> 'sld'
        OR oracle_id IS NOT NULL
        OR btrim(coalesce(oracle_text, '')) <> ''
        OR btrim(coalesce(type_line, '')) <> ''
        OR commander_status <> 'legal'
      )
    );

  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'PG646 abort: oracle identity exception precheck failed: %', v_bad;
  END IF;
END $$;

UPDATE public.cards
SET
  oracle_id = 'd3a0b660-358c-41bd-9cd2-41fbf3491b1a'::uuid,
  oracle_text = E'Flying\n{T}: Add one mana of any color.',
  type_line = 'Creature — Bird',
  mana_cost = '{G}',
  layout = 'reversible_card',
  card_faces_json = '[
    {
      "oracle_id": "d3a0b660-358c-41bd-9cd2-41fbf3491b1a",
      "layout": "normal",
      "name": "Birds of Paradise",
      "flavor_name": "African Swallow",
      "mana_cost": "{G}",
      "cmc": 1.0,
      "type_line": "Creature — Bird",
      "oracle_text": "Flying\n{T}: Add one mana of any color.",
      "colors": ["G"],
      "power": "0",
      "toughness": "1"
    },
    {
      "oracle_id": "d3a0b660-358c-41bd-9cd2-41fbf3491b1a",
      "layout": "normal",
      "name": "Birds of Paradise",
      "flavor_name": "European Swallow",
      "mana_cost": "{G}",
      "cmc": 1.0,
      "type_line": "Creature — Bird",
      "oracle_text": "Flying\n{T}: Add one mana of any color.",
      "colors": ["G"],
      "power": "0",
      "toughness": "1"
    }
  ]'::jsonb,
  colors = ARRAY['G']::text[],
  color_identity = ARRAY['G']::text[],
  power = '0',
  toughness = '1',
  keywords = ARRAY['Flying']::text[]
WHERE id = '68908e1f-4a77-4c33-96f8-954ee9523207'::uuid;

INSERT INTO public.card_legalities (card_id, format, status)
VALUES
  ('31807991-2e13-4418-9262-a1a15a4e708e'::uuid, 'commander', 'not_legal'),
  ('0c98f655-1590-41cf-8222-27991fa4fe48'::uuid, 'commander', 'not_legal'),
  ('84bba8e8-da9b-4ed7-9e3e-cb7520d75f50'::uuid, 'commander', 'not_legal')
ON CONFLICT (card_id, format) DO UPDATE
SET status = EXCLUDED.status;

SELECT
  count(*) FILTER (
    WHERE id = '68908e1f-4a77-4c33-96f8-954ee9523207'::uuid
      AND oracle_id = 'd3a0b660-358c-41bd-9cd2-41fbf3491b1a'::uuid
      AND oracle_text = E'Flying\n{T}: Add one mana of any color.'
      AND type_line = 'Creature — Bird'
      AND mana_cost = '{G}'
      AND layout = 'reversible_card'
  ) AS reversible_birds_backfilled_count
FROM public.cards;

SELECT
  count(*) FILTER (WHERE lower(format) = 'commander' AND status = 'not_legal') AS digital_commander_not_legal_count
FROM public.card_legalities
WHERE card_id IN (
  '31807991-2e13-4418-9262-a1a15a4e708e'::uuid,
  '0c98f655-1590-41cf-8222-27991fa4fe48'::uuid,
  '84bba8e8-da9b-4ed7-9e3e-cb7520d75f50'::uuid
);

COMMIT;
