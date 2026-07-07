BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('celestial prism', 'chromatic sphere', 'mana cylix', 'manalith', 'phyrexian altar')
   OR normalized_name LIKE 'celestial prism // %'
   OR normalized_name LIKE 'chromatic sphere // %'
   OR normalized_name LIKE 'mana cylix // %'
   OR normalized_name LIKE 'manalith // %'
   OR normalized_name LIKE 'phyrexian altar // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg596_any_color_mana_rock_alias_new_serv_20260707_052414;

COMMIT;
