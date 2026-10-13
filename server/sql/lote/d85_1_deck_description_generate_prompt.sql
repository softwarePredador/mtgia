-- D-85, correção 1: limpa de `decks.description` o prompt do Generate que o app
-- antigo gravava ali (`deck_generate_screen` salvava `description = prompt`).
-- Recomendação 5 da frente de deck (DCK-P0-04, D-29): limpar "a descrição igual ao
-- prompt salvo do Generate". Só entra a descrição que é igual, sem espaço nas
-- pontas, a um prompt salvo do mesmo dono:
--   - `ai_generate_jobs.result->>'prompt'` (resposta guardada do Generate assíncrono);
--   - `ai_generate_requests.prompt` (pedido durável da 069, enquanto o prompt existe).
-- Descrição que não bate com prompt salvo fica como está: não há como saber se era
-- prompt. A descrição vira NULL, como a do deck que o Generate novo materializa.
-- A revisão do deck e o ledger da 067 não mudam: é correção governada, não mudança
-- do dono, e o ledger só registra o que as rotas mudam.
--
-- Na produção, o esperado é achar 0 (D-118). O app antigo só deixava o prompt em
-- `ai_generate_jobs.result`, e a limpeza do próprio backend apaga cada job 30 minutos
-- depois de criado (`_cleanup` em `server/lib/ai_generate_job.dart`, `_jobTtl`, já
-- assim em 41bab49c9). O Generate novo (069) materializa o deck com a descrição NULL.
-- Então a regra não tem com o que comparar a descrição dos decks antigos. Na sessão
-- de leitura do lote, `server/sql/readonly/d85_1_generate_origin_count.sql` conta os
-- decks que vieram do Generate pela marca de origem, se houver: com marca, o dono
-- decide com o número; sem marca, esta correção é um no-op documentado (a prévia
-- mostra 0 e nada é gravado).
--
-- Roda no lote de deploy, depois da promoção (decisão do dono de 2026-10-10, item 11),
-- pelo wrapper de escrita e com as duas aprovações canônicas no processo chamador.
-- Primeiro a prévia (o padrão): faz tudo, imprime antes, ação e depois e desfaz
-- (ROLLBACK):
--   server/bin/with_new_server_pg.sh --write-approved psql -X -v ON_ERROR_STOP=1 \
--     -At -F $'\t' -f server/sql/lote/d85_1_deck_description_generate_prompt.sql
-- Depois, com a palavra do dono sobre o número da prévia, a gravação: `-v aplicar=1`
-- exige a contagem esperada da ação e recusa tudo (RAISE) se ela não bater:
--   ... -v aplicar=1 -v esperado_descricoes_limpas=<n da prévia> ...
-- Saída: linhas `fase<TAB>objeto<TAB>quantidade` (fases modo, antes, acao e depois).
-- Uma transação só: qualquer erro desfaz tudo. Idempotente: a segunda rodada não
-- acha alvo e não muda nada.

\set ON_ERROR_STOP on
\if :{?aplicar}
\else
\set aplicar 0
\endif
\if :{?esperado_descricoes_limpas}
\else
\set esperado_descricoes_limpas ''
\endif

BEGIN;
SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '120s';
SET LOCAL manaloom.lote_aplicar = :'aplicar';
SET LOCAL manaloom.lote_esperado_descricoes_limpas = :'esperado_descricoes_limpas';

DO $d85_1_modo$
BEGIN
  IF current_setting('manaloom.lote_aplicar') NOT IN ('0', '1') THEN
    RAISE EXCEPTION
      'd85_1 recusado: -v aplicar aceita só 1 (gravar); sem ele o script é prévia. Nada foi mudado.';
  END IF;
  IF current_setting('manaloom.lote_aplicar') = '1' THEN
    IF current_setting('manaloom.lote_esperado_descricoes_limpas') !~ '^[0-9]+$' THEN
      RAISE EXCEPTION
        'd85_1 recusado: com -v aplicar=1, informe -v esperado_descricoes_limpas=<n> (a contagem da prévia). Nada foi mudado.';
    END IF;
  END IF;
