BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg119_current_replay_simple_runtime_batch_20260623_22251 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('fierce guardianship', 'force of will', 'mindbreak trap', 'sevinne''s reclamation', 'abrupt decay', 'counterspell', 'deadly rollick', 'force of vigor', 'laughing mad', 'lightning bolt', 'negate', 'snapback', 'thrill of possibility', 'calamity of cinders', 'gut shot');

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('fierce guardianship', 'Fierce Guardianship', 'bc4b4203a40c025f864fb72b5e028507', 'battle_rule_v1:ab59b16c0affe83efd99245a87b0b785', '{"ability_kind":"one_shot","battle_model_scope":"counter_target_stack_object_variant_v1","effect":"counter_spell","target_constraints":{"zone":"stack"}}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class FierceGuardianship mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('force of will', 'Force of Will', '47f60c69ad0e8584a19c553ead1b804e', 'battle_rule_v1:ab59b16c0affe83efd99245a87b0b785', '{"ability_kind":"one_shot","battle_model_scope":"counter_target_stack_object_variant_v1","effect":"counter_spell","target_constraints":{"zone":"stack"}}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ForceOfWill mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('mindbreak trap', 'Mindbreak Trap', '59ac3fb4c9b6e1e17fa82e6f0c9a703f', 'battle_rule_v1:ac8ef4daa0b2bccca232c55650faaac7', '{"ability_kind":"one_shot","battle_model_scope":"targeted_exile_variant_v1","effect":"removal_exile","target_constraints":{"zone":"stack"}}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class MindbreakTrap mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('sevinne''s reclamation', 'Sevinne''s Reclamation', 'ef26bb3a88ec6e282792b3a5faad8f8f', 'battle_rule_v1:13150949864474c123d5a02a7a007722', '{"ability_kind":"one_shot","battle_model_scope":"graveyard_to_battlefield_variant_v1","effect":"recursion","target_constraints":{"card_types":["permanent"],"zone":"graveyard"}}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class SevinnesReclamation mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('abrupt decay', 'Abrupt Decay', '04ce5e5a3b4a8e9243a592cae2f67af8', 'battle_rule_v1:24839f966a77da6656c462aa885ccaa4', '{"ability_kind":"one_shot","battle_model_scope":"targeted_destroy_variant_v1","effect":"removal_destroy","target_constraints":{"card_types":["permanent"]}}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class AbruptDecay mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('counterspell', 'Counterspell', 'd748ee6dd8f8a81c2f3f28ac38dd895a', 'battle_rule_v1:ab59b16c0affe83efd99245a87b0b785', '{"ability_kind":"one_shot","battle_model_scope":"counter_target_stack_object_variant_v1","effect":"counter_spell","target_constraints":{"zone":"stack"}}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Counterspell mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('deadly rollick', 'Deadly Rollick', 'e437e191b057a33d4d4bec121c1cd435', 'battle_rule_v1:d0548bf7d63a72a613d0d7559c0bead5', '{"ability_kind":"one_shot","battle_model_scope":"targeted_exile_variant_v1","effect":"removal_exile","target_constraints":{"card_types":["creature"]}}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class DeadlyRollick mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('force of vigor', 'Force of Vigor', '0a5b0d5ec18fe010214e5074967e0f58', 'battle_rule_v1:c4882150a4b01688aa847f3a2b6b917e', '{"ability_kind":"one_shot","battle_model_scope":"targeted_destroy_variant_v1","effect":"removal_destroy","target_constraints":{"card_types":["artifact"]}}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ForceOfVigor mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('laughing mad', 'Laughing Mad', '77323f8288f108b027cf698e38e08341', 'battle_rule_v1:3af05007acd54aabd195ff390b8f082f', '{"ability_kind":"one_shot","battle_model_scope":"source_controller_draw_variant_v1","effect":"draw_cards"}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class LaughingMad mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('lightning bolt', 'Lightning Bolt', 'd6688e11f8fab7ac055bb72239825ab3', 'battle_rule_v1:a939ce51bf83fe086fc16a40d344752d', '{"ability_kind":"one_shot","battle_model_scope":"targeted_damage_variant_v1","effect":"direct_damage","target_constraints":{"scope":"any_target"}}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class LightningBolt mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('negate', 'Negate', '25854a654e42a97cc4802ee504f71c51', 'battle_rule_v1:ab59b16c0affe83efd99245a87b0b785', '{"ability_kind":"one_shot","battle_model_scope":"counter_target_stack_object_variant_v1","effect":"counter_spell","target_constraints":{"zone":"stack"}}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Negate mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('snapback', 'Snapback', '5bf90c640dc5f6814c35b1acc8021782', 'battle_rule_v1:ecb72fd4217be7d7c883b645bf4da384', '{"ability_kind":"one_shot","battle_model_scope":"targeted_return_to_hand_variant_v1","effect":"bounce","target_constraints":{"card_types":["creature"]}}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Snapback mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('thrill of possibility', 'Thrill of Possibility', '82c625909b3e6d29d4fa95e933cfc80e', 'battle_rule_v1:3af05007acd54aabd195ff390b8f082f', '{"ability_kind":"one_shot","battle_model_scope":"source_controller_draw_variant_v1","effect":"draw_cards"}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ThrillOfPossibility mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('calamity of cinders', 'Calamity of Cinders', '860e306393dd42863f84cbe930499be9', 'battle_rule_v1:83c697bb6d5579334bef054f2204b3a9', '{"ability_kind":"one_shot","battle_model_scope":"damage_all_variant_v1","effect":"sweeper_damage","target_constraints":{"card_types":["creature"]}}'::jsonb, '{"category":"interaction","effect":"board_control","subtype":"wipe_or_sacrifice","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class CalamityOfCinders mapped to family board_wipe_choice; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('gut shot', 'Gut Shot', '11231a3dc6228cf87243630826f882a7', 'battle_rule_v1:a939ce51bf83fe086fc16a40d344752d', '{"ability_kind":"one_shot","battle_model_scope":"targeted_damage_variant_v1","effect":"direct_damage","target_constraints":{"scope":"any_target"}}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class GutShot mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
      ON lower(c.name) = p.normalized_name
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

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('fierce guardianship', 'Fierce Guardianship', 'bc4b4203a40c025f864fb72b5e028507', 'battle_rule_v1:ab59b16c0affe83efd99245a87b0b785', '{"ability_kind":"one_shot","battle_model_scope":"counter_target_stack_object_variant_v1","effect":"counter_spell","target_constraints":{"zone":"stack"}}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class FierceGuardianship mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('force of will', 'Force of Will', '47f60c69ad0e8584a19c553ead1b804e', 'battle_rule_v1:ab59b16c0affe83efd99245a87b0b785', '{"ability_kind":"one_shot","battle_model_scope":"counter_target_stack_object_variant_v1","effect":"counter_spell","target_constraints":{"zone":"stack"}}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ForceOfWill mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('mindbreak trap', 'Mindbreak Trap', '59ac3fb4c9b6e1e17fa82e6f0c9a703f', 'battle_rule_v1:ac8ef4daa0b2bccca232c55650faaac7', '{"ability_kind":"one_shot","battle_model_scope":"targeted_exile_variant_v1","effect":"removal_exile","target_constraints":{"zone":"stack"}}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class MindbreakTrap mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('sevinne''s reclamation', 'Sevinne''s Reclamation', 'ef26bb3a88ec6e282792b3a5faad8f8f', 'battle_rule_v1:13150949864474c123d5a02a7a007722', '{"ability_kind":"one_shot","battle_model_scope":"graveyard_to_battlefield_variant_v1","effect":"recursion","target_constraints":{"card_types":["permanent"],"zone":"graveyard"}}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class SevinnesReclamation mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('abrupt decay', 'Abrupt Decay', '04ce5e5a3b4a8e9243a592cae2f67af8', 'battle_rule_v1:24839f966a77da6656c462aa885ccaa4', '{"ability_kind":"one_shot","battle_model_scope":"targeted_destroy_variant_v1","effect":"removal_destroy","target_constraints":{"card_types":["permanent"]}}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class AbruptDecay mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('counterspell', 'Counterspell', 'd748ee6dd8f8a81c2f3f28ac38dd895a', 'battle_rule_v1:ab59b16c0affe83efd99245a87b0b785', '{"ability_kind":"one_shot","battle_model_scope":"counter_target_stack_object_variant_v1","effect":"counter_spell","target_constraints":{"zone":"stack"}}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Counterspell mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('deadly rollick', 'Deadly Rollick', 'e437e191b057a33d4d4bec121c1cd435', 'battle_rule_v1:d0548bf7d63a72a613d0d7559c0bead5', '{"ability_kind":"one_shot","battle_model_scope":"targeted_exile_variant_v1","effect":"removal_exile","target_constraints":{"card_types":["creature"]}}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class DeadlyRollick mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('force of vigor', 'Force of Vigor', '0a5b0d5ec18fe010214e5074967e0f58', 'battle_rule_v1:c4882150a4b01688aa847f3a2b6b917e', '{"ability_kind":"one_shot","battle_model_scope":"targeted_destroy_variant_v1","effect":"removal_destroy","target_constraints":{"card_types":["artifact"]}}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ForceOfVigor mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('laughing mad', 'Laughing Mad', '77323f8288f108b027cf698e38e08341', 'battle_rule_v1:3af05007acd54aabd195ff390b8f082f', '{"ability_kind":"one_shot","battle_model_scope":"source_controller_draw_variant_v1","effect":"draw_cards"}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class LaughingMad mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('lightning bolt', 'Lightning Bolt', 'd6688e11f8fab7ac055bb72239825ab3', 'battle_rule_v1:a939ce51bf83fe086fc16a40d344752d', '{"ability_kind":"one_shot","battle_model_scope":"targeted_damage_variant_v1","effect":"direct_damage","target_constraints":{"scope":"any_target"}}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class LightningBolt mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('negate', 'Negate', '25854a654e42a97cc4802ee504f71c51', 'battle_rule_v1:ab59b16c0affe83efd99245a87b0b785', '{"ability_kind":"one_shot","battle_model_scope":"counter_target_stack_object_variant_v1","effect":"counter_spell","target_constraints":{"zone":"stack"}}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Negate mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('snapback', 'Snapback', '5bf90c640dc5f6814c35b1acc8021782', 'battle_rule_v1:ecb72fd4217be7d7c883b645bf4da384', '{"ability_kind":"one_shot","battle_model_scope":"targeted_return_to_hand_variant_v1","effect":"bounce","target_constraints":{"card_types":["creature"]}}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Snapback mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('thrill of possibility', 'Thrill of Possibility', '82c625909b3e6d29d4fa95e933cfc80e', 'battle_rule_v1:3af05007acd54aabd195ff390b8f082f', '{"ability_kind":"one_shot","battle_model_scope":"source_controller_draw_variant_v1","effect":"draw_cards"}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ThrillOfPossibility mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('calamity of cinders', 'Calamity of Cinders', '860e306393dd42863f84cbe930499be9', 'battle_rule_v1:83c697bb6d5579334bef054f2204b3a9', '{"ability_kind":"one_shot","battle_model_scope":"damage_all_variant_v1","effect":"sweeper_damage","target_constraints":{"card_types":["creature"]}}'::jsonb, '{"category":"interaction","effect":"board_control","subtype":"wipe_or_sacrifice","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class CalamityOfCinders mapped to family board_wipe_choice; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('gut shot', 'Gut Shot', '11231a3dc6228cf87243630826f882a7', 'battle_rule_v1:a939ce51bf83fe086fc16a40d344752d', '{"ability_kind":"one_shot","battle_model_scope":"targeted_damage_variant_v1","effect":"direct_damage","target_constraints":{"scope":"any_target"}}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class GutShot mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
),
deprecated AS (
  UPDATE public.card_battle_rules r
  SET
    review_status = 'deprecated',
    execution_status = 'disabled',
    updated_at = now(),
    notes = concat_ws(E'\n', nullif(r.notes, ''), 'XMage batch package: deprecated stale shadow before curated batch rule upsert.')
  FROM proposed p
  WHERE r.normalized_name = p.normalized_name
    AND r.logical_rule_key <> p.logical_rule_key
  RETURNING r.*
)
SELECT count(*) AS deprecated_shadow_rows FROM deprecated;

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('fierce guardianship', 'Fierce Guardianship', 'bc4b4203a40c025f864fb72b5e028507', 'battle_rule_v1:ab59b16c0affe83efd99245a87b0b785', '{"ability_kind":"one_shot","battle_model_scope":"counter_target_stack_object_variant_v1","effect":"counter_spell","target_constraints":{"zone":"stack"}}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class FierceGuardianship mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('force of will', 'Force of Will', '47f60c69ad0e8584a19c553ead1b804e', 'battle_rule_v1:ab59b16c0affe83efd99245a87b0b785', '{"ability_kind":"one_shot","battle_model_scope":"counter_target_stack_object_variant_v1","effect":"counter_spell","target_constraints":{"zone":"stack"}}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ForceOfWill mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('mindbreak trap', 'Mindbreak Trap', '59ac3fb4c9b6e1e17fa82e6f0c9a703f', 'battle_rule_v1:ac8ef4daa0b2bccca232c55650faaac7', '{"ability_kind":"one_shot","battle_model_scope":"targeted_exile_variant_v1","effect":"removal_exile","target_constraints":{"zone":"stack"}}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class MindbreakTrap mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('sevinne''s reclamation', 'Sevinne''s Reclamation', 'ef26bb3a88ec6e282792b3a5faad8f8f', 'battle_rule_v1:13150949864474c123d5a02a7a007722', '{"ability_kind":"one_shot","battle_model_scope":"graveyard_to_battlefield_variant_v1","effect":"recursion","target_constraints":{"card_types":["permanent"],"zone":"graveyard"}}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class SevinnesReclamation mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('abrupt decay', 'Abrupt Decay', '04ce5e5a3b4a8e9243a592cae2f67af8', 'battle_rule_v1:24839f966a77da6656c462aa885ccaa4', '{"ability_kind":"one_shot","battle_model_scope":"targeted_destroy_variant_v1","effect":"removal_destroy","target_constraints":{"card_types":["permanent"]}}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class AbruptDecay mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('counterspell', 'Counterspell', 'd748ee6dd8f8a81c2f3f28ac38dd895a', 'battle_rule_v1:ab59b16c0affe83efd99245a87b0b785', '{"ability_kind":"one_shot","battle_model_scope":"counter_target_stack_object_variant_v1","effect":"counter_spell","target_constraints":{"zone":"stack"}}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Counterspell mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('deadly rollick', 'Deadly Rollick', 'e437e191b057a33d4d4bec121c1cd435', 'battle_rule_v1:d0548bf7d63a72a613d0d7559c0bead5', '{"ability_kind":"one_shot","battle_model_scope":"targeted_exile_variant_v1","effect":"removal_exile","target_constraints":{"card_types":["creature"]}}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class DeadlyRollick mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('force of vigor', 'Force of Vigor', '0a5b0d5ec18fe010214e5074967e0f58', 'battle_rule_v1:c4882150a4b01688aa847f3a2b6b917e', '{"ability_kind":"one_shot","battle_model_scope":"targeted_destroy_variant_v1","effect":"removal_destroy","target_constraints":{"card_types":["artifact"]}}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ForceOfVigor mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('laughing mad', 'Laughing Mad', '77323f8288f108b027cf698e38e08341', 'battle_rule_v1:3af05007acd54aabd195ff390b8f082f', '{"ability_kind":"one_shot","battle_model_scope":"source_controller_draw_variant_v1","effect":"draw_cards"}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class LaughingMad mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('lightning bolt', 'Lightning Bolt', 'd6688e11f8fab7ac055bb72239825ab3', 'battle_rule_v1:a939ce51bf83fe086fc16a40d344752d', '{"ability_kind":"one_shot","battle_model_scope":"targeted_damage_variant_v1","effect":"direct_damage","target_constraints":{"scope":"any_target"}}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class LightningBolt mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('negate', 'Negate', '25854a654e42a97cc4802ee504f71c51', 'battle_rule_v1:ab59b16c0affe83efd99245a87b0b785', '{"ability_kind":"one_shot","battle_model_scope":"counter_target_stack_object_variant_v1","effect":"counter_spell","target_constraints":{"zone":"stack"}}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Negate mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('snapback', 'Snapback', '5bf90c640dc5f6814c35b1acc8021782', 'battle_rule_v1:ecb72fd4217be7d7c883b645bf4da384', '{"ability_kind":"one_shot","battle_model_scope":"targeted_return_to_hand_variant_v1","effect":"bounce","target_constraints":{"card_types":["creature"]}}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Snapback mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('thrill of possibility', 'Thrill of Possibility', '82c625909b3e6d29d4fa95e933cfc80e', 'battle_rule_v1:3af05007acd54aabd195ff390b8f082f', '{"ability_kind":"one_shot","battle_model_scope":"source_controller_draw_variant_v1","effect":"draw_cards"}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ThrillOfPossibility mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('calamity of cinders', 'Calamity of Cinders', '860e306393dd42863f84cbe930499be9', 'battle_rule_v1:83c697bb6d5579334bef054f2204b3a9', '{"ability_kind":"one_shot","battle_model_scope":"damage_all_variant_v1","effect":"sweeper_damage","target_constraints":{"card_types":["creature"]}}'::jsonb, '{"category":"interaction","effect":"board_control","subtype":"wipe_or_sacrifice","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class CalamityOfCinders mapped to family board_wipe_choice; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('gut shot', 'Gut Shot', '11231a3dc6228cf87243630826f882a7', 'battle_rule_v1:a939ce51bf83fe086fc16a40d344752d', '{"ability_kind":"one_shot","battle_model_scope":"targeted_damage_variant_v1","effect":"direct_damage","target_constraints":{"scope":"any_target"}}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class GutShot mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
    ON lower(c.name) = p.normalized_name
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
    p.notes
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
