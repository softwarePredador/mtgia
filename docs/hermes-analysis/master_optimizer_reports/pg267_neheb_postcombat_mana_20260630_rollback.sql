BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('neheb, the eternal')
   OR normalized_name LIKE 'neheb, the eternal // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg267_neheb_postcombat_mana_20260630_neheb_postcombat_ma;

COMMIT;
