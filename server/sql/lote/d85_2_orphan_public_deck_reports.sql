-- D-85, correção 2: apaga os relatórios públicos órfãos de decks já apagados.
-- Recomendação 10 da frente de deck (DCK-P0-06): relatórios com `deck_id` nulo e
-- `is_public` verdadeiro, de decks apagados antes da lixeira (a chave de
-- `shared_deck_reports.deck_id` é ON DELETE SET NULL). Desde `5850540d7` eles não são
-- servidos, mas são cópias sem finalidade. O órfão privado fica fora do que foi
-- aprovado: só é contado, para o dono decidir.
--
-- Roda no lote de deploy, depois da promoção (decisão do dono de 2026-10-10, item 11),
-- pelo wrapper de escrita e com as duas aprovações canônicas no processo chamador.
-- Primeiro a prévia (o padrão): faz tudo, imprime antes, ação e depois e desfaz
-- (ROLLBACK):
--   server/bin/with_new_server_pg.sh --write-approved psql -X -v ON_ERROR_STOP=1 \
--     -At -F $'\t' -f server/sql/lote/d85_2_orphan_public_deck_reports.sql
-- Depois, com a palavra do dono sobre o número da prévia, a gravação: `-v aplicar=1`
-- exige a contagem esperada da ação e recusa tudo (RAISE) se ela não bater:
--   ... -v aplicar=1 -v esperado_orfaos_publicos_apagados=<n da prévia> ...
-- Saída: linhas `fase<TAB>objeto<TAB>quantidade` (fases modo, antes, acao e depois).
-- Uma transação só: qualquer erro desfaz tudo. Idempotente: a segunda rodada não
-- acha alvo e não muda nada.

\set ON_ERROR_STOP on
\if :{?aplicar}
\else
\set aplicar 0
\endif
\if :{?esperado_orfaos_publicos_apagados}
\else
\set esperado_orfaos_publicos_apagados ''
\endif

BEGIN;
SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '120s';
SET LOCAL manaloom.lote_aplicar = :'aplicar';
SET LOCAL manaloom.lote_esperado_orfaos_publicos_apagados = :'esperado_orfaos_publicos_apagados';

DO $d85_2_modo$
BEGIN
  IF current_setting('manaloom.lote_aplicar') NOT IN ('0', '1') THEN
    RAISE EXCEPTION
      'd85_2 recusado: -v aplicar aceita só 1 (gravar); sem ele o script é prévia. Nada foi mudado.';
  END IF;
  IF current_setting('manaloom.lote_aplicar') = '1' THEN
    IF current_setting('manaloom.lote_esperado_orfaos_publicos_apagados') !~ '^[0-9]+$' THEN
      RAISE EXCEPTION
        'd85_2 recusado: com -v aplicar=1, informe -v esperado_orfaos_publicos_apagados=<n> (a contagem da prévia). Nada foi mudado.';
    END IF;
  END IF;
END;
$d85_2_modo$;

SELECT current_setting('manaloom.lote_aplicar') = '1' AS lote_grava \gset

SELECT 'modo' AS fase, 'escrita' AS objeto,
       CASE WHEN current_setting('manaloom.lote_aplicar') = '1'
            THEN 'aplicar' ELSE 'previa' END AS quantidade;

DO $d85_2_pre$
BEGIN
  IF to_regclass('public.shared_deck_reports') IS NULL THEN
    RAISE EXCEPTION 'd85_2 recusado: a tabela shared_deck_reports não existe';
  END IF;
END;
$d85_2_pre$;

-- Nenhum relatório muda entre a contagem e a exclusão.
LOCK TABLE public.shared_deck_reports IN SHARE ROW EXCLUSIVE MODE;

SELECT 'antes' AS fase, 'relatorios' AS objeto, COUNT(*)::text AS quantidade
FROM public.shared_deck_reports;

SELECT 'antes' AS fase, 'orfaos_publicos' AS objeto, COUNT(*)::text AS quantidade
FROM public.shared_deck_reports
WHERE deck_id IS NULL AND is_public;

SELECT 'antes' AS fase, 'orfaos_privados_fora_do_escopo' AS objeto,
       COUNT(*)::text AS quantidade
FROM public.shared_deck_reports
WHERE deck_id IS NULL AND NOT is_public;

WITH apagados AS (
  DELETE FROM public.shared_deck_reports
  WHERE deck_id IS NULL AND is_public
  RETURNING id
)
SELECT 'acao' AS fase, 'orfaos_publicos_apagados' AS objeto,
       set_config('manaloom.d85_2_apagados', COUNT(*)::text, true) AS quantidade
FROM apagados;

SELECT 'depois' AS fase, 'relatorios' AS objeto, COUNT(*)::text AS quantidade
FROM public.shared_deck_reports;

SELECT 'depois' AS fase, 'orfaos_publicos' AS objeto, COUNT(*)::text AS quantidade
FROM public.shared_deck_reports
WHERE deck_id IS NULL AND is_public;

SELECT 'depois' AS fase, 'orfaos_privados_fora_do_escopo' AS objeto,
       COUNT(*)::text AS quantidade
FROM public.shared_deck_reports
WHERE deck_id IS NULL AND NOT is_public;

DO $d85_2_pos$
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.shared_deck_reports WHERE deck_id IS NULL AND is_public
  ) THEN
    RAISE EXCEPTION 'd85_2: ainda há relatório público órfão depois da exclusão';
  END IF;
  IF current_setting('manaloom.lote_aplicar') = '1' THEN
    IF current_setting('manaloom.d85_2_apagados')::bigint
       <> current_setting('manaloom.lote_esperado_orfaos_publicos_apagados')::bigint THEN
      RAISE EXCEPTION
        'd85_2 recusado: a ação apagou % relatório(s) e o esperado (-v esperado_orfaos_publicos_apagados) é %. Nada foi gravado.',
        current_setting('manaloom.d85_2_apagados'),
        current_setting('manaloom.lote_esperado_orfaos_publicos_apagados');
    END IF;
  END IF;
END;
$d85_2_pos$;

\if :lote_grava
COMMIT;
SELECT 'modo' AS fase, 'desfecho' AS objeto, 'commit' AS quantidade;
\else
ROLLBACK;
SELECT 'modo' AS fase, 'desfecho' AS objeto, 'rollback' AS quantidade;
\endif
