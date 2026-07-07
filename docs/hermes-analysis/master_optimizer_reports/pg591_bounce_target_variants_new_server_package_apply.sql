BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg591_bounce_target_variants_new_server_20260707_035542 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('bounce off', 'cut the earthly bond', 'depart the realm', 'hoodwink', 'into thin air', 'wipe away')
   OR normalized_name LIKE 'bounce off // %'
   OR normalized_name LIKE 'cut the earthly bond // %'
   OR normalized_name LIKE 'depart the realm // %'
   OR normalized_name LIKE 'hoodwink // %'
   OR normalized_name LIKE 'into thin air // %'
   OR normalized_name LIKE 'wipe away // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('bounce off', 'Bounce Off', '4697e48be0d012476635626b59ff686b', 'battle_rule_v1:f2e24de1c6d45066dbda2109912a63e2', '{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","destination":"hand","effect":"remove_permanent","instant":true,"sorcery":false,"target":"creature_or_vehicle","target_constraints":{"any_of":[{"card_types":["creature"]},{"card_types":["artifact"],"required_subtypes":["vehicle"]}]},"xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"creature_or_vehicle","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BounceOff translated into ManaLoom runtime scope xmage_return_target_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('cut the earthly bond', 'Cut the Earthly Bond', '160612165db10cbd4158a1c24ceaa263', 'battle_rule_v1:f722ea9825e629e4690dabad8ea3536d', '{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","destination":"hand","effect":"remove_permanent","instant":true,"sorcery":false,"target":"enchanted_permanent","target_constraints":{"card_types":["permanent"],"enchanted":true},"xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"enchanted_permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CutTheEarthlyBond translated into ManaLoom runtime scope xmage_return_target_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('depart the realm', 'Depart the Realm', '6183c0a6f7e8710981aeb09c5c2fdee4', 'battle_rule_v1:001a1215317195fb0dd53f88c849c54c', '{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","destination":"hand","effect":"remove_permanent","instant":true,"sorcery":false,"target":"nonland_permanent","target_constraints":{"card_types":["permanent"],"exclude_card_types":["land"]},"xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"nonland_permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DepartTheRealm translated into ManaLoom runtime scope xmage_return_target_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hoodwink', 'Hoodwink', '89d3f25fb5311c47d4d3c11cc326914a', 'battle_rule_v1:09b2438b59221a455f58e7c7e8db8a22', '{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","destination":"hand","effect":"remove_permanent","instant":true,"sorcery":false,"target":"artifact_or_enchantment_or_land","target_constraints":{"card_types":["artifact","enchantment","land"]},"xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact_or_enchantment_or_land","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Hoodwink translated into ManaLoom runtime scope xmage_return_target_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('into thin air', 'Into Thin Air', '223da72bf51053d6b0f5dc8845673134', 'battle_rule_v1:1ced64c4f5a32cab3c82e97ad1f7bfad', '{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","destination":"hand","effect":"remove_permanent","instant":true,"sorcery":false,"target":"artifact","target_constraints":{"card_types":["artifact"]},"xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class IntoThinAir translated into ManaLoom runtime scope xmage_return_target_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wipe away', 'Wipe Away', '707e43acd81856daca2162b5de8dc02a', 'battle_rule_v1:2048333401c1ae3096acb4d43a4c83db', '{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","destination":"hand","effect":"remove_permanent","instant":true,"sorcery":false,"target":"permanent","target_constraints":{"card_types":["permanent"]},"xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WipeAway translated into ManaLoom runtime scope xmage_return_target_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('bounce off', 'Bounce Off', '4697e48be0d012476635626b59ff686b', 'battle_rule_v1:f2e24de1c6d45066dbda2109912a63e2', '{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","destination":"hand","effect":"remove_permanent","instant":true,"sorcery":false,"target":"creature_or_vehicle","target_constraints":{"any_of":[{"card_types":["creature"]},{"card_types":["artifact"],"required_subtypes":["vehicle"]}]},"xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"creature_or_vehicle","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BounceOff translated into ManaLoom runtime scope xmage_return_target_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('cut the earthly bond', 'Cut the Earthly Bond', '160612165db10cbd4158a1c24ceaa263', 'battle_rule_v1:f722ea9825e629e4690dabad8ea3536d', '{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","destination":"hand","effect":"remove_permanent","instant":true,"sorcery":false,"target":"enchanted_permanent","target_constraints":{"card_types":["permanent"],"enchanted":true},"xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"enchanted_permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CutTheEarthlyBond translated into ManaLoom runtime scope xmage_return_target_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('depart the realm', 'Depart the Realm', '6183c0a6f7e8710981aeb09c5c2fdee4', 'battle_rule_v1:001a1215317195fb0dd53f88c849c54c', '{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","destination":"hand","effect":"remove_permanent","instant":true,"sorcery":false,"target":"nonland_permanent","target_constraints":{"card_types":["permanent"],"exclude_card_types":["land"]},"xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"nonland_permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DepartTheRealm translated into ManaLoom runtime scope xmage_return_target_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hoodwink', 'Hoodwink', '89d3f25fb5311c47d4d3c11cc326914a', 'battle_rule_v1:09b2438b59221a455f58e7c7e8db8a22', '{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","destination":"hand","effect":"remove_permanent","instant":true,"sorcery":false,"target":"artifact_or_enchantment_or_land","target_constraints":{"card_types":["artifact","enchantment","land"]},"xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact_or_enchantment_or_land","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Hoodwink translated into ManaLoom runtime scope xmage_return_target_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('into thin air', 'Into Thin Air', '223da72bf51053d6b0f5dc8845673134', 'battle_rule_v1:1ced64c4f5a32cab3c82e97ad1f7bfad', '{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","destination":"hand","effect":"remove_permanent","instant":true,"sorcery":false,"target":"artifact","target_constraints":{"card_types":["artifact"]},"xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class IntoThinAir translated into ManaLoom runtime scope xmage_return_target_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wipe away', 'Wipe Away', '707e43acd81856daca2162b5de8dc02a', 'battle_rule_v1:2048333401c1ae3096acb4d43a4c83db', '{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","destination":"hand","effect":"remove_permanent","instant":true,"sorcery":false,"target":"permanent","target_constraints":{"card_types":["permanent"]},"xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WipeAway translated into ManaLoom runtime scope xmage_return_target_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('bounce off', 'Bounce Off', '4697e48be0d012476635626b59ff686b', 'battle_rule_v1:f2e24de1c6d45066dbda2109912a63e2', '{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","destination":"hand","effect":"remove_permanent","instant":true,"sorcery":false,"target":"creature_or_vehicle","target_constraints":{"any_of":[{"card_types":["creature"]},{"card_types":["artifact"],"required_subtypes":["vehicle"]}]},"xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"creature_or_vehicle","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BounceOff translated into ManaLoom runtime scope xmage_return_target_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('cut the earthly bond', 'Cut the Earthly Bond', '160612165db10cbd4158a1c24ceaa263', 'battle_rule_v1:f722ea9825e629e4690dabad8ea3536d', '{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","destination":"hand","effect":"remove_permanent","instant":true,"sorcery":false,"target":"enchanted_permanent","target_constraints":{"card_types":["permanent"],"enchanted":true},"xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"enchanted_permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CutTheEarthlyBond translated into ManaLoom runtime scope xmage_return_target_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('depart the realm', 'Depart the Realm', '6183c0a6f7e8710981aeb09c5c2fdee4', 'battle_rule_v1:001a1215317195fb0dd53f88c849c54c', '{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","destination":"hand","effect":"remove_permanent","instant":true,"sorcery":false,"target":"nonland_permanent","target_constraints":{"card_types":["permanent"],"exclude_card_types":["land"]},"xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"nonland_permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DepartTheRealm translated into ManaLoom runtime scope xmage_return_target_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hoodwink', 'Hoodwink', '89d3f25fb5311c47d4d3c11cc326914a', 'battle_rule_v1:09b2438b59221a455f58e7c7e8db8a22', '{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","destination":"hand","effect":"remove_permanent","instant":true,"sorcery":false,"target":"artifact_or_enchantment_or_land","target_constraints":{"card_types":["artifact","enchantment","land"]},"xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact_or_enchantment_or_land","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Hoodwink translated into ManaLoom runtime scope xmage_return_target_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('into thin air', 'Into Thin Air', '223da72bf51053d6b0f5dc8845673134', 'battle_rule_v1:1ced64c4f5a32cab3c82e97ad1f7bfad', '{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","destination":"hand","effect":"remove_permanent","instant":true,"sorcery":false,"target":"artifact","target_constraints":{"card_types":["artifact"]},"xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class IntoThinAir translated into ManaLoom runtime scope xmage_return_target_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wipe away', 'Wipe Away', '707e43acd81856daca2162b5de8dc02a', 'battle_rule_v1:2048333401c1ae3096acb4d43a4c83db', '{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","destination":"hand","effect":"remove_permanent","instant":true,"sorcery":false,"target":"permanent","target_constraints":{"card_types":["permanent"]},"xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WipeAway translated into ManaLoom runtime scope xmage_return_target_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
