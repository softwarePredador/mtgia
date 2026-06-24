BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('elvish spirit guide', 'mountain', 'plains')
   OR normalized_name LIKE 'elvish spirit guide // %'
   OR normalized_name LIKE 'mountain // %'
   OR normalized_name LIKE 'plains // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg168_land_and_hand_exile_20260624_113000;

COMMIT;
