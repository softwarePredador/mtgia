BEGIN;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'manaloom_deploy_audit'
      AND table_name = 'pg646_oracle_identity_exception_cards_20260707'
  ) THEN
    RAISE EXCEPTION 'PG646 rollback abort: cards backup table is missing';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'manaloom_deploy_audit'
      AND table_name = 'pg646_oracle_identity_exception_legalities_20260707'
  ) THEN
    RAISE EXCEPTION 'PG646 rollback abort: legalities backup table is missing';
  END IF;
END $$;

UPDATE public.cards c
SET
  scryfall_id = b.scryfall_id,
  name = b.name,
  mana_cost = b.mana_cost,
  type_line = b.type_line,
  oracle_text = b.oracle_text,
  colors = b.colors,
  image_url = b.image_url,
  set_code = b.set_code,
  rarity = b.rarity,
  price = b.price,
  ai_description = b.ai_description,
  color_identity = b.color_identity,
  price_updated_at = b.price_updated_at,
  price_usd = b.price_usd,
  price_usd_foil = b.price_usd_foil,
  cmc = b.cmc,
  collector_number = b.collector_number,
  foil = b.foil,
  edhrec_rank = b.edhrec_rank,
  is_reserved = b.is_reserved,
  power = b.power,
  toughness = b.toughness,
  keywords = b.keywords,
  oracle_id = b.oracle_id,
  layout = b.layout,
  card_faces_json = b.card_faces_json
FROM manaloom_deploy_audit.pg646_oracle_identity_exception_cards_20260707 b
WHERE c.id = b.id;

DELETE FROM public.card_legalities
WHERE card_id IN (
  SELECT card_id
  FROM manaloom_deploy_audit.pg646_oracle_identity_exception_legalities_20260707
  UNION
  SELECT '31807991-2e13-4418-9262-a1a15a4e708e'::uuid
  UNION
  SELECT '0c98f655-1590-41cf-8222-27991fa4fe48'::uuid
  UNION
  SELECT '84bba8e8-da9b-4ed7-9e3e-cb7520d75f50'::uuid
  UNION
  SELECT '68908e1f-4a77-4c33-96f8-954ee9523207'::uuid
);

INSERT INTO public.card_legalities (id, card_id, format, status)
SELECT id, card_id, format, status
FROM manaloom_deploy_audit.pg646_oracle_identity_exception_legalities_20260707
ON CONFLICT (card_id, format) DO UPDATE
SET status = EXCLUDED.status;

COMMIT;
