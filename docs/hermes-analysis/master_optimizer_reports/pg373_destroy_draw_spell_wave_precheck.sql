WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('aura blast', 'Aura Blast', 'a103ff2d47c77789ba5dba40890f1006', 'battle_rule_v1:882044d5cca2e497c0255b50a8414f24', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_permanent","target":"enchantment","target_constraints":{"card_types":["enchantment"]},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_destroy_target_and_draw_card_spell_v1","count":1,"destination":"graveyard","draw_count":1,"effect":"composite_resolution","instant":true,"sorcery":false,"target":"enchantment","target_constraints":{"card_types":["enchantment"]},"xmage_effect_classes":["DestroyTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"enchantment","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AuraBlast translated into ManaLoom runtime scope xmage_destroy_target_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('bright reprisal', 'Bright Reprisal', 'd4db5d6620900693583e80628077ff72', 'battle_rule_v1:c588fddfac957f3daa6f7b99a92df935', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"],"combat_state":"attacking"},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_destroy_target_and_draw_card_spell_v1","count":1,"destination":"graveyard","draw_count":1,"effect":"composite_resolution","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"combat_state":"attacking"},"xmage_effect_classes":["DestroyTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BrightReprisal translated into ManaLoom runtime scope xmage_destroy_target_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('implode', 'Implode', 'deb5d7aca0d3316f355df11672aa70fe', 'battle_rule_v1:9b6316a79499775b2b9207ed323cdd38', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_permanent","target":"land","target_constraints":{"card_types":["land"]},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_destroy_target_and_draw_card_spell_v1","count":1,"destination":"graveyard","draw_count":1,"effect":"composite_resolution","instant":false,"sorcery":true,"target":"land","target_constraints":{"card_types":["land"]},"xmage_effect_classes":["DestroyTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"land"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Implode translated into ManaLoom runtime scope xmage_destroy_target_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mirrodin avenged', 'Mirrodin Avenged', '22275969fd90ae4a70fe5d235458d188', 'battle_rule_v1:5cffb48098079353c7164f5ee7d6151d', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_destroy_target_and_draw_card_spell_v1","count":1,"destination":"graveyard","draw_count":1,"effect":"composite_resolution","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DestroyTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MirrodinAvenged translated into ManaLoom runtime scope xmage_destroy_target_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('slice in twain', 'Slice in Twain', '2202090348cf3c91e4ccec3d7ef1a26c', 'battle_rule_v1:dda8865d7606fcb23fa6883b24e5c670', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_permanent","target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"]},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_destroy_target_and_draw_card_spell_v1","count":1,"destination":"graveyard","draw_count":1,"effect":"composite_resolution","instant":true,"sorcery":false,"target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"]},"xmage_effect_classes":["DestroyTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"artifact_or_enchantment","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SliceInTwain translated into ManaLoom runtime scope xmage_destroy_target_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('smash', 'Smash', '855d8ae08ec6c7111304d24989b8193d', 'battle_rule_v1:fd27a8b7b3825c3fb135babff6476758', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_permanent","target":"artifact","target_constraints":{"card_types":["artifact"]},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_destroy_target_and_draw_card_spell_v1","count":1,"destination":"graveyard","draw_count":1,"effect":"composite_resolution","instant":true,"sorcery":false,"target":"artifact","target_constraints":{"card_types":["artifact"]},"xmage_effect_classes":["DestroyTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"artifact","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Smash translated into ManaLoom runtime scope xmage_destroy_target_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('you are already dead', 'You Are Already Dead', '22275969fd90ae4a70fe5d235458d188', 'battle_rule_v1:5cffb48098079353c7164f5ee7d6151d', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_destroy_target_and_draw_card_spell_v1","count":1,"destination":"graveyard","draw_count":1,"effect":"composite_resolution","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DestroyTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class YouAreAlreadyDead translated into ManaLoom runtime scope xmage_destroy_target_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
