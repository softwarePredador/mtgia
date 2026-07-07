BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg583b_safe_primary_sentence_removal_tar_20260707_005413 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('dark withering', 'death rattle', 'expunge', 'murderous compulsion', 'protective response', 'shoot down', 'slingbow trap', 'snuff out', 'thraben exorcism', 'vanishing verse')
   OR normalized_name LIKE 'dark withering // %'
   OR normalized_name LIKE 'death rattle // %'
   OR normalized_name LIKE 'expunge // %'
   OR normalized_name LIKE 'murderous compulsion // %'
   OR normalized_name LIKE 'protective response // %'
   OR normalized_name LIKE 'shoot down // %'
   OR normalized_name LIKE 'slingbow trap // %'
   OR normalized_name LIKE 'snuff out // %'
   OR normalized_name LIKE 'thraben exorcism // %'
   OR normalized_name LIKE 'vanishing verse // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('dark withering', 'Dark Withering', 'd5c7b1f417a26c6f3eb976d4adfb49ff', 'battle_rule_v1:168dcdc18248bd9b8dcd053f2113a0b4', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_colors":["B"]},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DarkWithering translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('death rattle', 'Death Rattle', '3d4cadad97a03d6659f1fe381ef8feed', 'battle_rule_v1:d7e45a943a889937ffa67d07f5b07b1e', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_colors":["G"]},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DeathRattle translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('expunge', 'Expunge', 'c3f856f283074bd20c4c6ae484dedfe0', 'battle_rule_v1:9811339b3ee6bf8bf1a584db8dfd5015', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_card_types":["artifact"],"exclude_colors":["B"]},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Expunge translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('murderous compulsion', 'Murderous Compulsion', '7049ca97d618808903e8523d3f67dafb', 'battle_rule_v1:97607a657274b25a6d4734d2bc4cbf97', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"],"tapped_state":"tapped"},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MurderousCompulsion translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('protective response', 'Protective Response', '045d82faf84d613c18cebfa0a09db559', 'battle_rule_v1:b13effdee2fe1313d4f6d0d3cc6f47fe', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"combat_state":"attacking_or_blocking"},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ProtectiveResponse translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('shoot down', 'Shoot Down', '7c8c39bfd8d3bb29ec8d702a5d278474', 'battle_rule_v1:c2b9fb8b06fde05a28b39336f43d2a15', '{"battle_model_scope":"xmage_exile_target_spell_v1","destination":"exile","effect":"remove_permanent","instant":false,"sorcery":true,"target":"permanent","target_constraints":{"any_of":[{"card_types":["artifact"]},{"card_types":["enchantment"]},{"card_types":["creature"],"required_keywords":["flying"]}]},"xmage_effect_class":"ExileTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ShootDown translated into ManaLoom runtime scope xmage_exile_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('slingbow trap', 'Slingbow Trap', 'f37057bd8c944691f76ff9d4e2921a93', 'battle_rule_v1:a3578e249fe8c4729d4574c4d4f3a314', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"combat_state":"attacking","required_keywords":["flying"]},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SlingbowTrap translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('snuff out', 'Snuff Out', 'b5a888a6cfcd7e750e05583aa261194d', 'battle_rule_v1:168dcdc18248bd9b8dcd053f2113a0b4', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_colors":["B"]},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SnuffOut translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thraben exorcism', 'Thraben Exorcism', '249419eda9079699d13711b8ee85aea4', 'battle_rule_v1:1f8ebe2e03b79895b49d9f788b0d9fb8', '{"battle_model_scope":"xmage_exile_target_spell_v1","destination":"exile","effect":"remove_permanent","instant":true,"sorcery":false,"target":"permanent","target_constraints":{"any_of":[{"card_types":["permanent"],"required_subtypes":["spirit"]},{"card_types":["creature"],"required_keywords":["disturb"]},{"card_types":["enchantment"]}]},"xmage_effect_class":"ExileTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThrabenExorcism translated into ManaLoom runtime scope xmage_exile_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vanishing verse', 'Vanishing Verse', '229f07c3ad92861e1368799937b30050', 'battle_rule_v1:ecdba7e71dfb810694c78fd7809fa855', '{"battle_model_scope":"xmage_exile_target_spell_v1","destination":"exile","effect":"remove_permanent","instant":true,"sorcery":false,"target":"permanent","target_constraints":{"card_types":["permanent"],"color_count_exact":1},"xmage_effect_class":"ExileTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VanishingVerse translated into ManaLoom runtime scope xmage_exile_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('dark withering', 'Dark Withering', 'd5c7b1f417a26c6f3eb976d4adfb49ff', 'battle_rule_v1:168dcdc18248bd9b8dcd053f2113a0b4', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_colors":["B"]},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DarkWithering translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('death rattle', 'Death Rattle', '3d4cadad97a03d6659f1fe381ef8feed', 'battle_rule_v1:d7e45a943a889937ffa67d07f5b07b1e', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_colors":["G"]},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DeathRattle translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('expunge', 'Expunge', 'c3f856f283074bd20c4c6ae484dedfe0', 'battle_rule_v1:9811339b3ee6bf8bf1a584db8dfd5015', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_card_types":["artifact"],"exclude_colors":["B"]},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Expunge translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('murderous compulsion', 'Murderous Compulsion', '7049ca97d618808903e8523d3f67dafb', 'battle_rule_v1:97607a657274b25a6d4734d2bc4cbf97', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"],"tapped_state":"tapped"},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MurderousCompulsion translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('protective response', 'Protective Response', '045d82faf84d613c18cebfa0a09db559', 'battle_rule_v1:b13effdee2fe1313d4f6d0d3cc6f47fe', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"combat_state":"attacking_or_blocking"},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ProtectiveResponse translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('shoot down', 'Shoot Down', '7c8c39bfd8d3bb29ec8d702a5d278474', 'battle_rule_v1:c2b9fb8b06fde05a28b39336f43d2a15', '{"battle_model_scope":"xmage_exile_target_spell_v1","destination":"exile","effect":"remove_permanent","instant":false,"sorcery":true,"target":"permanent","target_constraints":{"any_of":[{"card_types":["artifact"]},{"card_types":["enchantment"]},{"card_types":["creature"],"required_keywords":["flying"]}]},"xmage_effect_class":"ExileTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ShootDown translated into ManaLoom runtime scope xmage_exile_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('slingbow trap', 'Slingbow Trap', 'f37057bd8c944691f76ff9d4e2921a93', 'battle_rule_v1:a3578e249fe8c4729d4574c4d4f3a314', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"combat_state":"attacking","required_keywords":["flying"]},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SlingbowTrap translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('snuff out', 'Snuff Out', 'b5a888a6cfcd7e750e05583aa261194d', 'battle_rule_v1:168dcdc18248bd9b8dcd053f2113a0b4', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_colors":["B"]},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SnuffOut translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thraben exorcism', 'Thraben Exorcism', '249419eda9079699d13711b8ee85aea4', 'battle_rule_v1:1f8ebe2e03b79895b49d9f788b0d9fb8', '{"battle_model_scope":"xmage_exile_target_spell_v1","destination":"exile","effect":"remove_permanent","instant":true,"sorcery":false,"target":"permanent","target_constraints":{"any_of":[{"card_types":["permanent"],"required_subtypes":["spirit"]},{"card_types":["creature"],"required_keywords":["disturb"]},{"card_types":["enchantment"]}]},"xmage_effect_class":"ExileTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThrabenExorcism translated into ManaLoom runtime scope xmage_exile_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vanishing verse', 'Vanishing Verse', '229f07c3ad92861e1368799937b30050', 'battle_rule_v1:ecdba7e71dfb810694c78fd7809fa855', '{"battle_model_scope":"xmage_exile_target_spell_v1","destination":"exile","effect":"remove_permanent","instant":true,"sorcery":false,"target":"permanent","target_constraints":{"card_types":["permanent"],"color_count_exact":1},"xmage_effect_class":"ExileTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VanishingVerse translated into ManaLoom runtime scope xmage_exile_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('dark withering', 'Dark Withering', 'd5c7b1f417a26c6f3eb976d4adfb49ff', 'battle_rule_v1:168dcdc18248bd9b8dcd053f2113a0b4', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_colors":["B"]},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DarkWithering translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('death rattle', 'Death Rattle', '3d4cadad97a03d6659f1fe381ef8feed', 'battle_rule_v1:d7e45a943a889937ffa67d07f5b07b1e', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_colors":["G"]},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DeathRattle translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('expunge', 'Expunge', 'c3f856f283074bd20c4c6ae484dedfe0', 'battle_rule_v1:9811339b3ee6bf8bf1a584db8dfd5015', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_card_types":["artifact"],"exclude_colors":["B"]},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Expunge translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('murderous compulsion', 'Murderous Compulsion', '7049ca97d618808903e8523d3f67dafb', 'battle_rule_v1:97607a657274b25a6d4734d2bc4cbf97', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"],"tapped_state":"tapped"},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MurderousCompulsion translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('protective response', 'Protective Response', '045d82faf84d613c18cebfa0a09db559', 'battle_rule_v1:b13effdee2fe1313d4f6d0d3cc6f47fe', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"combat_state":"attacking_or_blocking"},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ProtectiveResponse translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('shoot down', 'Shoot Down', '7c8c39bfd8d3bb29ec8d702a5d278474', 'battle_rule_v1:c2b9fb8b06fde05a28b39336f43d2a15', '{"battle_model_scope":"xmage_exile_target_spell_v1","destination":"exile","effect":"remove_permanent","instant":false,"sorcery":true,"target":"permanent","target_constraints":{"any_of":[{"card_types":["artifact"]},{"card_types":["enchantment"]},{"card_types":["creature"],"required_keywords":["flying"]}]},"xmage_effect_class":"ExileTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ShootDown translated into ManaLoom runtime scope xmage_exile_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('slingbow trap', 'Slingbow Trap', 'f37057bd8c944691f76ff9d4e2921a93', 'battle_rule_v1:a3578e249fe8c4729d4574c4d4f3a314', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"combat_state":"attacking","required_keywords":["flying"]},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SlingbowTrap translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('snuff out', 'Snuff Out', 'b5a888a6cfcd7e750e05583aa261194d', 'battle_rule_v1:168dcdc18248bd9b8dcd053f2113a0b4', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_colors":["B"]},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SnuffOut translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thraben exorcism', 'Thraben Exorcism', '249419eda9079699d13711b8ee85aea4', 'battle_rule_v1:1f8ebe2e03b79895b49d9f788b0d9fb8', '{"battle_model_scope":"xmage_exile_target_spell_v1","destination":"exile","effect":"remove_permanent","instant":true,"sorcery":false,"target":"permanent","target_constraints":{"any_of":[{"card_types":["permanent"],"required_subtypes":["spirit"]},{"card_types":["creature"],"required_keywords":["disturb"]},{"card_types":["enchantment"]}]},"xmage_effect_class":"ExileTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThrabenExorcism translated into ManaLoom runtime scope xmage_exile_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vanishing verse', 'Vanishing Verse', '229f07c3ad92861e1368799937b30050', 'battle_rule_v1:ecdba7e71dfb810694c78fd7809fa855', '{"battle_model_scope":"xmage_exile_target_spell_v1","destination":"exile","effect":"remove_permanent","instant":true,"sorcery":false,"target":"permanent","target_constraints":{"card_types":["permanent"],"color_count_exact":1},"xmage_effect_class":"ExileTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VanishingVerse translated into ManaLoom runtime scope xmage_exile_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
