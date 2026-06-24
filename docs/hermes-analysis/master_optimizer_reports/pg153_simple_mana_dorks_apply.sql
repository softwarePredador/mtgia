BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg153_simple_mana_dorks_20260624_081116 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('birds of paradise', 'llanowar elves', 'elvish mystic', 'avacyn''s pilgrim', 'fyndhorn elves')
   OR normalized_name LIKE 'birds of paradise // %'
   OR normalized_name LIKE 'llanowar elves // %'
   OR normalized_name LIKE 'elvish mystic // %'
   OR normalized_name LIKE 'avacyn''s pilgrim // %'
   OR normalized_name LIKE 'fyndhorn elves // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('birds of paradise', 'Birds of Paradise', '2119fc1976cfab2480a9d86c57f1859b', 'battle_rule_v1:5d3ec3f1d92cfe2044d0172c4e3765ba', '{"ability_kind":"activated","battle_model_scope":"one_mana_zero_one_flying_any_color_mana_dork_v1","effect":"creature","flying":true,"is_mana_source":true,"mana_produced":1,"power":0,"produces":"WUBRG","toughness":1}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class BirdsOfParadise mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('llanowar elves', 'Llanowar Elves', 'fa07d150550fe544837233efd56086ac', 'battle_rule_v1:b4d210018767f5b0a4740adc889beb85', '{"ability_kind":"activated","battle_model_scope":"one_mana_one_one_green_mana_dork_v1","effect":"creature","is_mana_source":true,"mana_produced":1,"power":1,"produces":"G","toughness":1}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class LlanowarElves mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('elvish mystic', 'Elvish Mystic', 'fa07d150550fe544837233efd56086ac', 'battle_rule_v1:b4d210018767f5b0a4740adc889beb85', '{"ability_kind":"activated","battle_model_scope":"one_mana_one_one_green_mana_dork_v1","effect":"creature","is_mana_source":true,"mana_produced":1,"power":1,"produces":"G","toughness":1}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ElvishMystic mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('avacyn''s pilgrim', 'Avacyn''s Pilgrim', 'c7264c311c98ff99b293a96ad9ab2daf', 'battle_rule_v1:123fb4f1873cbd3debade4877e0b6788', '{"ability_kind":"activated","battle_model_scope":"one_mana_one_one_white_mana_dork_v1","effect":"creature","is_mana_source":true,"mana_produced":1,"power":1,"produces":"W","toughness":1}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class AvacynsPilgrim mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('fyndhorn elves', 'Fyndhorn Elves', 'fa07d150550fe544837233efd56086ac', 'battle_rule_v1:b4d210018767f5b0a4740adc889beb85', '{"ability_kind":"activated","battle_model_scope":"one_mana_one_one_green_mana_dork_v1","effect":"creature","is_mana_source":true,"mana_produced":1,"power":1,"produces":"G","toughness":1}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class FyndhornElves mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
    ('birds of paradise', 'Birds of Paradise', '2119fc1976cfab2480a9d86c57f1859b', 'battle_rule_v1:5d3ec3f1d92cfe2044d0172c4e3765ba', '{"ability_kind":"activated","battle_model_scope":"one_mana_zero_one_flying_any_color_mana_dork_v1","effect":"creature","flying":true,"is_mana_source":true,"mana_produced":1,"power":0,"produces":"WUBRG","toughness":1}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class BirdsOfParadise mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('llanowar elves', 'Llanowar Elves', 'fa07d150550fe544837233efd56086ac', 'battle_rule_v1:b4d210018767f5b0a4740adc889beb85', '{"ability_kind":"activated","battle_model_scope":"one_mana_one_one_green_mana_dork_v1","effect":"creature","is_mana_source":true,"mana_produced":1,"power":1,"produces":"G","toughness":1}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class LlanowarElves mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('elvish mystic', 'Elvish Mystic', 'fa07d150550fe544837233efd56086ac', 'battle_rule_v1:b4d210018767f5b0a4740adc889beb85', '{"ability_kind":"activated","battle_model_scope":"one_mana_one_one_green_mana_dork_v1","effect":"creature","is_mana_source":true,"mana_produced":1,"power":1,"produces":"G","toughness":1}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ElvishMystic mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('avacyn''s pilgrim', 'Avacyn''s Pilgrim', 'c7264c311c98ff99b293a96ad9ab2daf', 'battle_rule_v1:123fb4f1873cbd3debade4877e0b6788', '{"ability_kind":"activated","battle_model_scope":"one_mana_one_one_white_mana_dork_v1","effect":"creature","is_mana_source":true,"mana_produced":1,"power":1,"produces":"W","toughness":1}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class AvacynsPilgrim mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('fyndhorn elves', 'Fyndhorn Elves', 'fa07d150550fe544837233efd56086ac', 'battle_rule_v1:b4d210018767f5b0a4740adc889beb85', '{"ability_kind":"activated","battle_model_scope":"one_mana_one_one_green_mana_dork_v1","effect":"creature","is_mana_source":true,"mana_produced":1,"power":1,"produces":"G","toughness":1}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class FyndhornElves mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
    ('birds of paradise', 'Birds of Paradise', '2119fc1976cfab2480a9d86c57f1859b', 'battle_rule_v1:5d3ec3f1d92cfe2044d0172c4e3765ba', '{"ability_kind":"activated","battle_model_scope":"one_mana_zero_one_flying_any_color_mana_dork_v1","effect":"creature","flying":true,"is_mana_source":true,"mana_produced":1,"power":0,"produces":"WUBRG","toughness":1}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class BirdsOfParadise mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('llanowar elves', 'Llanowar Elves', 'fa07d150550fe544837233efd56086ac', 'battle_rule_v1:b4d210018767f5b0a4740adc889beb85', '{"ability_kind":"activated","battle_model_scope":"one_mana_one_one_green_mana_dork_v1","effect":"creature","is_mana_source":true,"mana_produced":1,"power":1,"produces":"G","toughness":1}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class LlanowarElves mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('elvish mystic', 'Elvish Mystic', 'fa07d150550fe544837233efd56086ac', 'battle_rule_v1:b4d210018767f5b0a4740adc889beb85', '{"ability_kind":"activated","battle_model_scope":"one_mana_one_one_green_mana_dork_v1","effect":"creature","is_mana_source":true,"mana_produced":1,"power":1,"produces":"G","toughness":1}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ElvishMystic mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('avacyn''s pilgrim', 'Avacyn''s Pilgrim', 'c7264c311c98ff99b293a96ad9ab2daf', 'battle_rule_v1:123fb4f1873cbd3debade4877e0b6788', '{"ability_kind":"activated","battle_model_scope":"one_mana_one_one_white_mana_dork_v1","effect":"creature","is_mana_source":true,"mana_produced":1,"power":1,"produces":"W","toughness":1}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class AvacynsPilgrim mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('fyndhorn elves', 'Fyndhorn Elves', 'fa07d150550fe544837233efd56086ac', 'battle_rule_v1:b4d210018767f5b0a4740adc889beb85', '{"ability_kind":"activated","battle_model_scope":"one_mana_one_one_green_mana_dork_v1","effect":"creature","is_mana_source":true,"mana_produced":1,"power":1,"produces":"G","toughness":1}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class FyndhornElves mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
