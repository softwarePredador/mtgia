\echo 'PG638 priority Lorehold status validation apply'

BEGIN;

CREATE TEMP TABLE _pg638_priority_targets(
  normalized_name text PRIMARY KEY,
  card_name text NOT NULL,
  logical_rule_key text NOT NULL,
  effect text NOT NULL,
  scope text NOT NULL
) ON COMMIT DROP;

INSERT INTO _pg638_priority_targets(normalized_name, card_name, logical_rule_key, effect, scope)
VALUES
  ('fellwar stone', 'Fellwar Stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba', 'ramp_permanent', 'conditional_opponent_color_mana_rock_v1'),
  ('library of leng', 'Library of Leng', 'battle_rule_v1:b6491cf6f7d7df9a3fb0d91abd3d31c3', 'passive', 'discard_replacement_to_top_v1'),
  ('scroll rack', 'Scroll Rack', 'battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2', 'topdeck_manipulation', 'scroll_rack_upkeep_single_exchange_v1'),
  ('talisman of conviction', 'Talisman of Conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470', 'ramp_permanent', 'pain_talisman_color_pair_partial_v1');

CREATE TEMP TABLE _pg638_priority_updated AS
WITH updated AS (
  UPDATE card_battle_rules cbr
     SET review_status = 'verified',
         reviewed_by = 'codex_priority_lorehold_validation_20260707',
         reviewed_at = now(),
         updated_at = now(),
         notes = CASE
           WHEN coalesce(cbr.notes, '') LIKE '%PG638 priority Lorehold status validation%'
             THEN cbr.notes
           ELSE concat_ws(E'\n', cbr.notes, 'PG638 priority Lorehold status validation: promoted from active to verified after focused runtime suite test_priority_lorehold_card_runtime.py passed 19/19 and current priority audit isolated status-only PG/SQLite/snapshot drift.')
         END
    FROM _pg638_priority_targets t
   WHERE cbr.normalized_name = t.normalized_name
     AND cbr.logical_rule_key = t.logical_rule_key
     AND cbr.card_name = t.card_name
     AND cbr.review_status = 'active'
     AND cbr.execution_status = 'auto'
     AND cbr.source = 'curated'
     AND cbr.oracle_hash IS NOT NULL
     AND cbr.effect_json->>'effect' = t.effect
     AND cbr.effect_json->>'battle_model_scope' = t.scope
  RETURNING cbr.card_name, cbr.normalized_name, cbr.logical_rule_key, cbr.review_status, cbr.execution_status, cbr.oracle_hash, cbr.effect_json->>'battle_model_scope' AS scope
)
SELECT * FROM updated;

DO $$
DECLARE
  updated_count integer;
BEGIN
  SELECT count(*) INTO updated_count FROM _pg638_priority_updated;
  IF updated_count <> 4 THEN
    RAISE EXCEPTION 'Expected to promote 4 PG638 priority rules, updated %', updated_count;
  END IF;
END $$;

TABLE _pg638_priority_updated ORDER BY card_name;

COMMIT;
