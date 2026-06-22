\pset pager off
\set ON_ERROR_STOP on

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DROP TABLE IF EXISTS manaloom_deploy_audit.pg019_jin_gitaxias_non_wheel_20260621_013900;
CREATE TABLE manaloom_deploy_audit.pg019_jin_gitaxias_non_wheel_20260621_013900 (
  section text NOT NULL,
  key text NOT NULL,
  payload jsonb NOT NULL,
  captured_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO manaloom_deploy_audit.pg019_jin_gitaxias_non_wheel_20260621_013900
  (section, key, payload)
SELECT
  'card_battle_rules',
  normalized_name || '|' || logical_rule_key,
  to_jsonb(cbr.*)
FROM card_battle_rules cbr
WHERE normalized_name = 'jin-gitaxias, core augur'
  AND logical_rule_key = 'battle_rule_v1:d14acbe78307b4328ec7c6b58500d39e';

DO $$
DECLARE
  v_rule_rows int;
  v_hash text;
BEGIN
  SELECT count(*) INTO v_rule_rows
  FROM card_battle_rules
  WHERE normalized_name = 'jin-gitaxias, core augur'
    AND logical_rule_key = 'battle_rule_v1:d14acbe78307b4328ec7c6b58500d39e'
    AND source = 'curated'
    AND review_status = 'verified'
    AND execution_status = 'auto';

  SELECT md5(regexp_replace(lower(coalesce(oracle_text, '')), '\s+', ' ', 'g'))
  INTO v_hash
  FROM cards
  WHERE lower(name) = 'jin-gitaxias, core augur';

  IF v_rule_rows <> 1 THEN
    RAISE EXCEPTION 'PG019 precondition failed: Jin curated rule rows=% expected 1', v_rule_rows;
  END IF;
  IF v_hash <> '6cbe9a3e4c114022f6a3e1b855bdc392' THEN
    RAISE EXCEPTION 'PG019 precondition failed: oracle_hash=% expected 6cbe9a3e4c114022f6a3e1b855bdc392', v_hash;
  END IF;
END $$;

UPDATE card_battle_rules
SET
  effect_json = effect_json || jsonb_build_object(
    'wheel_like', false,
    'battle_model_scope', 'jin_gitaxias_core_augur_draw_seven_self_only_proxy_max_hand_size_unmodeled_v2'
  ),
  notes = notes || ' PG-019: adds wheel_like=false so draw seven does not use multiplayer wheel discard/draw path; controller-only draw remains a proxy for beginning-of-end-step timing.',
  reviewed_by = 'codex_central_auditor_pg019',
  reviewed_at = now(),
  updated_at = now(),
  last_seen_at = now()
WHERE normalized_name = 'jin-gitaxias, core augur'
  AND logical_rule_key = 'battle_rule_v1:d14acbe78307b4328ec7c6b58500d39e';

DO $$
DECLARE
  v_updated int;
BEGIN
  SELECT count(*) INTO v_updated
  FROM card_battle_rules
  WHERE normalized_name = 'jin-gitaxias, core augur'
    AND logical_rule_key = 'battle_rule_v1:d14acbe78307b4328ec7c6b58500d39e'
    AND effect_json->>'effect' = 'draw_cards'
    AND effect_json->>'count' = '7'
    AND effect_json->>'wheel_like' = 'false'
    AND review_status = 'verified'
    AND execution_status = 'auto'
    AND source = 'curated';

  IF v_updated <> 1 THEN
    RAISE EXCEPTION 'PG019 apply failed: updated non-wheel Jin rule rows=% expected 1', v_updated;
  END IF;
END $$;

COMMIT;
