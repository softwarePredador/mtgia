BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('aesthir glider', 'daggerclaw imp', 'goblin glider', 'iron-barb hellion', 'kyren glider', 'nezumi cutthroat', 'nightshade stinger', 'vampire interloper')
   OR normalized_name LIKE 'aesthir glider // %'
   OR normalized_name LIKE 'daggerclaw imp // %'
   OR normalized_name LIKE 'goblin glider // %'
   OR normalized_name LIKE 'iron-barb hellion // %'
   OR normalized_name LIKE 'kyren glider // %'
   OR normalized_name LIKE 'nezumi cutthroat // %'
   OR normalized_name LIKE 'nightshade stinger // %'
   OR normalized_name LIKE 'vampire interloper // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg805_static_cant_block_with_keywords_ne_20260712_040435;

COMMIT;
