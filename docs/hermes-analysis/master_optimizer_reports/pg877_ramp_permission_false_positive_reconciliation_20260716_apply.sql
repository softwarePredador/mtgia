-- MUTATING. Requires explicit PostgreSQL approval for this execution.
-- PG877 exact remove-only reconciliation for 115 confirmed ramp false positives.
-- Six alternate accelerators are snapshotted and must remain byte-for-byte equal.

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

LOCK TABLE public.cards IN SHARE MODE;
LOCK TABLE public.card_function_tags IN SHARE ROW EXCLUSIVE MODE;
LOCK TABLE public.card_role_scores IN SHARE ROW EXCLUSIVE MODE;
LOCK TABLE public.card_semantic_tags_v2 IN SHARE ROW EXCLUSIVE MODE;
LOCK TABLE public.deck_cards IN SHARE MODE;
LOCK TABLE public.commander_card_usage IN SHARE MODE;

DO $$
BEGIN
  IF to_regclass(
       'manaloom_deploy_audit.pg877_ramp_target_20260716'
     ) IS NOT NULL
     OR to_regclass(
       'manaloom_deploy_audit.pg877_ramp_function_backup_20260716'
     ) IS NOT NULL
     OR to_regclass(
       'manaloom_deploy_audit.pg877_ramp_role_backup_20260716'
     ) IS NOT NULL
     OR to_regclass(
       'manaloom_deploy_audit.pg877_ramp_semantic_backup_20260716'
     ) IS NOT NULL
     OR to_regclass(
       'manaloom_deploy_audit.pg877_ramp_function_untouched_20260716'
     ) IS NOT NULL
     OR to_regclass(
       'manaloom_deploy_audit.pg877_ramp_role_untouched_20260716'
     ) IS NOT NULL
     OR to_regclass(
       'manaloom_deploy_audit.pg877_ramp_semantic_untouched_20260716'
     ) IS NOT NULL
     OR to_regclass(
       'manaloom_deploy_audit.pg877_ramp_preserved_function_20260716'
     ) IS NOT NULL
     OR to_regclass(
       'manaloom_deploy_audit.pg877_ramp_preserved_role_20260716'
     ) IS NOT NULL
     OR to_regclass(
       'manaloom_deploy_audit.pg877_ramp_preserved_semantic_20260716'
     ) IS NOT NULL
     OR to_regclass(
       'manaloom_deploy_audit.pg877_ramp_semantic_post_20260716'
     ) IS NOT NULL
     OR to_regclass(
       'manaloom_deploy_audit.pg877_ramp_deck_refs_20260716'
     ) IS NOT NULL
     OR to_regclass(
       'manaloom_deploy_audit.pg877_ramp_usage_refs_20260716'
     ) IS NOT NULL
  THEN
    RAISE EXCEPTION 'PG877 abort: an audit table already exists';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pg877_ramp_target_20260716 AS
