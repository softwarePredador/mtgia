-- PG-001 SELECT-only pre-apply validation.
-- Source artifact: docs/hermes-analysis/master_optimizer_reports/learned_deck_partner_identity_backfill_plan_20260620_005219.json
-- Expected before apply: matched_rows=10, needs_update_rows=10, already_persisted_rows=0.

WITH expected(id, source_ref, commander_name, expected_model) AS (
    VALUES
  ('0d9058af-51f1-4e2c-9dfa-d813880ae91c'::uuid, 'learned_deck:112', 'Akiri, Line-Slinger', '{"base_color_identity":["R","W"],"combined_color_identity":["G","R","U","W"],"declared_deck_name":"Akiri, Line-Slinger + Thrasios, Triton Hero","identity_components":[{"color_identity":["G","U"],"name":"Thrasios, Triton Hero","source":"deck_name_commander_component"}],"primary_commander_name":"Akiri, Line-Slinger","requires_first_class_persistence":true,"source":"deck_name_commander_component","status":"combined_identity_inferred"}'::jsonb),
  ('b8221a6b-af2b-4f7e-89c3-cea07e2d071f'::uuid, 'learned_deck:93', 'Dargo, the Shipwrecker', '{"base_color_identity":["R"],"combined_color_identity":["B","R","W"],"declared_deck_name":"Dargo, the Shipwrecker + Tymna the Weaver","identity_components":[{"color_identity":["B","W"],"name":"Tymna the Weaver","source":"deck_name_commander_component"}],"primary_commander_name":"Dargo, the Shipwrecker","requires_first_class_persistence":true,"source":"deck_name_commander_component","status":"combined_identity_inferred"}'::jsonb),
  ('7a7001a1-aebe-4963-830f-31031f92c105'::uuid, 'learned_deck:110', 'Ishai, Ojutai Dragonspeaker', '{"base_color_identity":["U","W"],"combined_color_identity":["R","U","W"],"declared_deck_name":"Ishai, Ojutai Dragonspeaker + Rograkh, Son of Rohgahh","identity_components":[{"color_identity":["R"],"name":"Rograkh, Son of Rohgahh","source":"deck_name_commander_component"}],"primary_commander_name":"Ishai, Ojutai Dragonspeaker","requires_first_class_persistence":true,"source":"deck_name_commander_component","status":"combined_identity_inferred"}'::jsonb),
  ('de69e590-452b-4e2d-bc64-df7145a930f3'::uuid, 'learned_deck:100', 'Jeska, Thrice Reborn', '{"base_color_identity":["R"],"combined_color_identity":["B","R","W"],"declared_deck_name":"Jeska, Thrice Reborn + Tymna the Weaver","identity_components":[{"color_identity":["B","W"],"name":"Tymna the Weaver","source":"deck_name_commander_component"}],"primary_commander_name":"Jeska, Thrice Reborn","requires_first_class_persistence":true,"source":"deck_name_commander_component","status":"combined_identity_inferred"}'::jsonb),
  ('421b13ef-c325-42e4-821c-8123dea59d15'::uuid, 'learned_deck:116', 'K-9, Mark I', '{"base_color_identity":["U"],"combined_color_identity":["G","R","U","W"],"declared_deck_name":"K-9, Mark I + The Fourteenth Doctor","identity_components":[{"color_identity":["G","R","U","W"],"name":"The Fourteenth Doctor","source":"deck_name_commander_component"}],"primary_commander_name":"K-9, Mark I","requires_first_class_persistence":true,"source":"deck_name_commander_component","status":"combined_identity_inferred"}'::jsonb),
  ('2d18afa2-561b-4c69-ad89-ce4bfb432770'::uuid, 'learned_deck:173', 'Krark, the Thumbless', '{"base_color_identity":["R"],"combined_color_identity":["R","U"],"declared_deck_name":"Krark, the Thumbless + Sakashima of a Thousand Faces","identity_components":[{"color_identity":["U"],"name":"Sakashima of a Thousand Faces // Sakashima of a Thousand Faces","source":"deck_name_commander_component"}],"primary_commander_name":"Krark, the Thumbless","requires_first_class_persistence":true,"source":"deck_name_commander_component","status":"combined_identity_inferred"}'::jsonb),
  ('367003b1-36f2-42ec-a015-fa605d0a9b97'::uuid, 'learned_deck:89', 'Kraum, Ludevic''s Opus', '{"base_color_identity":["R","U"],"combined_color_identity":["B","R","U","W"],"declared_deck_name":"Kraum, Ludevic''s Opus + Tymna the Weaver","identity_components":[{"color_identity":["B","W"],"name":"Tymna the Weaver","source":"deck_name_commander_component"}],"primary_commander_name":"Kraum, Ludevic''s Opus","requires_first_class_persistence":true,"source":"deck_name_commander_component","status":"combined_identity_inferred"}'::jsonb),
  ('5e6d0cbe-6b58-4bbd-8f2f-62aa03bf0cd9'::uuid, 'learned_deck:90', 'Malcolm, Keen-Eyed Navigator', '{"base_color_identity":["U"],"combined_color_identity":["B","R","U"],"declared_deck_name":"Malcolm, Keen-Eyed Navigator + Vial Smasher the Fierce","identity_components":[{"color_identity":["B","R"],"name":"Vial Smasher the Fierce","source":"deck_name_commander_component"},{"color_identity":["R"],"name":"Kediss, Emberclaw Familiar","source":"partner_text"}],"primary_commander_name":"Malcolm, Keen-Eyed Navigator","requires_first_class_persistence":true,"source":"mixed_commander_identity_inference","status":"combined_identity_inferred"}'::jsonb),
  ('5242b94b-954e-4a32-abc6-8b5fa2a4cabb'::uuid, 'learned_deck:85', 'Rograkh, Son of Rohgahh', '{"base_color_identity":["R"],"combined_color_identity":["B","R","U"],"declared_deck_name":"Rograkh, Son of Rohgahh + Silas Renn, Seeker Adept","identity_components":[{"color_identity":["B","U"],"name":"Silas Renn, Seeker Adept","source":"deck_name_commander_component"}],"primary_commander_name":"Rograkh, Son of Rohgahh","requires_first_class_persistence":true,"source":"deck_name_commander_component","status":"combined_identity_inferred"}'::jsonb),
  ('0e37c8b3-f931-47b9-9eec-7d4b755ccd78'::uuid, 'learned_deck:87', 'Thrasios, Triton Hero', '{"base_color_identity":["G","U"],"combined_color_identity":["G","U","W"],"declared_deck_name":"Thrasios, Triton Hero + Yoshimaru, Ever Faithful","identity_components":[{"color_identity":["W"],"name":"Yoshimaru, Ever Faithful","source":"deck_name_commander_component"}],"primary_commander_name":"Thrasios, Triton Hero","requires_first_class_persistence":true,"source":"deck_name_commander_component","status":"combined_identity_inferred"}'::jsonb)
), live AS (
    SELECT
        e.source_ref,
        e.id::text AS row_id,
        e.commander_name AS expected_commander_name,
        d.commander_name AS live_commander_name,
        d.deck_name,
        d.id IS NOT NULL AS matched_live_row,
        d.metadata ? 'commander_identity_model' AS current_has_commander_identity_model,
        (d.metadata -> 'commander_identity_model') = e.expected_model AS already_persisted,
        (d.metadata -> 'commander_identity_model') IS DISTINCT FROM e.expected_model AS needs_update
    FROM expected e
    LEFT JOIN commander_learned_decks d
      ON d.id = e.id
     AND d.source_ref = e.source_ref
)
SELECT
    count(*) AS expected_rows,
    count(*) FILTER (WHERE matched_live_row) AS matched_rows,
    count(*) FILTER (WHERE needs_update) AS needs_update_rows,
    count(*) FILTER (WHERE already_persisted) AS already_persisted_rows,
    bool_and(matched_live_row) AS all_rows_matched,
    bool_and(needs_update) AS all_rows_need_update
