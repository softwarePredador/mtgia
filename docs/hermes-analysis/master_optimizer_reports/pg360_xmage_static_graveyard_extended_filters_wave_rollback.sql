BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('runaway trash-bot', 'xande, dark mage')
   OR normalized_name LIKE 'runaway trash-bot // %'
   OR normalized_name LIKE 'xande, dark mage // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg360_xmage_static_graveyard_extended_filters_wave_20260;

COMMIT;
