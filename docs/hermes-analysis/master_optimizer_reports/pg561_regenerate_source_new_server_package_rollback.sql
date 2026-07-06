BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('ancient silverback', 'asphodel wanderer', 'clay statue', 'cudgel troll', 'diabolic machine', 'drowned', 'drudge skeletons', 'dutiful thrull', 'gorilla chieftain', 'horned troll', 'metathran zombie', 'odious trow', 'pewter golem', 'phyrexian monitor', 'restless dead', 'revered dead', 'selesnya sentry', 'skeletal wurm', 'tangle hulk', 'tel-jilad exile', 'unworthy dead', 'uthden troll', 'votary of the conclave', 'walking dead')
   OR normalized_name LIKE 'ancient silverback // %'
   OR normalized_name LIKE 'asphodel wanderer // %'
   OR normalized_name LIKE 'clay statue // %'
   OR normalized_name LIKE 'cudgel troll // %'
   OR normalized_name LIKE 'diabolic machine // %'
   OR normalized_name LIKE 'drowned // %'
   OR normalized_name LIKE 'drudge skeletons // %'
   OR normalized_name LIKE 'dutiful thrull // %'
   OR normalized_name LIKE 'gorilla chieftain // %'
   OR normalized_name LIKE 'horned troll // %'
   OR normalized_name LIKE 'metathran zombie // %'
   OR normalized_name LIKE 'odious trow // %'
   OR normalized_name LIKE 'pewter golem // %'
   OR normalized_name LIKE 'phyrexian monitor // %'
   OR normalized_name LIKE 'restless dead // %'
   OR normalized_name LIKE 'revered dead // %'
   OR normalized_name LIKE 'selesnya sentry // %'
   OR normalized_name LIKE 'skeletal wurm // %'
   OR normalized_name LIKE 'tangle hulk // %'
   OR normalized_name LIKE 'tel-jilad exile // %'
   OR normalized_name LIKE 'unworthy dead // %'
   OR normalized_name LIKE 'uthden troll // %'
   OR normalized_name LIKE 'votary of the conclave // %'
   OR normalized_name LIKE 'walking dead // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg561_regenerate_source_new_server_pg561_20260706_105239;

COMMIT;
