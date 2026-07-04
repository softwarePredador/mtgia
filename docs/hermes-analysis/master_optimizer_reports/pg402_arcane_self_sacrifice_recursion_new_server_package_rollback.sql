BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('hana kami')
   OR normalized_name LIKE 'hana kami // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg402_arcane_self_sacrifice_recursion_new_server_2026070;

COMMIT;
