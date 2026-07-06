BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('boggart harbinger', 'campus guide', 'compass gnome', 'faerie harbinger', 'flamekin harbinger', 'giant harbinger', 'giant ladybug', 'kithkin harbinger', 'loam larva', 'scampering surveyor', 'spider-bot')
   OR normalized_name LIKE 'boggart harbinger // %'
   OR normalized_name LIKE 'campus guide // %'
   OR normalized_name LIKE 'compass gnome // %'
   OR normalized_name LIKE 'faerie harbinger // %'
   OR normalized_name LIKE 'flamekin harbinger // %'
   OR normalized_name LIKE 'giant harbinger // %'
   OR normalized_name LIKE 'giant ladybug // %'
   OR normalized_name LIKE 'kithkin harbinger // %'
   OR normalized_name LIKE 'loam larva // %'
   OR normalized_name LIKE 'scampering surveyor // %'
   OR normalized_name LIKE 'spider-bot // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg577_etb_library_tutor_creatures_20260706_222420;

COMMIT;
