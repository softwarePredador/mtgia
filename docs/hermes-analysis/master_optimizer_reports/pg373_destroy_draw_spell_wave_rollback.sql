BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('aura blast', 'bright reprisal', 'implode', 'mirrodin avenged', 'slice in twain', 'smash', 'you are already dead')
   OR normalized_name LIKE 'aura blast // %'
   OR normalized_name LIKE 'bright reprisal // %'
   OR normalized_name LIKE 'implode // %'
   OR normalized_name LIKE 'mirrodin avenged // %'
   OR normalized_name LIKE 'slice in twain // %'
   OR normalized_name LIKE 'smash // %'
   OR normalized_name LIKE 'you are already dead // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg373_destroy_draw_spell_wave_pg373_destroy_draw_spell_w;

COMMIT;
