BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('angel''s feather', 'demon''s horn', 'dragon''s claw', 'kraken''s eye', 'wurm''s tooth')
   OR normalized_name LIKE 'angel''s feather // %'
   OR normalized_name LIKE 'demon''s horn // %'
   OR normalized_name LIKE 'dragon''s claw // %'
   OR normalized_name LIKE 'kraken''s eye // %'
   OR normalized_name LIKE 'wurm''s tooth // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg712_spell_cast_any_player_life_gain_ne_20260710_175213;

COMMIT;
