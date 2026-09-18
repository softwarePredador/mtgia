# Proposta de fichas — cadeia de qualidade de deck — 2026-09-18

Status: `PROPOSAL · NOT_MERGED · NO_AUTHORITY`

Este documento **não** é autoridade. Ele existe porque
`docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md` e
`docs/execution/CURRENT_QUEUE.md` estão sob edição em andamento (renomeação de
"Coach" para "Jogar contra IA", inclusão de `BT-PLAY-001/002`), e escrever
neles agora colidiria com esse trabalho.

As linhas abaixo estão prontas para colar no backlog mestre quando a edição
em curso fechar. Até lá, nenhuma delas tem ID reservado nem posição na fila.

Origem factual: `docs/DECK_QUALITY_MODEL.md`, verificado contra código em
`a2d044618`. Números de banco vêm do backup local de 2026-08-03.

---

## Parte 1 — Não criar ID novo: enriquecer IDs existentes

A investigação de 2026-09-18 produziu **detalhe de mecanismo**, não tarefas
novas. Três IDs já existentes cobrem o escopo e devem receber o detalhe em vez
de competir com um ID paralelo.

### `BT-AI-011` — vincular comandante à execução Generate

Estado atual no backlog: `P0 GENERATE · IN_PROGRESS_CONTAINED`.

O aceite hoje fala em fingerprint, cache e resultado. Falta o mecanismo que
torna o vínculo real:

> O pool determinístico de candidatos
> (`server/lib/ai/optimize_filler_loader_support.dart:1263-1320`) recebe
> apenas `identity` e `legality_format`. **O comandante não é parâmetro.**
> Dois comandantes de mesma identidade de cor recebem a mesma lista de 600
> cartas. `compareCandidates` (`:516-533`) desempata por penalidade de slot,
> nome preferido, ordem do SQL e alfabético — **sem termo de sinergia**.
> Aceite adicional sugerido: a query aceita o comandante e o ranking muda de
> forma observável entre dois comandantes da mesma identidade.

### `BT-CAT-01` — refresh de catálogo em job/CLI interno

Estado atual: `P0 CORE · TODO`. Já é o guarda-chuva correto.

Detalhe verificado a anexar:

> Os oito scripts de sync externo (`cron_sync_cards`, `cron_sync_combos`,
> `cron_sync_prices`, `cron_sync_prices_mtgjson`, `cron_sync_rulings`,
> `cron_sync_staples`, `cron_snapshot_edhrec`, `cron_snapshot_price_history`)
> existem e são determinísticos, mas **nunca foram registrados** em
> `server/bin/manaloom_ops_daemon.py` `JOBS`. São receitas de crontab em
> comentário. Frescor medido em 2026-09-18: catálogo 104 dias, EDHREC 108
> dias. Esta lane depende de `catalog_private`
> (`implemented_p0_open`, sem PII e sem superfície de consentimento) e **não**
> de `learning_writes`, que está bloqueada por schema — as duas devem ser
> tratadas separadamente.

### `BT-AI-017` — snapshot/provenance/freshness das referências Commander

Estado atual: `P1 · IN_PROGRESS_CONTAINED`.

> Não existe caminho automatizado de escrita em
> `commander_reference_profiles`: `upsertCommanderReferenceProfile` só é
> chamado por dois CLIs manuais. Enquanto isso, a cobertura não cresce e
> praticamente toda geração cai no caminho sem perfil. A cobertura real é
> **desconhecida** — o README do lote Strixhaven registra "no database apply
> was run" e os payloads de lote 2 / Anchor 30 foram removidos em
> `8cab6400b`. Fechar com leitura read-only antes de estimar esforço.

---

## Parte 2 — Linhas novas propostas

Formato da tabela do backlog: `ID | prioridade | estado | entrega | dependências | aceite`.

