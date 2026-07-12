BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('moment of craving', 'moment of triumph', 'syphon fuel', 'tandem tactics')
   OR normalized_name LIKE 'moment of craving // %'
   OR normalized_name LIKE 'moment of triumph // %'
   OR normalized_name LIKE 'syphon fuel // %'
   OR normalized_name LIKE 'tandem tactics // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg795_boost_life_gain_new_server_20260712_002511;

COMMIT;