FROM live;

WITH expected(id, source_ref, commander_name, expected_model) AS (
    VALUES
  ('0d9058af-51f1-4e2c-9dfa-d813880ae91c'::uuid, 'learned_deck:112', 'Akiri, Line-Slinger', '{"base_color_identity":["R","W"],"combined_color_identity":["G","R","U","W"],"declared_deck_name":"Akiri, Line-Slinger + Thrasios, Triton Hero","identity_components":[{"color_identity":["G","U"],"name":"Thrasios, Triton Hero","source":"deck_name_commander_component"}],"primary_commander_name":"Akiri, Line-Slinger","requires_first_class_persistence":true,"source":"deck_name_commander_component","status":"combined_identity_inferred"}'::jsonb),
  ('b8221a6b-af2b-4f7e-89c3-cea07e2d071f'::uuid, 'learned_deck:93', 'Dargo, the Shipwrecker', '{"base_color_identity":["R"],"combined_color_identity":["B","R","W"],"declared_deck_name":"Dargo, the Shipwrecker + Tymna the Weaver","identity_components":[{"color_identity":["B","W"],"name":"Tymna the Weaver","source":"deck_name_commander_component"}],"primary_commander_name":"Dargo, the Shipwrecker","requires_first_class_persistence":true,"source":"deck_name_commander_component","status":"combined_identity_inferred"}'::jsonb),
  ('7a7001a1-aebe-4963-830f-31031f92c105'::uuid, 'learned_deck:110', 'Ishai, Ojutai Dragonspeaker', '{"base_color_identity":["U","W"],"combined_color_identity":["R","U","W"],"declared_deck_name":"Ishai, Ojutai Dragonspeaker + Rograkh, Son of Rohgahh","identity_components":[{"color_identity":["R"],"name":"Rograkh, Son of Rohgahh","source":"deck_name_commander_component"}],"primary_commander_name":"Ishai, Ojutai Dragonspeaker","requires_first_class_persistence":true,"source":"deck_name_commander_component","status":"combined_identity_inferred"}'::jsonb),
  ('de69e590-452b-4e2d-bc64-df7145a930f3'::uuid, 'learned_deck:100', 'Jeska, Thrice Reborn', '{"base_color_identity":["R"],"combined_color_identity":["B","R","W"],"declared_deck_name":"Jeska, Thrice Reborn + Tymna the Weaver","identity_components":[{"color_identity":["B","W"],"name":"Tymna the Weaver","source":"deck_name_commander_component"}],"primary_commander_name":"Jeska, Thrice Reborn","requires_first_class_persistence":true,"source":"deck_name_commander_component","status":"combined_identity_inferred"}'::jsonb),
  ('421b13ef-c325-42e4-821c-8123dea59d15'::uuid, 'learned_deck:116', 'K-9, Mark I', '{"base_color_identity":["U"],"combined_color_identity":["G","R","U","W"],"declared_deck_name":"K-9, Mark I + The Fourteenth Doctor","identity_components":[{"color_identity":["G","R","U","W"],"name":"The Fourteenth Doctor","source":"deck_name_commander_component"}],"primary_commander_name":"K-9, Mark I","requires_first_class_persistence":true,"source":"deck_name_commander_component","status":"combined_identity_inferred"}'::jsonb),
  ('2d18afa2-561b-4c69-ad89-ce4bfb432770'::uuid, 'learned_deck:173', 'Krark, the Thumbless', '{"base_color_identity":["R"],"combined_color_identity":["R","U"],"declared_deck_name":"Krark, the Thumbless + Sakashima of a Thousand Faces","identity_components":[{"color_identity":["U"],"name":"Sakashima of a Thousand Faces // Sakashima of a Thousand Faces","source":"deck_name_commander_component"}],"primary_commander_name":"Krark, the Thumbless","requires_first_class_persistence":true,"source":"deck_name_commander_component","status":"combined_identity_inferred"}'::jsonb),
  ('367003b1-36f2-42ec-a015-fa605d0a9b97'::uuid, 'learned_deck:89', 'Kraum, Ludevic''s Opus', '{"base_color_identity":["R","U"],"combined_color_identity":["B","R","U","W"],"declared_deck_name":"Kraum, Ludevic''s Opus + Tymna the Weaver","identity_components":[{"color_identity":["B","W"],"name":"Tymna the Weaver","source":"deck_name_commander_component"}],"primary_commander_name":"Kraum, Ludevic''s Opus","requires_first_class_persistence":true,"source":"deck_name_commander_component","status":"combined_identity_inferred"}'::jsonb),
  ('5e6d0cbe-6b58-4bbd-8f2f-62aa03bf0cd9'::uuid, 'learned_deck:90', 'Malcolm, Keen-Eyed Navigator', '{"base_color_identity":["U"],"combined_color_identity":["B","R","U"],"declared_deck_name":"Malcolm, Keen-Eyed Navigator + Vial Smasher the Fierce","identity_components":[{"color_identity":["B","R"],"name":"Vial Smasher the Fierce","source":"deck_name_commander_component"},{"color_identity":["R"],"name":"Kediss, Emberclaw Familiar","source":"partner_text"}],"primary_commander_name":"Malcolm, Keen-Eyed Navigator","requires_first_class_persistence":true,"source":"mixed_commander_identity_inference","status":"combined_identity_inferred"}'::jsonb),
  ('5242b94b-954e-4a32-abc6-8b5fa2a4cabb'::uuid, 'learned_deck:85', 'Rograkh, Son of Rohgahh', '{"base_color_identity":["R"],"combined_color_identity":["B","R","U"],"declared_deck_name":"Rograkh, Son of Rohgahh + Silas Renn, Seeker Adept","identity_components":[{"color_identity":["B","U"],"name":"Silas Renn, Seeker Adept","source":"deck_name_commander_component"}],"primary_commander_name":"Rograkh, Son of Rohgahh","requires_first_class_persistence":true,"source":"deck_name_commander_component","status":"combined_identity_inferred"}'::jsonb),
  ('0e37c8b3-f931-47b9-9eec-7d4b755ccd78'::uuid, 'learned_deck:87', 'Thrasios, Triton Hero', '{"base_color_identity":["G","U"],"combined_color_identity":["G","U","W"],"declared_deck_name":"Thrasios, Triton Hero + Yoshimaru, Ever Faithful","identity_components":[{"color_identity":["W"],"name":"Yoshimaru, Ever Faithful","source":"deck_name_commander_component"}],"primary_commander_name":"Thrasios, Triton Hero","requires_first_class_persistence":true,"source":"deck_name_commander_component","status":"combined_identity_inferred"}'::jsonb)
)
SELECT
    e.source_ref,
    e.id::text AS row_id,
    e.commander_name AS expected_commander_name,
    d.commander_name AS live_commander_name,
    d.deck_name,
    d.metadata ? 'commander_identity_model' AS current_has_commander_identity_model,
    (d.metadata -> 'commander_identity_model') IS DISTINCT FROM e.expected_model AS needs_update
FROM expected e
LEFT JOIN commander_learned_decks d
  ON d.id = e.id
 AND d.source_ref = e.source_ref
ORDER BY e.source_ref;
