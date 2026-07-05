-- Lorehold external identity cache apply package.
-- Report-only generated SQL. Review before executing against local SQLite.
INSERT INTO card_oracle_cache (
  normalized_name,
  name,
  mana_cost,
  colors_json,
  color_identity_json,
  type_line,
  oracle_text,
  cmc,
  power,
  toughness,
  keywords_json,
  scryfall_id,
  source,
  updated_at,
  card_id
) VALUES
  ('anointed procession', 'Anointed Procession', '{3}{W}', '["W"]', '["W"]', 'Enchantment', 'If an effect would create one or more tokens under your control, it creates twice that many of those tokens instead.', 4.0, NULL, NULL, '[]', '9a52c265-6920-4929-ba0a-70da08df01f1', 'lorehold_external_identity_resolution_queue_20260705_current', '2026-07-05T01:45:52Z', '9a52c265-6920-4929-ba0a-70da08df01f1'),
  ('brain in a jar', 'Brain in a Jar', '{2}', '[]', '[]', 'Artifact', '{1}, {T}: Put a charge counter on this artifact, then you may cast an instant or sorcery spell with mana value equal to the number of charge counters on this artifact from your hand without paying its mana cost.
{3}, {T}, Remove X charge counters from this artifact: Scry X.', 2.0, NULL, NULL, '["Scry"]', '88ecfcbe-e8db-4f08-aa8b-5b7b3e6c6ce7', 'lorehold_external_identity_resolution_queue_20260705_current', '2026-07-05T01:45:52Z', '88ecfcbe-e8db-4f08-aa8b-5b7b3e6c6ce7'),
  ('entreat the angels', 'Entreat the Angels', '{X}{X}{W}{W}{W}', '["W"]', '["W"]', 'Sorcery', 'Create X 4/4 white Angel creature tokens with flying.
Miracle {X}{W}{W} (You may cast this card for its miracle cost when you draw it if it''s the first card you drew this turn.)', 3.0, NULL, NULL, '["Miracle"]', 'ff4411bc-ed4e-4d54-9e1b-21fc77b0e415', 'lorehold_external_identity_resolution_queue_20260705_current', '2026-07-05T01:45:52Z', 'ff4411bc-ed4e-4d54-9e1b-21fc77b0e415'),
  ('haze of rage', 'Haze of Rage', '{1}{R}', '["R"]', '["R"]', 'Sorcery', 'Buyback {2} (You may pay an additional {2} as you cast this spell. If you do, put this card into your hand as it resolves.)
Creatures you control get +1/+0 until end of turn.
Storm (When you cast this spell, copy it for each spell cast before it this turn.)', 2.0, NULL, NULL, '["Storm","Buyback"]', 'c344b885-68c6-43d2-b6c1-6c89b3c94983', 'lorehold_external_identity_resolution_queue_20260705_current', '2026-07-05T01:45:52Z', 'c344b885-68c6-43d2-b6c1-6c89b3c94983'),
  ('late to dinner', 'Late to Dinner', '{3}{W}', '["W"]', '["W"]', 'Sorcery', 'Return target creature card from your graveyard to the battlefield. Create a Food token. (It''s an artifact with "{2}, {T}, Sacrifice this token: You gain 3 life.")', 4.0, NULL, NULL, '["Food"]', '6633cab9-23f9-474e-96f1-ca7c0c67691c', 'lorehold_external_identity_resolution_queue_20260705_current', '2026-07-05T01:45:52Z', '6633cab9-23f9-474e-96f1-ca7c0c67691c'),
  ('miraculous recovery', 'Miraculous Recovery', '{4}{W}', '["W"]', '["W"]', 'Instant', 'Return target creature card from your graveyard to the battlefield. Put a +1/+1 counter on it.', 5.0, NULL, NULL, '[]', '2b3459d9-a667-4cee-9b39-844013576d0b', 'lorehold_external_identity_resolution_queue_20260705_current', '2026-07-05T01:45:52Z', '2b3459d9-a667-4cee-9b39-844013576d0b'),
  ('strata scythe', 'Strata Scythe', '{3}', '[]', '[]', 'Artifact — Equipment', 'Imprint — When this Equipment enters, search your library for a land card, exile it, then shuffle.
Equipped creature gets +1/+1 for each land on the battlefield with the same name as the exiled card.
Equip {3}', 3.0, NULL, NULL, '["Equip","Imprint"]', '4d623951-3896-494d-bcc5-6caf3cc74bc6', 'lorehold_external_identity_resolution_queue_20260705_current', '2026-07-05T01:45:52Z', '4d623951-3896-494d-bcc5-6caf3cc74bc6');
