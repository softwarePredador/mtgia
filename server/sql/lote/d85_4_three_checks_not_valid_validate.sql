-- D-85, correção 4: os três CHECK que o banco novo tem e a produção não tem
-- (BT-DB-005, ensaio na estrutura de 2026-09-28) entram na produção só depois de
-- contar zero violações, com `ADD CONSTRAINT ... NOT VALID` e depois `VALIDATE`:
--   - ml_prompt_feedback.chk_ml_prompt_feedback_effectiveness_score;
--   - notifications.notifications_type_check;
--   - user_binder_items.user_binder_items_currency_check.
-- A definição é a do `server/database_setup.sql`. A contagem é a mesma de
-- `server/sql/readonly/bt_db_005_check_violations.sql`: violação é a linha em que a
-- condição dá falso (NULL não viola um CHECK).
--
-- Na gravação (`-v aplicar=1`), duas transações:
--   1. conta as violações e, só com zero em todas, cria os que faltam como NOT VALID
--      (trava curta, sem varrer a tabela; a partir daqui linha nova já é conferida).
--      Uma violação em qualquer um recusa os três e nada é criado;
--   2. valida os que ainda não estão validados (varre a tabela sem bloquear escrita).
-- Se a validação falhar, o CHECK fica NOT VALID (continua barrando linha nova) e o
-- script sai com erro: o dado é tratado e o script roda de novo.
-- Na prévia (o padrão), as duas fases correm numa transação só, que é desfeita
-- (ROLLBACK) no fim; a trava do ADD CONSTRAINT dura até lá (as três tabelas são
-- pequenas, e a prévia leva segundos).
--
-- Roda no lote de deploy, depois da promoção (decisão do dono de 2026-10-10, item 11),
-- pelo wrapper de escrita e com as duas aprovações canônicas no processo chamador.
-- Primeiro a prévia:
--   server/bin/with_new_server_pg.sh --write-approved psql -X -v ON_ERROR_STOP=1 \
--     -At -F $'\t' -f server/sql/lote/d85_4_three_checks_not_valid_validate.sql
-- Depois, com a palavra do dono sobre os números da prévia, a gravação: `-v aplicar=1`
-- exige as duas contagens esperadas da ação e recusa (RAISE) se não baterem. As duas
-- são conferidas na transação 1, antes de criar qualquer CHECK, e cada uma de novo
-- depois da sua ação:
--   ... -v aplicar=1 -v esperado_checks_criados_not_valid=<n da prévia> \
--       -v esperado_checks_validados=<n da prévia> ...
-- Saída: linhas `fase<TAB>objeto<TAB>quantidade` (fases modo, antes, acao e depois); nas
-- linhas `<CHECK>:estado`, a terceira coluna é ausente, not_valid ou validado.
-- Idempotente: a segunda rodada acha os três validados e não muda nada.

\set ON_ERROR_STOP on
\if :{?aplicar}
\else
\set aplicar 0
\endif
\if :{?esperado_checks_criados_not_valid}
\else
\set esperado_checks_criados_not_valid ''
\endif
\if :{?esperado_checks_validados}
\else
\set esperado_checks_validados ''
\endif

-- Transação 1: contar e, com zero, criar NOT VALID. Na prévia, a única.
BEGIN;
SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '120s';
SET LOCAL manaloom.lote_aplicar = :'aplicar';
SET LOCAL manaloom.lote_esperado_checks_criados_not_valid = :'esperado_checks_criados_not_valid';
SET LOCAL manaloom.lote_esperado_checks_validados = :'esperado_checks_validados';

DO $d85_4_modo$
BEGIN
  IF current_setting('manaloom.lote_aplicar') NOT IN ('0', '1') THEN
    RAISE EXCEPTION
      'd85_4 recusado: -v aplicar aceita só 1 (gravar); sem ele o script é prévia. Nada foi mudado.';
  END IF;
  IF current_setting('manaloom.lote_aplicar') = '1' THEN
    IF (
      current_setting('manaloom.lote_esperado_checks_criados_not_valid') !~ '^[0-9]+$'
      OR current_setting('manaloom.lote_esperado_checks_validados') !~ '^[0-9]+$'
    ) THEN
      RAISE EXCEPTION
        'd85_4 recusado: com -v aplicar=1, informe -v esperado_checks_criados_not_valid=<n> e -v esperado_checks_validados=<n> (as contagens da prévia). Nada foi mudado.';
    END IF;
  END IF;
END;
$d85_4_modo$;

SELECT current_setting('manaloom.lote_aplicar') = '1' AS lote_grava \gset

