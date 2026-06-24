BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg179_discard_trigger_engines_20260624_140220 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('feast of sanity', 'geth''s grimoire', 'megrim')
   OR normalized_name LIKE 'feast of sanity // %'
   OR normalized_name LIKE 'geth''s grimoire // %'
   OR normalized_name LIKE 'megrim // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('feast of sanity', 'Feast of Sanity', '9d3f44ba9a777ab7510132842a854475', 'battle_rule_v1:8783617a8d44c4f2e0242d17976f8828', '{"ability_kind":"triggered","battle_model_scope":"controller_discards_card_damage_any_target_and_gain_life_v1","cmc":4.0,"controller_discard_damage_any_target":1,"controller_discard_gain_life":1,"effect":"passive","trigger":"controller_discard"}'::jsonb, '{"category":"support","effect":"passive","timing":"static"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class FeastOfSanity mapped to family passive; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('geth''s grimoire', 'Geth''s Grimoire', '6f91d335d1e146eb8f4f7e034130fa67', 'battle_rule_v1:293ee48b9a46181e885a4e563ef5868c', '{"ability_kind":"triggered","battle_model_scope":"opponent_discards_card_may_draw_v1","cmc":4.0,"draw_on_enter":false,"effect":"draw_engine","opponent_discard_draw_per_card":1,"trigger":"opponent_discard"}'::jsonb, '{"category":"draw","effect":"draw_engine","timing":"static_or_activated"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class GethsGrimoire mapped to family draw_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('megrim', 'Megrim', '2bb00f8626aef78bae0a72196673b7ec', 'battle_rule_v1:3c0ccb6b440a3128acdd19b58ace0b1e', '{"ability_kind":"triggered","battle_model_scope":"opponent_discards_card_damage_that_player_v1","cmc":3.0,"effect":"passive","opponent_discard_damage_per_card":2,"trigger":"opponent_discard"}'::jsonb, '{"category":"support","effect":"passive","timing":"static"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Megrim mapped to family passive; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
    ('feast of sanity', 'Feast of Sanity', '9d3f44ba9a777ab7510132842a854475', 'battle_rule_v1:8783617a8d44c4f2e0242d17976f8828', '{"ability_kind":"triggered","battle_model_scope":"controller_discards_card_damage_any_target_and_gain_life_v1","cmc":4.0,"controller_discard_damage_any_target":1,"controller_discard_gain_life":1,"effect":"passive","trigger":"controller_discard"}'::jsonb, '{"category":"support","effect":"passive","timing":"static"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class FeastOfSanity mapped to family passive; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('geth''s grimoire', 'Geth''s Grimoire', '6f91d335d1e146eb8f4f7e034130fa67', 'battle_rule_v1:293ee48b9a46181e885a4e563ef5868c', '{"ability_kind":"triggered","battle_model_scope":"opponent_discards_card_may_draw_v1","cmc":4.0,"draw_on_enter":false,"effect":"draw_engine","opponent_discard_draw_per_card":1,"trigger":"opponent_discard"}'::jsonb, '{"category":"draw","effect":"draw_engine","timing":"static_or_activated"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class GethsGrimoire mapped to family draw_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('megrim', 'Megrim', '2bb00f8626aef78bae0a72196673b7ec', 'battle_rule_v1:3c0ccb6b440a3128acdd19b58ace0b1e', '{"ability_kind":"triggered","battle_model_scope":"opponent_discards_card_damage_that_player_v1","cmc":3.0,"effect":"passive","opponent_discard_damage_per_card":2,"trigger":"opponent_discard"}'::jsonb, '{"category":"support","effect":"passive","timing":"static"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Megrim mapped to family passive; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
    ('feast of sanity', 'Feast of Sanity', '9d3f44ba9a777ab7510132842a854475', 'battle_rule_v1:8783617a8d44c4f2e0242d17976f8828', '{"ability_kind":"triggered","battle_model_scope":"controller_discards_card_damage_any_target_and_gain_life_v1","cmc":4.0,"controller_discard_damage_any_target":1,"controller_discard_gain_life":1,"effect":"passive","trigger":"controller_discard"}'::jsonb, '{"category":"support","effect":"passive","timing":"static"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class FeastOfSanity mapped to family passive; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('geth''s grimoire', 'Geth''s Grimoire', '6f91d335d1e146eb8f4f7e034130fa67', 'battle_rule_v1:293ee48b9a46181e885a4e563ef5868c', '{"ability_kind":"triggered","battle_model_scope":"opponent_discards_card_may_draw_v1","cmc":4.0,"draw_on_enter":false,"effect":"draw_engine","opponent_discard_draw_per_card":1,"trigger":"opponent_discard"}'::jsonb, '{"category":"draw","effect":"draw_engine","timing":"static_or_activated"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class GethsGrimoire mapped to family draw_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('megrim', 'Megrim', '2bb00f8626aef78bae0a72196673b7ec', 'battle_rule_v1:3c0ccb6b440a3128acdd19b58ace0b1e', '{"ability_kind":"triggered","battle_model_scope":"opponent_discards_card_damage_that_player_v1","cmc":3.0,"effect":"passive","opponent_discard_damage_per_card":2,"trigger":"opponent_discard"}'::jsonb, '{"category":"support","effect":"passive","timing":"static"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Megrim mapped to family passive; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
