BEGIN;

CREATE TABLE IF NOT EXISTS public.pg257_phyrexian_censor_static_runtime_20260629_backup AS
SELECT now() AS backed_up_at, r.*
FROM public.card_battle_rules r
WHERE false;

INSERT INTO public.pg257_phyrexian_censor_static_runtime_20260629_backup
SELECT now() AS backed_up_at, r.*
FROM public.card_battle_rules r
WHERE r.normalized_name IN (SELECT normalized_name FROM (VALUES ('phyrexian censor')) AS v(normalized_name))
AND NOT EXISTS (
  SELECT 1 FROM public.pg257_phyrexian_censor_static_runtime_20260629_backup b
  WHERE b.normalized_name = r.normalized_name
    AND b.logical_rule_key = r.logical_rule_key
);

DO $$
DECLARE v_missing text;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash) AS (VALUES ('phyrexian censor', 'Phyrexian Censor', 'deafed84b14f2008e85145ee17c162a7'))
  SELECT string_agg(p.card_name, ', ' ORDER BY p.card_name) INTO v_missing
  FROM proposed p
  WHERE NOT EXISTS (
    SELECT 1 FROM public.cards c
    WHERE (lower(c.name) = p.normalized_name OR split_part(lower(c.name), ' // ', 1) = p.normalized_name)
      AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
  );
  IF v_missing IS NOT NULL THEN
    RAISE EXCEPTION 'PG257 abort: expected at least one Oracle-hash-matched cards row for every proposed card: %', v_missing;
  END IF;
END $$;

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('phyrexian censor', 'Phyrexian Censor', 'deafed84b14f2008e85145ee17c162a7', 'battle_rule_v1:166240c94a4f8ba33fc80549c236deb7', '{"ability_kind":"static","battle_model_scope":"each_player_one_nonphyrexian_spell_per_turn_nonphyrexian_creatures_enter_tapped_v1","cmc":3.0,"colors":["W"],"effect":"creature","mana_cost":"{2}{W}","nonphyrexian_creatures_enter_tapped":true,"power":3,"restricted_spell_scope":"nonphyrexian_spells","restriction_controller_scope":"each_player","spell_limit_per_turn":1,"static_rule_restriction":true,"subtypes":["Phyrexian","Wizard"],"toughness":3,"type_line":"Creature - Phyrexian Wizard"}'::jsonb, '{"category":"stax","effect":"creature","subtype":"static_spell_limit_and_enter_tapped"}'::jsonb, 'curated', 0.97, 'verified', 'auto', 'PG257: promoted exact XMage-backed Phyrexian Censor static runtime rule; focused tests cover non-Phyrexian spell limit and non-Phyrexian creature enter-tapped semantics.', 'deprecate_nonmatching_rows')
), deprecated AS (
  UPDATE public.card_battle_rules r
  SET review_status = 'deprecated', execution_status = 'disabled', updated_at = now(),
      notes = concat_ws(E'\n', nullif(r.notes, ''), 'PG257: disabled stale static restriction shadow before exact Phyrexian Censor promotion.')
  FROM proposed p
  WHERE r.normalized_name = p.normalized_name
    AND p.shadow_handling = 'deprecate_nonmatching_rows'
    AND r.logical_rule_key <> p.logical_rule_key
    AND (r.review_status <> 'deprecated' OR r.execution_status <> 'disabled')
  RETURNING r.*
), target_cards AS (
  SELECT DISTINCT ON (p.normalized_name) p.normalized_name, c.id, c.name
  FROM proposed p
  JOIN public.cards c
    ON (lower(c.name) = p.normalized_name OR split_part(lower(c.name), ' // ', 1) = p.normalized_name)
   AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
  ORDER BY p.normalized_name, c.name
), upserted AS (
  INSERT INTO public.card_battle_rules (normalized_name, logical_rule_key, card_id, card_name, effect_json, deck_role_json, source, confidence, review_status, execution_status, rule_version, oracle_hash, notes, reviewed_by, reviewed_at, created_at, updated_at, last_seen_at)
  SELECT p.normalized_name, p.logical_rule_key, tc.id, tc.name, p.effect_json, p.deck_role_json, p.source, p.confidence, p.review_status, p.execution_status, 1, p.oracle_hash, p.notes, 'codex-pg257', now(), now(), now(), now()
  FROM proposed p
  JOIN target_cards tc ON tc.normalized_name = p.normalized_name
  ON CONFLICT (normalized_name, logical_rule_key) DO UPDATE
  SET card_id=EXCLUDED.card_id, card_name=EXCLUDED.card_name, effect_json=EXCLUDED.effect_json, deck_role_json=EXCLUDED.deck_role_json, source=EXCLUDED.source, confidence=EXCLUDED.confidence, review_status=EXCLUDED.review_status, execution_status=EXCLUDED.execution_status, rule_version=EXCLUDED.rule_version, oracle_hash=EXCLUDED.oracle_hash, notes=EXCLUDED.notes, reviewed_by=EXCLUDED.reviewed_by, reviewed_at=EXCLUDED.reviewed_at, updated_at=now(), last_seen_at=now()
  RETURNING *
)
SELECT (SELECT count(*) FROM deprecated) AS deprecated_rows, (SELECT count(*) FROM upserted) AS upserted_rows;

COMMIT;