SELECT 'modo' AS fase, 'escrita' AS objeto,
       CASE WHEN current_setting('manaloom.lote_aplicar') = '1'
            THEN 'aplicar' ELSE 'previa' END AS quantidade;

-- Objetos temporários dentro da transação. Na prévia, o ROLLBACK os desfaz; na
-- gravação, a transação 2 os apaga antes do COMMIT.
CREATE TEMP VIEW d85_4_violacoes AS
SELECT 'ml_prompt_feedback.chk_ml_prompt_feedback_effectiveness_score' AS objeto,
       (
         SELECT COUNT(*)
         FROM public.ml_prompt_feedback
         WHERE (
           effectiveness_score IS NULL
           OR (effectiveness_score >= 1 AND effectiveness_score <= 10)
         ) IS FALSE
       ) AS violacoes
UNION ALL
SELECT 'notifications.notifications_type_check',
       (
         SELECT COUNT(*)
         FROM public.notifications
         WHERE (type IN (
           'new_follower', 'trade_offer_received', 'trade_accepted',
           'trade_declined', 'trade_shipped', 'trade_delivered',
           'trade_completed', 'trade_message', 'direct_message'
         )) IS FALSE
       )
UNION ALL
SELECT 'user_binder_items.user_binder_items_currency_check',
       (
         SELECT COUNT(*)
         FROM public.user_binder_items
         WHERE (currency IN ('BRL', 'USD')) IS FALSE
       );

CREATE TEMP VIEW d85_4_estado AS
SELECT esperado.tabela || '.' || esperado.nome AS objeto,
       CASE
         WHEN restricao.oid IS NULL THEN 'ausente'
         WHEN restricao.convalidated THEN 'validado'
         ELSE 'not_valid'
       END AS estado
FROM (
  VALUES
    (1, 'ml_prompt_feedback', 'chk_ml_prompt_feedback_effectiveness_score'),
    (2, 'notifications', 'notifications_type_check'),
    (3, 'user_binder_items', 'user_binder_items_currency_check')
) AS esperado(ordem, tabela, nome)
LEFT JOIN pg_constraint restricao
  ON restricao.conrelid = format('public.%I', esperado.tabela)::regclass
 AND restricao.conname = esperado.nome
 AND restricao.contype = 'c'
ORDER BY esperado.ordem;

SELECT 'antes' AS fase, objeto || ':violacoes' AS objeto, violacoes::text AS quantidade
FROM d85_4_violacoes;

SELECT 'antes' AS fase, objeto || ':estado' AS objeto, estado AS quantidade
FROM d85_4_estado;

DO $d85_4_not_valid$
DECLARE
  recusa TEXT;
  criar_previsto INTEGER;
  validar_previsto INTEGER;
  criados INTEGER := 0;
BEGIN
  SELECT string_agg(
           contagem.objeto || ' (' || contagem.violacoes || ')',
           ', ' ORDER BY contagem.objeto
         )
  INTO recusa
  FROM d85_4_violacoes contagem
  WHERE contagem.violacoes > 0;
  IF recusa IS NOT NULL THEN
    RAISE EXCEPTION
      'd85_4 recusado: há linhas que violam %; trate o dado antes (D-85). Nada foi criado.',
      recusa;
  END IF;

  SELECT COUNT(*) FILTER (WHERE estado = 'ausente'),
         COUNT(*) FILTER (WHERE estado IN ('ausente', 'not_valid'))
  INTO criar_previsto, validar_previsto
  FROM d85_4_estado;
  IF current_setting('manaloom.lote_aplicar') = '1' THEN
    IF (
      criar_previsto
        <> current_setting('manaloom.lote_esperado_checks_criados_not_valid')::integer
      OR validar_previsto
        <> current_setting('manaloom.lote_esperado_checks_validados')::integer
    ) THEN
      RAISE EXCEPTION
        'd85_4 recusado: a ação criaria % e validaria % CHECK(s), e o esperado (-v esperado_checks_criados_not_valid, -v esperado_checks_validados) é % e %. Nada foi criado.',
        criar_previsto, validar_previsto,
        current_setting('manaloom.lote_esperado_checks_criados_not_valid'),
        current_setting('manaloom.lote_esperado_checks_validados');
    END IF;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'public.ml_prompt_feedback'::regclass
      AND conname = 'chk_ml_prompt_feedback_effectiveness_score'
  ) THEN
    ALTER TABLE public.ml_prompt_feedback
      ADD CONSTRAINT chk_ml_prompt_feedback_effectiveness_score
      CHECK (
        effectiveness_score IS NULL
        OR (effectiveness_score >= 1 AND effectiveness_score <= 10)
      ) NOT VALID;
    criados := criados + 1;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'public.notifications'::regclass
      AND conname = 'notifications_type_check'
  ) THEN
    ALTER TABLE public.notifications
      ADD CONSTRAINT notifications_type_check
      CHECK (type IN (
        'new_follower', 'trade_offer_received', 'trade_accepted',
        'trade_declined', 'trade_shipped', 'trade_delivered',
        'trade_completed', 'trade_message', 'direct_message'
      )) NOT VALID;
    criados := criados + 1;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'public.user_binder_items'::regclass
      AND conname = 'user_binder_items_currency_check'
  ) THEN
    ALTER TABLE public.user_binder_items
      ADD CONSTRAINT user_binder_items_currency_check
      CHECK (currency IN ('BRL', 'USD')) NOT VALID;
    criados := criados + 1;
  END IF;

  IF current_setting('manaloom.lote_aplicar') = '1' THEN
    IF criados
       <> current_setting('manaloom.lote_esperado_checks_criados_not_valid')::integer THEN
      RAISE EXCEPTION
        'd85_4 recusado: a ação criou % CHECK(s) e o esperado é %. Nada foi criado.',
        criados, current_setting('manaloom.lote_esperado_checks_criados_not_valid');
    END IF;
  END IF;
  PERFORM set_config('manaloom.d85_4_criados', criados::text, true);