WITH target_manifest(card_id, classification) AS (
  VALUES
    ('0081920d-2cef-47b5-bbba-a62111a90e13'::uuid, 'payment_permission_as_though_any'),
    ('05a823af-8616-4336-86d6-8b7eacfea643'::uuid, 'payment_permission_as_though_any'),
    ('05cae2c8-b7a1-490c-b951-bf064e959637'::uuid, 'payment_permission_as_though_any'),
    ('0b8dcfd5-9162-49e5-aeb2-4e1d6b2c3681'::uuid, 'payment_permission_as_though_any'),
    ('0d25856e-62e4-4887-b7e4-2c3f1bcfb21e'::uuid, 'payment_permission_as_though_any'),
    ('100d22df-ee31-4b1b-857e-925d5c66ff0d'::uuid, 'payment_permission_any_type_can_be_spent'),
    ('10422bbe-1ebc-4c9d-b82a-2458b61b6296'::uuid, 'payment_permission_as_though_any'),
    ('13f2ee9c-d0e3-41f2-8a58-449644dcd2f7'::uuid, 'payment_permission_any_type_can_be_spent'),
    ('1a0ba281-f8f2-4d46-8df6-be1f36670122'::uuid, 'payment_permission_as_though_any'),
    ('1af513c4-f9e8-45ca-b8b7-90694f2bf315'::uuid, 'payment_permission_as_though_any'),
    ('1bbc97cb-5580-43e2-a2cb-ece46befff89'::uuid, 'payment_permission_as_though_any'),
    ('1f4f3600-1e8e-4cd8-aac3-2db1ee78d526'::uuid, 'payment_permission_as_though_any'),
    ('1f5f6383-80e8-42ff-84fb-4a7d804f672d'::uuid, 'commander_color_identity_phrase_collision'),
    ('1fe61c3d-dee1-4b28-b56e-d5db24f6de8a'::uuid, 'payment_permission_as_though_any'),
    ('20591092-86d4-4816-9525-0f5ff1381588'::uuid, 'payment_permission_as_though_any'),
    ('22024f5c-f1f0-4197-a64d-2d6a43f75179'::uuid, 'payment_permission_any_type_can_be_spent'),
    ('226b2a84-dcf7-4846-bb4c-2a89cd4780f5'::uuid, 'commander_color_identity_phrase_collision'),
    ('265d2a18-085f-419a-ab8e-0a56501f5e9f'::uuid, 'commander_color_identity_phrase_collision'),
    ('30c3a084-1606-43a3-add0-7ce977a8e119'::uuid, 'payment_permission_as_though_any'),
    ('30f12182-8d31-427b-b7ba-c1dc365e79b5'::uuid, 'payment_permission_as_though_any'),
    ('32883290-4d41-4c29-b3dd-b4f909a41f8d'::uuid, 'payment_permission_as_though_any'),
    ('36b2718a-ae00-40ba-9d7e-33c0ddd9f6d6'::uuid, 'payment_permission_as_though_any'),
    ('36feab40-368f-4f8a-a25b-538f1225cb26'::uuid, 'payment_permission_as_though_any'),
    ('3a4a3c37-c4b9-42df-9a65-456eed7facec'::uuid, 'payment_permission_as_though_any'),
    ('3cf27bfd-8c91-4553-a7e5-fa7d7f2bcac8'::uuid, 'payment_permission_any_type_can_be_spent'),
    ('3f5062a5-82bc-46db-80a5-96822235a9b0'::uuid, 'payment_permission_as_though_any'),
    ('4017629d-6a62-4623-b1f1-27b6ea23ca7a'::uuid, 'payment_permission_any_type_can_be_spent'),
    ('42f418c4-2014-4cfd-980c-627e6a7f6d1a'::uuid, 'payment_permission_any_type_can_be_spent'),
    ('4430f5d5-b033-4c25-ab21-33c86db3db99'::uuid, 'payment_permission_as_though_any'),
    ('44e93f79-a4c1-4675-a86c-17bd8dd7bea1'::uuid, 'payment_permission_as_though_any'),
    ('44f47ebd-0df5-48a7-98d1-9e70cc7cd4fd'::uuid, 'payment_permission_any_type_can_be_spent'),
    ('476637c9-1e2f-496c-94ca-080f1d0128fc'::uuid, 'payment_permission_any_type_can_be_spent'),
    ('48863140-65dd-4f29-8bcc-77da98009d70'::uuid, 'payment_permission_as_though_any'),
    ('48963ade-4fe9-4a9e-8144-43e8fe0d097c'::uuid, 'payment_permission_any_type_can_be_spent'),
    ('4c210532-8d2a-42bb-96d5-929dc1d44202'::uuid, 'payment_permission_any_type_can_be_spent'),
    ('4e88ae54-cbb2-48a8-8685-baf1cef0b66e'::uuid, 'payment_permission_as_though_any'),
    ('4edafdbd-98f6-41ed-8e35-43ae85919a2d'::uuid, 'payment_permission_as_though_any'),
    ('5079aa6c-a388-42ec-944f-1ac0d1a6890d'::uuid, 'payment_permission_any_type_can_be_spent'),
    ('51cdbed4-af3d-4eb0-bb4f-3acf7249d6af'::uuid, 'commander_color_identity_phrase_collision'),
    ('54756c19-80ab-4b98-bb2a-fb1c9f9a3939'::uuid, 'payment_permission_as_though_any'),
    ('562aaf2d-953b-4e4e-af8d-fbf065913065'::uuid, 'payment_permission_as_though_any'),
    ('5ba89b02-b2df-4aaf-945d-9f9b046153c2'::uuid, 'payment_permission_as_though_any'),
    ('5dfa391d-c253-43ab-bdf6-434be41418a4'::uuid, 'payment_permission_as_though_any'),
    ('5f37e27f-1cf1-482f-a598-e611f8232342'::uuid, 'payment_permission_any_type_can_be_spent'),
    ('62824b5d-dbee-4a41-b64a-e0a82b048479'::uuid, 'payment_permission_spend_any_type'),
    ('62bfcb16-6411-456c-8069-40c096345887'::uuid, 'payment_permission_any_type_can_be_spent'),
    ('64712177-9c42-4789-a16f-9b8409a17f2b'::uuid, 'payment_permission_as_though_any'),
    ('64eb1114-b077-404a-b87a-acdabe53b4db'::uuid, 'payment_permission_as_though_any'),
    ('66aadeaa-2fc2-4ea7-abd2-061477b7804c'::uuid, 'payment_permission_as_though_any'),
    ('67116daa-5295-432a-8950-0d12d2e99207'::uuid, 'payment_permission_as_though_any'),
    ('689c6457-a8ef-4671-b674-ea1b9c12b08a'::uuid, 'payment_permission_any_type_can_be_spent'),
    ('6b75da38-5553-4bbf-be37-5cfed2d7181b'::uuid, 'payment_permission_any_type_can_be_spent'),
    ('6ba8092e-d625-4c95-95e6-2d6396e17472'::uuid, 'payment_permission_as_though_any'),
    ('6c4856b3-d77f-4dc5-bba3-f01fead57abd'::uuid, 'payment_permission_as_though_any'),
    ('6e840afa-2d94-451a-99b9-9ec348552200'::uuid, 'payment_permission_any_type_can_be_spent'),
    ('6fe4f32e-3b60-4b94-bde9-9c39e64ca64b'::uuid, 'payment_permission_any_type_can_be_spent'),
    ('7227892f-0ff0-4d41-a3f4-8afdacfbf0d6'::uuid, 'payment_permission_any_type_can_be_spent'),
    ('779fd6c0-d896-4cd8-8367-ba43b4cfe0ff'::uuid, 'payment_permission_as_though_any'),
    ('7877a75e-e2fb-4b08-8582-70ee237b823d'::uuid, 'commander_color_identity_phrase_collision'),
    ('79b1656d-0368-42f0-a4a6-11cf944cd3c1'::uuid, 'payment_permission_as_though_any'),
    ('7a1177a0-b77c-4ec1-8692-263cc33367f5'::uuid, 'payment_permission_as_though_any'),
    ('7a3ec965-150b-4150-b871-f37f5cf4beca'::uuid, 'commander_color_identity_phrase_collision'),
    ('7b0f0bb7-42e7-482d-8a0d-d964e592d3b2'::uuid, 'payment_permission_any_type_can_be_spent'),
    ('81c60941-3308-4c29-b13a-d9e0dcc6ce2e'::uuid, 'payment_permission_as_though_any'),
    ('84a4fde5-4829-4038-9ed0-aab734796c26'::uuid, 'payment_permission_any_type_can_be_spent'),
    ('86d223c3-ec5c-4ef4-83a0-16fb190563f6'::uuid, 'commander_color_identity_phrase_collision'),
    ('8854c511-2adf-45de-84dc-6a840e713eb3'::uuid, 'payment_permission_as_though_any'),
    ('8a11c89c-f6f6-4a7f-856c-b7f31a0dea10'::uuid, 'payment_permission_as_though_any'),
    ('8bb622c3-05e4-4b64-9424-accb267118b9'::uuid, 'payment_permission_as_though_any'),
    ('8c0a3181-0210-4126-919f-7da18cd8f331'::uuid, 'payment_permission_as_though_any'),
    ('8c2daabf-fc51-435c-9968-2fac30c17bf8'::uuid, 'payment_permission_as_though_any'),
    ('8d99d704-8701-4da9-8857-57b86a2ef69a'::uuid, 'payment_permission_as_though_any'),
    ('8d99fd35-5369-4dde-94d4-56143d27c37f'::uuid, 'payment_permission_as_though_any'),
    ('8e6585d4-c6ad-463f-a5a9-03e683dcb1ca'::uuid, 'payment_permission_any_type_can_be_spent'),
    ('8eb3ed7f-30ce-42ea-9376-d2b836dba6c6'::uuid, 'payment_permission_as_though_any'),
    ('8edea8f6-5ae6-4d46-9ded-390c6afeda73'::uuid, 'commander_color_identity_phrase_collision'),
    ('91cbfaea-0279-4de2-a13d-4a680152454c'::uuid, 'payment_permission_as_though_any'),
    ('92283fcd-e2ad-4a94-8636-4bf9e839e5ee'::uuid, 'payment_permission_as_though_any'),
    ('92d46561-c723-4042-a923-04f1cb08cc39'::uuid, 'payment_permission_any_type_can_be_spent'),
    ('958e8c84-4b06-4cab-b488-e84bd102ed30'::uuid, 'payment_permission_any_type_can_be_spent'),
    ('95e13e63-c7f4-40d3-a3c4-82fb35c4124a'::uuid, 'payment_permission_as_though_any'),
    ('9876ca60-ba0d-4aba-af80-391b80514cd7'::uuid, 'payment_permission_as_though_any'),
    ('99c75488-c483-471b-b460-dac7b1165f32'::uuid, 'payment_permission_as_though_any'),
    ('9e98d418-c8d8-441f-a6c1-83a1b8c22eb7'::uuid, 'payment_permission_as_though_any'),
    ('a195e2cd-ac16-4891-a5b8-49185cdb64d0'::uuid, 'payment_permission_as_though_any'),
    ('a3d8a8f2-082e-403d-9d76-543563f83c40'::uuid, 'payment_permission_any_type_can_be_spent'),
    ('a609cfcf-ff5d-4ad8-b913-40c969c07dfa'::uuid, 'payment_permission_any_type_can_be_spent'),
    ('ab229c0f-def2-4e04-97e6-b1e585270d41'::uuid, 'payment_permission_as_though_any'),
    ('ad01ba4b-469d-44f2-a955-17f1e267760e'::uuid, 'commander_color_identity_phrase_collision'),
    ('b0d53a8c-922f-4c50-b376-3d23f0388588'::uuid, 'payment_permission_spend_any_type'),
    ('b3871635-4370-45de-beaa-957a579aedce'::uuid, 'payment_permission_any_type_can_be_spent'),
    ('bc9244fa-4e7c-4a13-8b76-7473d7e11a03'::uuid, 'payment_permission_as_though_any'),
    ('be699e8e-bf52-445c-8166-77975c02722a'::uuid, 'payment_permission_any_type_can_be_spent'),
    ('bf4194da-06d2-4581-a9bd-dc2da7c40fed'::uuid, 'commander_color_identity_phrase_collision'),
    ('bf87b955-e319-425a-9ce1-760f7c35d137'::uuid, 'payment_permission_as_though_any'),
    ('c13a9149-8f66-4586-af6d-dbdc87fc2b97'::uuid, 'payment_permission_any_type_can_be_spent'),
    ('c28d3ff2-d2d5-44ee-aabb-d3773fce4772'::uuid, 'payment_permission_as_though_any'),
    ('c39cade1-85f0-41c1-9089-c352278b8ab6'::uuid, 'payment_permission_any_type_can_be_spent'),
    ('cf91d372-6e5d-45d1-9778-e8eeeef1d39e'::uuid, 'payment_permission_as_though_any'),
    ('d06285a7-9d94-44f8-a093-e005d5386ca9'::uuid, 'payment_permission_any_type_can_be_spent'),
    ('d5875336-2139-44bf-9042-35a4bd0d8955'::uuid, 'payment_permission_as_though_any'),
    ('db40d874-fa92-4734-a794-26c71b715ab8'::uuid, 'payment_permission_as_though_any'),
    ('dc84ea14-280f-4d1e-8fe7-261fabf74149'::uuid, 'payment_permission_as_though_any'),
    ('dd98a05e-66e7-474b-a8f8-3f2c39f16159'::uuid, 'payment_permission_as_though_any'),
    ('e4fd01bb-9746-4097-a116-722c4ca78eff'::uuid, 'payment_permission_as_though_any'),
    ('e9dcdc55-bb66-4a6d-bce8-fe212286d892'::uuid, 'payment_permission_as_though_any'),
    ('ebbfe3ad-1343-4fde-8780-32bc7e4b6280'::uuid, 'payment_permission_as_though_any'),
    ('ed95137d-cbd4-4741-b7ec-1d31c7022294'::uuid, 'payment_permission_any_type_can_be_spent'),
    ('efae4886-87a4-4cbe-adc3-8dca6bd02b6b'::uuid, 'payment_permission_as_though_any'),
    ('f528a1ea-4c3d-4d33-ae11-aeac59af2773'::uuid, 'payment_permission_as_though_any'),
    ('f5d8d5a9-a65f-43e3-a9d0-12e1089c5fc2'::uuid, 'payment_permission_as_though_any'),
    ('f6d414fa-4b57-4345-aee7-2f520c9d8bc5'::uuid, 'payment_permission_as_though_any'),
    ('fc9fb2c7-881b-4d76-b55c-221bf0b30b7e'::uuid, 'payment_permission_as_though_any'),
    ('ff0a3e3f-ea3d-45a0-b502-5ba0435001c2'::uuid, 'payment_permission_any_type_can_be_spent'),
    ('ff9d7f21-1837-406b-91bd-ca68ca0fbe44'::uuid, 'payment_permission_as_though_any')
)
SELECT
  c.id AS card_id,
  c.name,
  coalesce(c.type_line, '') AS type_line,
  coalesce(c.oracle_text, '') AS oracle_text,
  coalesce(c.mana_cost, '') AS mana_cost,
  c.cmc,
  t.classification
