BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg749_graveyard_to_library_draw_new_serv_20260711_074910 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('footbottom feast', 'forever young', 'frantic salvage', 'gravepurge')
   OR normalized_name LIKE 'footbottom feast // %'
   OR normalized_name LIKE 'forever young // %'
   OR normalized_name LIKE 'frantic salvage // %'
   OR normalized_name LIKE 'gravepurge // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('footbottom feast', 'Footbottom Feast', 'f791d7398b9442c9f4c31df79ce47a9e', 'battle_rule_v1:e3ed1b12cc00fa6bc40178e3489d8435', '{"_composite_rule_components":[{"any_number_targets":true,"battle_model_scope":"xmage_put_target_graveyard_card_on_library_spell_v1","compose_on_resolution":true,"count":99,"destination":"library_top","effect":"recursion","graveyard_to_library_any_number_targets":true,"graveyard_to_library_destination":"library_top","graveyard_to_library_prioritize_draw":true,"graveyard_to_library_target":"creature","graveyard_to_library_target_count":99,"graveyard_to_library_up_to_count":true,"library_controller":"self","target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","up_to_count":true,"xmage_effect_class":"PutOnLibraryTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"draw_count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"any_number_targets":true,"battle_model_scope":"xmage_put_graveyard_cards_on_library_then_draw_spell_v1","count":99,"destination":"library_top","draw_after_graveyard_to_library":true,"draw_after_graveyard_to_library_count":1,"draw_count":1,"effect":"recursion","graveyard_to_library_any_number_targets":true,"graveyard_to_library_destination":"library_top","graveyard_to_library_prioritize_draw":true,"graveyard_to_library_target":"creature","graveyard_to_library_target_count":99,"graveyard_to_library_up_to_count":true,"instant":true,"library_controller":"self","resolution_order":"graveyard_to_library_then_draw","sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","up_to_count":true,"xmage_effect_classes":["PutOnLibraryTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"engine","effect":"recursion","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FootbottomFeast translated into ManaLoom runtime scope xmage_put_graveyard_cards_on_library_then_draw_spell_v1. This row is package-ready only because the source signature is a narrow spell that puts graveyard cards on top of library then draws with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('forever young', 'Forever Young', 'f791d7398b9442c9f4c31df79ce47a9e', 'battle_rule_v1:6f8926cac507f9b2d8cdd14673f03e48', '{"_composite_rule_components":[{"any_number_targets":true,"battle_model_scope":"xmage_put_target_graveyard_card_on_library_spell_v1","compose_on_resolution":true,"count":99,"destination":"library_top","effect":"recursion","graveyard_to_library_any_number_targets":true,"graveyard_to_library_destination":"library_top","graveyard_to_library_prioritize_draw":true,"graveyard_to_library_target":"creature","graveyard_to_library_target_count":99,"graveyard_to_library_up_to_count":true,"library_controller":"self","target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","up_to_count":true,"xmage_effect_class":"PutOnLibraryTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"draw_count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"any_number_targets":true,"battle_model_scope":"xmage_put_graveyard_cards_on_library_then_draw_spell_v1","count":99,"destination":"library_top","draw_after_graveyard_to_library":true,"draw_after_graveyard_to_library_count":1,"draw_count":1,"effect":"recursion","graveyard_to_library_any_number_targets":true,"graveyard_to_library_destination":"library_top","graveyard_to_library_prioritize_draw":true,"graveyard_to_library_target":"creature","graveyard_to_library_target_count":99,"graveyard_to_library_up_to_count":true,"instant":false,"library_controller":"self","resolution_order":"graveyard_to_library_then_draw","sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","up_to_count":true,"xmage_effect_classes":["PutOnLibraryTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"engine","effect":"recursion","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ForeverYoung translated into ManaLoom runtime scope xmage_put_graveyard_cards_on_library_then_draw_spell_v1. This row is package-ready only because the source signature is a narrow spell that puts graveyard cards on top of library then draws with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('frantic salvage', 'Frantic Salvage', 'a421e5ec554a866a7b649c8ea476a14e', 'battle_rule_v1:0963436352b713988a9d733c66f33eb0', '{"_composite_rule_components":[{"any_number_targets":true,"battle_model_scope":"xmage_put_target_graveyard_card_on_library_spell_v1","compose_on_resolution":true,"count":99,"destination":"library_top","effect":"recursion","graveyard_to_library_any_number_targets":true,"graveyard_to_library_destination":"library_top","graveyard_to_library_prioritize_draw":true,"graveyard_to_library_target":"artifact","graveyard_to_library_target_count":99,"graveyard_to_library_up_to_count":true,"library_controller":"self","target":"artifact","target_constraints":{"card_types":["artifact"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","up_to_count":true,"xmage_effect_class":"PutOnLibraryTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"draw_count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"any_number_targets":true,"battle_model_scope":"xmage_put_graveyard_cards_on_library_then_draw_spell_v1","count":99,"destination":"library_top","draw_after_graveyard_to_library":true,"draw_after_graveyard_to_library_count":1,"draw_count":1,"effect":"recursion","graveyard_to_library_any_number_targets":true,"graveyard_to_library_destination":"library_top","graveyard_to_library_prioritize_draw":true,"graveyard_to_library_target":"artifact","graveyard_to_library_target_count":99,"graveyard_to_library_up_to_count":true,"instant":true,"library_controller":"self","resolution_order":"graveyard_to_library_then_draw","sorcery":false,"target":"artifact","target_constraints":{"card_types":["artifact"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","up_to_count":true,"xmage_effect_classes":["PutOnLibraryTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"engine","effect":"recursion","target":"artifact","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FranticSalvage translated into ManaLoom runtime scope xmage_put_graveyard_cards_on_library_then_draw_spell_v1. This row is package-ready only because the source signature is a narrow spell that puts graveyard cards on top of library then draws with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('gravepurge', 'Gravepurge', 'f791d7398b9442c9f4c31df79ce47a9e', 'battle_rule_v1:e3ed1b12cc00fa6bc40178e3489d8435', '{"_composite_rule_components":[{"any_number_targets":true,"battle_model_scope":"xmage_put_target_graveyard_card_on_library_spell_v1","compose_on_resolution":true,"count":99,"destination":"library_top","effect":"recursion","graveyard_to_library_any_number_targets":true,"graveyard_to_library_destination":"library_top","graveyard_to_library_prioritize_draw":true,"graveyard_to_library_target":"creature","graveyard_to_library_target_count":99,"graveyard_to_library_up_to_count":true,"library_controller":"self","target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","up_to_count":true,"xmage_effect_class":"PutOnLibraryTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"draw_count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"any_number_targets":true,"battle_model_scope":"xmage_put_graveyard_cards_on_library_then_draw_spell_v1","count":99,"destination":"library_top","draw_after_graveyard_to_library":true,"draw_after_graveyard_to_library_count":1,"draw_count":1,"effect":"recursion","graveyard_to_library_any_number_targets":true,"graveyard_to_library_destination":"library_top","graveyard_to_library_prioritize_draw":true,"graveyard_to_library_target":"creature","graveyard_to_library_target_count":99,"graveyard_to_library_up_to_count":true,"instant":true,"library_controller":"self","resolution_order":"graveyard_to_library_then_draw","sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","up_to_count":true,"xmage_effect_classes":["PutOnLibraryTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"engine","effect":"recursion","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Gravepurge translated into ManaLoom runtime scope xmage_put_graveyard_cards_on_library_then_draw_spell_v1. This row is package-ready only because the source signature is a narrow spell that puts graveyard cards on top of library then draws with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('footbottom feast', 'Footbottom Feast', 'f791d7398b9442c9f4c31df79ce47a9e', 'battle_rule_v1:e3ed1b12cc00fa6bc40178e3489d8435', '{"_composite_rule_components":[{"any_number_targets":true,"battle_model_scope":"xmage_put_target_graveyard_card_on_library_spell_v1","compose_on_resolution":true,"count":99,"destination":"library_top","effect":"recursion","graveyard_to_library_any_number_targets":true,"graveyard_to_library_destination":"library_top","graveyard_to_library_prioritize_draw":true,"graveyard_to_library_target":"creature","graveyard_to_library_target_count":99,"graveyard_to_library_up_to_count":true,"library_controller":"self","target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","up_to_count":true,"xmage_effect_class":"PutOnLibraryTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"draw_count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"any_number_targets":true,"battle_model_scope":"xmage_put_graveyard_cards_on_library_then_draw_spell_v1","count":99,"destination":"library_top","draw_after_graveyard_to_library":true,"draw_after_graveyard_to_library_count":1,"draw_count":1,"effect":"recursion","graveyard_to_library_any_number_targets":true,"graveyard_to_library_destination":"library_top","graveyard_to_library_prioritize_draw":true,"graveyard_to_library_target":"creature","graveyard_to_library_target_count":99,"graveyard_to_library_up_to_count":true,"instant":true,"library_controller":"self","resolution_order":"graveyard_to_library_then_draw","sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","up_to_count":true,"xmage_effect_classes":["PutOnLibraryTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"engine","effect":"recursion","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FootbottomFeast translated into ManaLoom runtime scope xmage_put_graveyard_cards_on_library_then_draw_spell_v1. This row is package-ready only because the source signature is a narrow spell that puts graveyard cards on top of library then draws with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('forever young', 'Forever Young', 'f791d7398b9442c9f4c31df79ce47a9e', 'battle_rule_v1:6f8926cac507f9b2d8cdd14673f03e48', '{"_composite_rule_components":[{"any_number_targets":true,"battle_model_scope":"xmage_put_target_graveyard_card_on_library_spell_v1","compose_on_resolution":true,"count":99,"destination":"library_top","effect":"recursion","graveyard_to_library_any_number_targets":true,"graveyard_to_library_destination":"library_top","graveyard_to_library_prioritize_draw":true,"graveyard_to_library_target":"creature","graveyard_to_library_target_count":99,"graveyard_to_library_up_to_count":true,"library_controller":"self","target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","up_to_count":true,"xmage_effect_class":"PutOnLibraryTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"draw_count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"any_number_targets":true,"battle_model_scope":"xmage_put_graveyard_cards_on_library_then_draw_spell_v1","count":99,"destination":"library_top","draw_after_graveyard_to_library":true,"draw_after_graveyard_to_library_count":1,"draw_count":1,"effect":"recursion","graveyard_to_library_any_number_targets":true,"graveyard_to_library_destination":"library_top","graveyard_to_library_prioritize_draw":true,"graveyard_to_library_target":"creature","graveyard_to_library_target_count":99,"graveyard_to_library_up_to_count":true,"instant":false,"library_controller":"self","resolution_order":"graveyard_to_library_then_draw","sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","up_to_count":true,"xmage_effect_classes":["PutOnLibraryTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"engine","effect":"recursion","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ForeverYoung translated into ManaLoom runtime scope xmage_put_graveyard_cards_on_library_then_draw_spell_v1. This row is package-ready only because the source signature is a narrow spell that puts graveyard cards on top of library then draws with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('frantic salvage', 'Frantic Salvage', 'a421e5ec554a866a7b649c8ea476a14e', 'battle_rule_v1:0963436352b713988a9d733c66f33eb0', '{"_composite_rule_components":[{"any_number_targets":true,"battle_model_scope":"xmage_put_target_graveyard_card_on_library_spell_v1","compose_on_resolution":true,"count":99,"destination":"library_top","effect":"recursion","graveyard_to_library_any_number_targets":true,"graveyard_to_library_destination":"library_top","graveyard_to_library_prioritize_draw":true,"graveyard_to_library_target":"artifact","graveyard_to_library_target_count":99,"graveyard_to_library_up_to_count":true,"library_controller":"self","target":"artifact","target_constraints":{"card_types":["artifact"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","up_to_count":true,"xmage_effect_class":"PutOnLibraryTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"draw_count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"any_number_targets":true,"battle_model_scope":"xmage_put_graveyard_cards_on_library_then_draw_spell_v1","count":99,"destination":"library_top","draw_after_graveyard_to_library":true,"draw_after_graveyard_to_library_count":1,"draw_count":1,"effect":"recursion","graveyard_to_library_any_number_targets":true,"graveyard_to_library_destination":"library_top","graveyard_to_library_prioritize_draw":true,"graveyard_to_library_target":"artifact","graveyard_to_library_target_count":99,"graveyard_to_library_up_to_count":true,"instant":true,"library_controller":"self","resolution_order":"graveyard_to_library_then_draw","sorcery":false,"target":"artifact","target_constraints":{"card_types":["artifact"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","up_to_count":true,"xmage_effect_classes":["PutOnLibraryTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"engine","effect":"recursion","target":"artifact","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FranticSalvage translated into ManaLoom runtime scope xmage_put_graveyard_cards_on_library_then_draw_spell_v1. This row is package-ready only because the source signature is a narrow spell that puts graveyard cards on top of library then draws with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('gravepurge', 'Gravepurge', 'f791d7398b9442c9f4c31df79ce47a9e', 'battle_rule_v1:e3ed1b12cc00fa6bc40178e3489d8435', '{"_composite_rule_components":[{"any_number_targets":true,"battle_model_scope":"xmage_put_target_graveyard_card_on_library_spell_v1","compose_on_resolution":true,"count":99,"destination":"library_top","effect":"recursion","graveyard_to_library_any_number_targets":true,"graveyard_to_library_destination":"library_top","graveyard_to_library_prioritize_draw":true,"graveyard_to_library_target":"creature","graveyard_to_library_target_count":99,"graveyard_to_library_up_to_count":true,"library_controller":"self","target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","up_to_count":true,"xmage_effect_class":"PutOnLibraryTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"draw_count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"any_number_targets":true,"battle_model_scope":"xmage_put_graveyard_cards_on_library_then_draw_spell_v1","count":99,"destination":"library_top","draw_after_graveyard_to_library":true,"draw_after_graveyard_to_library_count":1,"draw_count":1,"effect":"recursion","graveyard_to_library_any_number_targets":true,"graveyard_to_library_destination":"library_top","graveyard_to_library_prioritize_draw":true,"graveyard_to_library_target":"creature","graveyard_to_library_target_count":99,"graveyard_to_library_up_to_count":true,"instant":true,"library_controller":"self","resolution_order":"graveyard_to_library_then_draw","sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","up_to_count":true,"xmage_effect_classes":["PutOnLibraryTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"engine","effect":"recursion","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Gravepurge translated into ManaLoom runtime scope xmage_put_graveyard_cards_on_library_then_draw_spell_v1. This row is package-ready only because the source signature is a narrow spell that puts graveyard cards on top of library then draws with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('footbottom feast', 'Footbottom Feast', 'f791d7398b9442c9f4c31df79ce47a9e', 'battle_rule_v1:e3ed1b12cc00fa6bc40178e3489d8435', '{"_composite_rule_components":[{"any_number_targets":true,"battle_model_scope":"xmage_put_target_graveyard_card_on_library_spell_v1","compose_on_resolution":true,"count":99,"destination":"library_top","effect":"recursion","graveyard_to_library_any_number_targets":true,"graveyard_to_library_destination":"library_top","graveyard_to_library_prioritize_draw":true,"graveyard_to_library_target":"creature","graveyard_to_library_target_count":99,"graveyard_to_library_up_to_count":true,"library_controller":"self","target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","up_to_count":true,"xmage_effect_class":"PutOnLibraryTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"draw_count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"any_number_targets":true,"battle_model_scope":"xmage_put_graveyard_cards_on_library_then_draw_spell_v1","count":99,"destination":"library_top","draw_after_graveyard_to_library":true,"draw_after_graveyard_to_library_count":1,"draw_count":1,"effect":"recursion","graveyard_to_library_any_number_targets":true,"graveyard_to_library_destination":"library_top","graveyard_to_library_prioritize_draw":true,"graveyard_to_library_target":"creature","graveyard_to_library_target_count":99,"graveyard_to_library_up_to_count":true,"instant":true,"library_controller":"self","resolution_order":"graveyard_to_library_then_draw","sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","up_to_count":true,"xmage_effect_classes":["PutOnLibraryTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"engine","effect":"recursion","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FootbottomFeast translated into ManaLoom runtime scope xmage_put_graveyard_cards_on_library_then_draw_spell_v1. This row is package-ready only because the source signature is a narrow spell that puts graveyard cards on top of library then draws with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('forever young', 'Forever Young', 'f791d7398b9442c9f4c31df79ce47a9e', 'battle_rule_v1:6f8926cac507f9b2d8cdd14673f03e48', '{"_composite_rule_components":[{"any_number_targets":true,"battle_model_scope":"xmage_put_target_graveyard_card_on_library_spell_v1","compose_on_resolution":true,"count":99,"destination":"library_top","effect":"recursion","graveyard_to_library_any_number_targets":true,"graveyard_to_library_destination":"library_top","graveyard_to_library_prioritize_draw":true,"graveyard_to_library_target":"creature","graveyard_to_library_target_count":99,"graveyard_to_library_up_to_count":true,"library_controller":"self","target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","up_to_count":true,"xmage_effect_class":"PutOnLibraryTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"draw_count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"any_number_targets":true,"battle_model_scope":"xmage_put_graveyard_cards_on_library_then_draw_spell_v1","count":99,"destination":"library_top","draw_after_graveyard_to_library":true,"draw_after_graveyard_to_library_count":1,"draw_count":1,"effect":"recursion","graveyard_to_library_any_number_targets":true,"graveyard_to_library_destination":"library_top","graveyard_to_library_prioritize_draw":true,"graveyard_to_library_target":"creature","graveyard_to_library_target_count":99,"graveyard_to_library_up_to_count":true,"instant":false,"library_controller":"self","resolution_order":"graveyard_to_library_then_draw","sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","up_to_count":true,"xmage_effect_classes":["PutOnLibraryTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"engine","effect":"recursion","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ForeverYoung translated into ManaLoom runtime scope xmage_put_graveyard_cards_on_library_then_draw_spell_v1. This row is package-ready only because the source signature is a narrow spell that puts graveyard cards on top of library then draws with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('frantic salvage', 'Frantic Salvage', 'a421e5ec554a866a7b649c8ea476a14e', 'battle_rule_v1:0963436352b713988a9d733c66f33eb0', '{"_composite_rule_components":[{"any_number_targets":true,"battle_model_scope":"xmage_put_target_graveyard_card_on_library_spell_v1","compose_on_resolution":true,"count":99,"destination":"library_top","effect":"recursion","graveyard_to_library_any_number_targets":true,"graveyard_to_library_destination":"library_top","graveyard_to_library_prioritize_draw":true,"graveyard_to_library_target":"artifact","graveyard_to_library_target_count":99,"graveyard_to_library_up_to_count":true,"library_controller":"self","target":"artifact","target_constraints":{"card_types":["artifact"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","up_to_count":true,"xmage_effect_class":"PutOnLibraryTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"draw_count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"any_number_targets":true,"battle_model_scope":"xmage_put_graveyard_cards_on_library_then_draw_spell_v1","count":99,"destination":"library_top","draw_after_graveyard_to_library":true,"draw_after_graveyard_to_library_count":1,"draw_count":1,"effect":"recursion","graveyard_to_library_any_number_targets":true,"graveyard_to_library_destination":"library_top","graveyard_to_library_prioritize_draw":true,"graveyard_to_library_target":"artifact","graveyard_to_library_target_count":99,"graveyard_to_library_up_to_count":true,"instant":true,"library_controller":"self","resolution_order":"graveyard_to_library_then_draw","sorcery":false,"target":"artifact","target_constraints":{"card_types":["artifact"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","up_to_count":true,"xmage_effect_classes":["PutOnLibraryTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"engine","effect":"recursion","target":"artifact","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FranticSalvage translated into ManaLoom runtime scope xmage_put_graveyard_cards_on_library_then_draw_spell_v1. This row is package-ready only because the source signature is a narrow spell that puts graveyard cards on top of library then draws with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('gravepurge', 'Gravepurge', 'f791d7398b9442c9f4c31df79ce47a9e', 'battle_rule_v1:e3ed1b12cc00fa6bc40178e3489d8435', '{"_composite_rule_components":[{"any_number_targets":true,"battle_model_scope":"xmage_put_target_graveyard_card_on_library_spell_v1","compose_on_resolution":true,"count":99,"destination":"library_top","effect":"recursion","graveyard_to_library_any_number_targets":true,"graveyard_to_library_destination":"library_top","graveyard_to_library_prioritize_draw":true,"graveyard_to_library_target":"creature","graveyard_to_library_target_count":99,"graveyard_to_library_up_to_count":true,"library_controller":"self","target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","up_to_count":true,"xmage_effect_class":"PutOnLibraryTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"draw_count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"any_number_targets":true,"battle_model_scope":"xmage_put_graveyard_cards_on_library_then_draw_spell_v1","count":99,"destination":"library_top","draw_after_graveyard_to_library":true,"draw_after_graveyard_to_library_count":1,"draw_count":1,"effect":"recursion","graveyard_to_library_any_number_targets":true,"graveyard_to_library_destination":"library_top","graveyard_to_library_prioritize_draw":true,"graveyard_to_library_target":"creature","graveyard_to_library_target_count":99,"graveyard_to_library_up_to_count":true,"instant":true,"library_controller":"self","resolution_order":"graveyard_to_library_then_draw","sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","up_to_count":true,"xmage_effect_classes":["PutOnLibraryTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"engine","effect":"recursion","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Gravepurge translated into ManaLoom runtime scope xmage_put_graveyard_cards_on_library_then_draw_spell_v1. This row is package-ready only because the source signature is a narrow spell that puts graveyard cards on top of library then draws with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