END;
$d85_1_modo$;

SELECT current_setting('manaloom.lote_aplicar') = '1' AS lote_grava \gset

SELECT 'modo' AS fase, 'escrita' AS objeto,
       CASE WHEN current_setting('manaloom.lote_aplicar') = '1'
            THEN 'aplicar' ELSE 'previa' END AS quantidade;

DO $d85_1_pre$
BEGIN
  IF to_regclass('public.ai_generate_requests') IS NULL
     OR NOT EXISTS (
       SELECT 1 FROM public.schema_migrations WHERE version = '069'
     ) THEN
    RAISE EXCEPTION
      'd85_1 recusado: a migration 069 (ai_generate_requests) ainda não foi aplicada';
  END IF;
END;
$d85_1_pre$;

-- Nenhuma descrição muda entre a contagem e a limpeza.
LOCK TABLE public.decks IN SHARE ROW EXCLUSIVE MODE;

-- Objeto temporário dentro da transação: some no COMMIT ou no ROLLBACK da prévia.
CREATE TEMP VIEW d85_1_alvo AS
SELECT deck.id
FROM public.decks deck
WHERE NULLIF(btrim(deck.description), '') IS NOT NULL
  AND (
    EXISTS (
      SELECT 1
      FROM public.ai_generate_jobs job
      WHERE job.user_id = deck.user_id
        AND jsonb_typeof(job.result) = 'object'
        AND btrim(job.result ->> 'prompt') = btrim(deck.description)
    )
    OR EXISTS (
      SELECT 1
      FROM public.ai_generate_requests request
      WHERE request.user_id = deck.user_id
        AND request.prompt IS NOT NULL
        AND btrim(request.prompt) = btrim(deck.description)
    )
  );

SELECT 'antes' AS fase, 'decks_com_descricao' AS objeto, COUNT(*)::text AS quantidade
FROM public.decks
WHERE NULLIF(btrim(description), '') IS NOT NULL;

SELECT 'antes' AS fase, 'descricao_igual_a_prompt_salvo' AS objeto,
       COUNT(*)::text AS quantidade
FROM d85_1_alvo;

WITH limpos AS (
  UPDATE public.decks deck
  SET description = NULL
  WHERE deck.id IN (SELECT id FROM d85_1_alvo)
  RETURNING deck.id
)
SELECT 'acao' AS fase, 'descricoes_limpas' AS objeto,
       set_config('manaloom.d85_1_limpas', COUNT(*)::text, true) AS quantidade
FROM limpos;

SELECT 'depois' AS fase, 'decks_com_descricao' AS objeto, COUNT(*)::text AS quantidade
FROM public.decks
WHERE NULLIF(btrim(description), '') IS NOT NULL;

SELECT 'depois' AS fase, 'descricao_igual_a_prompt_salvo' AS objeto,
       COUNT(*)::text AS quantidade
FROM d85_1_alvo;

DO $d85_1_pos$
BEGIN
  IF EXISTS (SELECT 1 FROM d85_1_alvo) THEN
    RAISE EXCEPTION 'd85_1: ainda há descrição igual a prompt salvo depois da limpeza';
  END IF;
  IF current_setting('manaloom.lote_aplicar') = '1' THEN
    IF current_setting('manaloom.d85_1_limpas')::bigint
       <> current_setting('manaloom.lote_esperado_descricoes_limpas')::bigint THEN
      RAISE EXCEPTION
        'd85_1 recusado: a ação limpou % descrição(ões) e o esperado (-v esperado_descricoes_limpas) é %. Nada foi gravado.',
        current_setting('manaloom.d85_1_limpas'),
        current_setting('manaloom.lote_esperado_descricoes_limpas');
    END IF;
  END IF;
END;
$d85_1_pos$;

DROP VIEW d85_1_alvo;

\if :lote_grava
COMMIT;
SELECT 'modo' AS fase, 'desfecho' AS objeto, 'commit' AS quantidade;
\else
ROLLBACK;
SELECT 'modo' AS fase, 'desfecho' AS objeto, 'rollback' AS quantidade;
\endif