FROM target_manifest t
JOIN public.cards c ON c.id = t.card_id;

ALTER TABLE manaloom_deploy_audit.pg877_ramp_target_20260716
  ADD PRIMARY KEY (card_id);

CREATE TABLE manaloom_deploy_audit.pg877_ramp_deck_refs_20260716 AS
SELECT dc.*
FROM public.deck_cards dc
JOIN manaloom_deploy_audit.pg877_ramp_target_20260716 t
  ON t.card_id = dc.card_id;

CREATE TABLE manaloom_deploy_audit.pg877_ramp_usage_refs_20260716 AS
SELECT u.*
FROM public.commander_card_usage u
JOIN (
  SELECT DISTINCT lower(split_part(name, ' // ', 1)) AS card_name_normalized
  FROM manaloom_deploy_audit.pg877_ramp_target_20260716
) n USING (card_name_normalized);

CREATE TABLE
  manaloom_deploy_audit.pg877_ramp_function_backup_20260716 AS
SELECT f.*
FROM public.card_function_tags f
JOIN manaloom_deploy_audit.pg877_ramp_target_20260716 t USING (card_id)
WHERE f.tag = 'ramp'
  AND f.source IN (
    'deterministic_heuristic_v1',
    'deterministic_semantic_v2'
  );

CREATE TABLE
  manaloom_deploy_audit.pg877_ramp_role_backup_20260716 AS
