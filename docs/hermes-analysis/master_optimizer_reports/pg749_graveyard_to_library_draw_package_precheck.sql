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
