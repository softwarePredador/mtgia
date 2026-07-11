BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('gilanra, caller of wirewood', 'lapis orb of dragonkind', 'scaled nurturer')
   OR normalized_name LIKE 'gilanra, caller of wirewood // %'
   OR normalized_name LIKE 'lapis orb of dragonkind // %'
   OR normalized_name LIKE 'scaled nurturer // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg757_mana_spent_cast_trigger_new_server_20260711_105415;

COMMIT;
