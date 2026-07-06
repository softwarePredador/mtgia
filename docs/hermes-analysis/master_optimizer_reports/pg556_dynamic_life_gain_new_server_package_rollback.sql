BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('blessed reversal', 'bountiful harvest', 'festival of trokin', 'fruition', 'gerrard''s wisdom', 'invigorating falls', 'joyous respite', 'landbind ritual', 'peach garden oath', 'presence of the wise', 'toil to renown', 'wandering stream')
   OR normalized_name LIKE 'blessed reversal // %'
   OR normalized_name LIKE 'bountiful harvest // %'
   OR normalized_name LIKE 'festival of trokin // %'
   OR normalized_name LIKE 'fruition // %'
   OR normalized_name LIKE 'gerrard''s wisdom // %'
   OR normalized_name LIKE 'invigorating falls // %'
   OR normalized_name LIKE 'joyous respite // %'
   OR normalized_name LIKE 'landbind ritual // %'
   OR normalized_name LIKE 'peach garden oath // %'
   OR normalized_name LIKE 'presence of the wise // %'
   OR normalized_name LIKE 'toil to renown // %'
   OR normalized_name LIKE 'wandering stream // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg556_dynamic_life_gain_new_server_dynam_20260706_065301;

COMMIT;