END;
$d85_4_not_valid$;

SELECT 'acao' AS fase, 'checks_criados_not_valid' AS objeto,
       current_setting('manaloom.d85_4_criados') AS quantidade;

-- Transação 2: validar o que ainda está NOT VALID. Na prévia, a mesma transação.
\if :lote_grava
COMMIT;
BEGIN;
\endif
SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '300s';
SET LOCAL manaloom.lote_aplicar = :'aplicar';
SET LOCAL manaloom.lote_esperado_checks_validados = :'esperado_checks_validados';

DO $d85_4_validate$
DECLARE
  pendente RECORD;
  validados INTEGER := 0;
BEGIN
  FOR pendente IN
    SELECT restricao.conrelid::regclass AS tabela, restricao.conname AS nome
    FROM pg_constraint restricao
    WHERE restricao.contype = 'c'
      AND NOT restricao.convalidated
      AND (restricao.conrelid, restricao.conname) IN (
        ('public.ml_prompt_feedback'::regclass::oid,
         'chk_ml_prompt_feedback_effectiveness_score'::name),
        ('public.notifications'::regclass::oid, 'notifications_type_check'::name),
        ('public.user_binder_items'::regclass::oid,
         'user_binder_items_currency_check'::name)
      )
    ORDER BY restricao.conname
  LOOP
    EXECUTE format(
      'ALTER TABLE %s VALIDATE CONSTRAINT %I',
      pendente.tabela,
      pendente.nome
    );
    validados := validados + 1;
  END LOOP;
  PERFORM set_config('manaloom.d85_4_validados', validados::text, true);
END;
$d85_4_validate$;

SELECT 'acao' AS fase, 'checks_validados' AS objeto,
       current_setting('manaloom.d85_4_validados') AS quantidade;

SELECT 'depois' AS fase, objeto || ':violacoes' AS objeto, violacoes::text AS quantidade
FROM d85_4_violacoes;

SELECT 'depois' AS fase, objeto || ':estado' AS objeto, estado AS quantidade
FROM d85_4_estado;

DO $d85_4_pos$
BEGIN
  IF EXISTS (SELECT 1 FROM d85_4_estado WHERE estado <> 'validado') THEN
    RAISE EXCEPTION 'd85_4: os três CHECK não ficaram validados';
  END IF;
  IF current_setting('manaloom.lote_aplicar') = '1' THEN
    IF current_setting('manaloom.d85_4_validados')::integer
       <> current_setting('manaloom.lote_esperado_checks_validados')::integer THEN
      RAISE EXCEPTION
        'd85_4 recusado: a ação validou % CHECK(s) e o esperado (-v esperado_checks_validados) é %. A validação foi desfeita.',
        current_setting('manaloom.d85_4_validados'),
        current_setting('manaloom.lote_esperado_checks_validados');
    END IF;
  END IF;
END;
$d85_4_pos$;

DROP VIEW d85_4_estado;
DROP VIEW d85_4_violacoes;

\if :lote_grava
COMMIT;
SELECT 'modo' AS fase, 'desfecho' AS objeto, 'commit' AS quantidade;
\else
ROLLBACK;
SELECT 'modo' AS fase, 'desfecho' AS objeto, 'rollback' AS quantidade;
\endif
