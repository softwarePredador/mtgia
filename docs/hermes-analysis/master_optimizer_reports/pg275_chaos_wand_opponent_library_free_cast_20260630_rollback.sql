BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('chaos wand')
   OR normalized_name LIKE 'chaos wand // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg275_chaos_wand_opponent_library_free_cast_20260630_202;

COMMIT;
