BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('mana geyser', 'burnt offering')
   OR normalized_name LIKE 'mana geyser // %'
   OR normalized_name LIKE 'burnt offering // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg262_exact_ritual_runtime_20260629_20260629_174351;

COMMIT;
