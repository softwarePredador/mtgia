BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('heraldic banner')
   OR normalized_name LIKE 'heraldic banner // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg820_heraldic_banner_chosen_color_stati_20260712_084027;

COMMIT;
