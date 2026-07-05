BEGIN;

DELETE FROM public.card_battle_rules r
WHERE (
        r.normalized_name = 'brain in a jar'
        OR r.normalized_name LIKE 'brain in a jar // %'
      )
  AND r.logical_rule_key = 'battle_rule_v1:aedfa4929249f55c1d607effe109f3f3';

INSERT INTO public.card_battle_rules
SELECT b.*
FROM manaloom_deploy_audit.lorehold_brain_in_a_jar_pg_package_20260705_post_authorized_full_validation_backup b
WHERE NOT EXISTS (
  SELECT 1
  FROM public.card_battle_rules r
  WHERE r.normalized_name = b.normalized_name
    AND r.logical_rule_key = b.logical_rule_key
);

COMMIT;
