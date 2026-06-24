BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('grim monolith', 'basalt monolith')
   OR normalized_name LIKE 'grim monolith // %'
   OR normalized_name LIKE 'basalt monolith // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg172_monolith_mana_rocks_20260624_122041;

COMMIT;
