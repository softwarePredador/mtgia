-- D-74 (BT-CAT-01): funde os sets duplicados só por maiúscula e minúscula antes da
-- migration 077, que cria o índice único em LOWER(code) (decisão do dono de
-- 2026-10-10, item 22). Na produção eram 84 códigos em 971 linhas para 887 códigos
-- (receipt 2026-09-23/BT-CAT-01-ativacao-do-catalogo.md).
--
-- Em cada grupo de LOWER(code), fica a linha que as leituras já mostram como
-- canônica (a regra de `GET /sets`): a data de lançamento mais nova, depois o código
-- em maiúscula, depois o nome e, por último, o código em ordem binária. A que fica
-- herda das outras o que ela não tem (release_date, type, block, is_online_only e
-- is_foreign_only nulos); o resto dela não muda.
--
-- Quem aponta para `sets`:
--   - chave estrangeira: nenhuma nas migrations, no `database_setup.sql` nem na
--     auditoria da produção (BT-DB-001). Mesmo assim o script procura no catálogo
--     todas as chaves para `public.sets` e, antes de apagar, leva para a linha que
--     fica toda referência de uma coluna a `sets.code` que aponte para uma que sai;
--     chave de outra forma (várias colunas ou outra coluna de `sets`) recusa tudo;
--   - `cards.set_code` é texto, sem chave, gravado pelo job do catálogo (BT-CAT-01).
--     Toda leitura compara sem caixa (LOWER), e a 077 deixa uma linha por código;
--     o script só conta as cartas cujo código exato era o de uma linha que saiu.
--
-- Roda no lote de deploy, depois da 076 e antes da 077, na janela das migrations,
-- pelo wrapper de escrita e com as duas aprovações canônicas no processo chamador.
-- Primeiro a prévia (o padrão): faz tudo, imprime antes, ação e depois e desfaz
-- (ROLLBACK):
--   server/bin/with_new_server_pg.sh --write-approved psql -X -v ON_ERROR_STOP=1 \
--     -At -F $'\t' -f server/sql/lote/d74_dedupe_sets_lower_code.sql
-- Depois, com a palavra do dono sobre os números da prévia, a gravação: `-v aplicar=1`
-- exige as três contagens esperadas da ação e recusa tudo (RAISE) se uma não bater:
--   ... -v aplicar=1 \
--       -v esperado_referencias_levadas_para_a_linha_que_fica=<n da prévia> \
--       -v esperado_linhas_que_ficam_com_campo_herdado=<n da prévia> \
--       -v esperado_linhas_apagadas=<n da prévia> ...
-- Saída: linhas `fase<TAB>objeto<TAB>quantidade` (fases modo, antes, acao e depois).
-- Uma transação só, com `sets` travada contra escrita (o job do catálogo espera).
-- Idempotente: sem duplicata, não muda nada.

\set ON_ERROR_STOP on
\if :{?aplicar}
\else
\set aplicar 0
\endif
\if :{?esperado_referencias_levadas_para_a_linha_que_fica}
\else
\set esperado_referencias_levadas_para_a_linha_que_fica ''
\endif
\if :{?esperado_linhas_que_ficam_com_campo_herdado}
\else
\set esperado_linhas_que_ficam_com_campo_herdado ''
\endif
\if :{?esperado_linhas_apagadas}
\else
\set esperado_linhas_apagadas ''
\endif

BEGIN;
SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '300s';
SET LOCAL manaloom.lote_aplicar = :'aplicar';
SET LOCAL manaloom.lote_esperado_apontadas = :'esperado_referencias_levadas_para_a_linha_que_fica';
SET LOCAL manaloom.lote_esperado_fundidas = :'esperado_linhas_que_ficam_com_campo_herdado';
SET LOCAL manaloom.lote_esperado_apagadas = :'esperado_linhas_apagadas';

DO $d74_modo$
BEGIN
  IF current_setting('manaloom.lote_aplicar') NOT IN ('0', '1') THEN
    RAISE EXCEPTION
      'd74 recusado: -v aplicar aceita só 1 (gravar); sem ele o script é prévia. Nada foi mudado.';
  END IF;
  IF current_setting('manaloom.lote_aplicar') = '1' THEN
    IF (
      current_setting('manaloom.lote_esperado_apontadas') !~ '^[0-9]+$'
      OR current_setting('manaloom.lote_esperado_fundidas') !~ '^[0-9]+$'
      OR current_setting('manaloom.lote_esperado_apagadas') !~ '^[0-9]+$'
    ) THEN
      RAISE EXCEPTION
        'd74 recusado: com -v aplicar=1, informe -v esperado_referencias_levadas_para_a_linha_que_fica=<n>, -v esperado_linhas_que_ficam_com_campo_herdado=<n> e -v esperado_linhas_apagadas=<n> (as contagens da prévia). Nada foi mudado.';
    END IF;
  END IF;
END;
$d74_modo$;

SELECT current_setting('manaloom.lote_aplicar') = '1' AS lote_grava \gset

