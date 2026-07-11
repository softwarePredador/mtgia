BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('banishment decree', 'disempower', 'eternal isolation', 'excommunicate', 'fallow earth', 'forced landing', 'forced retreat', 'griptide', 'mystic repeal', 'natural obsolescence', 'plow under', 'rebuking ceremony', 'repel', 'run aground', 'temporal eddy', 'temporal spring', 'time ebb', 'totally lost', 'uproot')
   OR normalized_name LIKE 'banishment decree // %'
   OR normalized_name LIKE 'disempower // %'
   OR normalized_name LIKE 'eternal isolation // %'
   OR normalized_name LIKE 'excommunicate // %'
   OR normalized_name LIKE 'fallow earth // %'
   OR normalized_name LIKE 'forced landing // %'
   OR normalized_name LIKE 'forced retreat // %'
   OR normalized_name LIKE 'griptide // %'
   OR normalized_name LIKE 'mystic repeal // %'
   OR normalized_name LIKE 'natural obsolescence // %'
   OR normalized_name LIKE 'plow under // %'
   OR normalized_name LIKE 'rebuking ceremony // %'
   OR normalized_name LIKE 'repel // %'
   OR normalized_name LIKE 'run aground // %'
   OR normalized_name LIKE 'temporal eddy // %'
   OR normalized_name LIKE 'temporal spring // %'
   OR normalized_name LIKE 'time ebb // %'
   OR normalized_name LIKE 'totally lost // %'
   OR normalized_name LIKE 'uproot // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg751_put_target_on_library_new_server_p_20260711_090349;

COMMIT;
