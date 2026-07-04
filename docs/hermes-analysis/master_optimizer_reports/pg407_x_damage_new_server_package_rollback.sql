BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('blaze', 'heat ray', 'volcanic geyser')
   OR normalized_name LIKE 'blaze // %'
   OR normalized_name LIKE 'heat ray // %'
   OR normalized_name LIKE 'volcanic geyser // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg407_x_damage_new_server_package_20260704_132533;

COMMIT;
