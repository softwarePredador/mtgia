BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg791_dynamic_composite_damage_20260711_222405 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('focus fire', 'hobbit''s sting', 'road rage', 'slash of light')
   OR normalized_name LIKE 'focus fire // %'
   OR normalized_name LIKE 'hobbit''s sting // %'
   OR normalized_name LIKE 'road rage // %'
   OR normalized_name LIKE 'slash of light // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('focus fire', 'Focus Fire', 'dadac04a003dabbc0c02353de974b38e', 'battle_rule_v1:0a77c01b41e8b01edc7700293d29c782', '{"amount":0,"battle_model_scope":"xmage_dynamic_count_damage_spell_v1","battlefield_count_components":[{"battlefield_count_card_types":["creature"],"battlefield_count_scope":"controller_battlefield"},{"battlefield_count_scope":"controller_battlefield","battlefield_count_subtypes":["spacecraft"]}],"battlefield_count_composite_mode":"union","damage":0,"damage_amount_source":"composite_battlefield_permanent_count","damage_base_amount":2,"damage_per_count":1,"effect":"direct_damage","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"combat_state":"attacking_or_blocking"},"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FocusFire translated into ManaLoom runtime scope xmage_dynamic_count_damage_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hobbit''s sting', 'Hobbit''s Sting', 'c96fc623db953d300e37f66bcdd6e2a8', 'battle_rule_v1:4cc57a6a390ad2b30a79ce8a740c05ae', '{"amount":0,"battle_model_scope":"xmage_dynamic_count_damage_spell_v1","battlefield_count_components":[{"battlefield_count_card_types":["creature"],"battlefield_count_scope":"controller_battlefield"},{"battlefield_count_scope":"controller_battlefield","battlefield_count_subtypes":["food"]}],"battlefield_count_composite_mode":"sum","damage":0,"damage_amount_source":"composite_battlefield_permanent_count","damage_base_amount":0,"damage_per_count":1,"effect":"direct_damage","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HobbitsSting translated into ManaLoom runtime scope xmage_dynamic_count_damage_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('road rage', 'Road Rage', 'ade79182ddf63f024acbdd66cb9dbf78', 'battle_rule_v1:7aafa4698684da859113cb2b62e71232', '{"amount":0,"battle_model_scope":"xmage_dynamic_count_damage_spell_v1","battlefield_count_components":[{"battlefield_count_scope":"controller_battlefield","battlefield_count_subtypes":["mount"]},{"battlefield_count_scope":"controller_battlefield","battlefield_count_subtypes":["vehicle"]}],"battlefield_count_composite_mode":"union","damage":0,"damage_amount_source":"composite_battlefield_permanent_count","damage_base_amount":2,"damage_per_count":1,"effect":"direct_damage","instant":true,"sorcery":false,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature_or_planeswalker","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RoadRage translated into ManaLoom runtime scope xmage_dynamic_count_damage_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('slash of light', 'Slash of Light', 'cf5f56d8ffa98e6d77f5cc73369073c3', 'battle_rule_v1:d458a10a448c0e3796f48d5e721a36b0', '{"amount":0,"battle_model_scope":"xmage_dynamic_count_damage_spell_v1","battlefield_count_components":[{"battlefield_count_card_types":["creature"],"battlefield_count_scope":"controller_battlefield"},{"battlefield_count_card_types":["artifact"],"battlefield_count_scope":"controller_battlefield","battlefield_count_subtypes":["equipment"]}],"battlefield_count_composite_mode":"sum","damage":0,"damage_amount_source":"composite_battlefield_permanent_count","damage_base_amount":0,"damage_per_count":1,"effect":"direct_damage","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SlashOfLight translated into ManaLoom runtime scope xmage_dynamic_count_damage_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('focus fire', 'Focus Fire', 'dadac04a003dabbc0c02353de974b38e', 'battle_rule_v1:0a77c01b41e8b01edc7700293d29c782', '{"amount":0,"battle_model_scope":"xmage_dynamic_count_damage_spell_v1","battlefield_count_components":[{"battlefield_count_card_types":["creature"],"battlefield_count_scope":"controller_battlefield"},{"battlefield_count_scope":"controller_battlefield","battlefield_count_subtypes":["spacecraft"]}],"battlefield_count_composite_mode":"union","damage":0,"damage_amount_source":"composite_battlefield_permanent_count","damage_base_amount":2,"damage_per_count":1,"effect":"direct_damage","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"combat_state":"attacking_or_blocking"},"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FocusFire translated into ManaLoom runtime scope xmage_dynamic_count_damage_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hobbit''s sting', 'Hobbit''s Sting', 'c96fc623db953d300e37f66bcdd6e2a8', 'battle_rule_v1:4cc57a6a390ad2b30a79ce8a740c05ae', '{"amount":0,"battle_model_scope":"xmage_dynamic_count_damage_spell_v1","battlefield_count_components":[{"battlefield_count_card_types":["creature"],"battlefield_count_scope":"controller_battlefield"},{"battlefield_count_scope":"controller_battlefield","battlefield_count_subtypes":["food"]}],"battlefield_count_composite_mode":"sum","damage":0,"damage_amount_source":"composite_battlefield_permanent_count","damage_base_amount":0,"damage_per_count":1,"effect":"direct_damage","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HobbitsSting translated into ManaLoom runtime scope xmage_dynamic_count_damage_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('road rage', 'Road Rage', 'ade79182ddf63f024acbdd66cb9dbf78', 'battle_rule_v1:7aafa4698684da859113cb2b62e71232', '{"amount":0,"battle_model_scope":"xmage_dynamic_count_damage_spell_v1","battlefield_count_components":[{"battlefield_count_scope":"controller_battlefield","battlefield_count_subtypes":["mount"]},{"battlefield_count_scope":"controller_battlefield","battlefield_count_subtypes":["vehicle"]}],"battlefield_count_composite_mode":"union","damage":0,"damage_amount_source":"composite_battlefield_permanent_count","damage_base_amount":2,"damage_per_count":1,"effect":"direct_damage","instant":true,"sorcery":false,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature_or_planeswalker","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RoadRage translated into ManaLoom runtime scope xmage_dynamic_count_damage_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('slash of light', 'Slash of Light', 'cf5f56d8ffa98e6d77f5cc73369073c3', 'battle_rule_v1:d458a10a448c0e3796f48d5e721a36b0', '{"amount":0,"battle_model_scope":"xmage_dynamic_count_damage_spell_v1","battlefield_count_components":[{"battlefield_count_card_types":["creature"],"battlefield_count_scope":"controller_battlefield"},{"battlefield_count_card_types":["artifact"],"battlefield_count_scope":"controller_battlefield","battlefield_count_subtypes":["equipment"]}],"battlefield_count_composite_mode":"sum","damage":0,"damage_amount_source":"composite_battlefield_permanent_count","damage_base_amount":0,"damage_per_count":1,"effect":"direct_damage","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SlashOfLight translated into ManaLoom runtime scope xmage_dynamic_count_damage_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('focus fire', 'Focus Fire', 'dadac04a003dabbc0c02353de974b38e', 'battle_rule_v1:0a77c01b41e8b01edc7700293d29c782', '{"amount":0,"battle_model_scope":"xmage_dynamic_count_damage_spell_v1","battlefield_count_components":[{"battlefield_count_card_types":["creature"],"battlefield_count_scope":"controller_battlefield"},{"battlefield_count_scope":"controller_battlefield","battlefield_count_subtypes":["spacecraft"]}],"battlefield_count_composite_mode":"union","damage":0,"damage_amount_source":"composite_battlefield_permanent_count","damage_base_amount":2,"damage_per_count":1,"effect":"direct_damage","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"combat_state":"attacking_or_blocking"},"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FocusFire translated into ManaLoom runtime scope xmage_dynamic_count_damage_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hobbit''s sting', 'Hobbit''s Sting', 'c96fc623db953d300e37f66bcdd6e2a8', 'battle_rule_v1:4cc57a6a390ad2b30a79ce8a740c05ae', '{"amount":0,"battle_model_scope":"xmage_dynamic_count_damage_spell_v1","battlefield_count_components":[{"battlefield_count_card_types":["creature"],"battlefield_count_scope":"controller_battlefield"},{"battlefield_count_scope":"controller_battlefield","battlefield_count_subtypes":["food"]}],"battlefield_count_composite_mode":"sum","damage":0,"damage_amount_source":"composite_battlefield_permanent_count","damage_base_amount":0,"damage_per_count":1,"effect":"direct_damage","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HobbitsSting translated into ManaLoom runtime scope xmage_dynamic_count_damage_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('road rage', 'Road Rage', 'ade79182ddf63f024acbdd66cb9dbf78', 'battle_rule_v1:7aafa4698684da859113cb2b62e71232', '{"amount":0,"battle_model_scope":"xmage_dynamic_count_damage_spell_v1","battlefield_count_components":[{"battlefield_count_scope":"controller_battlefield","battlefield_count_subtypes":["mount"]},{"battlefield_count_scope":"controller_battlefield","battlefield_count_subtypes":["vehicle"]}],"battlefield_count_composite_mode":"union","damage":0,"damage_amount_source":"composite_battlefield_permanent_count","damage_base_amount":2,"damage_per_count":1,"effect":"direct_damage","instant":true,"sorcery":false,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature_or_planeswalker","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RoadRage translated into ManaLoom runtime scope xmage_dynamic_count_damage_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('slash of light', 'Slash of Light', 'cf5f56d8ffa98e6d77f5cc73369073c3', 'battle_rule_v1:d458a10a448c0e3796f48d5e721a36b0', '{"amount":0,"battle_model_scope":"xmage_dynamic_count_damage_spell_v1","battlefield_count_components":[{"battlefield_count_card_types":["creature"],"battlefield_count_scope":"controller_battlefield"},{"battlefield_count_card_types":["artifact"],"battlefield_count_scope":"controller_battlefield","battlefield_count_subtypes":["equipment"]}],"battlefield_count_composite_mode":"sum","damage":0,"damage_amount_source":"composite_battlefield_permanent_count","damage_base_amount":0,"damage_per_count":1,"effect":"direct_damage","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SlashOfLight translated into ManaLoom runtime scope xmage_dynamic_count_damage_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