SELECT r.*
FROM public.card_role_scores r
JOIN manaloom_deploy_audit.pg877_ramp_target_20260716 t USING (card_id)
WHERE r.role = 'ramp'
  AND r.source = 'deterministic_heuristic_v1';

CREATE TABLE
  manaloom_deploy_audit.pg877_ramp_semantic_backup_20260716 AS
SELECT s.*
FROM public.card_semantic_tags_v2 s
JOIN manaloom_deploy_audit.pg877_ramp_target_20260716 t USING (card_id)
WHERE s.source = 'deterministic_semantic_v2'
  AND s.schema_version = 'semantic_layer_v2_2026_05_18'
  AND s.tags @> '[{"tag":"ramp"}]'::jsonb;

CREATE TABLE
  manaloom_deploy_audit.pg877_ramp_function_untouched_20260716 AS
SELECT f.*
FROM public.card_function_tags f
JOIN manaloom_deploy_audit.pg877_ramp_target_20260716 t USING (card_id)
WHERE NOT (
  f.tag = 'ramp'
  AND f.source IN (
    'deterministic_heuristic_v1',
    'deterministic_semantic_v2'
  )
);

CREATE TABLE
  manaloom_deploy_audit.pg877_ramp_role_untouched_20260716 AS
SELECT r.*
FROM public.card_role_scores r
JOIN manaloom_deploy_audit.pg877_ramp_target_20260716 t USING (card_id)
WHERE NOT (
  r.role = 'ramp'
  AND r.source = 'deterministic_heuristic_v1'
);

CREATE TABLE
  manaloom_deploy_audit.pg877_ramp_semantic_untouched_20260716 AS
SELECT s.*
FROM public.card_semantic_tags_v2 s
JOIN manaloom_deploy_audit.pg877_ramp_target_20260716 t USING (card_id)
WHERE NOT (
  s.source = 'deterministic_semantic_v2'
  AND s.schema_version = 'semantic_layer_v2_2026_05_18'
  AND s.tags @> '[{"tag":"ramp"}]'::jsonb
);

CREATE TABLE
  manaloom_deploy_audit.pg877_ramp_preserved_function_20260716 AS
WITH preserved_manifest(card_id, preservation_reason) AS (
  VALUES
    ('00461ce4-a65e-4da2-8a33-7785711b344c'::uuid, 'granted_convoke'),
    ('37a71d19-965e-4cba-949d-5b64d2200f57'::uuid, 'qualified_cost_reduction'),
    ('59098116-a749-4c42-887e-73e89a7ced1a'::uuid, 'mana_dork_token'),
    ('7fd85cb4-4026-4130-bc23-25024ea7b653'::uuid, 'treasure_production'),
    ('a7ae6e85-3821-468b-8873-68cd8147d5dd'::uuid, 'mana_counter_virtual_mana'),
    ('cff0f184-02d7-4c9d-8499-6ba6889b9002'::uuid, 'copied_land_mana_abilities')
)
SELECT f.*
FROM public.card_function_tags f
JOIN preserved_manifest p USING (card_id)
WHERE f.tag = 'ramp'
  AND f.source IN (
    'deterministic_heuristic_v1',
    'deterministic_semantic_v2'
  );

CREATE TABLE
  manaloom_deploy_audit.pg877_ramp_preserved_role_20260716 AS
WITH preserved_manifest(card_id, preservation_reason) AS (
  VALUES
    ('00461ce4-a65e-4da2-8a33-7785711b344c'::uuid, 'granted_convoke'),
    ('37a71d19-965e-4cba-949d-5b64d2200f57'::uuid, 'qualified_cost_reduction'),
    ('59098116-a749-4c42-887e-73e89a7ced1a'::uuid, 'mana_dork_token'),
    ('7fd85cb4-4026-4130-bc23-25024ea7b653'::uuid, 'treasure_production'),
    ('a7ae6e85-3821-468b-8873-68cd8147d5dd'::uuid, 'mana_counter_virtual_mana'),
    ('cff0f184-02d7-4c9d-8499-6ba6889b9002'::uuid, 'copied_land_mana_abilities')
)
SELECT r.*
FROM public.card_role_scores r
JOIN preserved_manifest p USING (card_id)
WHERE r.role = 'ramp'
  AND r.source = 'deterministic_heuristic_v1';

CREATE TABLE
  manaloom_deploy_audit.pg877_ramp_preserved_semantic_20260716 AS
WITH preserved_manifest(card_id, preservation_reason) AS (
  VALUES
    ('00461ce4-a65e-4da2-8a33-7785711b344c'::uuid, 'granted_convoke'),
    ('37a71d19-965e-4cba-949d-5b64d2200f57'::uuid, 'qualified_cost_reduction'),
    ('59098116-a749-4c42-887e-73e89a7ced1a'::uuid, 'mana_dork_token'),
    ('7fd85cb4-4026-4130-bc23-25024ea7b653'::uuid, 'treasure_production'),
    ('a7ae6e85-3821-468b-8873-68cd8147d5dd'::uuid, 'mana_counter_virtual_mana'),
    ('cff0f184-02d7-4c9d-8499-6ba6889b9002'::uuid, 'copied_land_mana_abilities')
)
SELECT s.*
FROM public.card_semantic_tags_v2 s
JOIN preserved_manifest p USING (card_id)
WHERE s.source = 'deterministic_semantic_v2'
  AND s.schema_version = 'semantic_layer_v2_2026_05_18'
  AND s.tags @> '[{"tag":"ramp"}]'::jsonb;

DO $$
DECLARE
  v_target_count bigint;
  v_target_id_sha text;
  v_target_reason_sha text;
  v_target_input_sha text;
  v_deck_ref_count bigint;
  v_deck_ref_deck_count bigint;
  v_deck_ref_card_count bigint;
  v_deck_ref_card_id_sha text;
  v_deck_ref_full_sha text;
  v_usage_ref_count bigint;
  v_usage_ref_card_count bigint;
  v_usage_ref_total bigint;
  v_usage_ref_card_name_sha text;
  v_usage_ref_full_sha text;
  v_hf_count bigint;
  v_sf_count bigint;
  v_function_full_sha text;
  v_role_count bigint;
  v_role_key_sha text;
  v_role_full_sha text;
  v_semantic_count bigint;
  v_semantic_empty_count bigint;
  v_semantic_full_sha text;
  v_preserved_hf bigint;
  v_preserved_sf bigint;
  v_preserved_role bigint;
  v_preserved_semantic bigint;
  v_preserved_function_sha text;
  v_preserved_role_sha text;
  v_preserved_semantic_sha text;
