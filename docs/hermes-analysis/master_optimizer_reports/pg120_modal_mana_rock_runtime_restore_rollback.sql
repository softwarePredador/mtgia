BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('hedron archive', 'mind stone', 'stonespeaker crystal');

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg120_modal_mana_rock_runtime_restore_20260623_224532;

COMMIT;
