BEGIN;

CREATE TABLE IF NOT EXISTS public.pg255_fast_mana_runtime_promotions_20260629_backup AS
SELECT now() AS backed_up_at, r.*
FROM public.card_battle_rules r
WHERE false;

INSERT INTO public.pg255_fast_mana_runtime_promotions_20260629_backup
SELECT now() AS backed_up_at, r.*
FROM public.card_battle_rules r
WHERE r.normalized_name IN (SELECT normalized_name FROM (VALUES ('ashnod''s altar'), ('chrome mox'), ('mox diamond')) AS v(normalized_name))
AND NOT EXISTS (
  SELECT 1 FROM public.pg255_fast_mana_runtime_promotions_20260629_backup b
  WHERE b.normalized_name = r.normalized_name
    AND b.logical_rule_key = r.logical_rule_key
);

DO $$
DECLARE v_missing text;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash) AS (VALUES ('ashnod''s altar', 'Ashnod''s Altar', 'dd3e1f004f2b178f31b638fad9cad591'), ('chrome mox', 'Chrome Mox', '44481be7f5347792ede1a9b679a424b3'), ('mox diamond', 'Mox Diamond', '517f664e6c81ce9c204c09a20e14be2d'))
  SELECT string_agg(p.card_name, ', ' ORDER BY p.card_name) INTO v_missing
  FROM proposed p
  WHERE NOT EXISTS (
    SELECT 1 FROM public.cards c
    WHERE (lower(c.name) = p.normalized_name OR split_part(lower(c.name), ' // ', 1) = p.normalized_name)
      AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
  );
  IF v_missing IS NOT NULL THEN
    RAISE EXCEPTION 'PG255 abort: expected at least one Oracle-hash-matched cards row for every proposed card: %', v_missing;
  END IF;
END $$;

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('ashnod''s altar', 'Ashnod''s Altar', 'dd3e1f004f2b178f31b638fad9cad591', 'battle_rule_v1:5fd05007191c6e481e8371724035031c', '{"activated_mana_ability":true,"activation_cost":"sacrifice_creature","battle_model_scope":"activated_sacrifice_creature_add_two_colorless_mana_v1","effect":"passive","mana_produced":2,"produces":"C"}'::jsonb, '{"category":"ramp","effect":"passive","subtype":"sacrifice_mana_outlet"}'::jsonb, 'curated', 0.97, 'verified', 'auto', 'PG255: promoted exact XMage-backed fast-mana runtime rule for Ashnod''s Altar; focused runtime proof covers contextual creature-sacrifice mana activation.', 'deprecate_nonmatching_rows'),
    ('chrome mox', 'Chrome Mox', '44481be7f5347792ede1a9b679a424b3', 'battle_rule_v1:4b4ae6ec37e017046c6671e1a5985f17', '{"battle_model_scope":"zero_mana_artifact_imprint_nonartifact_nonland_tap_add_imprinted_color_v1","effect":"ramp_permanent","is_mana_source":true,"mana_produced":1,"produces":"WUBRG","requires_imprint_nonartifact_nonland":true}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.97, 'verified', 'auto', 'PG255: promoted exact XMage-backed fast-mana runtime rule for Chrome Mox; focused runtime proof covers imprint success and no-valid-imprint failure.', 'deprecate_nonmatching_rows'),
    ('mox diamond', 'Mox Diamond', '517f664e6c81ce9c204c09a20e14be2d', 'battle_rule_v1:0a78dec9b9b2b0b5218b7d0a64a9afb3', '{"battle_model_scope":"zero_mana_artifact_discard_land_etb_tap_add_any_color_v1","effect":"ramp_permanent","is_mana_source":true,"mana_produced":1,"produces":"WUBRG","requires_discard_land":true}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.97, 'verified', 'auto', 'PG255: promoted exact XMage-backed fast-mana runtime rule for Mox Diamond; focused runtime proof covers land discard when it unlocks a commander and refusal without payoff.', 'deprecate_nonmatching_rows')
), deprecated AS (
  UPDATE public.card_battle_rules r
  SET review_status = 'deprecated', execution_status = 'disabled', updated_at = now(),
      notes = concat_ws(E'\n', nullif(r.notes, ''), 'PG255: disabled stale shadow before curated tested exact fast-mana runtime promotion.')
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
  SELECT p.normalized_name, p.logical_rule_key, tc.id, tc.name, p.effect_json, p.deck_role_json, p.source, p.confidence, p.review_status, p.execution_status, 1, p.oracle_hash, p.notes, 'codex-pg255', now(), now(), now(), now()
  FROM proposed p
  JOIN target_cards tc ON tc.normalized_name = p.normalized_name
  ON CONFLICT (normalized_name, logical_rule_key) DO UPDATE
  SET card_id=EXCLUDED.card_id, card_name=EXCLUDED.card_name, effect_json=EXCLUDED.effect_json, deck_role_json=EXCLUDED.deck_role_json, source=EXCLUDED.source, confidence=EXCLUDED.confidence, review_status=EXCLUDED.review_status, execution_status=EXCLUDED.execution_status, rule_version=EXCLUDED.rule_version, oracle_hash=EXCLUDED.oracle_hash, notes=EXCLUDED.notes, reviewed_by=EXCLUDED.reviewed_by, reviewed_at=EXCLUDED.reviewed_at, updated_at=now(), last_seen_at=now()
  RETURNING *
)
SELECT (SELECT count(*) FROM deprecated) AS deprecated_rows, (SELECT count(*) FROM upserted) AS upserted_rows;

COMMIT;
