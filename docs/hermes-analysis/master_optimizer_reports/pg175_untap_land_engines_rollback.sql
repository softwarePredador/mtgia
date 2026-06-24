BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('candelabra of tawnos', 'earthcraft', 'magus of the candelabra', 'oboro breezecaller')
   OR normalized_name LIKE 'candelabra of tawnos // %'
   OR normalized_name LIKE 'earthcraft // %'
   OR normalized_name LIKE 'magus of the candelabra // %'
   OR normalized_name LIKE 'oboro breezecaller // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg175_untap_land_engines_20260624_130140;

COMMIT;
