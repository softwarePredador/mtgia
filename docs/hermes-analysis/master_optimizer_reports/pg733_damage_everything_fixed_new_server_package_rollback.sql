BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('dakmor plague', 'dry spell', 'famine', 'fire tempest', 'inferno', 'rain of embers', 'steam blast')
   OR normalized_name LIKE 'dakmor plague // %'
   OR normalized_name LIKE 'dry spell // %'
   OR normalized_name LIKE 'famine // %'
   OR normalized_name LIKE 'fire tempest // %'
   OR normalized_name LIKE 'inferno // %'
   OR normalized_name LIKE 'rain of embers // %'
   OR normalized_name LIKE 'steam blast // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg733_damage_everything_fixed_new_server_20260711_014908;

COMMIT;
