BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('accorder''s shield', 'aeronaut''s wings', 'barbed battlegear', 'behemoth sledge', 'bone saw', 'bonesplitter', 'brawler''s plate', 'bronze sword', 'cathar''s shield', 'ceremonial groundbreaker', 'chitinous cloak', 'crystal slipper', 'cultist''s staff', 'dúnedain blade', 'gorgon flail', 'greataxe', 'greatsword', 'honed khopesh', 'kite shield', 'kitesail', 'kor halberd', 'leonin scimitar', 'loxodon warhammer', 'marauder''s axe', 'mask of avacyn', 'no-dachi', 'ogre''s cleaver', 'riot gear', 'short bow', 'short sword', 'shuko', 'slagwurm armor', 'spidersilk net', 'steelclaw lance', 'strider harness', 'sword of vengeance', 'team pennant', 'thinking cap', 'torch gauntlet', 'trusty machete', 'vanquisher''s axe', 'veteran''s powerblade', 'veteran''s sidearm', 'viridian claw', 'vulshok battlegear', 'vulshok morningstar', 'warlord''s axe')
   OR normalized_name LIKE 'accorder''s shield // %'
   OR normalized_name LIKE 'aeronaut''s wings // %'
   OR normalized_name LIKE 'barbed battlegear // %'
   OR normalized_name LIKE 'behemoth sledge // %'
   OR normalized_name LIKE 'bone saw // %'
   OR normalized_name LIKE 'bonesplitter // %'
   OR normalized_name LIKE 'brawler''s plate // %'
   OR normalized_name LIKE 'bronze sword // %'
   OR normalized_name LIKE 'cathar''s shield // %'
   OR normalized_name LIKE 'ceremonial groundbreaker // %'
   OR normalized_name LIKE 'chitinous cloak // %'
   OR normalized_name LIKE 'crystal slipper // %'
   OR normalized_name LIKE 'cultist''s staff // %'
   OR normalized_name LIKE 'dúnedain blade // %'
   OR normalized_name LIKE 'gorgon flail // %'
   OR normalized_name LIKE 'greataxe // %'
   OR normalized_name LIKE 'greatsword // %'
   OR normalized_name LIKE 'honed khopesh // %'
   OR normalized_name LIKE 'kite shield // %'
   OR normalized_name LIKE 'kitesail // %'
   OR normalized_name LIKE 'kor halberd // %'
   OR normalized_name LIKE 'leonin scimitar // %'
   OR normalized_name LIKE 'loxodon warhammer // %'
   OR normalized_name LIKE 'marauder''s axe // %'
   OR normalized_name LIKE 'mask of avacyn // %'
   OR normalized_name LIKE 'no-dachi // %'
   OR normalized_name LIKE 'ogre''s cleaver // %'
   OR normalized_name LIKE 'riot gear // %'
   OR normalized_name LIKE 'short bow // %'
   OR normalized_name LIKE 'short sword // %'
   OR normalized_name LIKE 'shuko // %'
   OR normalized_name LIKE 'slagwurm armor // %'
   OR normalized_name LIKE 'spidersilk net // %'
   OR normalized_name LIKE 'steelclaw lance // %'
   OR normalized_name LIKE 'strider harness // %'
   OR normalized_name LIKE 'sword of vengeance // %'
   OR normalized_name LIKE 'team pennant // %'
   OR normalized_name LIKE 'thinking cap // %'
   OR normalized_name LIKE 'torch gauntlet // %'
   OR normalized_name LIKE 'trusty machete // %'
   OR normalized_name LIKE 'vanquisher''s axe // %'
   OR normalized_name LIKE 'veteran''s powerblade // %'
   OR normalized_name LIKE 'veteran''s sidearm // %'
   OR normalized_name LIKE 'viridian claw // %'
   OR normalized_name LIKE 'vulshok battlegear // %'
   OR normalized_name LIKE 'vulshok morningstar // %'
   OR normalized_name LIKE 'warlord''s axe // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg530_equipment_static_pt_new_server_20260705_205635;

COMMIT;
