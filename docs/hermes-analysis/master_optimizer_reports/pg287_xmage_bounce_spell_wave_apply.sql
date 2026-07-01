BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg287_xmage_bounce_spell_wave_20260701_081902 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('boomerang', 'disperse', 'drown in shapelessness', 'eye of nowhere', 'regress', 'unsummon', 'void snare')
   OR normalized_name LIKE 'boomerang // %'
   OR normalized_name LIKE 'disperse // %'
   OR normalized_name LIKE 'drown in shapelessness // %'
   OR normalized_name LIKE 'eye of nowhere // %'
   OR normalized_name LIKE 'regress // %'
   OR normalized_name LIKE 'unsummon // %'
   OR normalized_name LIKE 'void snare // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('boomerang', 'Boomerang', 'ce97f55e49504ae77e37b12d347da4ed', 'battle_rule_v1:2048333401c1ae3096acb4d43a4c83db', '{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","destination":"hand","effect":"remove_permanent","instant":true,"sorcery":false,"target":"permanent","target_constraints":{"card_types":["permanent"]},"xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Boomerang translated into ManaLoom runtime scope xmage_return_target_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('disperse', 'Disperse', '4051670871d0fa08e186d4dcdc7fe854', 'battle_rule_v1:e0cd5a647871ffed2ebf25c3b0fa4ab2', '{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","destination":"hand","effect":"remove_permanent","instant":true,"sorcery":false,"target":"nonland_permanent","target_constraints":{"card_types":["nonland_permanent"]},"xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"nonland_permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Disperse translated into ManaLoom runtime scope xmage_return_target_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('drown in shapelessness', 'Drown in Shapelessness', 'e273efeb41fba4daf066d9df143c8522', 'battle_rule_v1:92639258e9e2b1aa134f47b808061c76', '{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","destination":"hand","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DrownInShapelessness translated into ManaLoom runtime scope xmage_return_target_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('eye of nowhere', 'Eye of Nowhere', 'ce97f55e49504ae77e37b12d347da4ed', 'battle_rule_v1:3bf436b016651becbbdb0d7d2fb400dc', '{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","destination":"hand","effect":"remove_permanent","instant":false,"sorcery":true,"target":"permanent","target_constraints":{"card_types":["permanent"]},"xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EyeOfNowhere translated into ManaLoom runtime scope xmage_return_target_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('regress', 'Regress', 'ce97f55e49504ae77e37b12d347da4ed', 'battle_rule_v1:2048333401c1ae3096acb4d43a4c83db', '{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","destination":"hand","effect":"remove_permanent","instant":true,"sorcery":false,"target":"permanent","target_constraints":{"card_types":["permanent"]},"xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Regress translated into ManaLoom runtime scope xmage_return_target_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('unsummon', 'Unsummon', 'e273efeb41fba4daf066d9df143c8522', 'battle_rule_v1:92639258e9e2b1aa134f47b808061c76', '{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","destination":"hand","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Unsummon translated into ManaLoom runtime scope xmage_return_target_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('void snare', 'Void Snare', '4051670871d0fa08e186d4dcdc7fe854', 'battle_rule_v1:45be913b2a550d0ade45b3d034532330', '{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","destination":"hand","effect":"remove_permanent","instant":false,"sorcery":true,"target":"nonland_permanent","target_constraints":{"card_types":["nonland_permanent"]},"xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"nonland_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VoidSnare translated into ManaLoom runtime scope xmage_return_target_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('boomerang', 'Boomerang', 'ce97f55e49504ae77e37b12d347da4ed', 'battle_rule_v1:2048333401c1ae3096acb4d43a4c83db', '{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","destination":"hand","effect":"remove_permanent","instant":true,"sorcery":false,"target":"permanent","target_constraints":{"card_types":["permanent"]},"xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Boomerang translated into ManaLoom runtime scope xmage_return_target_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('disperse', 'Disperse', '4051670871d0fa08e186d4dcdc7fe854', 'battle_rule_v1:e0cd5a647871ffed2ebf25c3b0fa4ab2', '{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","destination":"hand","effect":"remove_permanent","instant":true,"sorcery":false,"target":"nonland_permanent","target_constraints":{"card_types":["nonland_permanent"]},"xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"nonland_permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Disperse translated into ManaLoom runtime scope xmage_return_target_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('drown in shapelessness', 'Drown in Shapelessness', 'e273efeb41fba4daf066d9df143c8522', 'battle_rule_v1:92639258e9e2b1aa134f47b808061c76', '{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","destination":"hand","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DrownInShapelessness translated into ManaLoom runtime scope xmage_return_target_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('eye of nowhere', 'Eye of Nowhere', 'ce97f55e49504ae77e37b12d347da4ed', 'battle_rule_v1:3bf436b016651becbbdb0d7d2fb400dc', '{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","destination":"hand","effect":"remove_permanent","instant":false,"sorcery":true,"target":"permanent","target_constraints":{"card_types":["permanent"]},"xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EyeOfNowhere translated into ManaLoom runtime scope xmage_return_target_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('regress', 'Regress', 'ce97f55e49504ae77e37b12d347da4ed', 'battle_rule_v1:2048333401c1ae3096acb4d43a4c83db', '{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","destination":"hand","effect":"remove_permanent","instant":true,"sorcery":false,"target":"permanent","target_constraints":{"card_types":["permanent"]},"xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Regress translated into ManaLoom runtime scope xmage_return_target_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('unsummon', 'Unsummon', 'e273efeb41fba4daf066d9df143c8522', 'battle_rule_v1:92639258e9e2b1aa134f47b808061c76', '{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","destination":"hand","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Unsummon translated into ManaLoom runtime scope xmage_return_target_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('void snare', 'Void Snare', '4051670871d0fa08e186d4dcdc7fe854', 'battle_rule_v1:45be913b2a550d0ade45b3d034532330', '{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","destination":"hand","effect":"remove_permanent","instant":false,"sorcery":true,"target":"nonland_permanent","target_constraints":{"card_types":["nonland_permanent"]},"xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"nonland_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VoidSnare translated into ManaLoom runtime scope xmage_return_target_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('boomerang', 'Boomerang', 'ce97f55e49504ae77e37b12d347da4ed', 'battle_rule_v1:2048333401c1ae3096acb4d43a4c83db', '{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","destination":"hand","effect":"remove_permanent","instant":true,"sorcery":false,"target":"permanent","target_constraints":{"card_types":["permanent"]},"xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Boomerang translated into ManaLoom runtime scope xmage_return_target_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('disperse', 'Disperse', '4051670871d0fa08e186d4dcdc7fe854', 'battle_rule_v1:e0cd5a647871ffed2ebf25c3b0fa4ab2', '{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","destination":"hand","effect":"remove_permanent","instant":true,"sorcery":false,"target":"nonland_permanent","target_constraints":{"card_types":["nonland_permanent"]},"xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"nonland_permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Disperse translated into ManaLoom runtime scope xmage_return_target_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('drown in shapelessness', 'Drown in Shapelessness', 'e273efeb41fba4daf066d9df143c8522', 'battle_rule_v1:92639258e9e2b1aa134f47b808061c76', '{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","destination":"hand","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DrownInShapelessness translated into ManaLoom runtime scope xmage_return_target_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('eye of nowhere', 'Eye of Nowhere', 'ce97f55e49504ae77e37b12d347da4ed', 'battle_rule_v1:3bf436b016651becbbdb0d7d2fb400dc', '{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","destination":"hand","effect":"remove_permanent","instant":false,"sorcery":true,"target":"permanent","target_constraints":{"card_types":["permanent"]},"xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EyeOfNowhere translated into ManaLoom runtime scope xmage_return_target_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('regress', 'Regress', 'ce97f55e49504ae77e37b12d347da4ed', 'battle_rule_v1:2048333401c1ae3096acb4d43a4c83db', '{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","destination":"hand","effect":"remove_permanent","instant":true,"sorcery":false,"target":"permanent","target_constraints":{"card_types":["permanent"]},"xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Regress translated into ManaLoom runtime scope xmage_return_target_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('unsummon', 'Unsummon', 'e273efeb41fba4daf066d9df143c8522', 'battle_rule_v1:92639258e9e2b1aa134f47b808061c76', '{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","destination":"hand","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Unsummon translated into ManaLoom runtime scope xmage_return_target_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('void snare', 'Void Snare', '4051670871d0fa08e186d4dcdc7fe854', 'battle_rule_v1:45be913b2a550d0ade45b3d034532330', '{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","destination":"hand","effect":"remove_permanent","instant":false,"sorcery":true,"target":"nonland_permanent","target_constraints":{"card_types":["nonland_permanent"]},"xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"nonland_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VoidSnare translated into ManaLoom runtime scope xmage_return_target_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
