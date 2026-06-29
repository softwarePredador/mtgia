BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg251_adagia_hazel_purphoros_runtime_batch_20260629_151845 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('hazel''s brewmaster', 'adagia, windswept bastion', 'purphoros, god of the forge');

DO $$
DECLARE
  v_missing integer;
BEGIN
  WITH proposed(normalized_name, oracle_hash) AS (
    VALUES
    ('hazel''s brewmaster', 'a6e600363c1a67a7d0d507a0ae00021d'),
    ('adagia, windswept bastion', 'e6878f05503ba8e6454108ddcbfca84d'),
    ('purphoros, god of the forge', '01ee853118a4f1e5fe31a9d1e3ec6c5d')
  ), matched AS (
    SELECT p.normalized_name, count(c.id) AS matched_rows
    FROM proposed p
    LEFT JOIN public.cards c
      ON (lower(c.name) = p.normalized_name OR split_part(lower(c.name), ' // ', 1) = p.normalized_name)
     AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
    GROUP BY p.normalized_name
  )
  SELECT count(*) INTO v_missing
  FROM matched
  WHERE matched_rows < 1;

  IF v_missing <> 0 THEN
    RAISE EXCEPTION 'PG251 abort: expected at least one Oracle-hash-matched card row for every proposed card; missing=%', v_missing;
  END IF;
END $$;

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('hazel''s brewmaster', 'Hazel''s Brewmaster', 'a6e600363c1a67a7d0d507a0ae00021d', 'battle_rule_v1:68abb87ba90186e55c4e4341506b1c4f', '{"ability_kind":"triggered_static","battle_model_scope":"etb_or_attack_exile_graveyard_card_create_food_share_exiled_creature_activated_abilities_v1","create_food_token":true,"effect":"creature","foods_gain_activated_abilities_from_exiled_creatures":true,"hazel_brewmaster_etb_or_attack_exile_graveyard_card_create_food":true,"keywords":["menace"],"menace":true,"power":3,"target_count_max":1,"target_optional":true,"target_zone":"graveyard","toughness":4,"trigger":"enters_battlefield_or_attacks","trigger_effect":"exile_graveyard_card_create_food"}'::jsonb, '{"category":"board_development","effect":"token_maker","timing":"resolution_or_trigger"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'PG251: XMage batch proposal: exact local XMage class HazelsBrewmaster mapped to family token_maker; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('adagia, windswept bastion', 'Adagia, Windswept Bastion', 'e6878f05503ba8e6454108ddcbfca84d', 'battle_rule_v1:cc429e2792076144a1d51f692c70d726', '{"ability_kind":"activated","activate_only_as_sorcery":true,"activation_cost_mana":"{3}{W}","activation_requires_tap":true,"battle_model_scope":"station_12_copy_artifact_or_enchantment_you_control_legendary_token_v1","copy_target_types":["artifact","enchantment"],"effect":"copy_creature_token","station_level_required":12,"target_controller":"own","token_legendary":true}'::jsonb, '{"category":"board_development","effect":"copy_creature_token","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'PG251: XMage batch proposal: exact local XMage class AdagiaWindsweptBastion mapped to family copy_creature_token; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use. Existing land rule is preserved because this is a multi-function land.', 'preserve_existing_rows'),
    ('purphoros, god of the forge', 'Purphoros, God of the Forge', '01ee853118a4f1e5fe31a9d1e3ec6c5d', 'battle_rule_v1:2fb771380609b4d180c1e6816bf8b556', '{"ability_kind":"triggered","battle_model_scope":"controlled_creature_enters_damage_each_opponent_v1","damage":2,"effect":"passive","target_controller":"opponents","trigger":"creature_you_control_enters","trigger_another_creature_you_control_enters":true,"trigger_creature_you_control_enters":true,"trigger_damage_each_opponent":2,"trigger_effect":"damage_each_opponent"}'::jsonb, '{"category":"burn_engine","effect":"damage_each_opponent","subtype":"creature_enter_trigger","timing":"triggered"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'PG251: XMage batch proposal: exact local XMage class PurphorosGodOfTheForge mapped to family controlled_creature_etb_damage_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'preserve_existing_rows')
), deprecated AS (
  UPDATE public.card_battle_rules r
  SET
    review_status = 'deprecated',
    execution_status = 'disabled',
    updated_at = now(),
    notes = concat_ws(E'\n', nullif(r.notes, ''), 'PG251: disabled stale shadow before curated exact runtime batch rule upsert.')
  FROM proposed p
  WHERE r.normalized_name = p.normalized_name
    AND p.shadow_handling = 'deprecate_nonmatching_rows'
    AND r.logical_rule_key <> p.logical_rule_key
    AND (r.review_status <> 'deprecated' OR r.execution_status <> 'disabled')
  RETURNING r.*
), target_cards AS (
  SELECT DISTINCT ON (p.normalized_name)
    p.normalized_name,
    c.id,
    c.name
  FROM proposed p
  JOIN public.cards c
    ON (lower(c.name) = p.normalized_name OR split_part(lower(c.name), ' // ', 1) = p.normalized_name)
   AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
  ORDER BY p.normalized_name, c.name
), upserted AS (
  INSERT INTO public.card_battle_rules (
    normalized_name, logical_rule_key, card_id, card_name, effect_json, deck_role_json,
    source, confidence, review_status, execution_status, rule_version, oracle_hash,
    notes, reviewed_by, reviewed_at, created_at, updated_at, last_seen_at
  )
  SELECT
    p.normalized_name,
    p.logical_rule_key,
    tc.id,
    tc.name,
    p.effect_json,
    p.deck_role_json,
    p.source,
    p.confidence,
    p.review_status,
    p.execution_status,
    1,
    p.oracle_hash,
    p.notes,
    'codex-pg251',
    now(),
    now(),
    now(),
    now()
  FROM proposed p
  JOIN target_cards tc ON tc.normalized_name = p.normalized_name
  ON CONFLICT (normalized_name, logical_rule_key) DO UPDATE
  SET
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
    updated_at = EXCLUDED.updated_at,
    last_seen_at = EXCLUDED.last_seen_at
  RETURNING *
)
SELECT
  (SELECT count(*) FROM deprecated) AS deprecated_rows,
  (SELECT count(*) FROM upserted) AS upserted_rows;

COMMIT;