SELECT 'modo' AS fase, 'escrita' AS objeto,
       CASE WHEN current_setting('manaloom.lote_aplicar') = '1'
            THEN 'aplicar' ELSE 'previa' END AS quantidade;

LOCK TABLE public.sets IN SHARE ROW EXCLUSIVE MODE;

-- Tabelas temporárias dentro da transação (ON COMMIT DROP): somem no COMMIT ou no
-- ROLLBACK da prévia.
CREATE TEMP TABLE d74_grupo ON COMMIT DROP AS
SELECT set_row.code,
       LOWER(set_row.code) AS chave,
       ROW_NUMBER() OVER (
         PARTITION BY LOWER(set_row.code)
         ORDER BY
           set_row.release_date DESC NULLS LAST,
           CASE WHEN set_row.code = UPPER(set_row.code) THEN 0 ELSE 1 END,
           set_row.name ASC,
           set_row.code COLLATE "C" ASC
       ) AS posicao,
       COUNT(*) OVER (PARTITION BY LOWER(set_row.code)) AS linhas_no_grupo
FROM public.sets set_row;

CREATE TEMP TABLE d74_troca ON COMMIT DROP AS
SELECT sai.code AS sai, fica.code AS fica
FROM d74_grupo sai
JOIN d74_grupo fica ON fica.chave = sai.chave AND fica.posicao = 1
WHERE sai.posicao > 1;

SELECT 'antes' AS fase, 'sets' AS objeto, COUNT(*)::text AS quantidade
FROM public.sets;

SELECT 'antes' AS fase, 'codigos_sem_caixa' AS objeto,
       COUNT(DISTINCT LOWER(code))::text AS quantidade
FROM public.sets;

SELECT 'antes' AS fase, 'codigos_duplicados' AS objeto,
       COUNT(DISTINCT chave)::text AS quantidade
FROM d74_grupo
WHERE linhas_no_grupo > 1;

SELECT 'antes' AS fase, 'linhas_a_mais' AS objeto, COUNT(*)::text AS quantidade
FROM d74_troca;

SELECT 'antes' AS fase, 'chaves_estrangeiras_para_sets' AS objeto,
       COUNT(*)::text AS quantidade
FROM pg_constraint
WHERE contype = 'f' AND confrelid = 'public.sets'::regclass;

SELECT 'antes' AS fase, 'cartas_com_codigo_exato_de_linha_que_sai' AS objeto,
       COUNT(*)::text AS quantidade
FROM public.cards card
WHERE card.set_code IN (SELECT sai FROM d74_troca);

DO $d74_dedupe$
DECLARE
  chave_estrangeira RECORD;
  apontadas BIGINT := 0;
  linhas BIGINT;
  fundidas BIGINT;
  apagadas BIGINT;
BEGIN
  FOR chave_estrangeira IN
    SELECT constraint_row.conname,
           constraint_row.conrelid::regclass AS tabela,
           constraint_row.conkey,
           constraint_row.confkey,
           (
             SELECT attribute_row.attname
             FROM pg_attribute attribute_row
             WHERE attribute_row.attrelid = constraint_row.conrelid
               AND attribute_row.attnum = constraint_row.conkey[1]
           ) AS coluna
    FROM pg_constraint constraint_row
    WHERE constraint_row.contype = 'f'
      AND constraint_row.confrelid = 'public.sets'::regclass
    ORDER BY constraint_row.conrelid::regclass::text, constraint_row.conname
  LOOP
    IF array_length(chave_estrangeira.conkey, 1) <> 1
       OR chave_estrangeira.confkey <> ARRAY[(
         SELECT attribute_row.attnum
         FROM pg_attribute attribute_row
         WHERE attribute_row.attrelid = 'public.sets'::regclass
           AND attribute_row.attname = 'code'
       )]::int2[] THEN
      RAISE EXCEPTION
        'd74 recusado: a chave % de % para sets não é de uma coluna para sets.code; nada foi mudado',
        chave_estrangeira.conname, chave_estrangeira.tabela;
    END IF;
    EXECUTE format(
      'UPDATE %s AS referencia SET %I = troca.fica '
      'FROM d74_troca AS troca WHERE referencia.%I = troca.sai',
      chave_estrangeira.tabela,
      chave_estrangeira.coluna,
      chave_estrangeira.coluna
    );
    GET DIAGNOSTICS linhas = ROW_COUNT;
    apontadas := apontadas + linhas;
  END LOOP;

  UPDATE public.sets fica
  SET release_date = COALESCE(fica.release_date, herdado.release_date),
      type = COALESCE(fica.type, herdado.type),
      block = COALESCE(fica.block, herdado.block),
      is_online_only = COALESCE(fica.is_online_only, herdado.is_online_only),
      is_foreign_only = COALESCE(fica.is_foreign_only, herdado.is_foreign_only),
      updated_at = CURRENT_TIMESTAMP
  FROM (
    SELECT troca.fica,
           (array_agg(sai.release_date ORDER BY grupo.posicao)
              FILTER (WHERE sai.release_date IS NOT NULL))[1] AS release_date,
           (array_agg(sai.type ORDER BY grupo.posicao)
              FILTER (WHERE sai.type IS NOT NULL))[1] AS type,
           (array_agg(sai.block ORDER BY grupo.posicao)
              FILTER (WHERE sai.block IS NOT NULL))[1] AS block,
           (array_agg(sai.is_online_only ORDER BY grupo.posicao)
              FILTER (WHERE sai.is_online_only IS NOT NULL))[1] AS is_online_only,
           (array_agg(sai.is_foreign_only ORDER BY grupo.posicao)
              FILTER (WHERE sai.is_foreign_only IS NOT NULL))[1] AS is_foreign_only
    FROM d74_troca troca
    JOIN public.sets sai ON sai.code = troca.sai
    JOIN d74_grupo grupo ON grupo.code = troca.sai
    GROUP BY troca.fica
  ) herdado
  WHERE fica.code = herdado.fica
    AND (
      (fica.release_date IS NULL AND herdado.release_date IS NOT NULL)
      OR (fica.type IS NULL AND herdado.type IS NOT NULL)
      OR (fica.block IS NULL AND herdado.block IS NOT NULL)
      OR (fica.is_online_only IS NULL AND herdado.is_online_only IS NOT NULL)
      OR (fica.is_foreign_only IS NULL AND herdado.is_foreign_only IS NOT NULL)
    );
  GET DIAGNOSTICS fundidas = ROW_COUNT;

  DELETE FROM public.sets set_row
  USING d74_troca troca
  WHERE set_row.code = troca.sai;
  GET DIAGNOSTICS apagadas = ROW_COUNT;

  PERFORM set_config('manaloom.d74_apontadas', apontadas::text, true);
  PERFORM set_config('manaloom.d74_fundidas', fundidas::text, true);
  PERFORM set_config('manaloom.d74_apagadas', apagadas::text, true);
