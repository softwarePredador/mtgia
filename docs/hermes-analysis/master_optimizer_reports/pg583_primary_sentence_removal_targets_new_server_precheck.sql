WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('assassin''s blade', 'Assassin''s Blade', '3c76ec715b342aac290df549b825664f', 'battle_rule_v1:747d0d1801b1a202b69db07525c9573c', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"combat_state":"attacking","exclude_colors":["B"]},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AssassinsBlade translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dark withering', 'Dark Withering', 'd5c7b1f417a26c6f3eb976d4adfb49ff', 'battle_rule_v1:168dcdc18248bd9b8dcd053f2113a0b4', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_colors":["B"]},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DarkWithering translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('death rattle', 'Death Rattle', '3d4cadad97a03d6659f1fe381ef8feed', 'battle_rule_v1:d7e45a943a889937ffa67d07f5b07b1e', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_colors":["G"]},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DeathRattle translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('eightfold maze', 'Eightfold Maze', '690ca0334f9961796edfe77df82148d9', 'battle_rule_v1:ae301b41d5999917d4bab570b5be6e4c', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"combat_state":"attacking"},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EightfoldMaze translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('expunge', 'Expunge', 'c3f856f283074bd20c4c6ae484dedfe0', 'battle_rule_v1:9811339b3ee6bf8bf1a584db8dfd5015', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_card_types":["artifact"],"exclude_colors":["B"]},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Expunge translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('just fate', 'Just Fate', '690ca0334f9961796edfe77df82148d9', 'battle_rule_v1:ae301b41d5999917d4bab570b5be6e4c', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"combat_state":"attacking"},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JustFate translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('murderous compulsion', 'Murderous Compulsion', '7049ca97d618808903e8523d3f67dafb', 'battle_rule_v1:97607a657274b25a6d4734d2bc4cbf97', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"],"tapped_state":"tapped"},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MurderousCompulsion translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('protective response', 'Protective Response', '045d82faf84d613c18cebfa0a09db559', 'battle_rule_v1:b13effdee2fe1313d4f6d0d3cc6f47fe', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"combat_state":"attacking_or_blocking"},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ProtectiveResponse translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sheer drop', 'Sheer Drop', '9ae8efd77d2b65991921b73689bc27b1', 'battle_rule_v1:97607a657274b25a6d4734d2bc4cbf97', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"],"tapped_state":"tapped"},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SheerDrop translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('shoot down', 'Shoot Down', '7c8c39bfd8d3bb29ec8d702a5d278474', 'battle_rule_v1:c2b9fb8b06fde05a28b39336f43d2a15', '{"battle_model_scope":"xmage_exile_target_spell_v1","destination":"exile","effect":"remove_permanent","instant":false,"sorcery":true,"target":"permanent","target_constraints":{"any_of":[{"card_types":["artifact"]},{"card_types":["enchantment"]},{"card_types":["creature"],"required_keywords":["flying"]}]},"xmage_effect_class":"ExileTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ShootDown translated into ManaLoom runtime scope xmage_exile_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('slaughter', 'Slaughter', '2daa1c7f401001b36b87fe474b87763f', 'battle_rule_v1:168dcdc18248bd9b8dcd053f2113a0b4', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_colors":["B"]},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Slaughter translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
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
  LEFT JOIN public.cards c
    ON (
         lower(c.name) = p.normalized_name
         OR split_part(lower(c.name), ' // ', 1) = p.normalized_name
       )
   AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
),
target_cards AS (
  SELECT
    normalized_name,
    card_name,
    oracle_hash,
    count(card_id) AS target_card_rows,
    min(card_id::text)::uuid AS canonical_card_id,
    min(db_card_name) AS canonical_card_name
  FROM matched_cards
  GROUP BY normalized_name, card_name, oracle_hash
),
rule_rows AS (
  SELECT p.normalized_name, count(r.*) AS existing_rule_rows
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
  GROUP BY p.normalized_name
),
expected_rows AS (
  SELECT p.normalized_name, count(r.*) AS expected_rule_rows_before
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key = p.logical_rule_key
  GROUP BY p.normalized_name
),
shadow_rows AS (
  SELECT p.normalized_name, count(r.*) AS would_deprecate_shadow_rows
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key <> p.logical_rule_key
   AND r.review_status NOT IN ('deprecated', 'rejected')
   AND r.execution_status <> 'disabled'
  GROUP BY p.normalized_name
)
SELECT
  p.card_name,
  p.normalized_name,
  p.oracle_hash,
  p.logical_rule_key,
  p.shadow_handling,
  tc.target_card_rows,
  tc.canonical_card_id,
  rr.existing_rule_rows,
  er.expected_rule_rows_before,
  sr.would_deprecate_shadow_rows
FROM proposed p
JOIN target_cards tc USING (normalized_name, card_name, oracle_hash)
JOIN rule_rows rr USING (normalized_name)
JOIN expected_rows er USING (normalized_name)
JOIN shadow_rows sr USING (normalized_name)
ORDER BY p.card_name;
