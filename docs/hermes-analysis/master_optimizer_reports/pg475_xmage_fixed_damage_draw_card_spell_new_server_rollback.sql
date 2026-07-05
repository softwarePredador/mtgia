BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('ember shot', 'playful shove', 'zap')
   OR normalized_name LIKE 'ember shot // %'
   OR normalized_name LIKE 'playful shove // %'
   OR normalized_name LIKE 'zap // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg475_xmage_fixed_damage_draw_card_spell_new_server_2026;

COMMIT;