END;
$d74_dedupe$;

SELECT 'acao' AS fase, 'referencias_levadas_para_a_linha_que_fica' AS objeto,
       current_setting('manaloom.d74_apontadas') AS quantidade;
SELECT 'acao' AS fase, 'linhas_que_ficam_com_campo_herdado' AS objeto,
       current_setting('manaloom.d74_fundidas') AS quantidade;
SELECT 'acao' AS fase, 'linhas_apagadas' AS objeto,
       current_setting('manaloom.d74_apagadas') AS quantidade;

SELECT 'depois' AS fase, 'sets' AS objeto, COUNT(*)::text AS quantidade
FROM public.sets;

SELECT 'depois' AS fase, 'codigos_sem_caixa' AS objeto,
       COUNT(DISTINCT LOWER(code))::text AS quantidade
FROM public.sets;

SELECT 'depois' AS fase, 'codigos_duplicados' AS objeto, COUNT(*)::text AS quantidade
FROM (
  SELECT 1 FROM public.sets GROUP BY LOWER(code) HAVING COUNT(*) > 1
) duplicados;

SELECT 'depois' AS fase, 'cartas_com_codigo_exato_de_linha_que_sai' AS objeto,
       COUNT(*)::text AS quantidade
FROM public.cards card
WHERE card.set_code IN (SELECT sai FROM d74_troca);

DO $d74_pos$
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.sets GROUP BY LOWER(code) HAVING COUNT(*) > 1
  ) THEN
    RAISE EXCEPTION 'd74: ainda há código de set duplicado sem caixa';
  END IF;
  IF current_setting('manaloom.lote_aplicar') = '1' THEN
    IF (
      current_setting('manaloom.d74_apontadas')::bigint
        <> current_setting('manaloom.lote_esperado_apontadas')::bigint
      OR current_setting('manaloom.d74_fundidas')::bigint
        <> current_setting('manaloom.lote_esperado_fundidas')::bigint
      OR current_setting('manaloom.d74_apagadas')::bigint
        <> current_setting('manaloom.lote_esperado_apagadas')::bigint
    ) THEN
      RAISE EXCEPTION
        'd74 recusado: a ação levou % referência(s), fundiu % e apagou % linha(s), e o esperado é %, % e %. Nada foi gravado.',
        current_setting('manaloom.d74_apontadas'),
        current_setting('manaloom.d74_fundidas'),
        current_setting('manaloom.d74_apagadas'),
        current_setting('manaloom.lote_esperado_apontadas'),
        current_setting('manaloom.lote_esperado_fundidas'),
        current_setting('manaloom.lote_esperado_apagadas');
    END IF;
  END IF;
END;
$d74_pos$;

\if :lote_grava
COMMIT;
SELECT 'modo' AS fase, 'desfecho' AS objeto, 'commit' AS quantidade;
\else
ROLLBACK;
SELECT 'modo' AS fase, 'desfecho' AS objeto, 'rollback' AS quantidade;
\endif
