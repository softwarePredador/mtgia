BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('broken concentration', 'change the equation', 'fervent denial', 'neutralize', 'overwhelming denial', 'spell blast')
   OR normalized_name LIKE 'broken concentration // %'
   OR normalized_name LIKE 'change the equation // %'
   OR normalized_name LIKE 'fervent denial // %'
   OR normalized_name LIKE 'neutralize // %'
   OR normalized_name LIKE 'overwhelming denial // %'
   OR normalized_name LIKE 'spell blast // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg664_counter_oracle_auxiliary_x_modal_n_20260708_170208;

COMMIT;
