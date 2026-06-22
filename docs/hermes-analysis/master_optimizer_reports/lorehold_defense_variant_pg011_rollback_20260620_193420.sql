\pset pager off
\set ON_ERROR_STOP on

BEGIN;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg011_lorehold_defense_variant_20260620_193420') IS NULL THEN
    RAISE EXCEPTION 'PG011 rollback backup table is missing';
  END IF;
END $$;

WITH in_cards(name) AS (
  VALUES
    ('Ghostly Prison'),
    ('Crawlspace'),
    ('Chaos Warp'),
    ('Austere Command'),
    ('Get Lost'),
    ('Professional Face-Breaker')
)
DELETE FROM deck_cards dc
USING cards c, in_cards ic
WHERE dc.card_id = c.id
  AND lower(c.name) = lower(ic.name)
  AND dc.deck_id = '528c877f-f829-4207-95e6-73981776c323'::uuid;

INSERT INTO deck_cards (
  id,
  deck_id,
  card_id,
  quantity,
  is_commander,
  condition
)
SELECT
  (payload->>'id')::uuid,
  (payload->>'deck_id')::uuid,
  (payload->>'card_id')::uuid,
  (payload->>'quantity')::int,
  (payload->>'is_commander')::boolean,
  COALESCE(payload->>'condition', 'NM')
FROM manaloom_deploy_audit.pg011_lorehold_defense_variant_20260620_193420
WHERE section = 'deck_cards'
  AND (payload->>'deck_id')::uuid = '528c877f-f829-4207-95e6-73981776c323'::uuid
ON CONFLICT (deck_id, card_id)
DO UPDATE SET
  quantity = EXCLUDED.quantity,
  is_commander = EXCLUDED.is_commander,
  condition = EXCLUDED.condition;

UPDATE commander_learned_decks cld
SET
  commander_name = backup.payload->>'commander_name',
  commander_name_normalized = backup.payload->>'commander_name_normalized',
  deck_name = backup.payload->>'deck_name',
  source_system = backup.payload->>'source_system',
  source_ref = backup.payload->>'source_ref',
  source_url = backup.payload->>'source_url',
  archetype = backup.payload->>'archetype',
  card_list = backup.payload->>'card_list',
  card_count = (backup.payload->>'card_count')::int,
  score = NULLIF(backup.payload->>'score', '')::numeric,
  wincon_primary = backup.payload->>'wincon_primary',
  wincon_backup = backup.payload->>'wincon_backup',
  legal_status = backup.payload->>'legal_status',
  notes = backup.payload->>'notes',
  metadata = COALESCE(backup.payload->'metadata', '{}'::jsonb),
  is_active = (backup.payload->>'is_active')::boolean,
  promoted_at = NULLIF(backup.payload->>'promoted_at', '')::timestamptz,
  updated_at = now()
FROM manaloom_deploy_audit.pg011_lorehold_defense_variant_20260620_193420 backup
WHERE backup.section = 'commander_learned_decks'
  AND backup.key = cld.id::text
  AND cld.id = 'f46c0421-71b4-4de3-bb79-05a916b4988b'::uuid;

DELETE FROM card_battle_rules
WHERE lower(card_name) IN ('ghostly prison', 'crawlspace', 'get lost');

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
  payload->>'normalized_name',
  payload->>'logical_rule_key',
  NULLIF(payload->>'card_id', '')::uuid,
  payload->>'card_name',
  COALESCE(payload->'effect_json', '{}'::jsonb),
  COALESCE(payload->'deck_role_json', '{}'::jsonb),
  payload->>'source',
  (payload->>'confidence')::numeric,
  payload->>'review_status',
  COALESCE(payload->>'execution_status', 'auto'),
  COALESCE((payload->>'rule_version')::int, 1),
  payload->>'oracle_hash',
  payload->>'notes',
  payload->>'reviewed_by',
  NULLIF(payload->>'reviewed_at', '')::timestamptz,
  COALESCE(NULLIF(payload->>'created_at', '')::timestamptz, now()),
  now(),
  NULLIF(payload->>'last_seen_at', '')::timestamptz
FROM manaloom_deploy_audit.pg011_lorehold_defense_variant_20260620_193420
WHERE section = 'card_battle_rules'
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
  last_seen_at = EXCLUDED.last_seen_at;

DELETE FROM card_function_tags cft
USING cards c
WHERE cft.card_id = c.id
  AND lower(c.name) IN ('ghostly prison', 'crawlspace');

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
  (payload->>'card_id')::uuid,
  payload->>'card_name',
  payload->>'tag',
  (payload->>'confidence')::numeric,
  payload->>'source',
  payload->>'evidence',
  COALESCE(NULLIF(payload->>'updated_at', '')::timestamptz, now())
FROM manaloom_deploy_audit.pg011_lorehold_defense_variant_20260620_193420
WHERE section = 'card_function_tags'
ON CONFLICT (card_id, tag, source)
DO UPDATE SET
  card_name = EXCLUDED.card_name,
  confidence = EXCLUDED.confidence,
  evidence = EXCLUDED.evidence,
  updated_at = now();

SELECT
  'pg011_rollback_result' AS result,
  (
    SELECT COALESCE(SUM(quantity), 0)::int
    FROM deck_cards
    WHERE deck_id = '528c877f-f829-4207-95e6-73981776c323'::uuid
  ) AS target_deck_qty;

COMMIT;