```
| `BT-CI-001` | P0 CORE | TODO | Fazer a suíte do project logic rodar dentro do cold bootstrap, resolvendo o conflito entre o binding de PUB_CACHE e o próprio `dart test`. | `BT-SCP-001` | `manaloom_local_ci.sh quick` e `full` passam sem bypass; `git commit` e `git push` deixam de exigir `--no-verify`. |
| `BT-META-001` | P0 AI | TODO | Filtrar o corpus de meta insights por formato Commander. | — | `extract_meta_insights` ignora decks não-Commander; o ranking do pool deixa de ser liderado por staples de Legacy/Vintage. |
| `BT-META-002` | P0 AI | TODO | Tornar `card_meta_insights.usage_count` idempotente e com decaimento. | `BT-META-001` | Rodar o extractor duas vezes não altera o resultado; carta ausente do corpus corrente perde posição; divergência corpus↔tabela vai a zero. |
| `BT-FRESH-001` | P1 | TODO | Comparar a lista oficial de Game Changers com a fonte upstream, não só JSON↔Dart. | `BT-CAT-01` | O gate falha quando `source_checked_at` excede o limite de idade ou quando a lista upstream diverge; segue read-only, com provenance. |
| `BT-HERMES-RET-001` | P2 | TODO | Decidir formalmente o destino do serviço `hermes-lab` e emitir receipt. | — | Serviço parado ou mantido por decisão registrada; `OPENAI_API_KEY` e `HERMES_GITHUB_TOKEN` revogados se parado; nenhum documento restante o descreve como frota ativa. |
```

### Justificativa de cada uma

**`BT-CI-001`** — bloqueia tudo. Investigado em 2026-09-18 até o ponto em que
a continuação exige contexto de desenho do `BT-SCP-001`. O que está
estabelecido, o que foi descartado, e a pergunta que resta:

**Fatos verificados**

| Fato | Onde |
| --- | --- |
| O CI roda `dart test` fora do ambiente preparado | `scripts/manaloom_local_ci.sh:105-112` |
| O script **não reescreve** `package_config.json` — faz snapshot e restaura byte a byte | `manaloom_project_logic.sh:439-470` |
| Existe **um único** `pub get`, e só em `tools/project_logic` | `:544` |
| `generate()` chama `_validateWorkspacePackageMetadata()` como primeira instrução, sem guarda | `project_logic_generator.dart:285-286` |
| A validação exige que raiz, `app` e `server` apontem para o task cache | `:547` |
| Modificar o próprio script muda o digest de fonte do project logic | observado: uma sonda temporária causou drift sozinha |

**Hipóteses descartadas com evidência**

1. *"Basta propagar `MANALOOM_PROJECT_LOGIC_TASK_PUB_CACHE` para o subshell."*
   Não basta. Foi implementado um modo `--test` que roda a suíte dentro do
   ambiente materializado; o `setUpAll` continua abortando com
   `.dart_tool/package_config.json points outside the task PUB_CACHE`, e o
   caminho relativo é o da raiz. A mudança foi revertida.
2. *"É um Dart workspace, então resolver um membro reescreve a raiz."*
   Não é. O repositório é Melos: não há `workspace:` no `pubspec.yaml` da raiz
   nem `resolution: workspace` nos membros.
3. *"O script separa raiz lógica de física (`cd -P` + `MANALOOM_PROJECT_LOGIC_LOGICAL_ROOT`),
   então script e teste olham `.dart_tool` diferentes."* Não. Medido:
   `pwd -L` e `pwd -P` são idênticos e nenhum componente do caminho é symlink.

**A contradição em aberto**

Os fatos acima são mutuamente inconsistentes. Se o script nunca reescreve o
config da raiz, e a validação exige a raiz no task cache sem guarda, então
`--check` deveria falhar sempre. **E `--check` passa.**

Uma sonda temporária leu, no momento imediatamente anterior à chamada do
gerador, `raiz pubCache = file:///Users/<user>/.pub-cache` — o cache global.

Busca exaustiva feita depois disso, e o resultado **fecha** a contradição em
vez de abri-la: o script tem exatamente duas invocações de Dart
(`pub get` em `tools/project_logic` e o binário do gerador), nenhum script do
repositório escreve a chave `pubCache` em lugar nenhum, e `seed_task_cache`
apenas copia pacotes do cache global para o task cache — não toca em
`package_config.json`. O binário chama `generate()` nos dois modos
(`bin/manaloom_project_logic.dart:29`), e `generate()` chama a validação como
primeira instrução.

Logo: pelo código lido, `--check` deveria falhar sempre — e passa. A
explicação **não está** em nenhuma das três hipóteses testadas, e resolvê-la
exige instrumentar o próprio gerador, o que altera o digest e mexe no núcleo
do `BT-SCP-001`. É onde esta investigação para.

