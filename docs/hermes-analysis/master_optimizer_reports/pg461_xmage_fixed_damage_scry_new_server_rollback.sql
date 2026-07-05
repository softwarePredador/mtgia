BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('bolt of keranos', 'fateful end', 'jaya''s firenado', 'jaya''s greeting', 'lightning javelin', 'magma jet', 'piercing light', 'spark jolt')
   OR normalized_name LIKE 'bolt of keranos // %'
   OR normalized_name LIKE 'fateful end // %'
   OR normalized_name LIKE 'jaya''s firenado // %'
   OR normalized_name LIKE 'jaya''s greeting // %'
   OR normalized_name LIKE 'lightning javelin // %'
   OR normalized_name LIKE 'magma jet // %'
   OR normalized_name LIKE 'piercing light // %'
   OR normalized_name LIKE 'spark jolt // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg461_xmage_fixed_damage_scry_new_server_20260705_005558;

COMMIT;
