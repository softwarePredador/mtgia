-- D-85, correção 5, passo a (só leitura): gera o arquivo de `card_rulings_legacy`
-- (o resto da 016, sem consumidor) e do enum `poststatus` (só da produção), que a
-- higiene da D-49 manda arquivar antes de apagar. O passo b
-- (`d85_5b_drop_legacy_ruling_poststatus.sql`) só apaga se o conteúdo do banco
-- ainda for byte a byte o deste arquivo.
--
-- O arquivo é JSON Lines: a primeira linha é o enum (se existir) e depois uma linha
-- por registro da tabela (se existir), na ordem binária do texto. O psql não escreve
-- mais nada na saída, então o sha256 e o número de linhas do arquivo são os que o
-- passo b recalcula no banco.
--
-- Roda no lote, antes do passo b, pelo wrapper em modo leitura, com a saída no
-- diretório de backups da D-84 (`backups/manaloom-postgres/`, cifrado em repouso pelo
-- FileVault):
--   server/bin/with_new_server_pg.sh --read-only psql -X -v ON_ERROR_STOP=1 \
--     -f server/sql/lote/d85_5a_legacy_ruling_poststatus_archive.sql \
--     > backups/manaloom-postgres/d85-5-legado-<UTC>.jsonl
--   shasum -a 256 backups/manaloom-postgres/d85-5-legado-<UTC>.jsonl
--   wc -l < backups/manaloom-postgres/d85-5-legado-<UTC>.jsonl
-- O sha256 e as linhas vão para o receipt e para o passo b.

\set ON_ERROR_STOP on
\set QUIET on
\encoding UTF8
\pset format unaligned
\pset tuples_only on
\pset footer off

BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ READ ONLY;

SELECT to_regtype('public.poststatus') IS NOT NULL AS d85_5_tem_tipo,
       to_regclass('public.card_rulings_legacy') IS NOT NULL AS d85_5_tem_tabela
\gset

\if :d85_5_tem_tipo
SELECT json_build_object(
         'objeto', 'public.poststatus',
         'tipo', 'enum',
         'rotulos', (
           SELECT json_agg(enum_row.enumlabel ORDER BY enum_row.enumsortorder)
           FROM pg_enum enum_row
           WHERE enum_row.enumtypid = 'public.poststatus'::regtype
         )
       )::text;
\endif

\if :d85_5_tem_tabela
SELECT arquivo.linha
FROM (
  SELECT json_build_object(
           'objeto', 'public.card_rulings_legacy',
           'linha', row_to_json(registro)
         )::text AS linha
  FROM public.card_rulings_legacy registro
) arquivo
ORDER BY arquivo.linha COLLATE "C";
\endif

ROLLBACK;
