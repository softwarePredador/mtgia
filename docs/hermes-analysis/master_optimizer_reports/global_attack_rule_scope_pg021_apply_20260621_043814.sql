\pset pager off
\set ON_ERROR_STOP on

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg021_global_attack_rule_scope_20260621_043814 (
  backup_id bigserial PRIMARY KEY,
  backed_up_at timestamptz NOT NULL DEFAULT now(),
  reason text NOT NULL,
  normalized_name text NOT NULL,
  logical_rule_key text NOT NULL,
  payload jsonb NOT NULL
);

DO $$
DECLARE
  v_existing_backup integer;
  v_cards_found integer;
  v_legal_rows integer;
  v_hash_matches integer;
  v_rule_rows integer;
BEGIN
  SELECT COUNT(*)
  INTO v_existing_backup
  FROM manaloom_deploy_audit.pg021_global_attack_rule_scope_20260621_043814;

  IF v_existing_backup <> 0 THEN
    RAISE EXCEPTION 'PG021 backup table already has % row(s), refusing reapply', v_existing_backup;
  END IF;

  WITH wanted(card_name, logical_rule_key, expected_oracle_hash) AS (
    VALUES
      ('Silent Arbiter', 'battle_rule_v1:6f6089b73fb8f7f9aee20cacb64fffc7', '77d31b859247e6129c25b4fa47be336e'),
      ('Magus of the Moat', 'battle_rule_v1:439de5be33887bbce5dde1cfb367774a', 'da1c62032e405fc6fc6151ccdf6df879'),
      ('Ensnaring Bridge', 'battle_rule_v1:1ea5840419f4343c05a661e79d6829d5', 'f5f24e3b4b9f6a52fb0afa1cef9ae3d3')
  )
  SELECT
    count(*) FILTER (WHERE c.id IS NOT NULL),
    count(*) FILTER (WHERE cl.status = 'legal'),
    count(*) FILTER (
      WHERE md5(regexp_replace(lower(coalesce(c.oracle_text, '')), '\s+', ' ', 'g')) = wanted.expected_oracle_hash
    ),
    count(*) FILTER (WHERE cbr.logical_rule_key IS NOT NULL)
  INTO v_cards_found, v_legal_rows, v_hash_matches, v_rule_rows
  FROM wanted
  LEFT JOIN cards c ON lower(c.name) = lower(wanted.card_name)
  LEFT JOIN card_legalities cl ON cl.card_id = c.id AND cl.format = 'commander'
  LEFT JOIN card_battle_rules cbr
    ON cbr.normalized_name = lower(wanted.card_name)
   AND cbr.logical_rule_key = wanted.logical_rule_key;

  IF v_cards_found <> 3 OR v_legal_rows <> 3 OR v_hash_matches <> 3 OR v_rule_rows <> 3 THEN
    RAISE EXCEPTION 'PG021 precondition failed: cards=%, legal=%, hashes=%, rules=%',
      v_cards_found, v_legal_rows, v_hash_matches, v_rule_rows;
  END IF;
END $$;

WITH wanted(card_name, logical_rule_key) AS (
  VALUES
    ('Silent Arbiter', 'battle_rule_v1:6f6089b73fb8f7f9aee20cacb64fffc7'),
    ('Magus of the Moat', 'battle_rule_v1:439de5be33887bbce5dde1cfb367774a'),
    ('Ensnaring Bridge', 'battle_rule_v1:1ea5840419f4343c05a661e79d6829d5')
)
INSERT INTO manaloom_deploy_audit.pg021_global_attack_rule_scope_20260621_043814 (
  reason,
  normalized_name,
  logical_rule_key,
  payload
)
SELECT
  'PG-021: preserve pre-global-scope anti-combat battle rule before oracle-scope correction',
  cbr.normalized_name,
  cbr.logical_rule_key,
  to_jsonb(cbr.*)
FROM card_battle_rules cbr
JOIN wanted w
  ON cbr.normalized_name = lower(w.card_name)
 AND cbr.logical_rule_key = w.logical_rule_key;

WITH updates(card_name, logical_rule_key, effect_json, deck_role_json, notes) AS (
  VALUES
    (
      'Silent Arbiter',
      'battle_rule_v1:6f6089b73fb8f7f9aee20cacb64fffc7',
      jsonb_build_object(
        'effect', 'attack_limit',
        'max_attackers', 1,
        'cmc', 4.0,
        'battle_model_scope', 'silent_arbiter_global_single_attacker_v2'
      ),
      jsonb_build_object(
        'category', 'protection',
        'effect', 'attack_limit',
        'subtype', 'silent_arbiter_global_single_attacker_v2'
      ),
      'PG-021: oracle-scope correction. Silent Arbiter is global: no more than one creature can attack each combat. Runtime now applies max_attackers table-wide; one-blocker clause remains not modeled in this pass.'
    ),
    (
      'Magus of the Moat',
      'battle_rule_v1:439de5be33887bbce5dde1cfb367774a',
      jsonb_build_object(
        'effect', 'attack_limit',
        'attack_requires_keyword', 'flying',
        'cmc', 4.0,
        'battle_model_scope', 'magus_of_the_moat_global_flying_attack_filter_v2'
      ),
      jsonb_build_object(
        'category', 'protection',
        'effect', 'attack_limit',
        'subtype', 'magus_of_the_moat_global_flying_attack_filter_v2'
      ),
      'PG-021: oracle-scope correction. Magus of the Moat is global: all creatures without flying cannot attack, including its controller''s creatures.'
    ),
    (
      'Ensnaring Bridge',
      'battle_rule_v1:1ea5840419f4343c05a661e79d6829d5',
      jsonb_build_object(
        'effect', 'attack_limit',
        'max_attacker_power_by_controller_hand_size', true,
        'cmc', 3.0,
        'battle_model_scope', 'ensnaring_bridge_controller_hand_size_power_filter_v2'
      ),
      jsonb_build_object(
        'category', 'protection',
        'effect', 'attack_limit',
        'subtype', 'ensnaring_bridge_controller_hand_size_power_filter_v2'
      ),
      'PG-021: oracle-scope correction. Ensnaring Bridge is global and uses the Bridge controller hand size, not the defending player hand size.'
    )
)
UPDATE card_battle_rules cbr
SET
  effect_json = updates.effect_json,
  deck_role_json = updates.deck_role_json,
  notes = updates.notes,
  reviewed_by = 'codex_central_auditor_pg021',
  reviewed_at = now(),
  updated_at = now(),
  last_seen_at = now()
FROM updates
WHERE cbr.normalized_name = lower(updates.card_name)
  AND cbr.logical_rule_key = updates.logical_rule_key;

COMMIT;

SELECT
  'pg021_global_attack_rule_scope_apply' AS check_name,
  normalized_name,
  logical_rule_key,
  effect_json,
  notes
FROM card_battle_rules
WHERE (normalized_name, logical_rule_key) IN (
  ('silent arbiter', 'battle_rule_v1:6f6089b73fb8f7f9aee20cacb64fffc7'),
  ('magus of the moat', 'battle_rule_v1:439de5be33887bbce5dde1cfb367774a'),
  ('ensnaring bridge', 'battle_rule_v1:1ea5840419f4343c05a661e79d6829d5')
)
ORDER BY normalized_name;
