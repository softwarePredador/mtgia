BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('bear trap', 'defender of chaos', 'defender of law', 'springjaw trap')
   OR normalized_name LIKE 'bear trap // %'
   OR normalized_name LIKE 'defender of chaos // %'
   OR normalized_name LIKE 'defender of law // %'
   OR normalized_name LIKE 'springjaw trap // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg426_xmage_flash_auxiliary_residuals_new_server_2026070;

COMMIT;
