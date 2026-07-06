BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('carnassid', 'carrion wall', 'charging troll', 'drudge reavers', 'fog of gnats', 'ghost ship', 'lim-dûl''s high guard', 'living airship', 'living wall', 'malach of the dawn', 'manor skeleton', 'ranger en-vec', 'sanguine guard', 'screeching harpy', 'tattered drake', 'trestle troll', 'wall of bone', 'wall of brambles', 'wall of pine needles', 'will-o''-the-wisp', 'wolfir avenger', 'yavimaya gnats')
   OR normalized_name LIKE 'carnassid // %'
   OR normalized_name LIKE 'carrion wall // %'
   OR normalized_name LIKE 'charging troll // %'
   OR normalized_name LIKE 'drudge reavers // %'
   OR normalized_name LIKE 'fog of gnats // %'
   OR normalized_name LIKE 'ghost ship // %'
   OR normalized_name LIKE 'lim-dûl''s high guard // %'
   OR normalized_name LIKE 'living airship // %'
   OR normalized_name LIKE 'living wall // %'
   OR normalized_name LIKE 'malach of the dawn // %'
   OR normalized_name LIKE 'manor skeleton // %'
   OR normalized_name LIKE 'ranger en-vec // %'
   OR normalized_name LIKE 'sanguine guard // %'
   OR normalized_name LIKE 'screeching harpy // %'
   OR normalized_name LIKE 'tattered drake // %'
   OR normalized_name LIKE 'trestle troll // %'
   OR normalized_name LIKE 'wall of bone // %'
   OR normalized_name LIKE 'wall of brambles // %'
   OR normalized_name LIKE 'wall of pine needles // %'
   OR normalized_name LIKE 'will-o''-the-wisp // %'
   OR normalized_name LIKE 'wolfir avenger // %'
   OR normalized_name LIKE 'yavimaya gnats // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg563_regenerate_static_keyword_new_serv_20260706_112424;

COMMIT;
