BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('common crook', 'dire fleet hoarder', 'gleaming barrier', 'jewel-eyed cobra', 'piggy bank')
   OR normalized_name LIKE 'common crook // %'
   OR normalized_name LIKE 'dire fleet hoarder // %'
   OR normalized_name LIKE 'gleaming barrier // %'
   OR normalized_name LIKE 'jewel-eyed cobra // %'
   OR normalized_name LIKE 'piggy bank // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg541_dies_treasure_new_server_pg541_die_20260706_013556;

COMMIT;
