BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('agate instigator', 'impact tremors', 'molten gatekeeper')
   OR normalized_name LIKE 'agate instigator // %'
   OR normalized_name LIKE 'impact tremors // %'
   OR normalized_name LIKE 'molten gatekeeper // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg207_creature_etb_damage_20260625_071108;

COMMIT;
