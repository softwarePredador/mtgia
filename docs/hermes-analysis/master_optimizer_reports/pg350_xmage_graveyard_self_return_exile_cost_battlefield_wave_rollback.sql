BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('bone dragon', 'despoiler of souls', 'scrapheap scrounger')
   OR normalized_name LIKE 'bone dragon // %'
   OR normalized_name LIKE 'despoiler of souls // %'
   OR normalized_name LIKE 'scrapheap scrounger // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg350_xmage_graveyard_self_return_exile_cost_battlefield;

COMMIT;