**Escopo medido em 2026-09-18.** Com o drift resolvido, foi feita uma
tentativa de commit com o hook **ativo**. O `manaloom_local_ci.sh quick`
passou em tudo — contratos de shell, fonte de Game Changers, MCP local,
secret scan, e `Project logic is synchronized (9 artifacts)` — e parou em
`8 passed, 1 failed`, com a única falha sendo
`test/project_logic_generator_test.dart: (setUpAll)`.

Ou seja: **o escopo desta ficha é um único `setUpAll`.** Destravado ele,
`git commit` e `git push` voltam a passar sem bypass.

**Pergunta que fecha a ficha:** por que `--check` passa se a raiz não aponta
para o task cache? Respondida isso, a correção do CI decorre — e só então faz
sentido escolher entre fazer o `dart test` participar do cold bootstrap ou dar
ao `setUpAll` um ponto de injeção para o caso "sob teste".

**Custo de não ter o gate**, observado nesta sessão: registrar dois documentos
em `canonical_documents` mudou o digest de fonte e deixou os artefatos
defasados. O gate de drift existe para barrar isso no commit; com
`--no-verify` passou e exigiu correção posterior.

**`BT-META-001`** — maior retorno por esforço de toda a cadeia, e é um `WHERE`.
`server/bin/extract_meta_insights.dart:134-149` lê `SELECT ... FROM meta_decks
ORDER BY created_at DESC`, sem cláusula `WHERE`. Composição medida do corpus
(653 decks): cEDH 34,2%, EDH 24,8%, e **39% Standard, Pioneer, Vintage,
Modern, Pauper e Legacy**. O topo do ranking que ordena o pool inteiro é
`Force of Will`, `Thoughtseize`, `Wasteland`, `Steam Vents`.

**`BT-META-002`** — `extract_meta_insights.dart:838` faz
`usage_count = card_meta_insights.usage_count + @usage`. Sem idempotência e
sem decaimento: o valor mede quantas vezes o script rodou, não o meta. No
backup, 29.593 nomes gravados não existem no corpus atual.

**`BT-FRESH-001`** — `commander_game_changers.json` tem
`source_checked_at=2026-07-14` apontando para um anúncio de 2026-02-09. O
drift gate valida atribuição de fonte, 53 nomes e igualdade JSON↔Dart, mas
**nunca consulta a WotC**. Isso alimenta `edh_bracket_policy.dart`. O molde de
auditoria upstream já existe e roda no gate:
`docs/hermes-analysis/manaloom-knowledge/scripts/external_engine_upstream_delta_audit.py`.

**`BT-HERMES-RET-001`** — o serviço está dormente desde 2026-06-23, nenhum
documento o governa, e dois segredos seguem válidos. Ver a análise em
`docs/qa/execution/2026-09-18/deck-quality-harness.md`.

---

## Parte 3 — Ordem recomendada

1. `BT-SCP-001` (já é o slot `NOW`) → destrava commit/push sem bypass, e
   `BT-CI-001` sai junto ou logo depois.
2. `BT-FRESH-001` → bug de produto vivo, barato, independente do resto.
3. `BT-META-001` e `BT-META-002` → limpam o sinal.
4. `BT-AI-011` → só depois de 3, porque sinergia sobre sinal contaminado é
   otimizar ruído.
5. `BT-CAT-01` → lane de ingestão, separada da de learning.
6. `BT-AI-017` e `BT-HERMES-RET-001` → sem urgência.

`DCK-P0-05`, `BT-AI-001`, `BT-AI-014` e `BT-AI-030` (lane de learning de
usuário) continuam onde estão. O schema não permite cumprir revogação por
sujeito — `deck_learning_events` não tem `user_id` nem coluna de
consentimento, e `commander_card_usage` é agregado irreversível. Ligar
learning antes disso cria obrigação que o banco não cumpre.

---

## Medição

`scripts/quality_gate.sh deck-quality` pontua consistência de mana de forma
determinística sobre 17 decks reais, com baseline de tolerância zero. Serve
para provar que `BT-META-001/002` e `BT-AI-011` não pioraram a base de mana.
**Não** mede potência de deck — ver
`server/test/ai/deck_quality_report_limits_test.dart`.

## Verificações pendentes que mudam estimativa

```bash
# cobertura real de perfis: muda a escala de BT-AI-017 e BT-AI-011
psql "$DATABASE_URL" -c "select commander_name, source, updated_at from commander_reference_profiles order by updated_at desc;"

# estado do container hermes-lab: entrada de BT-HERMES-RET-001
python3 server/bin/audit_easypanel_cron_runtime.py --require-hermes-lab
```
