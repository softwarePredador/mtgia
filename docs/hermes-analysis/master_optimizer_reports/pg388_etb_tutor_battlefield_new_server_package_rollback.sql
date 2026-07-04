BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('farhaven elf', 'kor cartographer', 'ondu giant', 'quandrix cultivator', 'quirion trailblazer', 'silverglade elemental', 'wild wanderer', 'wood elves')
   OR normalized_name LIKE 'farhaven elf // %'
   OR normalized_name LIKE 'kor cartographer // %'
   OR normalized_name LIKE 'ondu giant // %'
   OR normalized_name LIKE 'quandrix cultivator // %'
   OR normalized_name LIKE 'quirion trailblazer // %'
   OR normalized_name LIKE 'silverglade elemental // %'
   OR normalized_name LIKE 'wild wanderer // %'
   OR normalized_name LIKE 'wood elves // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg388_etb_tutor_battlefield_new_server_20260704_pg388_et;

COMMIT;
