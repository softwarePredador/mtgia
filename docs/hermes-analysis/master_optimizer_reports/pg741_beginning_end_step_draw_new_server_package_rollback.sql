BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('deathreap ritual', 'mercadian atlas', 'owlbear shepherd', 'sygg, river cutthroat', 'the gaffer', 'twinblade assassins', 'well of discovery')
   OR normalized_name LIKE 'deathreap ritual // %'
   OR normalized_name LIKE 'mercadian atlas // %'
   OR normalized_name LIKE 'owlbear shepherd // %'
   OR normalized_name LIKE 'sygg, river cutthroat // %'
   OR normalized_name LIKE 'the gaffer // %'
   OR normalized_name LIKE 'twinblade assassins // %'
   OR normalized_name LIKE 'well of discovery // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg741_beginning_end_step_draw_new_server_20260711_045427;

COMMIT;
