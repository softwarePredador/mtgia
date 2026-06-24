BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg166_copy_permanent_etb_20260624_111014 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('copy enchantment', 'mirrormade', 'phyrexian metamorph', 'clever impersonator', 'copy artifact')
   OR normalized_name LIKE 'copy enchantment // %'
   OR normalized_name LIKE 'mirrormade // %'
   OR normalized_name LIKE 'phyrexian metamorph // %'
   OR normalized_name LIKE 'clever impersonator // %'
   OR normalized_name LIKE 'copy artifact // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('copy enchantment', 'Copy Enchantment', 'e1e0ee06fa971e9233368741b7478a7d', 'battle_rule_v1:ca58149e510c6834c2ed6ae602074483', '{"ability_kind":"replacement","battle_model_scope":"etb_copy_target_permanent_with_optional_extra_type_v1","copy_target_types":["enchantment"],"effect":"copy_permanent_etb","target_controller":"any"}'::jsonb, '{"category":"board_development","effect":"copy_permanent_etb","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class CopyEnchantment mapped to family copy_permanent_etb; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('mirrormade', 'Mirrormade', '49a1b071e36257efbc6ddb75d03ac14a', 'battle_rule_v1:d267ffd54ecf9c5026b8aaf43076edc9', '{"ability_kind":"replacement","battle_model_scope":"etb_copy_target_permanent_with_optional_extra_type_v1","copy_target_types":["artifact","enchantment"],"effect":"copy_permanent_etb","target_controller":"any"}'::jsonb, '{"category":"board_development","effect":"copy_permanent_etb","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Mirrormade mapped to family copy_permanent_etb; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('phyrexian metamorph', 'Phyrexian Metamorph', 'f33412ad2deef26bceca34c6b467f890', 'battle_rule_v1:1c9b7206e4e878ac743fc9186cdf5beb', '{"ability_kind":"replacement","battle_model_scope":"etb_copy_target_permanent_with_optional_extra_type_v1","copy_additional_types":["artifact"],"copy_target_types":["artifact","creature"],"effect":"copy_permanent_etb","target_controller":"any"}'::jsonb, '{"category":"board_development","effect":"copy_permanent_etb","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class PhyrexianMetamorph mapped to family copy_permanent_etb; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('clever impersonator', 'Clever Impersonator', 'b5a888ad1107dbe2b4d9be83113e83bb', 'battle_rule_v1:743bc58026f68050c6ef7c902ce85cde', '{"ability_kind":"replacement","battle_model_scope":"etb_copy_target_permanent_with_optional_extra_type_v1","copy_target_types":["nonland_permanent"],"effect":"copy_permanent_etb","target_controller":"any"}'::jsonb, '{"category":"board_development","effect":"copy_permanent_etb","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class CleverImpersonator mapped to family copy_permanent_etb; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('copy artifact', 'Copy Artifact', '394ca9be04e11f918cac24d8cc648f1f', 'battle_rule_v1:d466142f168d3c2d58c0594eb14214c9', '{"ability_kind":"replacement","battle_model_scope":"etb_copy_target_permanent_with_optional_extra_type_v1","copy_additional_types":["enchantment"],"copy_target_types":["artifact"],"effect":"copy_permanent_etb","target_controller":"any"}'::jsonb, '{"category":"board_development","effect":"copy_permanent_etb","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class CopyArtifact mapped to family copy_permanent_etb; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
),
  counts AS (
    SELECT
      p.card_name,
      p.normalized_name,
      p.oracle_hash,
      count(c.id) AS target_card_rows,
      min(c.id::text)::uuid AS canonical_card_id
    FROM proposed p
    LEFT JOIN public.cards c
      ON (
           lower(c.name) = p.normalized_name
           OR split_part(lower(c.name), ' // ', 1) = p.normalized_name
         )
     AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
    GROUP BY p.card_name, p.normalized_name, p.oracle_hash
  )
  SELECT jsonb_agg(counts ORDER BY card_name)
    INTO v_missing
  FROM counts
  WHERE target_card_rows < 1;

  IF v_missing IS NOT NULL THEN
    RAISE EXCEPTION 'XMage batch package abort: expected at least one Oracle-hash-matched card row for every proposed card: %', v_missing;
  END IF;
END $$;

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('copy enchantment', 'Copy Enchantment', 'e1e0ee06fa971e9233368741b7478a7d', 'battle_rule_v1:ca58149e510c6834c2ed6ae602074483', '{"ability_kind":"replacement","battle_model_scope":"etb_copy_target_permanent_with_optional_extra_type_v1","copy_target_types":["enchantment"],"effect":"copy_permanent_etb","target_controller":"any"}'::jsonb, '{"category":"board_development","effect":"copy_permanent_etb","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class CopyEnchantment mapped to family copy_permanent_etb; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('mirrormade', 'Mirrormade', '49a1b071e36257efbc6ddb75d03ac14a', 'battle_rule_v1:d267ffd54ecf9c5026b8aaf43076edc9', '{"ability_kind":"replacement","battle_model_scope":"etb_copy_target_permanent_with_optional_extra_type_v1","copy_target_types":["artifact","enchantment"],"effect":"copy_permanent_etb","target_controller":"any"}'::jsonb, '{"category":"board_development","effect":"copy_permanent_etb","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Mirrormade mapped to family copy_permanent_etb; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('phyrexian metamorph', 'Phyrexian Metamorph', 'f33412ad2deef26bceca34c6b467f890', 'battle_rule_v1:1c9b7206e4e878ac743fc9186cdf5beb', '{"ability_kind":"replacement","battle_model_scope":"etb_copy_target_permanent_with_optional_extra_type_v1","copy_additional_types":["artifact"],"copy_target_types":["artifact","creature"],"effect":"copy_permanent_etb","target_controller":"any"}'::jsonb, '{"category":"board_development","effect":"copy_permanent_etb","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class PhyrexianMetamorph mapped to family copy_permanent_etb; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('clever impersonator', 'Clever Impersonator', 'b5a888ad1107dbe2b4d9be83113e83bb', 'battle_rule_v1:743bc58026f68050c6ef7c902ce85cde', '{"ability_kind":"replacement","battle_model_scope":"etb_copy_target_permanent_with_optional_extra_type_v1","copy_target_types":["nonland_permanent"],"effect":"copy_permanent_etb","target_controller":"any"}'::jsonb, '{"category":"board_development","effect":"copy_permanent_etb","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class CleverImpersonator mapped to family copy_permanent_etb; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('copy artifact', 'Copy Artifact', '394ca9be04e11f918cac24d8cc648f1f', 'battle_rule_v1:d466142f168d3c2d58c0594eb14214c9', '{"ability_kind":"replacement","battle_model_scope":"etb_copy_target_permanent_with_optional_extra_type_v1","copy_additional_types":["enchantment"],"copy_target_types":["artifact"],"effect":"copy_permanent_etb","target_controller":"any"}'::jsonb, '{"category":"board_development","effect":"copy_permanent_etb","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class CopyArtifact mapped to family copy_permanent_etb; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
),
deprecated AS (
  UPDATE public.card_battle_rules r
  SET
    review_status = 'deprecated',
    execution_status = 'disabled',
    updated_at = now(),
    notes = concat_ws(E'\n', nullif(r.notes, ''), 'XMage batch package: deprecated stale shadow before curated batch rule upsert.')
  FROM proposed p
  WHERE (
        r.normalized_name = p.normalized_name
        OR r.normalized_name LIKE p.normalized_name || ' // %'
      )
    AND r.logical_rule_key <> p.logical_rule_key
  RETURNING r.*
)
SELECT count(*) AS deprecated_shadow_rows FROM deprecated;

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('copy enchantment', 'Copy Enchantment', 'e1e0ee06fa971e9233368741b7478a7d', 'battle_rule_v1:ca58149e510c6834c2ed6ae602074483', '{"ability_kind":"replacement","battle_model_scope":"etb_copy_target_permanent_with_optional_extra_type_v1","copy_target_types":["enchantment"],"effect":"copy_permanent_etb","target_controller":"any"}'::jsonb, '{"category":"board_development","effect":"copy_permanent_etb","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class CopyEnchantment mapped to family copy_permanent_etb; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('mirrormade', 'Mirrormade', '49a1b071e36257efbc6ddb75d03ac14a', 'battle_rule_v1:d267ffd54ecf9c5026b8aaf43076edc9', '{"ability_kind":"replacement","battle_model_scope":"etb_copy_target_permanent_with_optional_extra_type_v1","copy_target_types":["artifact","enchantment"],"effect":"copy_permanent_etb","target_controller":"any"}'::jsonb, '{"category":"board_development","effect":"copy_permanent_etb","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Mirrormade mapped to family copy_permanent_etb; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('phyrexian metamorph', 'Phyrexian Metamorph', 'f33412ad2deef26bceca34c6b467f890', 'battle_rule_v1:1c9b7206e4e878ac743fc9186cdf5beb', '{"ability_kind":"replacement","battle_model_scope":"etb_copy_target_permanent_with_optional_extra_type_v1","copy_additional_types":["artifact"],"copy_target_types":["artifact","creature"],"effect":"copy_permanent_etb","target_controller":"any"}'::jsonb, '{"category":"board_development","effect":"copy_permanent_etb","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class PhyrexianMetamorph mapped to family copy_permanent_etb; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('clever impersonator', 'Clever Impersonator', 'b5a888ad1107dbe2b4d9be83113e83bb', 'battle_rule_v1:743bc58026f68050c6ef7c902ce85cde', '{"ability_kind":"replacement","battle_model_scope":"etb_copy_target_permanent_with_optional_extra_type_v1","copy_target_types":["nonland_permanent"],"effect":"copy_permanent_etb","target_controller":"any"}'::jsonb, '{"category":"board_development","effect":"copy_permanent_etb","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class CleverImpersonator mapped to family copy_permanent_etb; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('copy artifact', 'Copy Artifact', '394ca9be04e11f918cac24d8cc648f1f', 'battle_rule_v1:d466142f168d3c2d58c0594eb14214c9', '{"ability_kind":"replacement","battle_model_scope":"etb_copy_target_permanent_with_optional_extra_type_v1","copy_additional_types":["enchantment"],"copy_target_types":["artifact"],"effect":"copy_permanent_etb","target_controller":"any"}'::jsonb, '{"category":"board_development","effect":"copy_permanent_etb","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class CopyArtifact mapped to family copy_permanent_etb; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
),
matched_cards AS (
  SELECT
    p.normalized_name,
    p.card_name,
    p.oracle_hash,
    c.id AS card_id,
    c.name AS db_card_name
  FROM proposed p
  JOIN public.cards c
    ON (
         lower(c.name) = p.normalized_name
         OR split_part(lower(c.name), ' // ', 1) = p.normalized_name
       )
   AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
),
canonical_target_cards AS (
  SELECT
    p.*,
    min(m.card_id::text)::uuid AS card_id,
    min(m.db_card_name) AS db_card_name
  FROM proposed p
  JOIN matched_cards m
    USING (normalized_name, card_name, oracle_hash)
  GROUP BY
    p.normalized_name,
    p.card_name,
    p.oracle_hash,
    p.logical_rule_key,
    p.effect_json,
    p.deck_role_json,
    p.source,
    p.confidence,
    p.review_status,
    p.execution_status,
    p.notes
),
upserted AS (
  INSERT INTO public.card_battle_rules (
    normalized_name,
    card_id,
    card_name,
    effect_json,
    deck_role_json,
    source,
    confidence,
    review_status,
    rule_version,
    oracle_hash,
    notes,
    reviewed_by,
    reviewed_at,
    created_at,
    updated_at,
    last_seen_at,
    logical_rule_key,
    execution_status
  )
  SELECT
    normalized_name,
    card_id,
    db_card_name,
    effect_json,
    deck_role_json,
    source,
    confidence,
    review_status,
    2,
    oracle_hash,
    notes,
    'codex-xmage-batch',
    now(),
    now(),
    now(),
    now(),
    logical_rule_key,
    execution_status
  FROM canonical_target_cards
  ON CONFLICT (normalized_name, logical_rule_key) DO UPDATE
  SET
    card_id = EXCLUDED.card_id,
    card_name = EXCLUDED.card_name,
    effect_json = EXCLUDED.effect_json,
    deck_role_json = EXCLUDED.deck_role_json,
    source = EXCLUDED.source,
    confidence = EXCLUDED.confidence,
    review_status = EXCLUDED.review_status,
    rule_version = EXCLUDED.rule_version,
    oracle_hash = EXCLUDED.oracle_hash,
    notes = EXCLUDED.notes,
    reviewed_by = EXCLUDED.reviewed_by,
    reviewed_at = EXCLUDED.reviewed_at,
    updated_at = EXCLUDED.updated_at,
    last_seen_at = EXCLUDED.last_seen_at,
    execution_status = EXCLUDED.execution_status
  RETURNING *
)
SELECT count(*) AS upserted_rows FROM upserted;

COMMIT;