BEGIN
  SELECT
    count(*),
    encode(digest(string_agg(
      card_id::text, E'\n' ORDER BY card_id::text
    ), 'sha256'), 'hex'),
    encode(digest(string_agg(
      card_id::text || '|' || classification,
      E'\n' ORDER BY card_id::text
    ), 'sha256'), 'hex'),
    encode(digest(string_agg(
      concat_ws(
        '|', card_id::text, name, type_line, oracle_text, mana_cost,
        cmc::text, classification
      ), E'\n' ORDER BY card_id::text
    ), 'sha256'), 'hex')
  INTO
    v_target_count, v_target_id_sha, v_target_reason_sha, v_target_input_sha
  FROM manaloom_deploy_audit.pg877_ramp_target_20260716;

  SELECT
    count(*),
    count(DISTINCT deck_id),
    count(DISTINCT card_id),
    encode(digest(string_agg(
      concat_ws(
        '|', id::text, deck_id::text, card_id::text, quantity::text,
        is_commander::text, condition
      ), E'\n' ORDER BY id::text
    ), 'sha256'), 'hex')
  INTO
    v_deck_ref_count, v_deck_ref_deck_count, v_deck_ref_card_count,
    v_deck_ref_full_sha
  FROM manaloom_deploy_audit.pg877_ramp_deck_refs_20260716;

  SELECT encode(digest(string_agg(
    card_id::text, E'\n' ORDER BY card_id::text
  ), 'sha256'), 'hex')
  INTO v_deck_ref_card_id_sha
  FROM (
    SELECT DISTINCT card_id
    FROM manaloom_deploy_audit.pg877_ramp_deck_refs_20260716
  ) distinct_deck_cards;

  SELECT
    count(*),
    count(DISTINCT card_name_normalized),
    coalesce(sum(usage_count), 0),
    encode(digest(string_agg(
      concat_ws(
        '|', commander_name_normalized, card_name_normalized,
        usage_count::text,
        to_char(
          last_used_at AT TIME ZONE 'UTC',
          'YYYY-MM-DD"T"HH24:MI:SS.US'
        )
      ), E'\n' ORDER BY commander_name_normalized, card_name_normalized
    ), 'sha256'), 'hex')
  INTO
    v_usage_ref_count, v_usage_ref_card_count, v_usage_ref_total,
    v_usage_ref_full_sha
  FROM manaloom_deploy_audit.pg877_ramp_usage_refs_20260716;

  SELECT encode(digest(string_agg(
    card_name_normalized, E'\n' ORDER BY card_name_normalized
  ), 'sha256'), 'hex')
  INTO v_usage_ref_card_name_sha
  FROM (
    SELECT DISTINCT card_name_normalized
    FROM manaloom_deploy_audit.pg877_ramp_usage_refs_20260716
  ) distinct_usage_cards;

  SELECT
    count(*) FILTER (WHERE source = 'deterministic_heuristic_v1'),
    count(*) FILTER (WHERE source = 'deterministic_semantic_v2'),
    encode(digest(string_agg(
      concat_ws(
        '|', card_id::text, card_name, tag, confidence::text, source,
        evidence,
        coalesce(to_char(
          updated_at AT TIME ZONE 'UTC',
          'YYYY-MM-DD"T"HH24:MI:SS.US'
        ), '')
      ), E'\n' ORDER BY source, card_id::text, tag
    ), 'sha256'), 'hex')
  INTO v_hf_count, v_sf_count, v_function_full_sha
  FROM manaloom_deploy_audit.pg877_ramp_function_backup_20260716;

  SELECT
    count(*),
    encode(digest(string_agg(
      card_id::text || '|' || format || '|' || subformat || '|' ||
      bracket_scope || '|' || budget_tier,
      E'\n' ORDER BY
        card_id::text, format, subformat, bracket_scope, budget_tier
    ), 'sha256'), 'hex'),
    encode(digest(string_agg(
      concat_ws(
        '|', card_id::text, card_name, role, score::text, format,
        subformat, bracket_scope, budget_tier, source, evidence,
        coalesce(to_char(
          updated_at AT TIME ZONE 'UTC',
          'YYYY-MM-DD"T"HH24:MI:SS.US'
        ), '')
      ), E'\n' ORDER BY
        card_id::text, format, subformat, bracket_scope, budget_tier
    ), 'sha256'), 'hex')
  INTO v_role_count, v_role_key_sha, v_role_full_sha
  FROM manaloom_deploy_audit.pg877_ramp_role_backup_20260716;

  SELECT
    count(*),
    count(*) FILTER (WHERE jsonb_array_length(tags) = 1),
    encode(digest(string_agg(
      concat_ws(
        '|', card_id::text, card_name, schema_version, speed,
        mana_efficiency, card_advantage_type, interaction_scope,
        combo_piece::text, wincon::text, engine::text, payoff::text,
        enabler::text, protection_type, recursion_type,
        role_confidence::text, explanation_reason, tags::text, source,
        coalesce(to_char(
          updated_at AT TIME ZONE 'UTC',
          'YYYY-MM-DD"T"HH24:MI:SS.US'
        ), '')
      ), E'\n' ORDER BY card_id::text
    ), 'sha256'), 'hex')
  INTO v_semantic_count, v_semantic_empty_count, v_semantic_full_sha
  FROM manaloom_deploy_audit.pg877_ramp_semantic_backup_20260716;

  SELECT
    count(*) FILTER (WHERE source = 'deterministic_heuristic_v1'),
    count(*) FILTER (WHERE source = 'deterministic_semantic_v2'),
    encode(digest(string_agg(
      card_id::text || '|' || source,
      E'\n' ORDER BY card_id::text, source
    ), 'sha256'), 'hex')
  INTO v_preserved_hf, v_preserved_sf, v_preserved_function_sha
  FROM manaloom_deploy_audit.pg877_ramp_preserved_function_20260716;

  SELECT
    count(*),
    encode(digest(string_agg(
      card_id::text || '|' || format || '|' || subformat || '|' ||
      bracket_scope || '|' || budget_tier,
      E'\n' ORDER BY card_id::text
    ), 'sha256'), 'hex')
  INTO v_preserved_role, v_preserved_role_sha
  FROM manaloom_deploy_audit.pg877_ramp_preserved_role_20260716;

  SELECT
    count(*),
    encode(digest(string_agg(
      card_id::text, E'\n' ORDER BY card_id::text
    ), 'sha256'), 'hex')
  INTO v_preserved_semantic, v_preserved_semantic_sha
  FROM manaloom_deploy_audit.pg877_ramp_preserved_semantic_20260716;

  IF v_target_count <> 115
     OR v_target_id_sha <>
       'b8e4fa337a747efadfd6cb1ab57ed5796e75de7387f3c85fd39cb3f4e742cc98'
     OR v_target_reason_sha <>
       '592c05966f7d8555543b4207c2ba38d423479db9e5812f9a0f7be4ed3c635ded'
     OR v_target_input_sha <>
       'ffda83a778b6668059fa1fd983d56e591e5f3c2a1daa044216b8c08d379838a2'
     OR v_deck_ref_count <> 28
     OR v_deck_ref_deck_count <> 24
     OR v_deck_ref_card_count <> 11
     OR v_deck_ref_card_id_sha <>
       '4539610c0a0c1d5b6ec42d92a28afc149ea2f6f208e01d0e005561f9f46a71df'
     OR v_deck_ref_full_sha <>
       '8183fd629f26d7030f1ee5b0b3f9b95516f70a4829838290ec6f37a8d4534dce'
     OR v_usage_ref_count <> 8
     OR v_usage_ref_card_count <> 8
     OR v_usage_ref_total <> 54
     OR v_usage_ref_card_name_sha <>
       '5bfdf040e76b7909be466ce923fad32fe54b01e4247fe0418657e8f440d3585a'
     OR v_usage_ref_full_sha <>
       '42aa361635ba609e18b987a924bf350fbd828c6c0b1ad51821592a4a764413a1'
     OR v_hf_count <> 105
     OR v_sf_count <> 105
     OR v_function_full_sha <>
       '8f885ffcc651b51a24d89e51df566e6f1dff54edd643c59cd99667074488621a'
     OR v_role_count <> 115
     OR v_role_key_sha <>
       '2457d7e9893b1bb942b3f8aa152e9ae601695e89af354cb0a7bfdfe82853767d'
     OR v_role_full_sha <>
       '0960dfd25538f2cf46888adf1d854831122424102a9596212334f709e68eb062'
     OR v_semantic_count <> 105
     OR v_semantic_empty_count <> 22
     OR v_semantic_full_sha <>
       'f8d4b1ee8fad1e88d5fb9d309ca7577d5345d3fed4c80b6cf125c1f9b537a752'
     OR v_preserved_hf <> 4
     OR v_preserved_sf <> 4
     OR v_preserved_role <> 6
     OR v_preserved_semantic <> 4
     OR v_preserved_function_sha <>
       '3b9ffb6210e08db290916d8c6e4b2c156ffed124459ed9d55d24ba389245e530'
     OR v_preserved_role_sha <>
       '1193285fbd80aca4d568491a64a89b0a5a4bf6af66f0f827442e3458b874d3bb'
     OR v_preserved_semantic_sha <>
       '6507efb591888106b09e5ff8c74a67b462b43b20847931122f48ba006734ad44'
  THEN
    RAISE EXCEPTION
      'PG877 abort: exact prestate drift target=% hf=% sf=% role=% semantic=%',
      v_target_count, v_hf_count, v_sf_count, v_role_count, v_semantic_count;
  END IF;
