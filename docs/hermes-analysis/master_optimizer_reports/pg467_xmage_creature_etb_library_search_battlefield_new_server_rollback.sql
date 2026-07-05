BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('farhaven elf', 'kor cartographer', 'ondu giant', 'quandrix cultivator', 'quirion trailblazer', 'wild wanderer')
   OR normalized_name LIKE 'farhaven elf // %'
   OR normalized_name LIKE 'kor cartographer // %'
   OR normalized_name LIKE 'ondu giant // %'
   OR normalized_name LIKE 'quandrix cultivator // %'
   OR normalized_name LIKE 'quirion trailblazer // %'
   OR normalized_name LIKE 'wild wanderer // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg467_xmage_creature_etb_library_search_battlefield_new_;

COMMIT;
