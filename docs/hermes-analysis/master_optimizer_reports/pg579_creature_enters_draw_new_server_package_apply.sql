BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg579_creature_enters_draw_new_server_20260706_231755 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('elemental bond', 'garruk''s packleader', 'mary jane watson', 'wirewood savage', 'woodland liege')
   OR normalized_name LIKE 'elemental bond // %'
   OR normalized_name LIKE 'garruk''s packleader // %'
   OR normalized_name LIKE 'mary jane watson // %'
   OR normalized_name LIKE 'wirewood savage // %'
   OR normalized_name LIKE 'woodland liege // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('elemental bond', 'Elemental Bond', '5a691f455e7c6bc07be2216acc17dd12', 'battle_rule_v1:bd1c61d07d0cfba06bd4b9cd2c8e3563', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_draw_trigger_v1","effect":"enchantment","trigger":"creature_you_control_enters","trigger_another_creature_enters":false,"trigger_controller_scope":"self","trigger_draw_count":1,"trigger_effect":"draw_cards","trigger_entering_card_types":["creature"],"trigger_entering_power_min":3,"trigger_optional":false,"xmage_ability_class":"EntersBattlefieldAllTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"enchantment"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ElementalBond translated into ManaLoom runtime scope xmage_creature_enters_draw_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller draws cards with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('garruk''s packleader', 'Garruk''s Packleader', '75e46cdf177b60f8222c11dd2a23fe4a', 'battle_rule_v1:0f60b037ce53a92cb805467893c4b09b', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_draw_trigger_v1","effect":"creature","trigger":"creature_you_control_enters","trigger_another_creature_enters":true,"trigger_controller_scope":"self","trigger_draw_count":1,"trigger_effect":"draw_cards","trigger_entering_card_types":["creature"],"trigger_entering_power_min":3,"trigger_optional":true,"xmage_ability_class":"EntersBattlefieldAllTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GarruksPackleader translated into ManaLoom runtime scope xmage_creature_enters_draw_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller draws cards with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mary jane watson', 'Mary Jane Watson', 'cf34165c6f4e6d223d5a808d08d31820', 'battle_rule_v1:cc844d8be9823c1e24a8a527104759b7', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_draw_trigger_v1","effect":"creature","trigger":"creature_you_control_enters","trigger_another_creature_enters":false,"trigger_controller_scope":"self","trigger_draw_count":1,"trigger_effect":"draw_cards","trigger_entering_card_types":["creature"],"trigger_entering_subtypes":["spider"],"trigger_limit_each_turn":1,"trigger_optional":false,"xmage_ability_class":"EntersBattlefieldAllTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MaryJaneWatson translated into ManaLoom runtime scope xmage_creature_enters_draw_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller draws cards with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wirewood savage', 'Wirewood Savage', 'd9bea46f134c92b206b9825d99fd4536', 'battle_rule_v1:082b3870153de03b308b0b1845fac9a3', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_draw_trigger_v1","effect":"creature","trigger":"creature_enters","trigger_another_creature_enters":false,"trigger_controller_scope":"any","trigger_draw_count":1,"trigger_effect":"draw_cards","trigger_entering_card_types":["creature"],"trigger_entering_subtypes":["beast"],"trigger_optional":true,"xmage_ability_class":"EntersBattlefieldAllTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WirewoodSavage translated into ManaLoom runtime scope xmage_creature_enters_draw_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller draws cards with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('woodland liege', 'Woodland Liege', 'b88741308258706f6b2a4bcc27621de9', 'battle_rule_v1:0b327e4ff0cfb5815d7d2b7cf7adea6d', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_draw_trigger_v1","effect":"creature","trigger":"creature_you_control_enters","trigger_another_creature_enters":false,"trigger_controller_scope":"self","trigger_draw_count":1,"trigger_effect":"draw_cards","trigger_entering_card_types":["creature"],"trigger_entering_subtypes":["beast"],"trigger_optional":false,"xmage_ability_class":"EntersBattlefieldAllTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WoodlandLiege translated into ManaLoom runtime scope xmage_creature_enters_draw_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller draws cards with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('elemental bond', 'Elemental Bond', '5a691f455e7c6bc07be2216acc17dd12', 'battle_rule_v1:bd1c61d07d0cfba06bd4b9cd2c8e3563', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_draw_trigger_v1","effect":"enchantment","trigger":"creature_you_control_enters","trigger_another_creature_enters":false,"trigger_controller_scope":"self","trigger_draw_count":1,"trigger_effect":"draw_cards","trigger_entering_card_types":["creature"],"trigger_entering_power_min":3,"trigger_optional":false,"xmage_ability_class":"EntersBattlefieldAllTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"enchantment"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ElementalBond translated into ManaLoom runtime scope xmage_creature_enters_draw_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller draws cards with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('garruk''s packleader', 'Garruk''s Packleader', '75e46cdf177b60f8222c11dd2a23fe4a', 'battle_rule_v1:0f60b037ce53a92cb805467893c4b09b', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_draw_trigger_v1","effect":"creature","trigger":"creature_you_control_enters","trigger_another_creature_enters":true,"trigger_controller_scope":"self","trigger_draw_count":1,"trigger_effect":"draw_cards","trigger_entering_card_types":["creature"],"trigger_entering_power_min":3,"trigger_optional":true,"xmage_ability_class":"EntersBattlefieldAllTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GarruksPackleader translated into ManaLoom runtime scope xmage_creature_enters_draw_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller draws cards with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mary jane watson', 'Mary Jane Watson', 'cf34165c6f4e6d223d5a808d08d31820', 'battle_rule_v1:cc844d8be9823c1e24a8a527104759b7', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_draw_trigger_v1","effect":"creature","trigger":"creature_you_control_enters","trigger_another_creature_enters":false,"trigger_controller_scope":"self","trigger_draw_count":1,"trigger_effect":"draw_cards","trigger_entering_card_types":["creature"],"trigger_entering_subtypes":["spider"],"trigger_limit_each_turn":1,"trigger_optional":false,"xmage_ability_class":"EntersBattlefieldAllTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MaryJaneWatson translated into ManaLoom runtime scope xmage_creature_enters_draw_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller draws cards with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wirewood savage', 'Wirewood Savage', 'd9bea46f134c92b206b9825d99fd4536', 'battle_rule_v1:082b3870153de03b308b0b1845fac9a3', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_draw_trigger_v1","effect":"creature","trigger":"creature_enters","trigger_another_creature_enters":false,"trigger_controller_scope":"any","trigger_draw_count":1,"trigger_effect":"draw_cards","trigger_entering_card_types":["creature"],"trigger_entering_subtypes":["beast"],"trigger_optional":true,"xmage_ability_class":"EntersBattlefieldAllTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WirewoodSavage translated into ManaLoom runtime scope xmage_creature_enters_draw_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller draws cards with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('woodland liege', 'Woodland Liege', 'b88741308258706f6b2a4bcc27621de9', 'battle_rule_v1:0b327e4ff0cfb5815d7d2b7cf7adea6d', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_draw_trigger_v1","effect":"creature","trigger":"creature_you_control_enters","trigger_another_creature_enters":false,"trigger_controller_scope":"self","trigger_draw_count":1,"trigger_effect":"draw_cards","trigger_entering_card_types":["creature"],"trigger_entering_subtypes":["beast"],"trigger_optional":false,"xmage_ability_class":"EntersBattlefieldAllTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WoodlandLiege translated into ManaLoom runtime scope xmage_creature_enters_draw_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller draws cards with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('elemental bond', 'Elemental Bond', '5a691f455e7c6bc07be2216acc17dd12', 'battle_rule_v1:bd1c61d07d0cfba06bd4b9cd2c8e3563', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_draw_trigger_v1","effect":"enchantment","trigger":"creature_you_control_enters","trigger_another_creature_enters":false,"trigger_controller_scope":"self","trigger_draw_count":1,"trigger_effect":"draw_cards","trigger_entering_card_types":["creature"],"trigger_entering_power_min":3,"trigger_optional":false,"xmage_ability_class":"EntersBattlefieldAllTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"enchantment"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ElementalBond translated into ManaLoom runtime scope xmage_creature_enters_draw_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller draws cards with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('garruk''s packleader', 'Garruk''s Packleader', '75e46cdf177b60f8222c11dd2a23fe4a', 'battle_rule_v1:0f60b037ce53a92cb805467893c4b09b', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_draw_trigger_v1","effect":"creature","trigger":"creature_you_control_enters","trigger_another_creature_enters":true,"trigger_controller_scope":"self","trigger_draw_count":1,"trigger_effect":"draw_cards","trigger_entering_card_types":["creature"],"trigger_entering_power_min":3,"trigger_optional":true,"xmage_ability_class":"EntersBattlefieldAllTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GarruksPackleader translated into ManaLoom runtime scope xmage_creature_enters_draw_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller draws cards with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mary jane watson', 'Mary Jane Watson', 'cf34165c6f4e6d223d5a808d08d31820', 'battle_rule_v1:cc844d8be9823c1e24a8a527104759b7', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_draw_trigger_v1","effect":"creature","trigger":"creature_you_control_enters","trigger_another_creature_enters":false,"trigger_controller_scope":"self","trigger_draw_count":1,"trigger_effect":"draw_cards","trigger_entering_card_types":["creature"],"trigger_entering_subtypes":["spider"],"trigger_limit_each_turn":1,"trigger_optional":false,"xmage_ability_class":"EntersBattlefieldAllTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MaryJaneWatson translated into ManaLoom runtime scope xmage_creature_enters_draw_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller draws cards with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wirewood savage', 'Wirewood Savage', 'd9bea46f134c92b206b9825d99fd4536', 'battle_rule_v1:082b3870153de03b308b0b1845fac9a3', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_draw_trigger_v1","effect":"creature","trigger":"creature_enters","trigger_another_creature_enters":false,"trigger_controller_scope":"any","trigger_draw_count":1,"trigger_effect":"draw_cards","trigger_entering_card_types":["creature"],"trigger_entering_subtypes":["beast"],"trigger_optional":true,"xmage_ability_class":"EntersBattlefieldAllTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WirewoodSavage translated into ManaLoom runtime scope xmage_creature_enters_draw_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller draws cards with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('woodland liege', 'Woodland Liege', 'b88741308258706f6b2a4bcc27621de9', 'battle_rule_v1:0b327e4ff0cfb5815d7d2b7cf7adea6d', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_draw_trigger_v1","effect":"creature","trigger":"creature_you_control_enters","trigger_another_creature_enters":false,"trigger_controller_scope":"self","trigger_draw_count":1,"trigger_effect":"draw_cards","trigger_entering_card_types":["creature"],"trigger_entering_subtypes":["beast"],"trigger_optional":false,"xmage_ability_class":"EntersBattlefieldAllTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WoodlandLiege translated into ManaLoom runtime scope xmage_creature_enters_draw_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller draws cards with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
