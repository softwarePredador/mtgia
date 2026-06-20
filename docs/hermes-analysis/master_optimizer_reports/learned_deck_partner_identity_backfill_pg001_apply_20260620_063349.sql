-- PG-001: Partner/background identity metadata backfill.
-- Source artifact: docs/hermes-analysis/master_optimizer_reports/learned_deck_partner_identity_backfill_plan_20260620_005219.json
-- Generated: 2026-06-20 06:33:49 -0300
-- Scope: commander_learned_decks.metadata only, expected rows: 10.
-- Execute only after explicit Rafael/Auditor Central approval.

\set ON_ERROR_STOP on
BEGIN;

CREATE TEMP TABLE pg001_partner_identity_expected (
    id uuid PRIMARY KEY,
    source_ref text NOT NULL,
    new_metadata jsonb NOT NULL
) ON COMMIT DROP;

INSERT INTO pg001_partner_identity_expected (id, source_ref, new_metadata)
VALUES
  ('0d9058af-51f1-4e2c-9dfa-d813880ae91c'::uuid, 'learned_deck:112', '{"board_wipe_count":0,"combined_commander_color_identity":["G","R","U","W"],"commander_identity_model":{"base_color_identity":["R","W"],"combined_color_identity":["G","R","U","W"],"declared_deck_name":"Akiri, Line-Slinger + Thrasios, Triton Hero","identity_components":[{"color_identity":["G","U"],"name":"Thrasios, Triton Hero","source":"deck_name_commander_component"}],"primary_commander_name":"Akiri, Line-Slinger","requires_first_class_persistence":true,"source":"deck_name_commander_component","status":"combined_identity_inferred"},"draw_count":0,"engine_count":0,"partner_identity_backfill":{"mode":"dry_run_plan_only","requires_explicit_postgresql_mutation_approval":true,"source":"learned_deck_partner_identity_inference_2026_06_20","source_ref":"learned_deck:112"},"partner_identity_candidates":[{"color_identity":["G","U"],"name":"Thrasios, Triton Hero","reason":"deck_name_commander_component"}],"protection_count":0,"ramp_count":0,"recursion_count":0,"removal_count":0,"total_lands":0,"tutor_count":0,"wincon_count":0}'::jsonb),
  ('b8221a6b-af2b-4f7e-89c3-cea07e2d071f'::uuid, 'learned_deck:93', '{"board_wipe_count":0,"combined_commander_color_identity":["B","R","W"],"commander_identity_model":{"base_color_identity":["R"],"combined_color_identity":["B","R","W"],"declared_deck_name":"Dargo, the Shipwrecker + Tymna the Weaver","identity_components":[{"color_identity":["B","W"],"name":"Tymna the Weaver","source":"deck_name_commander_component"}],"primary_commander_name":"Dargo, the Shipwrecker","requires_first_class_persistence":true,"source":"deck_name_commander_component","status":"combined_identity_inferred"},"draw_count":0,"engine_count":0,"partner_identity_backfill":{"mode":"dry_run_plan_only","requires_explicit_postgresql_mutation_approval":true,"source":"learned_deck_partner_identity_inference_2026_06_20","source_ref":"learned_deck:93"},"partner_identity_candidates":[{"color_identity":["B","W"],"name":"Tymna the Weaver","reason":"deck_name_commander_component"}],"protection_count":0,"ramp_count":0,"recursion_count":0,"removal_count":0,"total_lands":0,"tutor_count":0,"wincon_count":0}'::jsonb),
  ('7a7001a1-aebe-4963-830f-31031f92c105'::uuid, 'learned_deck:110', '{"board_wipe_count":0,"combined_commander_color_identity":["R","U","W"],"commander_identity_model":{"base_color_identity":["U","W"],"combined_color_identity":["R","U","W"],"declared_deck_name":"Ishai, Ojutai Dragonspeaker + Rograkh, Son of Rohgahh","identity_components":[{"color_identity":["R"],"name":"Rograkh, Son of Rohgahh","source":"deck_name_commander_component"}],"primary_commander_name":"Ishai, Ojutai Dragonspeaker","requires_first_class_persistence":true,"source":"deck_name_commander_component","status":"combined_identity_inferred"},"draw_count":0,"engine_count":0,"partner_identity_backfill":{"mode":"dry_run_plan_only","requires_explicit_postgresql_mutation_approval":true,"source":"learned_deck_partner_identity_inference_2026_06_20","source_ref":"learned_deck:110"},"partner_identity_candidates":[{"color_identity":["R"],"name":"Rograkh, Son of Rohgahh","reason":"deck_name_commander_component"}],"protection_count":0,"ramp_count":0,"recursion_count":0,"removal_count":0,"total_lands":0,"tutor_count":0,"wincon_count":0}'::jsonb),
  ('de69e590-452b-4e2d-bc64-df7145a930f3'::uuid, 'learned_deck:100', '{"board_wipe_count":0,"combined_commander_color_identity":["B","R","W"],"commander_identity_model":{"base_color_identity":["R"],"combined_color_identity":["B","R","W"],"declared_deck_name":"Jeska, Thrice Reborn + Tymna the Weaver","identity_components":[{"color_identity":["B","W"],"name":"Tymna the Weaver","source":"deck_name_commander_component"}],"primary_commander_name":"Jeska, Thrice Reborn","requires_first_class_persistence":true,"source":"deck_name_commander_component","status":"combined_identity_inferred"},"draw_count":0,"engine_count":0,"partner_identity_backfill":{"mode":"dry_run_plan_only","requires_explicit_postgresql_mutation_approval":true,"source":"learned_deck_partner_identity_inference_2026_06_20","source_ref":"learned_deck:100"},"partner_identity_candidates":[{"color_identity":["B","W"],"name":"Tymna the Weaver","reason":"deck_name_commander_component"}],"protection_count":0,"ramp_count":0,"recursion_count":0,"removal_count":0,"total_lands":0,"tutor_count":0,"wincon_count":0}'::jsonb),
  ('421b13ef-c325-42e4-821c-8123dea59d15'::uuid, 'learned_deck:116', '{"board_wipe_count":0,"combined_commander_color_identity":["G","R","U","W"],"commander_identity_model":{"base_color_identity":["U"],"combined_color_identity":["G","R","U","W"],"declared_deck_name":"K-9, Mark I + The Fourteenth Doctor","identity_components":[{"color_identity":["G","R","U","W"],"name":"The Fourteenth Doctor","source":"deck_name_commander_component"}],"primary_commander_name":"K-9, Mark I","requires_first_class_persistence":true,"source":"deck_name_commander_component","status":"combined_identity_inferred"},"draw_count":0,"engine_count":0,"partner_identity_backfill":{"mode":"dry_run_plan_only","requires_explicit_postgresql_mutation_approval":true,"source":"learned_deck_partner_identity_inference_2026_06_20","source_ref":"learned_deck:116"},"partner_identity_candidates":[{"color_identity":["G","R","U","W"],"name":"The Fourteenth Doctor","reason":"deck_name_commander_component"}],"protection_count":0,"ramp_count":0,"recursion_count":0,"removal_count":0,"total_lands":0,"tutor_count":0,"wincon_count":0}'::jsonb),
  ('2d18afa2-561b-4c69-ad89-ce4bfb432770'::uuid, 'learned_deck:173', '{"board_wipe_count":0,"combined_commander_color_identity":["R","U"],"commander_identity_model":{"base_color_identity":["R"],"combined_color_identity":["R","U"],"declared_deck_name":"Krark, the Thumbless + Sakashima of a Thousand Faces","identity_components":[{"color_identity":["U"],"name":"Sakashima of a Thousand Faces // Sakashima of a Thousand Faces","source":"deck_name_commander_component"}],"primary_commander_name":"Krark, the Thumbless","requires_first_class_persistence":true,"source":"deck_name_commander_component","status":"combined_identity_inferred"},"draw_count":0,"engine_count":0,"partner_identity_backfill":{"mode":"dry_run_plan_only","requires_explicit_postgresql_mutation_approval":true,"source":"learned_deck_partner_identity_inference_2026_06_20","source_ref":"learned_deck:173"},"partner_identity_candidates":[{"color_identity":["U"],"name":"Sakashima of a Thousand Faces // Sakashima of a Thousand Faces","reason":"deck_name_commander_component"}],"protection_count":0,"ramp_count":0,"recursion_count":0,"removal_count":0,"total_lands":0,"tutor_count":0,"wincon_count":0}'::jsonb),
  ('367003b1-36f2-42ec-a015-fa605d0a9b97'::uuid, 'learned_deck:89', '{"board_wipe_count":0,"combined_commander_color_identity":["B","R","U","W"],"commander_identity_model":{"base_color_identity":["R","U"],"combined_color_identity":["B","R","U","W"],"declared_deck_name":"Kraum, Ludevic''s Opus + Tymna the Weaver","identity_components":[{"color_identity":["B","W"],"name":"Tymna the Weaver","source":"deck_name_commander_component"}],"primary_commander_name":"Kraum, Ludevic''s Opus","requires_first_class_persistence":true,"source":"deck_name_commander_component","status":"combined_identity_inferred"},"draw_count":0,"engine_count":0,"partner_identity_backfill":{"mode":"dry_run_plan_only","requires_explicit_postgresql_mutation_approval":true,"source":"learned_deck_partner_identity_inference_2026_06_20","source_ref":"learned_deck:89"},"partner_identity_candidates":[{"color_identity":["B","W"],"name":"Tymna the Weaver","reason":"deck_name_commander_component"}],"protection_count":0,"ramp_count":0,"recursion_count":0,"removal_count":0,"total_lands":0,"tutor_count":0,"wincon_count":0}'::jsonb),
  ('5e6d0cbe-6b58-4bbd-8f2f-62aa03bf0cd9'::uuid, 'learned_deck:90', '{"board_wipe_count":0,"combined_commander_color_identity":["B","R","U"],"commander_identity_model":{"base_color_identity":["U"],"combined_color_identity":["B","R","U"],"declared_deck_name":"Malcolm, Keen-Eyed Navigator + Vial Smasher the Fierce","identity_components":[{"color_identity":["B","R"],"name":"Vial Smasher the Fierce","source":"deck_name_commander_component"},{"color_identity":["R"],"name":"Kediss, Emberclaw Familiar","source":"partner_text"}],"primary_commander_name":"Malcolm, Keen-Eyed Navigator","requires_first_class_persistence":true,"source":"mixed_commander_identity_inference","status":"combined_identity_inferred"},"draw_count":0,"engine_count":0,"partner_identity_backfill":{"mode":"dry_run_plan_only","requires_explicit_postgresql_mutation_approval":true,"source":"learned_deck_partner_identity_inference_2026_06_20","source_ref":"learned_deck:90"},"partner_identity_candidates":[{"color_identity":["B","R"],"name":"Vial Smasher the Fierce","reason":"deck_name_commander_component"},{"color_identity":["R"],"name":"Kediss, Emberclaw Familiar","reason":"partner_text"}],"protection_count":0,"ramp_count":0,"recursion_count":0,"removal_count":0,"total_lands":0,"tutor_count":0,"wincon_count":0}'::jsonb),
  ('5242b94b-954e-4a32-abc6-8b5fa2a4cabb'::uuid, 'learned_deck:85', '{"board_wipe_count":0,"combined_commander_color_identity":["B","R","U"],"commander_identity_model":{"base_color_identity":["R"],"combined_color_identity":["B","R","U"],"declared_deck_name":"Rograkh, Son of Rohgahh + Silas Renn, Seeker Adept","identity_components":[{"color_identity":["B","U"],"name":"Silas Renn, Seeker Adept","source":"deck_name_commander_component"}],"primary_commander_name":"Rograkh, Son of Rohgahh","requires_first_class_persistence":true,"source":"deck_name_commander_component","status":"combined_identity_inferred"},"draw_count":0,"engine_count":0,"partner_identity_backfill":{"mode":"dry_run_plan_only","requires_explicit_postgresql_mutation_approval":true,"source":"learned_deck_partner_identity_inference_2026_06_20","source_ref":"learned_deck:85"},"partner_identity_candidates":[{"color_identity":["B","U"],"name":"Silas Renn, Seeker Adept","reason":"deck_name_commander_component"}],"protection_count":0,"ramp_count":0,"recursion_count":0,"removal_count":0,"total_lands":0,"tutor_count":0,"wincon_count":0}'::jsonb),
  ('0e37c8b3-f931-47b9-9eec-7d4b755ccd78'::uuid, 'learned_deck:87', '{"board_wipe_count":0,"combined_commander_color_identity":["G","U","W"],"commander_identity_model":{"base_color_identity":["G","U"],"combined_color_identity":["G","U","W"],"declared_deck_name":"Thrasios, Triton Hero + Yoshimaru, Ever Faithful","identity_components":[{"color_identity":["W"],"name":"Yoshimaru, Ever Faithful","source":"deck_name_commander_component"}],"primary_commander_name":"Thrasios, Triton Hero","requires_first_class_persistence":true,"source":"deck_name_commander_component","status":"combined_identity_inferred"},"draw_count":0,"engine_count":0,"partner_identity_backfill":{"mode":"dry_run_plan_only","requires_explicit_postgresql_mutation_approval":true,"source":"learned_deck_partner_identity_inference_2026_06_20","source_ref":"learned_deck:87"},"partner_identity_candidates":[{"color_identity":["W"],"name":"Yoshimaru, Ever Faithful","reason":"deck_name_commander_component"}],"protection_count":0,"ramp_count":0,"recursion_count":0,"removal_count":0,"total_lands":0,"tutor_count":0,"wincon_count":0}'::jsonb);

