BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg373_destroy_draw_spell_wave_pg373_destroy_draw_spell_w AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('aura blast', 'bright reprisal', 'implode', 'mirrodin avenged', 'slice in twain', 'smash', 'you are already dead')
   OR normalized_name LIKE 'aura blast // %'
   OR normalized_name LIKE 'bright reprisal // %'
   OR normalized_name LIKE 'implode // %'
   OR normalized_name LIKE 'mirrodin avenged // %'
   OR normalized_name LIKE 'slice in twain // %'
   OR normalized_name LIKE 'smash // %'
   OR normalized_name LIKE 'you are already dead // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
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
    ('aura blast', 'Aura Blast', 'a103ff2d47c77789ba5dba40890f1006', 'battle_rule_v1:882044d5cca2e497c0255b50a8414f24', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_permanent","target":"enchantment","target_constraints":{"card_types":["enchantment"]},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_destroy_target_and_draw_card_spell_v1","count":1,"destination":"graveyard","draw_count":1,"effect":"composite_resolution","instant":true,"sorcery":false,"target":"enchantment","target_constraints":{"card_types":["enchantment"]},"xmage_effect_classes":["DestroyTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"enchantment","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AuraBlast translated into ManaLoom runtime scope xmage_destroy_target_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('bright reprisal', 'Bright Reprisal', 'd4db5d6620900693583e80628077ff72', 'battle_rule_v1:c588fddfac957f3daa6f7b99a92df935', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"],"combat_state":"attacking"},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_destroy_target_and_draw_card_spell_v1","count":1,"destination":"graveyard","draw_count":1,"effect":"composite_resolution","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"combat_state":"attacking"},"xmage_effect_classes":["DestroyTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BrightReprisal translated into ManaLoom runtime scope xmage_destroy_target_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('implode', 'Implode', 'deb5d7aca0d3316f355df11672aa70fe', 'battle_rule_v1:9b6316a79499775b2b9207ed323cdd38', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_permanent","target":"land","target_constraints":{"card_types":["land"]},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_destroy_target_and_draw_card_spell_v1","count":1,"destination":"graveyard","draw_count":1,"effect":"composite_resolution","instant":false,"sorcery":true,"target":"land","target_constraints":{"card_types":["land"]},"xmage_effect_classes":["DestroyTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"land"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Implode translated into ManaLoom runtime scope xmage_destroy_target_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mirrodin avenged', 'Mirrodin Avenged', '22275969fd90ae4a70fe5d235458d188', 'battle_rule_v1:5cffb48098079353c7164f5ee7d6151d', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_destroy_target_and_draw_card_spell_v1","count":1,"destination":"graveyard","draw_count":1,"effect":"composite_resolution","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DestroyTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MirrodinAvenged translated into ManaLoom runtime scope xmage_destroy_target_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('slice in twain', 'Slice in Twain', '2202090348cf3c91e4ccec3d7ef1a26c', 'battle_rule_v1:dda8865d7606fcb23fa6883b24e5c670', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_permanent","target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"]},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_destroy_target_and_draw_card_spell_v1","count":1,"destination":"graveyard","draw_count":1,"effect":"composite_resolution","instant":true,"sorcery":false,"target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"]},"xmage_effect_classes":["DestroyTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"artifact_or_enchantment","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SliceInTwain translated into ManaLoom runtime scope xmage_destroy_target_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('smash', 'Smash', '855d8ae08ec6c7111304d24989b8193d', 'battle_rule_v1:fd27a8b7b3825c3fb135babff6476758', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_permanent","target":"artifact","target_constraints":{"card_types":["artifact"]},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_destroy_target_and_draw_card_spell_v1","count":1,"destination":"graveyard","draw_count":1,"effect":"composite_resolution","instant":true,"sorcery":false,"target":"artifact","target_constraints":{"card_types":["artifact"]},"xmage_effect_classes":["DestroyTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"artifact","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Smash translated into ManaLoom runtime scope xmage_destroy_target_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('you are already dead', 'You Are Already Dead', '22275969fd90ae4a70fe5d235458d188', 'battle_rule_v1:5cffb48098079353c7164f5ee7d6151d', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_destroy_target_and_draw_card_spell_v1","count":1,"destination":"graveyard","draw_count":1,"effect":"composite_resolution","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DestroyTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class YouAreAlreadyDead translated into ManaLoom runtime scope xmage_destroy_target_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
