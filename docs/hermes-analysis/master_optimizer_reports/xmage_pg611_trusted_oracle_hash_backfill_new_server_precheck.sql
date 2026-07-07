WITH target(normalized_name, logical_rule_key) AS (
  VALUES
  ('akroma''s will', 'battle_rule_v1:1134718ef1509d04fbc1291dbdbdf23e'),
  ('ancient den', 'battle_rule_v1:ea7e00f2d90b2ceead4036ab10cd0200'),
  ('ancient tomb', 'battle_rule_v1:c364544e9bd651211acf851db2313ccd'),
  ('angel''s grace', 'battle_rule_v1:2833836fd4d943d3e02d1cfa2d284227'),
  ('basking broodscale', 'battle_rule_v1:4a8564b60f39507bb2bb7fe5ca0b3a72'),
  ('chromatic star', 'battle_rule_v1:7ff862e1720f195ee0374e3a6767b0da'),
  ('dismember', 'battle_rule_v1:2f513570333d9f48be476602a7ce1593'),
  ('entomb', 'battle_rule_v1:eb8223965ca43b8748902c1f16770332'),
  ('everflowing chalice', 'battle_rule_v1:67f848a7a9f40c7337ec0c13e0c1de7c'),
  ('fellwar stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba'),
  ('formidable speaker', 'battle_rule_v1:ba0c54df93c61d9c92a11905c50b7bea'),
  ('gemstone caverns', 'battle_rule_v1:9384b4cf2ffc3b4afc5cb65fb4febaea'),
  ('great furnace', 'battle_rule_v1:9a28465081dd2ac48819f94e919646a6'),
  ('hall of heliod''s generosity', 'battle_rule_v1:4bddcb4c084d969a7ac60a4e378b06dd'),
  ('inventors'' fair', 'battle_rule_v1:c11487143935b327650306d7e7e8c8e2'),
  ('library of leng', 'battle_rule_v1:b6491cf6f7d7df9a3fb0d91abd3d31c3'),
  ('lumra, bellow of the woods', 'battle_rule_v1:847f9ee3ec1da14f043c8a52a4dbfb52'),
  ('mana vault', 'battle_rule_v1:5a2533694ffd19223d3cde1e25d258ff'),
  ('mox amber', 'battle_rule_v1:972703914ee50acd7a4e6f529fea1adf'),
  ('natural order', 'battle_rule_v1:8a9cf49fe56ad1fabdb48aead5531bd1'),
  ('rampant growth', 'battle_rule_v1:439f162ed0ffa2321dd21b0692f07af4'),
  ('reanimate', 'battle_rule_v1:853d724485700fc5e29a050e9f5856a4'),
  ('runaway steam-kin', 'battle_rule_v1:955e0141660dfdc8b31aaf15056693aa'),
  ('sami''s curiosity', 'battle_rule_v1:b25c35d72e00a057dc20945c38059d0e'),
  ('scavenging ooze', 'battle_rule_v1:c6c94f94c02d497596c4f1b1cd05a9bd'),
  ('scroll rack', 'battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2'),
  ('seething song', 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7'),
  ('silence', 'battle_rule_v1:74b210b77b004a677906e0216d44e445'),
  ('skullclamp', 'battle_rule_v1:f996204e0cd900b700b6bf7defb607a6'),
  ('soul-guide lantern', 'battle_rule_v1:3454aa122d10a4abd906132eb7745339'),
  ('splendid reclamation', 'battle_rule_v1:323e4e2c6e95da761c1614e4dff44778'),
  ('staff of compleation', 'battle_rule_v1:d464d25de43eb912c79baea1cee783e5'),
  ('sunbaked canyon', 'battle_rule_v1:07c97c73f65d524510e30b6bbfca0b61'),
  ('talisman of conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470'),
  ('unexpected windfall', 'battle_rule_v1:f9f98ea1925518eea7a7c94c21ef2dc4'),
  ('urza''s saga', 'battle_rule_v1:b62b6dfa5cdc9db4b8b21faf7bfc0498'),
  ('valakut awakening', 'battle_rule_v1:245b8d2627720fadfd7a30464d07605a'),
  ('valakut awakening // valakut stoneforge', 'battle_rule_v1:6e1f3b876822abafe1de47610f46858d'),
  ('vexing bauble', 'battle_rule_v1:6a85170698c85498bf618c0c0283a770'),
  ('wall of omens', 'battle_rule_v1:ee84dfe5a22708bf0b0ef435699ed7a4'),
  ('war room', 'battle_rule_v1:9cdb33ac0e813c0a25d960b65dbc7417'),
  ('wayfarer''s bauble', 'battle_rule_v1:97eb0d5868d1c777b74aa7d35fc85eab'),
  ('worldfire', 'battle_rule_v1:1b9bb9bfd6774cc55d21e50009efa9f3'),
  ('zuran orb', 'battle_rule_v1:d977323f1ef9834d148ef87dc519ba37')
),
candidate AS (
  SELECT r.card_name, r.normalized_name, r.logical_rule_key, c.name AS matched_card,
         md5(coalesce(c.oracle_text, '')) AS computed_oracle_hash
  FROM card_battle_rules r
  JOIN target t USING (normalized_name, logical_rule_key)
  JOIN cards c ON c.id = r.card_id
  WHERE r.source IN ('curated', 'manual')
    AND r.review_status IN ('verified', 'active')
    AND r.execution_status IN ('auto', 'executable')
    AND coalesce(r.oracle_hash, '') = ''
    AND coalesce(c.oracle_text, '') <> ''
)
SELECT count(*) AS target_rows,
       count(computed_oracle_hash) AS rows_with_computed_oracle_hash
FROM candidate;

WITH target(normalized_name, logical_rule_key) AS (
  VALUES
  ('akroma''s will', 'battle_rule_v1:1134718ef1509d04fbc1291dbdbdf23e'),
  ('ancient den', 'battle_rule_v1:ea7e00f2d90b2ceead4036ab10cd0200'),
  ('ancient tomb', 'battle_rule_v1:c364544e9bd651211acf851db2313ccd'),
  ('angel''s grace', 'battle_rule_v1:2833836fd4d943d3e02d1cfa2d284227'),
  ('basking broodscale', 'battle_rule_v1:4a8564b60f39507bb2bb7fe5ca0b3a72'),
  ('chromatic star', 'battle_rule_v1:7ff862e1720f195ee0374e3a6767b0da'),
  ('dismember', 'battle_rule_v1:2f513570333d9f48be476602a7ce1593'),
  ('entomb', 'battle_rule_v1:eb8223965ca43b8748902c1f16770332'),
  ('everflowing chalice', 'battle_rule_v1:67f848a7a9f40c7337ec0c13e0c1de7c'),
  ('fellwar stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba'),
  ('formidable speaker', 'battle_rule_v1:ba0c54df93c61d9c92a11905c50b7bea'),
  ('gemstone caverns', 'battle_rule_v1:9384b4cf2ffc3b4afc5cb65fb4febaea'),
  ('great furnace', 'battle_rule_v1:9a28465081dd2ac48819f94e919646a6'),
  ('hall of heliod''s generosity', 'battle_rule_v1:4bddcb4c084d969a7ac60a4e378b06dd'),
  ('inventors'' fair', 'battle_rule_v1:c11487143935b327650306d7e7e8c8e2'),
  ('library of leng', 'battle_rule_v1:b6491cf6f7d7df9a3fb0d91abd3d31c3'),
  ('lumra, bellow of the woods', 'battle_rule_v1:847f9ee3ec1da14f043c8a52a4dbfb52'),
  ('mana vault', 'battle_rule_v1:5a2533694ffd19223d3cde1e25d258ff'),
  ('mox amber', 'battle_rule_v1:972703914ee50acd7a4e6f529fea1adf'),
  ('natural order', 'battle_rule_v1:8a9cf49fe56ad1fabdb48aead5531bd1'),
  ('rampant growth', 'battle_rule_v1:439f162ed0ffa2321dd21b0692f07af4'),
  ('reanimate', 'battle_rule_v1:853d724485700fc5e29a050e9f5856a4'),
  ('runaway steam-kin', 'battle_rule_v1:955e0141660dfdc8b31aaf15056693aa'),
  ('sami''s curiosity', 'battle_rule_v1:b25c35d72e00a057dc20945c38059d0e'),
  ('scavenging ooze', 'battle_rule_v1:c6c94f94c02d497596c4f1b1cd05a9bd'),
  ('scroll rack', 'battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2'),
  ('seething song', 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7'),
  ('silence', 'battle_rule_v1:74b210b77b004a677906e0216d44e445'),
  ('skullclamp', 'battle_rule_v1:f996204e0cd900b700b6bf7defb607a6'),
  ('soul-guide lantern', 'battle_rule_v1:3454aa122d10a4abd906132eb7745339'),
  ('splendid reclamation', 'battle_rule_v1:323e4e2c6e95da761c1614e4dff44778'),
  ('staff of compleation', 'battle_rule_v1:d464d25de43eb912c79baea1cee783e5'),
  ('sunbaked canyon', 'battle_rule_v1:07c97c73f65d524510e30b6bbfca0b61'),
  ('talisman of conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470'),
  ('unexpected windfall', 'battle_rule_v1:f9f98ea1925518eea7a7c94c21ef2dc4'),
  ('urza''s saga', 'battle_rule_v1:b62b6dfa5cdc9db4b8b21faf7bfc0498'),
  ('valakut awakening', 'battle_rule_v1:245b8d2627720fadfd7a30464d07605a'),
  ('valakut awakening // valakut stoneforge', 'battle_rule_v1:6e1f3b876822abafe1de47610f46858d'),
  ('vexing bauble', 'battle_rule_v1:6a85170698c85498bf618c0c0283a770'),
  ('wall of omens', 'battle_rule_v1:ee84dfe5a22708bf0b0ef435699ed7a4'),
  ('war room', 'battle_rule_v1:9cdb33ac0e813c0a25d960b65dbc7417'),
  ('wayfarer''s bauble', 'battle_rule_v1:97eb0d5868d1c777b74aa7d35fc85eab'),
  ('worldfire', 'battle_rule_v1:1b9bb9bfd6774cc55d21e50009efa9f3'),
  ('zuran orb', 'battle_rule_v1:d977323f1ef9834d148ef87dc519ba37')
)
SELECT r.card_name, r.review_status, r.execution_status, c.name AS matched_card,
       md5(coalesce(c.oracle_text, '')) AS computed_oracle_hash
FROM card_battle_rules r
JOIN target t USING (normalized_name, logical_rule_key)
JOIN cards c ON c.id = r.card_id
ORDER BY r.card_name, r.logical_rule_key;
