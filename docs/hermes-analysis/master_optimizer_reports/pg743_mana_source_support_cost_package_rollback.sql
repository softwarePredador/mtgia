BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('citanul stalwart', 'jaspera sentinel', 'loam dryad', 'saruli caretaker')
   OR normalized_name LIKE 'citanul stalwart // %'
   OR normalized_name LIKE 'jaspera sentinel // %'
   OR normalized_name LIKE 'loam dryad // %'
   OR normalized_name LIKE 'saruli caretaker // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg743_mana_source_support_cost_new_serve_20260711_055411;

COMMIT;
