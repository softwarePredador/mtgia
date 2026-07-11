BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('jade orb of dragonkind')
   OR normalized_name LIKE 'jade orb of dragonkind // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg764_jade_orb_new_server_jade_orb_mana_20260711_132543;

COMMIT;
