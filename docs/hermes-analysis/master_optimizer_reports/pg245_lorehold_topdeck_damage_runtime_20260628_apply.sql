BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg245_lorehold_topdeck_damage_runtime_20260628_015359 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('twinflame tyrant', 'verge rangers')
   OR normalized_name LIKE 'twinflame tyrant // %'
   OR normalized_name LIKE 'verge rangers // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('twinflame tyrant', 'Twinflame Tyrant', 'e4ca0585f743b1c34c36649bfbb1fff6', 'battle_rule_v1:072370a98c9b332eef021390bfc1694a', '{"ability_kind":"static","battle_model_scope":"controlled_source_damage_to_opponent_or_opponent_permanent_doubled_v1","cmc":5.0,"damage_modifier_applies_to":"sources_you_control","damage_modifier_duration":"while_on_battlefield","damage_modifier_targets":["opponents","opponent_permanents"],"damage_multiplier":2,"effect":"damage_modifier","flying":true,"power":3,"toughness":5}'::jsonb, '{"category":"wincon","effect":"damage_modifier","subtype":"damage_doubler","timing":"static"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class TwinflameTyrant mapped to family static_damage_modifier; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('verge rangers', 'Verge Rangers', '44aa2eeb2eeb517fb30478aec7cec42f', 'battle_rule_v1:85ae1e46c9ad082e1807ac9e9f5420bd', '{"ability_kind":"static","battle_model_scope":"look_top_library_play_lands_from_top_if_opponent_more_lands_v1","cmc":3.0,"effect":"topdeck_play","keywords":["first_strike"],"look_top_library_any_time":true,"play_from_top_condition":"opponent_controls_more_lands","play_lands_from_top_library":true,"power":3,"toughness":3}'::jsonb, '{"category":"ramp","effect":"topdeck_play","subtype":"play_lands_from_library","timing":"static"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class VergeRangers mapped to family topdeck_play; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows')
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

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('twinflame tyrant', 'Twinflame Tyrant', 'e4ca0585f743b1c34c36649bfbb1fff6', 'battle_rule_v1:072370a98c9b332eef021390bfc1694a', '{"ability_kind":"static","battle_model_scope":"controlled_source_damage_to_opponent_or_opponent_permanent_doubled_v1","cmc":5.0,"damage_modifier_applies_to":"sources_you_control","damage_modifier_duration":"while_on_battlefield","damage_modifier_targets":["opponents","opponent_permanents"],"damage_multiplier":2,"effect":"damage_modifier","flying":true,"power":3,"toughness":5}'::jsonb, '{"category":"wincon","effect":"damage_modifier","subtype":"damage_doubler","timing":"static"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class TwinflameTyrant mapped to family static_damage_modifier; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('verge rangers', 'Verge Rangers', '44aa2eeb2eeb517fb30478aec7cec42f', 'battle_rule_v1:85ae1e46c9ad082e1807ac9e9f5420bd', '{"ability_kind":"static","battle_model_scope":"look_top_library_play_lands_from_top_if_opponent_more_lands_v1","cmc":3.0,"effect":"topdeck_play","keywords":["first_strike"],"look_top_library_any_time":true,"play_from_top_condition":"opponent_controls_more_lands","play_lands_from_top_library":true,"power":3,"toughness":3}'::jsonb, '{"category":"ramp","effect":"topdeck_play","subtype":"play_lands_from_library","timing":"static"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class VergeRangers mapped to family topdeck_play; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows')
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
    AND p.shadow_handling <> 'preserve_existing_rows'
    AND r.logical_rule_key <> p.logical_rule_key
  RETURNING r.*
)
SELECT count(*) AS deprecated_shadow_rows FROM deprecated;

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('twinflame tyrant', 'Twinflame Tyrant', 'e4ca0585f743b1c34c36649bfbb1fff6', 'battle_rule_v1:072370a98c9b332eef021390bfc1694a', '{"ability_kind":"static","battle_model_scope":"controlled_source_damage_to_opponent_or_opponent_permanent_doubled_v1","cmc":5.0,"damage_modifier_applies_to":"sources_you_control","damage_modifier_duration":"while_on_battlefield","damage_modifier_targets":["opponents","opponent_permanents"],"damage_multiplier":2,"effect":"damage_modifier","flying":true,"power":3,"toughness":5}'::jsonb, '{"category":"wincon","effect":"damage_modifier","subtype":"damage_doubler","timing":"static"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class TwinflameTyrant mapped to family static_damage_modifier; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('verge rangers', 'Verge Rangers', '44aa2eeb2eeb517fb30478aec7cec42f', 'battle_rule_v1:85ae1e46c9ad082e1807ac9e9f5420bd', '{"ability_kind":"static","battle_model_scope":"look_top_library_play_lands_from_top_if_opponent_more_lands_v1","cmc":3.0,"effect":"topdeck_play","keywords":["first_strike"],"look_top_library_any_time":true,"play_from_top_condition":"opponent_controls_more_lands","play_lands_from_top_library":true,"power":3,"toughness":3}'::jsonb, '{"category":"ramp","effect":"topdeck_play","subtype":"play_lands_from_library","timing":"static"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class VergeRangers mapped to family topdeck_play; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows')
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
    p.notes,
    p.shadow_handling
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