END $$;

DELETE FROM public.card_function_tags f
USING manaloom_deploy_audit.pg877_ramp_target_20260716 t
WHERE f.card_id = t.card_id
  AND f.tag = 'ramp'
  AND f.source IN (
    'deterministic_heuristic_v1',
    'deterministic_semantic_v2'
  );

DELETE FROM public.card_role_scores r
USING manaloom_deploy_audit.pg877_ramp_target_20260716 t
WHERE r.card_id = t.card_id
  AND r.role = 'ramp'
  AND r.source = 'deterministic_heuristic_v1';

WITH rebuilt AS (
  SELECT
    b.card_id,
    coalesce(
      jsonb_agg(
        e ORDER BY (e->>'confidence')::numeric DESC, e->>'tag'
      ) FILTER (WHERE e->>'tag' <> 'ramp'),
      '[]'::jsonb
    ) AS tags
  FROM manaloom_deploy_audit.pg877_ramp_semantic_backup_20260716 b
  CROSS JOIN LATERAL jsonb_array_elements(b.tags) e
  GROUP BY b.card_id
), derived AS (
  SELECT
    card_id,
    tags,
    coalesce(
      (
        SELECT max((e->>'confidence')::numeric)
        FROM jsonb_array_elements(tags) e
      ),
      0
    )::numeric(4,3) AS role_confidence,
    (
      tags @> '[{"tag":"enabler"}]'::jsonb
      OR tags @> '[{"tag":"loot"}]'::jsonb
      OR tags @> '[{"tag":"tutor"}]'::jsonb
    ) AS enabler,
    CASE
      WHEN tags @> '[{"tag":"land"}]'::jsonb
        THEN 'land_or_mana_source'
      WHEN tags @> '[{"tag":"draw"}]'::jsonb
        THEN 'adds_cards_or_refills_hand'
      WHEN tags @> '[{"tag":"loot"}]'::jsonb
        THEN 'filters_hand_quality'
      WHEN tags @> '[{"tag":"tutor"}]'::jsonb
        THEN 'searches_library_for_nonland_card'
      WHEN tags @> '[{"tag":"removal"}]'::jsonb
        THEN 'answers_targeted_threats'
      WHEN tags @> '[{"tag":"board_wipe"}]'::jsonb
        THEN 'answers_multiple_threats'
      WHEN tags @> '[{"tag":"protection"}]'::jsonb
        THEN 'protects_plan_or_permanents'
      WHEN tags @> '[{"tag":"recursion"}]'::jsonb
        THEN 'returns_resources_from_graveyard'
      WHEN tags @> '[{"tag":"wincon"}]'::jsonb
        THEN 'can_close_or_win_the_game'
      WHEN tags @> '[{"tag":"combo_piece"}]'::jsonb
        THEN 'matches_known_combo_pattern'
      WHEN tags @> '[{"tag":"engine"}]'::jsonb
        THEN 'creates_repeatable_value'
      WHEN tags @> '[{"tag":"payoff"}]'::jsonb
        THEN 'rewards_the_deck_plan'
      WHEN tags @> '[{"tag":"enabler"}]'::jsonb
        THEN 'sets_up_the_deck_plan'
      ELSE 'no_primary_function_detected'
    END AS explanation_reason
  FROM rebuilt
)
UPDATE public.card_semantic_tags_v2 s
SET
  tags = d.tags,
  role_confidence = d.role_confidence,
  enabler = d.enabler,
  explanation_reason = d.explanation_reason,
  updated_at = CURRENT_TIMESTAMP
