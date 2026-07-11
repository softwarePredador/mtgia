BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('limits of solidarity', 'lose calm', 'traitorous blood', 'turn against', 'word of seizing')
   OR normalized_name LIKE 'limits of solidarity // %'
   OR normalized_name LIKE 'lose calm // %'
   OR normalized_name LIKE 'traitorous blood // %'
   OR normalized_name LIKE 'turn against // %'
   OR normalized_name LIKE 'word of seizing // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg760_gain_control_keywords_new_server_g_20260711_121318;

COMMIT;
