BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('atzocan seer', 'blitzball', 'infernal idol', 'sunset strikemaster', 'unstable obelisk')
   OR normalized_name LIKE 'atzocan seer // %'
   OR normalized_name LIKE 'blitzball // %'
   OR normalized_name LIKE 'infernal idol // %'
   OR normalized_name LIKE 'sunset strikemaster // %'
   OR normalized_name LIKE 'unstable obelisk // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg555_independent_mana_aux_new_server_in_20260706_062953;

COMMIT;
