BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('fiery intervention', 'molten blast', 'ready to rumble', 'rip apart', 'start from scratch')
   OR normalized_name LIKE 'fiery intervention // %'
   OR normalized_name LIKE 'molten blast // %'
   OR normalized_name LIKE 'ready to rumble // %'
   OR normalized_name LIKE 'rip apart // %'
   OR normalized_name LIKE 'start from scratch // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg639_modal_damage_destroy_new_server_20260707_205654;

COMMIT;
