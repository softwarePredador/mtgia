BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('currency converter')
   OR normalized_name LIKE 'currency converter // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg270_currency_converter_draw_engine_20260630_currency_c;

COMMIT;
