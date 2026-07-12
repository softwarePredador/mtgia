BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('coldsteel heart', 'silhana starfletcher', 'sol grail')
   OR normalized_name LIKE 'coldsteel heart // %'
   OR normalized_name LIKE 'silhana starfletcher // %'
   OR normalized_name LIKE 'sol grail // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg813_chosen_color_mana_rocks_new_server_20260712_072553;

COMMIT;