DO $$
DECLARE
    expected_count integer;
    matched_count integer;
    needs_update_count integer;
BEGIN
    SELECT count(*) INTO expected_count
    FROM pg001_partner_identity_expected;

    IF expected_count <> 10 THEN
        RAISE EXCEPTION 'PG-001 expected 10 input rows, got %', expected_count;
    END IF;

    SELECT count(*) INTO matched_count
    FROM pg001_partner_identity_expected e
    JOIN commander_learned_decks d
      ON d.id = e.id
     AND d.source_ref = e.source_ref;

    IF matched_count <> 10 THEN
        RAISE EXCEPTION 'PG-001 expected 10 live id/source_ref matches, got %', matched_count;
    END IF;

    SELECT count(*) INTO needs_update_count
    FROM pg001_partner_identity_expected e
    JOIN commander_learned_decks d
      ON d.id = e.id
     AND d.source_ref = e.source_ref
    WHERE d.metadata IS DISTINCT FROM e.new_metadata;

    IF needs_update_count <> 10 THEN
        RAISE EXCEPTION 'PG-001 expected 10 rows needing metadata update, got %', needs_update_count;
    END IF;
END $$;

CREATE TEMP TABLE pg001_partner_identity_updated ON COMMIT DROP AS
WITH updated AS (
    UPDATE commander_learned_decks d
       SET metadata = e.new_metadata
      FROM pg001_partner_identity_expected e
     WHERE d.id = e.id
       AND d.source_ref = e.source_ref
       AND d.metadata IS DISTINCT FROM e.new_metadata
     RETURNING
        d.id::text AS row_id,
        d.source_ref,
        d.commander_name,
        d.deck_name,
        d.metadata -> 'commander_identity_model' ->> 'status' AS identity_status,
        d.metadata -> 'combined_commander_color_identity' AS combined_commander_color_identity,
        d.metadata -> 'partner_identity_backfill' ->> 'source' AS backfill_source
)
SELECT * FROM updated;

DO $$
DECLARE
    updated_count integer;
BEGIN
    SELECT count(*) INTO updated_count
    FROM pg001_partner_identity_updated;

    IF updated_count <> 10 THEN
        RAISE EXCEPTION 'PG-001 expected 10 updated rows, got %', updated_count;
    END IF;
END $$;

TABLE pg001_partner_identity_updated ORDER BY source_ref;

COMMIT;
