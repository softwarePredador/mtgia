# Proposta de fichas — cadeia de qualidade de deck — 2026-09-18

Status: `PROPOSAL · NOT_MERGED · NO_AUTHORITY`

Este documento não é autoridade. As linhas da Parte 2 aguardam decisão do dono
para entrar no backlog mestre (a edição que bloqueava, `f6f791098`, já landou).

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
| `BT-UIEV-001` | P0 CORE | IN_PROGRESS_CONTAINED | Restabelecer a prova de UI viva após mudança de fonte, com pin único de ChromeDriver. | `BT-SCP-001` | `manaloom_local_ci.sh quick` passa sem --no-verify; os 23 manifests de docs/qa/ui-live/latest.json no digest corrente e latest.json reescrito. Evidência: b397f477b, 9a9ba66de, d08c18717; receipt docs/qa/execution/2026-09-21/btuiev001-chromedriver-e-recaptura.md (22/23 em 8bba809c). |
| `BT-META-001` | P0 AI | TODO | Filtrar o corpus de meta insights por formato Commander. | — | `extract_meta_insights` ignora decks não-Commander; o ranking do pool deixa de ser liderado por staples de Legacy/Vintage. |
| `BT-META-002` | P0 AI | TODO | Tornar `card_meta_insights.usage_count` idempotente e com decaimento. | `BT-META-001` | Rodar o extractor duas vezes não altera o resultado; carta ausente do corpus corrente perde posição; divergência corpus↔tabela vai a zero. |
| `BT-FRESH-001` | P1 | TODO | Comparar a lista oficial de Game Changers com a fonte upstream, não só JSON↔Dart. | `BT-CAT-01` | O gate falha quando `source_checked_at` excede o limite de idade ou quando a lista upstream diverge; segue read-only, com provenance. |
| `BT-HERMES-RET-001` | P2 | TODO | Decidir formalmente o destino do serviço `hermes-lab` e emitir receipt. | — | Serviço parado ou mantido por decisão registrada; `OPENAI_API_KEY` e `HERMES_GITHUB_TOKEN` revogados se parado; nenhum documento restante o descreve como frota ativa. |
```

### Justificativa de cada uma

**`BT-CI-001` — RESOLVIDO em 2026-09-18, commit `d83e9b1e1`.** Linha para o
backlog mestre:

```
| `BT-CI-001` | P0 CORE | IMPLEMENTED_LOCAL_PENDING_FULL_GATE | Suíte de project logic roda dentro do bootstrap frio; bootstrap e validação usam a mesma lista de pacotes. | — | `manaloom_project_logic.sh --test` passa; divergência bootstrap↔validação falha por mutação. Commits d83e9b1e1, 07014b431; receipt formal pendente. |
```

Causa raiz: `bin/manaloom_project_logic.dart` chamava um
`_bootstrapWorkspacePackages(root)` **privado** antes de `generate()`. Essa
função roda `pub get --offline --enforce-lockfile` em `''`, `app` e `server`
com `includeParentEnvironment: true`, amarrando cada `package_config.json` ao
`PUB_CACHE` task-scoped. `generate()` valida exatamente essa amarração.

`project_logic_generator_test.dart` chamava `generate()` direto. Nunca fazia o
bootstrap, então validava uma amarração que ninguém havia estabelecido. Era
**assimetria entre dois pontos de entrada** — não ovo-e-galinha, não o
`dart test` reescrevendo nada.

Três hipóteses foram testadas e descartadas antes da certa: propagar a env var
(implementada como modo `--test`, continuou falhando), cascata de Dart
workspace (é Melos, sem `workspace:`), e divergência entre raiz lógica e
física (`pwd -L` = `pwd -P`, sem symlink). A resposta veio de instrumentar o
gerador, não de raciocinar sobre o script.

Correção aplicada: `bootstrapWorkspacePackages` movida para a biblioteca e
tornada pública; `workspacePackageRelativePaths` virou constante compartilhada
entre o bootstrap e a validação, que antes duplicavam o literal; o teste passa
a fazer o bootstrap; o script ganhou modo `--test`; o CI usa esse modo.

Verificado com hook ativo: `Project logic is synchronized (9 artifacts)` e
`All tests passed!` (40 testes, incluindo o de drift).

---

**`BT-UIEV-001`** — o bloqueio que sobrou no caminho de commit, e é de outra
natureza. Levantado em 2026-09-21.

Com o project logic verde, o `quick` passa a parar em `run_ui_live_evidence`
(`manaloom_local_ci.sh:222`) com `review source digest is stale`,
`capture source digest is stale` e `runtime capture manifest hash does not
match`. **23 dos 35 packs** de captura estão defasados.

**O digest é global, por desenho.** `scripts/manaloom_ui_source_digest.sh`
computa um único SHA-256 sobre `app/lib`, `app/assets`, `app/web`, recursos e
build files do Android, os dois pubspecs, os 11 testes de prova visual, os
drivers e as fixtures de matriz. Não existe granularidade por superfície:
**qualquer** mudança em `app/lib` invalida todos os packs de uma vez. A
entrega do Jogar contra IA tocou 13 arquivos ali, e foi o suficiente.

Isso é deliberado e defensável — nenhuma evidência visual sobrevive a uma
mudança de fonte não revisada. Mas elimina a opção de recapturar só a parte
afetada.

**Bloqueio de ambiente adicional.** A captura usa `flutter drive` contra build
real de Chrome, com ChromeDriver pinado. Medido:

Resolvido em `b397f477b`: pin único `153.0.8010.52` em
`scripts/lib/manaloom_chromedriver.sh`, bootstrap com SHA-256, contrato "every
ChromeDriver consumer resolves through the shared pin". Ver receipt
`2026-09-21/btuiev001-chromedriver-e-recaptura.md`.

Estado em 2026-09-21: recapturado (22/23). Falta: (1) o estágio esperar a
liberação de `server/build`; (2) recapturar `play-vs-ai-web-real`; (3)
reescrever `latest.json` com 23 manifests.

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

1. `BT-SCP-001` (`NOW`) só destrava commit/push sem bypass depois de
   `BT-UIEV-001` fechar `latest.json` e do bump `next` 15.5.25 / `sharp`
   0.35.4 (autorizado pelo dono em 2026-09-21, execução pendente).
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
