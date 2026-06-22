\pset pager off
\set ON_ERROR_STOP on

WITH target AS (
  SELECT '528c877f-f829-4207-95e6-73981776c323'::uuid AS deck_id
)
SELECT
  'pg026_lorehold_magus_sphere_precheck' AS check_name,
  (SELECT count(*) FROM deck_cards dc JOIN target t ON t.deck_id = dc.deck_id) AS deck_rows,
  (SELECT coalesce(sum(quantity), 0) FROM deck_cards dc JOIN target t ON t.deck_id = dc.deck_id) AS deck_qty,
  (SELECT count(*) FROM cards WHERE lower(name) = 'electroduplicate') AS electroduplicate_card_rows,
  (SELECT count(*) FROM cards WHERE lower(name) = 'victory chimes') AS victory_chimes_card_rows,
  (SELECT count(*) FROM cards WHERE lower(name) = 'magus of the moat') AS magus_card_rows,
  (SELECT count(*) FROM cards WHERE lower(name) = 'sphere of safety') AS sphere_card_rows,
  (
    SELECT count(*)
    FROM deck_cards dc
    JOIN cards c ON c.id = dc.card_id
    JOIN target t ON t.deck_id = dc.deck_id
    WHERE lower(c.name) = 'electroduplicate'
  ) AS electroduplicate_deck_rows,
  (
    SELECT coalesce(sum(dc.quantity), 0)
    FROM deck_cards dc
    JOIN cards c ON c.id = dc.card_id
    JOIN target t ON t.deck_id = dc.deck_id
    WHERE lower(c.name) = 'electroduplicate'
  ) AS electroduplicate_deck_qty,
  (
    SELECT count(*)
    FROM deck_cards dc
    JOIN cards c ON c.id = dc.card_id
    JOIN target t ON t.deck_id = dc.deck_id
    WHERE lower(c.name) = 'victory chimes'
  ) AS victory_chimes_deck_rows,
  (
    SELECT coalesce(sum(dc.quantity), 0)
    FROM deck_cards dc
    JOIN cards c ON c.id = dc.card_id
    JOIN target t ON t.deck_id = dc.deck_id
    WHERE lower(c.name) = 'victory chimes'
  ) AS victory_chimes_deck_qty,
  (
    SELECT count(*)
    FROM deck_cards dc
    JOIN cards c ON c.id = dc.card_id
    JOIN target t ON t.deck_id = dc.deck_id
    WHERE lower(c.name) = 'magus of the moat'
  ) AS magus_deck_rows,
  (
    SELECT count(*)
    FROM deck_cards dc
    JOIN cards c ON c.id = dc.card_id
    JOIN target t ON t.deck_id = dc.deck_id
    WHERE lower(c.name) = 'sphere of safety'
  ) AS sphere_deck_rows,
  (
    SELECT count(*)
    FROM cards c
    JOIN card_legalities cl ON cl.card_id = c.id
    WHERE lower(c.name) = 'magus of the moat'
      AND cl.format = 'commander'
      AND cl.status = 'legal'
  ) AS magus_commander_legal_rows,
  (
    SELECT count(*)
    FROM cards c
    JOIN card_legalities cl ON cl.card_id = c.id
    WHERE lower(c.name) = 'sphere of safety'
      AND cl.format = 'commander'
      AND cl.status = 'legal'
  ) AS sphere_commander_legal_rows,
  (
    SELECT count(*)
    FROM card_battle_rules cbr
    JOIN cards c ON c.id = cbr.card_id
    WHERE lower(c.name) = 'magus of the moat'
      AND cbr.logical_rule_key = 'battle_rule_v1:439de5be33887bbce5dde1cfb367774a'
      AND cbr.source = 'curated'
      AND cbr.review_status = 'verified'
      AND cbr.execution_status = 'auto'
      AND cbr.effect_json->>'effect' = 'attack_limit'
      AND cbr.effect_json->>'battle_model_scope' = 'magus_of_the_moat_global_flying_attack_filter_v2'
  ) AS magus_verified_rule_rows,
  (
    SELECT count(*)
    FROM card_battle_rules cbr
    JOIN cards c ON c.id = cbr.card_id
    WHERE lower(c.name) = 'sphere of safety'
      AND cbr.logical_rule_key = 'battle_rule_v1:a619518cf24caa68fdd86b555687f20f'
      AND cbr.source = 'curated'
      AND cbr.review_status = 'verified'
      AND cbr.execution_status = 'auto'
      AND cbr.effect_json->>'effect' = 'attack_tax'
      AND cbr.effect_json->>'battle_model_scope' = 'sphere_of_safety_enchantment_scaled_attack_tax'
  ) AS sphere_verified_rule_rows,
  (
    SELECT count(*)
    FROM information_schema.tables
    WHERE table_schema = 'manaloom_deploy_audit'
      AND table_name = 'pg026_lorehold_magus_sphere_deck_swap_20260622_165810'
  ) AS existing_backup_table_rows;