FROM derived d
WHERE s.card_id = d.card_id
  AND s.source = 'deterministic_semantic_v2'
  AND s.schema_version = 'semantic_layer_v2_2026_05_18'
  AND jsonb_array_length(d.tags) > 0;

DELETE FROM public.card_semantic_tags_v2 s
USING manaloom_deploy_audit.pg877_ramp_semantic_backup_20260716 b
WHERE s.card_id = b.card_id
  AND s.source = b.source
  AND s.schema_version = b.schema_version
  AND NOT EXISTS (
    SELECT 1
    FROM jsonb_array_elements(b.tags) e
    WHERE e->>'tag' <> 'ramp'
  );

CREATE TABLE
  manaloom_deploy_audit.pg877_ramp_semantic_post_20260716 AS
SELECT s.*
FROM public.card_semantic_tags_v2 s
JOIN manaloom_deploy_audit.pg877_ramp_semantic_backup_20260716 b
  ON b.card_id = s.card_id
  AND b.source = s.source
  AND b.schema_version = s.schema_version;

DO $$
DECLARE
  v_bad_function bigint;
  v_bad_role bigint;
  v_bad_semantic bigint;
  v_semantic_post_count bigint;
  v_semantic_post_content_sha text;
BEGIN
  SELECT count(*)
  INTO v_bad_function
  FROM public.card_function_tags f
  JOIN manaloom_deploy_audit.pg877_ramp_target_20260716 t USING (card_id)
  WHERE f.tag = 'ramp'
    AND f.source IN (
      'deterministic_heuristic_v1',
      'deterministic_semantic_v2'
    );

  SELECT count(*)
  INTO v_bad_role
  FROM public.card_role_scores r
  JOIN manaloom_deploy_audit.pg877_ramp_target_20260716 t USING (card_id)
  WHERE r.role = 'ramp'
    AND r.source = 'deterministic_heuristic_v1';

  SELECT count(*)
  INTO v_bad_semantic
  FROM public.card_semantic_tags_v2 s
  JOIN manaloom_deploy_audit.pg877_ramp_target_20260716 t USING (card_id)
  WHERE s.source = 'deterministic_semantic_v2'
    AND s.schema_version = 'semantic_layer_v2_2026_05_18'
    AND s.tags @> '[{"tag":"ramp"}]'::jsonb;

  SELECT
    count(*),
    encode(digest(string_agg(
      concat_ws(
        '|', card_id::text, card_name, schema_version, speed,
        mana_efficiency, card_advantage_type, interaction_scope,
        combo_piece::text, wincon::text, engine::text, payoff::text,
        enabler::text, protection_type, recursion_type,
        role_confidence::text, explanation_reason, tags::text, source
      ), E'\n' ORDER BY card_id::text
    ), 'sha256'), 'hex')
  INTO v_semantic_post_count, v_semantic_post_content_sha
  FROM manaloom_deploy_audit.pg877_ramp_semantic_post_20260716;

  IF v_bad_function <> 0
     OR v_bad_role <> 0
     OR v_bad_semantic <> 0
     OR v_semantic_post_count <> 83
     OR v_semantic_post_content_sha <>
       'd06f7f53ec19b866e6b9e9160af69ca6b977ef623bf72eaf7d0c4926c236d4fa'
  THEN
    RAISE EXCEPTION
      'PG877 abort: poststate drift f=% r=% s=% semantic_post=% semantic_hash=%',
      v_bad_function, v_bad_role, v_bad_semantic, v_semantic_post_count,
      v_semantic_post_content_sha;
  END IF;

  IF EXISTS (
    (
      SELECT f.*
      FROM public.card_function_tags f
      JOIN manaloom_deploy_audit.pg877_ramp_target_20260716 t USING (card_id)
      WHERE NOT (
        f.tag = 'ramp'
        AND f.source IN (
          'deterministic_heuristic_v1',
          'deterministic_semantic_v2'
        )
      )
      EXCEPT
      SELECT *
      FROM manaloom_deploy_audit.pg877_ramp_function_untouched_20260716
    )
    UNION ALL
    (
      SELECT *
      FROM manaloom_deploy_audit.pg877_ramp_function_untouched_20260716
      EXCEPT
      SELECT f.*
      FROM public.card_function_tags f
      JOIN manaloom_deploy_audit.pg877_ramp_target_20260716 t USING (card_id)
      WHERE NOT (
        f.tag = 'ramp'
        AND f.source IN (
          'deterministic_heuristic_v1',
          'deterministic_semantic_v2'
        )
      )
    )
  ) THEN
    RAISE EXCEPTION 'PG877 abort: untouched function rows changed';
  END IF;

  IF EXISTS (
    (
      SELECT r.*
      FROM public.card_role_scores r
      JOIN manaloom_deploy_audit.pg877_ramp_target_20260716 t USING (card_id)
      WHERE NOT (
        r.role = 'ramp'
        AND r.source = 'deterministic_heuristic_v1'
      )
      EXCEPT
      SELECT *
      FROM manaloom_deploy_audit.pg877_ramp_role_untouched_20260716
    )
    UNION ALL
    (
      SELECT *
      FROM manaloom_deploy_audit.pg877_ramp_role_untouched_20260716
      EXCEPT
      SELECT r.*
      FROM public.card_role_scores r
      JOIN manaloom_deploy_audit.pg877_ramp_target_20260716 t USING (card_id)
      WHERE NOT (
        r.role = 'ramp'
        AND r.source = 'deterministic_heuristic_v1'
      )
    )
  ) THEN
    RAISE EXCEPTION 'PG877 abort: untouched role rows changed';
  END IF;

  IF EXISTS (
    (
      SELECT s.*
      FROM public.card_semantic_tags_v2 s
      JOIN manaloom_deploy_audit.pg877_ramp_target_20260716 t USING (card_id)
      WHERE NOT (
        s.source = 'deterministic_semantic_v2'
        AND s.schema_version = 'semantic_layer_v2_2026_05_18'
        AND s.card_id IN (
          SELECT card_id
          FROM manaloom_deploy_audit.pg877_ramp_semantic_backup_20260716
        )
      )
      EXCEPT
      SELECT *
      FROM manaloom_deploy_audit.pg877_ramp_semantic_untouched_20260716
    )
    UNION ALL
    (
      SELECT *
      FROM manaloom_deploy_audit.pg877_ramp_semantic_untouched_20260716
      EXCEPT
      SELECT s.*
      FROM public.card_semantic_tags_v2 s
      JOIN manaloom_deploy_audit.pg877_ramp_target_20260716 t USING (card_id)
      WHERE NOT (
        s.source = 'deterministic_semantic_v2'
        AND s.schema_version = 'semantic_layer_v2_2026_05_18'
        AND s.card_id IN (
          SELECT card_id
          FROM manaloom_deploy_audit.pg877_ramp_semantic_backup_20260716
        )
      )
    )
  ) THEN
    RAISE EXCEPTION 'PG877 abort: untouched semantic rows changed';
  END IF;

  IF EXISTS (
    (
      SELECT f.*
      FROM public.card_function_tags f
      WHERE f.card_id IN (
        SELECT card_id
        FROM manaloom_deploy_audit.pg877_ramp_preserved_function_20260716
      )
        AND f.tag = 'ramp'
        AND f.source IN (
          'deterministic_heuristic_v1',
          'deterministic_semantic_v2'
        )
      EXCEPT
      SELECT *
      FROM manaloom_deploy_audit.pg877_ramp_preserved_function_20260716
    )
    UNION ALL
    (
      SELECT *
      FROM manaloom_deploy_audit.pg877_ramp_preserved_function_20260716
      EXCEPT
      SELECT f.*
      FROM public.card_function_tags f
      WHERE f.card_id IN (
        SELECT card_id
        FROM manaloom_deploy_audit.pg877_ramp_preserved_function_20260716
      )
        AND f.tag = 'ramp'
        AND f.source IN (
          'deterministic_heuristic_v1',
          'deterministic_semantic_v2'
        )
    )
  ) THEN
    RAISE EXCEPTION 'PG877 abort: preserved function rows changed';
  END IF;

  IF EXISTS (
    (
      SELECT r.*
      FROM public.card_role_scores r
      WHERE r.card_id IN (
        SELECT card_id
        FROM manaloom_deploy_audit.pg877_ramp_preserved_role_20260716
      )
        AND r.role = 'ramp'
        AND r.source = 'deterministic_heuristic_v1'
      EXCEPT
      SELECT *
      FROM manaloom_deploy_audit.pg877_ramp_preserved_role_20260716
    )
    UNION ALL
    (
      SELECT *
      FROM manaloom_deploy_audit.pg877_ramp_preserved_role_20260716
      EXCEPT
      SELECT r.*
      FROM public.card_role_scores r
      WHERE r.card_id IN (
        SELECT card_id
        FROM manaloom_deploy_audit.pg877_ramp_preserved_role_20260716
      )
        AND r.role = 'ramp'
        AND r.source = 'deterministic_heuristic_v1'
    )
  ) THEN
    RAISE EXCEPTION 'PG877 abort: preserved role rows changed';
  END IF;

  IF EXISTS (
    (
      SELECT s.*
      FROM public.card_semantic_tags_v2 s
      WHERE s.card_id IN (
        SELECT card_id
        FROM manaloom_deploy_audit.pg877_ramp_preserved_semantic_20260716
      )
        AND s.source = 'deterministic_semantic_v2'
        AND s.schema_version = 'semantic_layer_v2_2026_05_18'
        AND s.tags @> '[{"tag":"ramp"}]'::jsonb
      EXCEPT
      SELECT *
      FROM manaloom_deploy_audit.pg877_ramp_preserved_semantic_20260716
    )
    UNION ALL
    (
      SELECT *
      FROM manaloom_deploy_audit.pg877_ramp_preserved_semantic_20260716
      EXCEPT
      SELECT s.*
      FROM public.card_semantic_tags_v2 s
      WHERE s.card_id IN (
        SELECT card_id
        FROM manaloom_deploy_audit.pg877_ramp_preserved_semantic_20260716
      )
        AND s.source = 'deterministic_semantic_v2'
        AND s.schema_version = 'semantic_layer_v2_2026_05_18'
        AND s.tags @> '[{"tag":"ramp"}]'::jsonb
    )
  ) THEN
    RAISE EXCEPTION 'PG877 abort: preserved semantic rows changed';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM (
      (
        SELECT dc.*
        FROM public.deck_cards dc
        JOIN manaloom_deploy_audit.pg877_ramp_target_20260716 t
          ON t.card_id = dc.card_id
        EXCEPT
        SELECT *
        FROM manaloom_deploy_audit.pg877_ramp_deck_refs_20260716
      )
      UNION ALL
      (
        SELECT *
        FROM manaloom_deploy_audit.pg877_ramp_deck_refs_20260716
        EXCEPT
        SELECT dc.*
        FROM public.deck_cards dc
        JOIN manaloom_deploy_audit.pg877_ramp_target_20260716 t
          ON t.card_id = dc.card_id
      )
    ) diff
  ) THEN
    RAISE EXCEPTION 'PG877 abort: deck references changed';
  END IF;

  IF EXISTS (
    WITH target_usage_names AS (
      SELECT DISTINCT
        lower(split_part(name, ' // ', 1)) AS card_name_normalized
      FROM manaloom_deploy_audit.pg877_ramp_target_20260716
    ), current_usage_refs AS (
      SELECT u.*
      FROM public.commander_card_usage u
      JOIN target_usage_names n USING (card_name_normalized)
    )
    SELECT 1
    FROM (
      (SELECT * FROM current_usage_refs
       EXCEPT
       SELECT *
       FROM manaloom_deploy_audit.pg877_ramp_usage_refs_20260716)
      UNION ALL
      (SELECT *
       FROM manaloom_deploy_audit.pg877_ramp_usage_refs_20260716
       EXCEPT
       SELECT * FROM current_usage_refs)
    ) diff
  ) THEN
    RAISE EXCEPTION 'PG877 abort: commander usage references changed';
  END IF;

  IF EXISTS (
    WITH current_target AS (
      SELECT
        c.id AS card_id,
        c.name,
        coalesce(c.type_line, '') AS type_line,
        coalesce(c.oracle_text, '') AS oracle_text,
        coalesce(c.mana_cost, '') AS mana_cost,
        c.cmc,
        t.classification
      FROM manaloom_deploy_audit.pg877_ramp_target_20260716 t
      JOIN public.cards c ON c.id = t.card_id
    )
    SELECT 1
    FROM (
      (SELECT * FROM current_target
       EXCEPT
       SELECT * FROM manaloom_deploy_audit.pg877_ramp_target_20260716)
      UNION ALL
      (SELECT * FROM manaloom_deploy_audit.pg877_ramp_target_20260716
       EXCEPT
       SELECT * FROM current_target)
    ) diff
  ) THEN
    RAISE EXCEPTION 'PG877 abort: target card inputs changed';
  END IF;
END $$;

COMMIT;
