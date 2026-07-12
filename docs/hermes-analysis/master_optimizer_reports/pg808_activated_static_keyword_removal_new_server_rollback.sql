BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('cathar commando', 'daraja griffin', 'goblin firebomb', 'pit trap', 'shattered acolyte', 'tolarian sentinel', 'tradewind rider', 'uktabi faerie', 'undergrowth leopard', 'visara the dreadful', 'voracious varmint')
   OR normalized_name LIKE 'cathar commando // %'
   OR normalized_name LIKE 'daraja griffin // %'
   OR normalized_name LIKE 'goblin firebomb // %'
   OR normalized_name LIKE 'pit trap // %'
   OR normalized_name LIKE 'shattered acolyte // %'
   OR normalized_name LIKE 'tolarian sentinel // %'
   OR normalized_name LIKE 'tradewind rider // %'
   OR normalized_name LIKE 'uktabi faerie // %'
   OR normalized_name LIKE 'undergrowth leopard // %'
   OR normalized_name LIKE 'visara the dreadful // %'
   OR normalized_name LIKE 'voracious varmint // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg808_activated_static_keyword_removal_n_20260712_052844;

COMMIT;
